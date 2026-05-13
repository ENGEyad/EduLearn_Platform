<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Services\StudentProgressSummaryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentProgressController extends Controller
{
    public function __construct(
        protected StudentProgressSummaryService $progressService,
    ) {
    }

    /**
     * GET /api/student/progress/overview
     */
    public function overview(Request $request): JsonResponse
    {
        $student = $request->user();
        if (!$student instanceof Student) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        return response()->json([
            'success' => true,
            'data' => $this->progressService->buildStudentOverview($student),
        ]);
    }

    /**
     * GET /api/student/subjects/{subject}/progress
     */
    public function subject(Request $request, int $subject): JsonResponse
    {
        $student = $request->user();
        if (!$student instanceof Student) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        return response()->json([
            'success' => true,
            'data' => $this->progressService->buildStudentSubjectProgress($student, $subject),
        ]);
    }
}
