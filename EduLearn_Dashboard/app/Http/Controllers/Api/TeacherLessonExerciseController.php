<?php



namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\Teacher;
use App\Services\LessonExerciseDraftService;
use App\Services\LessonExercisePublishService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TeacherLessonExerciseController extends Controller
{
    public function __construct(
        protected LessonExerciseDraftService $draftService,
        protected LessonExercisePublishService $publishService,
    ) {
    }

    protected function resolveTeacher(string $teacherCode): Teacher
    {
        return Teacher::query()
            ->where('teacher_code', $teacherCode)
            ->firstOrFail();
    }

    protected function resolveLessonForTeacher(int $lessonId, Teacher $teacher): Lesson
    {
        $lesson = Lesson::query()
            ->where('id', $lessonId)
            ->firstOrFail();

        abort_if(
            (int) $lesson->teacher_id !== (int) $teacher->id,
            403,
            'This teacher is not allowed to manage exercises for this lesson.'
        );

        return $lesson;
    }

    public function showDraft(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getDraftForLesson($lessonModel, (int) $teacher->id);

        return response()->json([
            'success' => true,
            'data' => $set,
        ]);
    }

    public function saveDraft(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
            'title' => ['nullable', 'string', 'max:255'],
            'generation_source' => ['nullable', 'in:manual,ai,mixed'],

            'questions' => ['nullable', 'array'],
            'questions.*.stable_question_key' => ['nullable', 'string'],
            'questions.*.origin' => ['nullable', 'in:manual,ai,mixed'],
            'questions.*.type' => ['required_with:questions', 'in:true_false,multiple_choice,short_answer'],
            'questions.*.question_text' => ['required_with:questions', 'string'],
            'questions.*.correct_text_answer' => ['nullable', 'string'],
            'questions.*.explanation' => ['nullable', 'string'],
            'questions.*.points' => ['nullable', 'numeric', 'min:0'],
            'questions.*.position' => ['nullable', 'integer', 'min:1'],
            'questions.*.is_active' => ['nullable', 'boolean'],
            'questions.*.is_archived' => ['nullable', 'boolean'],
            'questions.*.meta' => ['nullable', 'array'],

            'questions.*.options' => ['nullable', 'array'],
            'questions.*.options.*.stable_option_key' => ['nullable', 'string'],
            'questions.*.options.*.option_text' => ['required_with:questions.*.options', 'string'],
            'questions.*.options.*.is_correct' => ['nullable', 'boolean'],
            'questions.*.options.*.position' => ['nullable', 'integer', 'min:1'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->saveDraft($lessonModel, (int) $teacher->id, $validated);

        return response()->json([
            'success' => true,
            'message' => 'Exercise draft saved successfully.',
            'data' => $set,
        ]);
    }

    public function publish(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getOrCreateSet($lessonModel, (int) $teacher->id);
        $version = $this->publishService->publish($set, (int) $teacher->id);

        return response()->json([
            'success' => true,
            'message' => 'Exercises published successfully.',
            'data' => $version,
        ]);
    }

    public function archiveSet(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getOrCreateSet($lessonModel, (int) $teacher->id);
        $set = $this->draftService->archiveSet($set);

        return response()->json([
            'success' => true,
            'message' => 'Exercise set archived successfully.',
            'data' => $set,
        ]);
    }

    public function unarchiveSet(Request $request, int $lesson): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getOrCreateSet($lessonModel, (int) $teacher->id);
        $set = $this->draftService->unarchiveSet($set);

        return response()->json([
            'success' => true,
            'message' => 'Exercise set unarchived successfully.',
            'data' => $set,
        ]);
    }

    public function deleteDraftQuestion(Request $request, int $lesson, string $stableQuestionKey): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getOrCreateSet($lessonModel, (int) $teacher->id);
        $item = $this->draftService->softDeleteDraftQuestion($set, $stableQuestionKey);

        abort_if(!$item, 404, 'Draft question not found.');

        return response()->json([
            'success' => true,
            'message' => 'Draft question deleted successfully.',
            'data' => $item,
        ]);
    }

    public function restoreDraftQuestion(Request $request, int $lesson, string $stableQuestionKey): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getOrCreateSet($lessonModel, (int) $teacher->id);
        $item = $this->draftService->restoreDraftQuestion($set, $stableQuestionKey);

        abort_if(!$item, 404, 'Draft question not found.');

        return response()->json([
            'success' => true,
            'message' => 'Draft question restored successfully.',
            'data' => $item,
        ]);
    }

    public function archiveDraftQuestion(Request $request, int $lesson, string $stableQuestionKey): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getOrCreateSet($lessonModel, (int) $teacher->id);
        $item = $this->draftService->archiveDraftQuestion($set, $stableQuestionKey);

        abort_if(!$item, 404, 'Draft question not found.');

        return response()->json([
            'success' => true,
            'message' => 'Draft question archived successfully.',
            'data' => $item,
        ]);
    }

    public function unarchiveDraftQuestion(Request $request, int $lesson, string $stableQuestionKey): JsonResponse
    {
        $validated = $request->validate([
            'teacher_code' => ['required', 'string'],
        ]);

        $teacher = $this->resolveTeacher($validated['teacher_code']);
        $lessonModel = $this->resolveLessonForTeacher($lesson, $teacher);

        $set = $this->draftService->getOrCreateSet($lessonModel, (int) $teacher->id);
        $item = $this->draftService->unarchiveDraftQuestion($set, $stableQuestionKey);

        abort_if(!$item, 404, 'Draft question not found.');

        return response()->json([
            'success' => true,
            'message' => 'Draft question unarchived successfully.',
            'data' => $item,
        ]);
    }
}