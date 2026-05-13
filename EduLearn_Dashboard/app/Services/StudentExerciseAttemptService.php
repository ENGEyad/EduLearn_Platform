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

    /**
     * نرجّع النسخة المنشورة الحالية بشكل آمن.
     */
    public function getCurrentPublishedSetForStudent(LessonExerciseSet $set): ?LessonExerciseVersion
    {
        if ($set->status === 'archived') {
            return null;
        }

        $version = $set->activeVersion;

        if ($version) {
            $version->load(['items.options']);
        }

        return $version;
    }

    public function getOrCreateAttempt(
        int $studentId,
        LessonExerciseSet $set,
        LessonExerciseVersion $version
    ): StudentExerciseAttempt {
        $attempt = StudentExerciseAttempt::query()->firstOrCreate(
            [
                'student_id' => $studentId,
                'exercise_set_id' => $set->id,
                'exercise_version_id' => $version->id,
            ],
            [
                'lesson_id' => $set->lesson_id,
                'status' => 'in_progress',
                'started_at' => now(),
                'last_synced_version_id' => $version->id,
                'has_pending_changes' => false,
            ]
        );

        if (!$attempt->started_at) {
            $attempt->started_at = now();
            $attempt->save();
        }

        return $attempt;
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

    /**
     * حفظ الإجابات بدون تصحيح.
     */
    public function saveAttempt(
        int $studentId,
        LessonExerciseSet $set,
        LessonExerciseVersion $version,
        array $answersPayload,
        int $timeSpentSeconds = 0
    ): StudentExerciseAttempt {
        return DB::connection($this->connection)->transaction(function () use ($studentId, $set, $version, $answersPayload, $timeSpentSeconds) {
            $attempt = $this->getOrCreateAttempt($studentId, $set, $version);

            if ($attempt->status === 'graded' && !$attempt->has_pending_changes) {
                return $attempt->fresh([
                    'answers.versionItem.options',
                    'version.items.options',
                ]);
            }

            $attempt->load([
                'answers.versionItem.options',
                'version.items.options',
            ]);

            $answersByStableQuestionKey = collect($answersPayload)->keyBy('stable_question_key');

            $versionItems = $version->items()
                ->with('options')
                ->where('is_active', true)
                ->orderBy('position')
                ->get();

            foreach ($versionItems as $versionItem) {
                /** @var LessonExerciseVersionItem $versionItem */
                $existingAnswer = $attempt->answers
                    ->firstWhere('stable_question_key', $versionItem->stable_question_key);

                $incomingAnswer = $answersByStableQuestionKey->get($versionItem->stable_question_key);

                if (!$existingAnswer) {
                    $existingAnswer = new StudentExerciseAnswer();
                    $existingAnswer->attempt_id = $attempt->id;
                    $existingAnswer->version_item_id = $versionItem->id;
                    $existingAnswer->stable_question_key = $versionItem->stable_question_key;
                    $existingAnswer->answer_state = 'active';
                }

                if (in_array($existingAnswer->answer_state, ['deleted_question', 'readonly_history'], true)) {
                    continue;
                }

                if (!$incomingAnswer) {
                    continue;
                }

                if ($existingAnswer->answer_state === 'needs_reanswer') {
                    $existingAnswer->selected_option_id = null;
                    $existingAnswer->answer_text = null;
                    $existingAnswer->is_correct = null;
                    $existingAnswer->awarded_points = null;
                    $existingAnswer->checked_at = null;
                    $existingAnswer->feedback_snapshot = [
                        'change_status' => $versionItem->change_status_from_previous,
                    ];
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

                $existingAnswer->save();
            }

            $attempt->last_synced_version_id = $version->id;
            $attempt->status = 'in_progress';
            $attempt->started_at = $attempt->started_at ?: now();

            if ($timeSpentSeconds > 0) {
                $attempt->time_spent_seconds = ((int) ($attempt->time_spent_seconds ?? 0)) + $timeSpentSeconds;
            }

            if (!empty($answersPayload)) {
                $attempt->last_saved_at = now();
            }

            if (!$attempt->has_pending_changes) {
                $attempt->has_pending_changes = $this->versionHasChangeDrivenQuestions($version);
            }

            $attempt->save();

            $attempt = $attempt->fresh([
                'answers.versionItem.options',
                'version.items.options',
            ]);

            $this->refreshAttemptMetrics($attempt, false);

            return $attempt->fresh([
                'answers.versionItem.options',
                'version.items.options',
            ]);
        });
    }

    /**
     * submit: تصحيح المحاولة وإغلاقها.
     */
    public function submitAttempt(
        int $studentId,
        LessonExerciseSet $set,
        LessonExerciseVersion $version,
        array $answersPayload,
        int $timeSpentSeconds = 0
    ): StudentExerciseAttempt {
        return DB::connection($this->connection)->transaction(function () use ($studentId, $set, $version, $answersPayload, $timeSpentSeconds) {
            $attempt = $this->saveAttempt($studentId, $set, $version, $answersPayload, $timeSpentSeconds);

            $attempt->load([
                'answers.versionItem.options',
                'version.items.options',
            ]);

            $visibleItems = $attempt->version->items
                ->where('is_active', true)
                ->sortBy('position')
                ->values();

            $answersByVersionItemId = $attempt->answers->keyBy('version_item_id');

            $missingCount = 0;
            foreach ($visibleItems as $item) {
                /** @var LessonExerciseVersionItem $item */
                $answer = $answersByVersionItemId->get($item->id);

                if ($answer && in_array($answer->answer_state, ['readonly_history', 'deleted_question'], true)) {
                    continue;
                }

                if (!$answer || !$this->hasAnswerContent($item, $answer)) {
                    $missingCount++;
                }
            }

            if ($missingCount > 0) {
                throw new InvalidArgumentException('Please answer all questions before submitting.');
            }

            $score = 0.0;
            $totalPoints = 0.0;
            $correctCount = 0;
            $wrongCount = 0;

            foreach ($visibleItems as $item) {
                /** @var LessonExerciseVersionItem $item */
                $answer = $answersByVersionItemId->get($item->id);

                $totalPoints += (float) $item->points;

                if ($answer && $answer->answer_state === 'readonly_history') {
                    if ($answer->is_correct === true) {
                        $score += (float) ($answer->awarded_points ?? 0);
                        $correctCount++;
                    } else {
                        $wrongCount++;
                    }
                    continue;
                }

                $isCorrect = $this->evaluateAnswer($item, $answer);
                $awardedPoints = $isCorrect ? (float) $item->points : 0.0;

                $answer->is_correct = $isCorrect;
                $answer->awarded_points = $awardedPoints;
                $answer->checked_at = now();
                $answer->feedback_snapshot = $this->buildFeedbackSnapshot($item);
                $answer->answer_state = 'readonly_history';
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
            $attempt->submit_count = ((int) ($attempt->submit_count ?? 0)) + 1;
            $attempt->last_synced_version_id = $version->id;
            $attempt->has_pending_changes = false;
            $attempt->save();

            $attempt = $attempt->fresh([
                'answers.versionItem.options',
                'version.items.options',
            ]);

            $this->refreshAttemptMetrics($attempt, true);

            return $attempt->fresh([
                'answers.versionItem.options',
                'version.items.options',
            ]);
        });
    }

    protected function versionHasChangeDrivenQuestions(LessonExerciseVersion $version): bool
    {
        return $version->items()
            ->where('is_active', true)
            ->whereIn('change_status_from_previous', ['new', 'updated', 'restored'])
            ->exists();
    }

    protected function refreshAttemptMetrics(StudentExerciseAttempt $attempt, bool $isSubmitted): void
    {
        $attempt->loadMissing([
            'answers.versionItem.options',
            'version.items.options',
        ]);

        $visibleItems = $attempt->version
            ? $attempt->version->items->where('is_active', true)->values()
            : collect();

        $answersByVersionItemId = $attempt->answers->keyBy('version_item_id');

        $questionCount = $visibleItems->count();
        $answeredCount = 0;

        foreach ($visibleItems as $item) {
            /** @var LessonExerciseVersionItem $item */
            $answer = $answersByVersionItemId->get($item->id);

            if ($answer && in_array($answer->answer_state, ['readonly_history', 'deleted_question'], true)) {
                $answeredCount++;
                continue;
            }

            if ($answer && $this->hasAnswerContent($item, $answer)) {
                $answeredCount++;
            }
        }

        $unansweredCount = max(0, $questionCount - $answeredCount);
        $completionRate = $questionCount > 0
            ? round(($answeredCount / $questionCount) * 100, 2)
            : 0.0;

        $totalPoints = (float) ($attempt->total_points ?? 0);
        $score = (float) ($attempt->score ?? 0);
        $accuracyRate = $isSubmitted && $totalPoints > 0
            ? round(($score / $totalPoints) * 100, 2)
            : null;

        $attempt->question_count = $questionCount;
        $attempt->answered_count = $answeredCount;
        $attempt->unanswered_count = $isSubmitted ? 0 : $unansweredCount;
        $attempt->completion_rate = $isSubmitted ? 100 : $completionRate;
        $attempt->accuracy_rate = $accuracyRate;
        $attempt->save();
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

    protected function buildFeedbackSnapshot(LessonExerciseVersionItem $item): array
    {
        return [
            'question_type' => $item->type,
            'question_text' => $item->question_text,
            'correct_text_answer' => $item->correct_text_answer,
            'explanation' => $item->explanation,
            'change_status' => $item->change_status_from_previous,
        ];
    }
}