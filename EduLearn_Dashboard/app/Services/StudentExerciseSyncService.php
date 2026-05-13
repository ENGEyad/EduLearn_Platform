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
                'answers.versionItem.options',
                'version.items.options',
            ])
            ->first();

        // أول دخول للطالب: ننشئ محاولة فارغة للنسخة الحالية
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

        // إذا كان أصلًا على نفس النسخة فلا ننشئ محاولة جديدة
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
                // سنحسبها لاحقًا بدقة
                'has_pending_changes' => false,
            ]);

            $carriedForwardCount = 0;
            $needsReanswerCount = 0;
            $deletedCount = 0;
            $newCount = 0;
            $hasPendingChanges = false;

            $currentItems = $currentVersion->items()
                ->with('options')
                ->orderBy('position')
                ->get();

            foreach ($currentItems as $item) {
                $status = $item->change_status_from_previous ?? 'unchanged';
                $oldAnswer = $oldAnswersByStableKey->get($item->stable_question_key);

                /**
                 * مبدأ مهم:
                 * - الأسئلة غير النشطة (محذوفة / مؤرشفة في النسخة الحالية) لا نعرضها للطالب.
                 * - لذلك لا ننشئ لها Answer row جديدة داخل المحاولة المرئية.
                 * - نكتفي فقط بإحصاء أنها حُذفت إن كان لها أثر سابق.
                 */
                if (!$item->is_active || $status === 'deleted') {
                    if ($oldAnswer) {
                        $deletedCount++;
                    }
                    continue;
                }

                /**
                 * الأسئلة الجديدة / المعدلة / المستعادة:
                 * - لا نحمل الإجابة القديمة
                 * - لا نحمل الشرح القديم
                 * - تبقى needs_reanswer حتى submit
                 */
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

                    $hasPendingChanges = true;

                    if ($status === 'new') {
                        $newCount++;
                    } else {
                        $needsReanswerCount++;
                    }

                    continue;
                }

                /**
                 * unchanged:
                 * - إذا كانت المحاولة السابقة graded/submitted نحملها كـ readonly_history
                 *   لكي تبقى مقيدة ومصححة كما هي.
                 * - إذا كانت المحاولة السابقة لم تُرسل بعد، نبقي الإجابة active
                 *   حتى لا نكسر تجربة الحفظ المؤقت.
                 */
                if ($oldAnswer) {
                    $carriedSelectedOptionId = $this->mapSelectedOptionIdToNewVersion($oldAnswer, $item);

                    StudentExerciseAnswer::query()->create([
                        'attempt_id' => $newAttempt->id,
                        'version_item_id' => $item->id,
                        'stable_question_key' => $item->stable_question_key,
                        'selected_option_id' => $carriedSelectedOptionId,
                        'answer_text' => $oldAnswer->answer_text,
                        'is_correct' => $oldAnswer->is_correct,
                        'awarded_points' => $oldAnswer->awarded_points,
                        'checked_at' => $oldAnswer->checked_at,
                        'feedback_snapshot' => $oldAnswer->feedback_snapshot,
                        'answer_state' => in_array($latestAttempt->status, ['graded', 'submitted'], true)
                            ? 'readonly_history'
                            : 'active',
                    ]);

                    $carriedForwardCount++;
                    continue;
                }

                /**
                 * إذا السؤال unchanged لكن لم تكن هناك إجابة سابقة:
                 * - لو كانت المحاولة السابقة graded نثبته كـ readonly_history فارغ
                 *   حتى يبقى سلوكه ثابتًا ولا يعاد فتحه بشكل خاطئ.
                 * - غير ذلك نتركه active.
                 */
                if (in_array($latestAttempt->status, ['graded', 'submitted'], true)) {
                    StudentExerciseAnswer::query()->create([
                        'attempt_id' => $newAttempt->id,
                        'version_item_id' => $item->id,
                        'stable_question_key' => $item->stable_question_key,
                        'selected_option_id' => null,
                        'answer_text' => null,
                        'is_correct' => false,
                        'awarded_points' => 0,
                        'checked_at' => $latestAttempt->graded_at ?? $latestAttempt->submitted_at,
                        'feedback_snapshot' => [
                            'change_status' => 'unchanged',
                            'carried_forward' => false,
                        ],
                        'answer_state' => 'readonly_history',
                    ]);
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

            $newAttempt->has_pending_changes = $hasPendingChanges;
            $newAttempt->save();

            $newAttempt->load([
                'answers.versionItem.options',
                'version.items.options',
            ]);

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

    /**
     * نربط الخيار المختار السابق بنظيره في النسخة الجديدة عبر stable_option_key
     * حتى لا يضيع carry-forward للأسئلة غير المعدلة.
     */
    protected function mapSelectedOptionIdToNewVersion(StudentExerciseAnswer $oldAnswer, $newVersionItem): ?int
    {
        if (!$oldAnswer->selected_option_id) {
            return null;
        }

        $oldAnswer->loadMissing('versionItem.options');

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