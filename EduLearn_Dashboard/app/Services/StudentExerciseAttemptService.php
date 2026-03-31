<?php

namespace App\Services;

use App\Models\LessonExerciseSet;
use App\Models\LessonExerciseVersion;
use App\Models\LessonExerciseVersionItem;
use App\Models\StudentExerciseAnswer;
use App\Models\StudentExerciseAttempt;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class StudentExerciseAttemptService
{
    protected string $connection = 'app_mysql';

    public function getCurrentPublishedSetForStudent(LessonExerciseSet $set): ?LessonExerciseVersion
    {
        if ($set->status === 'archived') {
            return null;
        }

        return $set->activeVersion()
            ->with(['items.options'])
            ->first();
    }

    public function getOrCreateAttempt(int $studentId, LessonExerciseSet $set, LessonExerciseVersion $version): StudentExerciseAttempt
    {
        return StudentExerciseAttempt::query()->firstOrCreate(
            [
                'student_id' => $studentId,
                'exercise_set_id' => $set->id,
                'exercise_version_id' => $version->id,
            ],
            [
                'lesson_id' => $set->lesson_id,
                'status' => 'in_progress',
                'last_synced_version_id' => $version->id,
                'has_pending_changes' => false,
            ]
        );
    }

    public function getLatestAttempt(int $studentId, LessonExerciseSet $set): ?StudentExerciseAttempt
    {
        return StudentExerciseAttempt::query()
            ->where('student_id', $studentId)
            ->where('exercise_set_id', $set->id)
            ->latest('id')
            ->with([
                'answers.versionItem.options',
                'version.items.options',
            ])
            ->first();
    }

    public function saveAttempt(int $studentId, LessonExerciseSet $set, LessonExerciseVersion $version, array $answersPayload): StudentExerciseAttempt
    {
        return DB::connection($this->connection)->transaction(function () use ($studentId, $set, $version, $answersPayload) {
            $attempt = $this->getOrCreateAttempt($studentId, $set, $version);

            if ($attempt->status === 'graded') {
                throw new InvalidArgumentException('This attempt has already been submitted and graded.');
            }

            $attempt->load([
                'answers.versionItem.options',
                'version.items.options',
            ]);

            $answersByStableQuestionKey = collect($answersPayload)->keyBy('stable_question_key');

            $versionItems = $version->items()
                ->with('options')
                ->orderBy('position')
                ->get();

            foreach ($versionItems as $versionItem) {
                /** @var LessonExerciseVersionItem $versionItem */
                if (!$versionItem->is_active) {
                    continue;
                }

                $existingAnswer = $attempt->answers
                    ->firstWhere('stable_question_key', $versionItem->stable_question_key);

                $incomingAnswer = $answersByStableQuestionKey->get($versionItem->stable_question_key);

                if (!$existingAnswer) {
                    $existingAnswer = StudentExerciseAnswer::query()->firstOrNew([
                        'attempt_id' => $attempt->id,
                        'version_item_id' => $versionItem->id,
                    ]);

                    $existingAnswer->stable_question_key = $versionItem->stable_question_key;
                    $existingAnswer->answer_state = 'active';
                }

                // الأسئلة المحذوفة تاريخيًا أو المقيدة لا تُعدل
                if ($existingAnswer->answer_state === 'deleted_question' || $existingAnswer->answer_state === 'readonly_history') {
                    continue;
                }

                // إذا لم يرسل الفرونت هذا السؤال، لا نلمسه
                if (!$incomingAnswer) {
                    continue;
                }

                // أسئلة تحتاج إعادة إجابة
                if ($existingAnswer->answer_state === 'needs_reanswer') {
                    $existingAnswer->selected_option_id = null;
                    $existingAnswer->answer_text = null;
                    $existingAnswer->is_correct = null;
                    $existingAnswer->awarded_points = null;
                    $existingAnswer->checked_at = null;
                }

                if (in_array($versionItem->type, ['multiple_choice', 'true_false'], true)) {
                    $selectedOptionId = $incomingAnswer['selected_option_id'] ?? null;

                    if ($selectedOptionId) {
                        $validOption = $versionItem->options->firstWhere('id', (int) $selectedOptionId);
                        $existingAnswer->selected_option_id = $validOption?->id;
                    } else {
                        $existingAnswer->selected_option_id = null;
                    }

                    $existingAnswer->answer_text = null;
                } elseif ($versionItem->type === 'short_answer') {
                    $existingAnswer->selected_option_id = null;
                    $existingAnswer->answer_text = isset($incomingAnswer['answer_text'])
                        ? trim((string) $incomingAnswer['answer_text'])
                        : null;
                }

                $existingAnswer->is_correct = null;
                $existingAnswer->awarded_points = null;
                $existingAnswer->checked_at = null;

                if ($existingAnswer->answer_state === 'needs_reanswer') {
                    $existingAnswer->answer_state = 'active';
                }

                $existingAnswer->save();
            }

            // لو النسخة الحالية أحدث من آخر مزامنة
            $attempt->last_synced_version_id = $version->id;
            $attempt->status = 'in_progress';
            $attempt->save();

            return $attempt->fresh([
                'answers.versionItem.options',
                'version.items.options',
            ]);
        });
    }

    public function submitAttempt(int $studentId, LessonExerciseSet $set, LessonExerciseVersion $version, array $answersPayload): StudentExerciseAttempt
    {
        return DB::connection($this->connection)->transaction(function () use ($studentId, $set, $version, $answersPayload) {
            $attempt = $this->saveAttempt($studentId, $set, $version, $answersPayload);

            $attempt->load([
                'answers.versionItem.options',
                'version.items.options',
            ]);

            $score = 0.0;
            $totalPoints = 0.0;
            $correctCount = 0;
            $wrongCount = 0;
            $hasPendingChanges = false;

            $answersByVersionItemId = $attempt->answers->keyBy('version_item_id');

            foreach ($attempt->version->items as $item) {
                /** @var LessonExerciseVersionItem $item */
                if (!$item->is_active) {
                    continue;
                }

                $answer = $answersByVersionItemId->get($item->id);

                // إذا السؤال جديد/معدل/مستعاد ولم يُجب عليه بعد
                if ($answer && $answer->answer_state === 'needs_reanswer') {
                    $hasPendingChanges = true;
                }

                // الأسئلة المحذوفة لا تدخل في الدرجة
                if ($answer && $answer->answer_state === 'deleted_question') {
                    continue;
                }

                $totalPoints += (float) $item->points;

                if (!$answer || !$this->hasAnswerContent($item, $answer)) {
                    $wrongCount++;
                    continue;
                }

                $isCorrect = $this->evaluateAnswer($item, $answer);
                $awardedPoints = $isCorrect ? (float) $item->points : 0.0;

                $answer->is_correct = $isCorrect;
                $answer->awarded_points = $awardedPoints;
                $answer->checked_at = now();
                $answer->feedback_snapshot = [
                    'question_type' => $item->type,
                    'question_text' => $item->question_text,
                    'correct_text_answer' => $item->correct_text_answer,
                    'change_status' => $item->change_status_from_previous,
                ];
                $answer->save();

                if ($isCorrect) {
                    $score += $awardedPoints;
                    $correctCount++;
                } else {
                    $wrongCount++;
                }
            }

            $attempt->status = 'graded';
            $attempt->score = $score;
            $attempt->total_points = $totalPoints;
            $attempt->correct_count = $correctCount;
            $attempt->wrong_count = $wrongCount;
            $attempt->submitted_at = now();
            $attempt->graded_at = now();
            $attempt->last_synced_version_id = $version->id;
            $attempt->has_pending_changes = $hasPendingChanges;
            $attempt->save();

            return $attempt->fresh([
                'answers.versionItem.options',
                'version.items.options',
            ]);
        });
    }

    protected function hasAnswerContent(LessonExerciseVersionItem $item, StudentExerciseAnswer $answer): bool
    {
        if (in_array($item->type, ['multiple_choice', 'true_false'], true)) {
            return !empty($answer->selected_option_id);
        }

        if ($item->type === 'short_answer') {
            return trim((string) $answer->answer_text) !== '';
        }

        return false;
    }

    protected function evaluateAnswer(LessonExerciseVersionItem $item, StudentExerciseAnswer $answer): bool
    {
        if ($item->type === 'short_answer') {
            return trim(mb_strtolower((string) $answer->answer_text)) ===
                trim(mb_strtolower((string) $item->correct_text_answer));
        }

        if (in_array($item->type, ['multiple_choice', 'true_false'], true)) {
            $correctOption = $item->options->firstWhere('is_correct', true);

            if (!$correctOption) {
                return false;
            }

            return (int) $answer->selected_option_id === (int) $correctOption->id;
        }

        return false;
    }
}