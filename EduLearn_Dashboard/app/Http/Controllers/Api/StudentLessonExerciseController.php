<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\LessonExerciseSet;
use App\Models\LessonExerciseVersion;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Services\StudentExerciseAttemptService;
use App\Services\StudentExerciseSyncService;
use App\Services\LearningActivityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentLessonExerciseController extends Controller
{
    public function __construct(
        protected StudentExerciseAttemptService $attemptService,
        protected StudentExerciseSyncService $syncService,
        protected LearningActivityService $activityService,
    ) {
    }

    protected function resolveStudent(string|int $academicId): Student
    {
        return Student::query()
            ->where('academic_id', $academicId)
            ->firstOrFail();
    }

    protected function resolvePublishedExerciseSetForStudent(int $lessonId, Student $student): LessonExerciseSet
    {
        $lesson = Lesson::query()->findOrFail($lessonId);

        abort_if(
            !$student->class_section_id || (int) $lesson->class_section_id !== (int) $student->class_section_id,
            403,
            'This student is not allowed to access exercises for this lesson.'
        );

        return LessonExerciseSet::query()
            ->where('lesson_id', $lesson->id)
            ->firstOrFail();
    }

    public function current(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'academic_id' => ['required'],
        ]);

        $student = $this->resolveStudent($validated['academic_id']);
        $set = $this->resolvePublishedExerciseSetForStudent($lesson, $student);

        $currentVersion = $this->attemptService->getCurrentPublishedSetForStudent($set);

        if (!$currentVersion) {
            return response()->json([
                'success' => true,
                'data' => null,
                'message' => 'No published exercises are currently available for this lesson.',
            ]);
        }

        $syncResult = $this->syncService->syncStudentToCurrentVersion(
            (int) $student->id,
            $set,
            $currentVersion
        );

        /** @var StudentExerciseAttempt $attempt */
        $attempt = $syncResult['attempt'];

        return response()->json([
            'success' => true,
            'data' => [
                'exercise_set' => $this->formatExerciseSetForStudent($set->fresh()),
                'version' => $this->formatVersionForStudent($currentVersion->fresh(['items.options'])),
                'latest_attempt' => $this->formatAttemptForStudent(
                    $attempt->fresh([
                        'answers.versionItem.options',
                        'version.items.options',
                    ])
                ),
                'sync_summary' => $syncResult['sync_summary'],
            ],
        ]);
    }

    public function latestAttempt(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'academic_id' => ['required'],
        ]);

        $student = $this->resolveStudent($validated['academic_id']);
        $set = $this->resolvePublishedExerciseSetForStudent($lesson, $student);

        $attempt = $this->attemptService->getLatestAttempt((int) $student->id, $set);

        return response()->json([
            'success' => true,
            'data' => $attempt ? $this->formatAttemptForStudent($attempt) : null,
        ]);
    }

    public function save(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'academic_id' => ['required'],
            'answers' => ['nullable', 'array'],
            'answers.*.stable_question_key' => ['required_with:answers', 'string'],
            'answers.*.selected_option_id' => ['nullable', 'integer'],
            'answers.*.answer_text' => ['nullable', 'string'],
        ]);

        $student = $this->resolveStudent($validated['academic_id']);
        $set = $this->resolvePublishedExerciseSetForStudent($lesson, $student);

        $currentVersion = $this->attemptService->getCurrentPublishedSetForStudent($set);
        abort_if(!$currentVersion, 422, 'No published exercise version available.');

        // مهم: نزامن أولاً حتى تُبنى محاولة النسخة الحالية بشكل صحيح
        $syncResult = $this->syncService->syncStudentToCurrentVersion(
            (int) $student->id,
            $set,
            $currentVersion
        );

        $attempt = $this->attemptService->saveAttempt(
            (int) $student->id,
            $set,
            $currentVersion,
            $validated['answers'] ?? []
        );

        return response()->json([
            'success' => true,
            'message' => 'Exercise answers saved successfully.',
            'data' => [
                'attempt' => $this->formatAttemptForStudent($attempt),
                'sync_summary' => $syncResult['sync_summary'],
            ],
        ]);
    }

    public function submit(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'academic_id' => ['required'],
            'answers' => ['nullable', 'array'],
            'answers.*.stable_question_key' => ['required_with:answers', 'string'],
            'answers.*.selected_option_id' => ['nullable', 'integer'],
            'answers.*.answer_text' => ['nullable', 'string'],
        ]);

        $student = $this->resolveStudent($validated['academic_id']);
        $set = $this->resolvePublishedExerciseSetForStudent($lesson, $student);

        $currentVersion = $this->attemptService->getCurrentPublishedSetForStudent($set);
        abort_if(!$currentVersion, 422, 'No published exercise version available.');

        // نزامن أولاً قبل submit حتى لا نصحح نسخة قديمة
        $syncResult = $this->syncService->syncStudentToCurrentVersion(
            (int) $student->id,
            $set,
            $currentVersion
        );

        $attempt = $this->attemptService->submitAttempt(
            (int) $student->id,
            $set,
            $currentVersion,
            $validated['answers'] ?? []
        );

        // Record activity for teacher
        $teacher = \App\Models\Teacher::query()->find($set->lesson->teacher_id);
        $this->activityService->recordStudentExerciseActivityForTeacher([
            'student_id' => $student->id,
            'academic_id' => $student->academic_id,
            'student_name' => $student->full_name,
            'teacher_id' => $teacher?->id,
            'teacher_code' => $teacher?->teacher_code,
            'class_section_id' => $student->class_section_id,
            'subject_id' => $set->lesson->subject_id,
            'lesson_id' => $set->lesson_id,
            'exercise_set_id' => $set->id,
            'exercise_attempt_id' => $attempt->id,
            'event_type' => \App\Models\LearningActivity::EVENT_STUDENT_SUBMITTED_EXERCISE,
            'title' => 'قام طالب بتسليم تمارين',
            'body' => "قام الطالب {$student->full_name} بتسليم حلول الدرس: {$set->lesson->title}",
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Exercise attempt submitted successfully.',
            'data' => [
                'attempt' => $this->formatAttemptForStudent($attempt),
                'sync_summary' => $syncResult['sync_summary'],
            ],
        ]);
    }

    /**
     * نرجّع للطالب فقط البيانات التي يحتاجها على مستوى المجموعة.
     */
    protected function formatExerciseSetForStudent(LessonExerciseSet $set): array
    {
        return [
            'id' => $set->id,
            'lesson_id' => $set->lesson_id,
            'title' => $set->title,
            'status' => $set->status,
            'published_at' => optional($set->published_at)?->toISOString(),
        ];
    }

    /**
     * نرجّع فقط الأسئلة المرئية للطالب.
     * مهم جدًا:
     * - لا نرجّع الأسئلة غير النشطة (المحذوفة/المؤرشفة على مستوى النسخة)
     * - لا نسرّب correct_text_answer ولا explanation من السؤال نفسه
     *   لأن شرح الإجابة يجب أن يظهر فقط من feedback_snapshot بعد submit.
     */
    protected function formatVersionForStudent(LessonExerciseVersion $version): array
    {
        $items = $version->items
            ->where('is_active', true)
            ->sortBy('position')
            ->values()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'version_id' => $item->version_id,
                    'stable_question_key' => $item->stable_question_key,
                    'origin' => $item->origin,
                    'type' => $item->type,
                    'question_text' => $item->question_text,
                    'correct_text_answer' => null, // لا نكشفها من هنا للطالب
                    'explanation' => null,         // لا نكشفها من هنا للطالب
                    'points' => $item->points,
                    'position' => $item->position,
                    'is_active' => (bool) $item->is_active,
                    'change_status_from_previous' => $item->change_status_from_previous,
                    'options' => $item->options
                        ->sortBy('position')
                        ->values()
                        ->map(function ($option) {
                            return [
                                'id' => $option->id,
                                'version_item_id' => $option->version_item_id,
                                'stable_option_key' => $option->stable_option_key,
                                'option_text' => $option->option_text,
                                // لا نكشف is_correct ضمن السؤال للطالب
                                'is_correct' => false,
                                'position' => $option->position,
                            ];
                        })
                        ->toArray(),
                ];
            })
            ->toArray();

        return [
            'id' => $version->id,
            'exercise_set_id' => $version->exercise_set_id,
            'version_no' => $version->version_no,
            'previous_version_id' => $version->previous_version_id,
            'published_at' => optional($version->published_at)?->toISOString(),
            'is_active' => (bool) $version->is_active,
            'change_summary_json' => $version->change_summary_json,
            'items' => $items,
        ];
    }

    /**
     * نرجّع فقط الإجابات المرتبطة بالأسئلة المرئية للطالب.
     * الإجابات المحذوفة تاريخيًا لا نعرضها داخل الصفحة لأنها أصبحت غير مرئية.
     */
    protected function formatAttemptForStudent(StudentExerciseAttempt $attempt): array
    {
        $visibleVersionItemIds = $attempt->version
            ? $attempt->version->items
                ->where('is_active', true)
                ->pluck('id')
                ->all()
            : [];

        $answers = $attempt->answers
            ->filter(function ($answer) use ($visibleVersionItemIds) {
                return in_array((int) $answer->version_item_id, $visibleVersionItemIds, true);
            })
            ->values()
            ->map(function ($answer) {
                return [
                    'id' => $answer->id,
                    'attempt_id' => $answer->attempt_id,
                    'version_item_id' => $answer->version_item_id,
                    'stable_question_key' => $answer->stable_question_key,
                    'selected_option_id' => $answer->selected_option_id,
                    'answer_text' => $answer->answer_text,
                    'is_correct' => $answer->is_correct,
                    'awarded_points' => $answer->awarded_points,
                    'checked_at' => optional($answer->checked_at)?->toISOString(),
                    'feedback_snapshot' => $answer->feedback_snapshot,
                    'answer_state' => $answer->answer_state,
                ];
            })
            ->toArray();

        return [
            'id' => $attempt->id,
            'exercise_set_id' => $attempt->exercise_set_id,
            'exercise_version_id' => $attempt->exercise_version_id,
            'lesson_id' => $attempt->lesson_id,
            'student_id' => $attempt->student_id,
            'status' => $attempt->status,
            'score' => $attempt->score,
            'total_points' => $attempt->total_points,
            'correct_count' => $attempt->correct_count,
            'wrong_count' => $attempt->wrong_count,
            'submitted_at' => optional($attempt->submitted_at)?->toISOString(),
            'graded_at' => optional($attempt->graded_at)?->toISOString(),
            'last_synced_version_id' => $attempt->last_synced_version_id,
            'has_pending_changes' => (bool) $attempt->has_pending_changes,
            'answers' => $answers,
        ];
    }
}