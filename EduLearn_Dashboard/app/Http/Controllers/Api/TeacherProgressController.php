<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Teacher;
use App\Services\TeacherProgressSummaryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TeacherProgressController extends Controller
{
    public function __construct(
        protected TeacherProgressSummaryService $progressService,
    ) {
    }

    public function summary(Request $request): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher instanceof Teacher) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        return response()->json([
            'success' => true,
            'data' => $this->progressService->buildTeacherSummary($teacher->id),
        ]);
    }

    public function classSubject(Request $request): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher instanceof Teacher) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $validated = $request->validate([
            'class_section_id' => ['required', 'integer'],
            'subject_id' => ['required', 'integer'],
        ]);

        return response()->json([
            'success' => true,
            'data' => $this->progressService->buildClassSubjectProgress(
                teacherId: $teacher->id,
                classSectionId: (int) $validated['class_section_id'],
                subjectId: (int) $validated['subject_id'],
            ),
        ]);
    }

    public function studentSubject(Request $request): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher instanceof Teacher) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $validated = $request->validate([
            'student_id' => ['nullable', 'integer'],
            'academic_id' => ['nullable', 'string'],
            'subject_id' => ['required', 'integer'],
        ]);

        if (empty($validated['student_id']) && empty($validated['academic_id'])) {
            return response()->json(['success' => false, 'message' => 'student_id or academic_id is required.'], 422);
        }

        return response()->json([
            'success' => true,
            'data' => $this->progressService->buildStudentSubjectProgress(
                teacherId: $teacher->id,
                studentId: $validated['student_id'] ?? null,
                academicId: $validated['academic_id'] ?? null,
                subjectId: (int) $validated['subject_id'],
            ),
        ]);
    }
}
