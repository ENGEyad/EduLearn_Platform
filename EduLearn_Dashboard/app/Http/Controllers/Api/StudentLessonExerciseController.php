<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\LessonExerciseSet;
use App\Models\Student;
use App\Services\StudentExerciseAttemptService;
use App\Services\StudentExerciseSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentLessonExerciseController extends Controller
{
    public function __construct(
        protected StudentExerciseAttemptService $attemptService,
        protected StudentExerciseSyncService $syncService,
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

        $set = LessonExerciseSet::query()
            ->where('lesson_id', $lesson->id)
            ->firstOrFail();

        return $set;
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

        return response()->json([
            'success' => true,
            'data' => [
                'exercise_set' => $set->fresh(),
                'version' => $currentVersion->fresh(['items.options']),
                'latest_attempt' => $syncResult['attempt'],
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
            'data' => $attempt,
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

        // تأكد من المزامنة أولًا قبل الحفظ
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
                'attempt' => $attempt,
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

        // تأكد من المزامنة أولًا قبل الإرسال
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

        return response()->json([
            'success' => true,
            'message' => 'Exercise attempt submitted successfully.',
            'data' => [
                'attempt' => $attempt,
                'sync_summary' => $syncResult['sync_summary'],
            ],
        ]);
    }
}