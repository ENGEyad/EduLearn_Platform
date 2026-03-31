<?php

namespace App\Services;

use App\Models\LessonExerciseSet;
use App\Models\LessonExerciseVersion;
use App\Models\StudentExerciseAnswer;
use App\Models\StudentExerciseAttempt;
use Illuminate\Support\Facades\DB;

class StudentExerciseSyncService
{
    protected string $connection = 'app_mysql';

    public function syncStudentToCurrentVersion(
        int $studentId,
        LessonExerciseSet $set,
        LessonExerciseVersion $currentVersion
    ): array {
        $latestAttempt = StudentExerciseAttempt::query()
            ->where('student_id', $studentId)
            ->where('exercise_set_id', $set->id)
            ->latest('id')
            ->with([
                'answers',
                'version.items.options',
            ])
            ->first();

        // أول دخول أو لا توجد محاولة سابقة
        if (!$latestAttempt) {
            $attempt = StudentExerciseAttempt::query()->create([
                'exercise_set_id' => $set->id,
                'exercise_version_id' => $currentVersion->id,
                'lesson_id' => $set->lesson_id,
                'student_id' => $studentId,
                'status' => 'in_progress',
                'last_synced_version_id' => $currentVersion->id,
                'has_pending_changes' => false,
            ]);

            return [
                'attempt' => $attempt->fresh(['answers']),
                'sync_summary' => [
                    'is_first_attempt' => true,
                    'version_changed' => false,
                    'carried_forward_count' => 0,
                    'needs_reanswer_count' => 0,
                    'deleted_count' => 0,
                    'new_count' => $currentVersion->items()->where('is_active', true)->count(),
                ],
            ];
        }

        // لو نفس النسخة الحالية، لا نحتاج مزامنة جديدة
        if ((int) $latestAttempt->exercise_version_id === (int) $currentVersion->id) {
            return [
                'attempt' => $latestAttempt,
                'sync_summary' => [
                    'is_first_attempt' => false,
                    'version_changed' => false,
                    'carried_forward_count' => 0,
                    'needs_reanswer_count' => 0,
                    'deleted_count' => 0,
                    'new_count' => 0,
                ],
            ];
        }

        return DB::connection($this->connection)->transaction(function () use ($latestAttempt, $currentVersion, $set, $studentId) {
            $oldAnswersByStableKey = $latestAttempt->answers->keyBy('stable_question_key');

            $newAttempt = StudentExerciseAttempt::query()->create([
                'exercise_set_id' => $set->id,
                'exercise_version_id' => $currentVersion->id,
                'lesson_id' => $set->lesson_id,
                'student_id' => $studentId,
                'status' => 'in_progress',
                'last_synced_version_id' => $currentVersion->id,
                'has_pending_changes' => true,
            ]);

            $carriedForwardCount = 0;
            $needsReanswerCount = 0;
            $deletedCount = 0;
            $newCount = 0;

            $currentItems = $currentVersion->items()->with('options')->orderBy('position')->get();

            foreach ($currentItems as $item) {
                $status = $item->change_status_from_previous ?? 'unchanged';
                $oldAnswer = $oldAnswersByStableKey->get($item->stable_question_key);

                // سؤال محذوف في النسخة الجديدة
                if ($status === 'deleted' || !$item->is_active) {
                    if ($oldAnswer) {
                        StudentExerciseAnswer::query()->create([
                            'attempt_id' => $newAttempt->id,
                            'version_item_id' => $item->id,
                            'stable_question_key' => $item->stable_question_key,
                            'selected_option_id' => null,
                            'answer_text' => null,
                            'is_correct' => null,
                            'awarded_points' => null,
                            'checked_at' => null,
                            'feedback_snapshot' => [
                                'change_status' => 'deleted',
                                'message' => 'This question was deleted by the teacher.',
                            ],
                            'answer_state' => 'deleted_question',
                        ]);
                    }

                    $deletedCount++;
                    continue;
                }

                // سؤال جديد أو معدل أو مستعاد: يحتاج إعادة إجابة
                if (in_array($status, ['new', 'updated', 'restored'], true)) {
                    StudentExerciseAnswer::query()->create([
                        'attempt_id' => $newAttempt->id,
                        'version_item_id' => $item->id,
                        'stable_question_key' => $item->stable_question_key,
                        'selected_option_id' => null,
                        'answer_text' => null,
                        'is_correct' => null,
                        'awarded_points' => null,
                        'checked_at' => null,
                        'feedback_snapshot' => [
                            'change_status' => $status,
                            'message' => match ($status) {
                                'new' => 'This question is new.',
                                'updated' => 'This question was updated by the teacher.',
                                'restored' => 'This question was restored by the teacher.',
                                default => null,
                            },
                        ],
                        'answer_state' => 'needs_reanswer',
                    ]);

                    if ($status === 'new') {
                        $newCount++;
                    } else {
                        $needsReanswerCount++;
                    }

                    continue;
                }

                // unchanged
                if ($oldAnswer) {
                    StudentExerciseAnswer::query()->create([
                        'attempt_id' => $newAttempt->id,
                        'version_item_id' => $item->id,
                        'stable_question_key' => $item->stable_question_key,
                        'selected_option_id' => $this->mapSelectedOptionIdToNewVersion($oldAnswer, $item),
                        'answer_text' => $oldAnswer->answer_text,
                        'is_correct' => $oldAnswer->is_correct,
                        'awarded_points' => $oldAnswer->awarded_points,
                        'checked_at' => $oldAnswer->checked_at,
                        'feedback_snapshot' => [
                            'change_status' => 'unchanged',
                            'carried_forward' => true,
                        ],
                        'answer_state' => 'active',
                    ]);

                    $carriedForwardCount++;
                } else {
                    StudentExerciseAnswer::query()->create([
                        'attempt_id' => $newAttempt->id,
                        'version_item_id' => $item->id,
                        'stable_question_key' => $item->stable_question_key,
                        'selected_option_id' => null,
                        'answer_text' => null,
                        'is_correct' => null,
                        'awarded_points' => null,
                        'checked_at' => null,
                        'feedback_snapshot' => [
                            'change_status' => 'unchanged',
                            'carried_forward' => false,
                        ],
                        'answer_state' => 'active',
                    ]);
                }
            }

            $newAttempt->load(['answers', 'version.items.options']);

            return [
                'attempt' => $newAttempt,
                'sync_summary' => [
                    'is_first_attempt' => false,
                    'version_changed' => true,
                    'from_version_id' => $latestAttempt->exercise_version_id,
                    'to_version_id' => $currentVersion->id,
                    'carried_forward_count' => $carriedForwardCount,
                    'needs_reanswer_count' => $needsReanswerCount,
                    'deleted_count' => $deletedCount,
                    'new_count' => $newCount,
                ],
            ];
        });
    }

    protected function mapSelectedOptionIdToNewVersion(StudentExerciseAnswer $oldAnswer, $newVersionItem): ?int
    {
        if (!$oldAnswer->selected_option_id) {
            return null;
        }

        $oldSelectedOption = optional($oldAnswer->versionItem)
            ->options
            ?->firstWhere('id', $oldAnswer->selected_option_id);

        if (!$oldSelectedOption) {
            return null;
        }

        $newOption = $newVersionItem->options
            ->firstWhere('stable_option_key', $oldSelectedOption->stable_option_key);

        return $newOption?->id;
    }
}