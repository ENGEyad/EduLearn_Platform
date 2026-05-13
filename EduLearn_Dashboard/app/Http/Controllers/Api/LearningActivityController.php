<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LearningActivity;
use App\Models\Student;
use App\Models\Teacher;
use App\Services\LearningActivityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LearningActivityController extends Controller
{
    public function __construct(
        protected LearningActivityService $activityService,
    ) {
    }

    /**
     * GET /api/student/activities
     */
    public function studentActivities(Request $request): JsonResponse
    {
        $student = $request->user();
        if (!$student instanceof Student) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $limit = (int) ($request->input('limit', 20));
        $limit = min(max($limit, 1), 50);
        $beforeId = $request->input('before_id') ? (int) $request->input('before_id') : null;

        $activities = $this->activityService->recentForStudent($student, $limit, $beforeId);

        $payload = $activities
            ->map(fn (LearningActivity $activity) => $this->formatActivity($activity))
            ->values();

        $nextCursor = $payload->isNotEmpty() ? $payload->last()['id'] : null;

        return response()->json([
            'success'     => true,
            'activities'  => $payload,
            'next_cursor' => $nextCursor,
        ]);
    }

    /**
     * GET /api/teacher/activities
     */
    public function teacherActivities(Request $request): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher instanceof Teacher) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $limit = (int) ($request->input('limit', 20));
        $limit = min(max($limit, 1), 50);
        $beforeId = $request->input('before_id') ? (int) $request->input('before_id') : null;

        $activities = $this->activityService->recentForTeacher($teacher->id, $limit, $beforeId);

        $payload = $activities
            ->map(fn (LearningActivity $activity) => $this->formatActivity($activity))
            ->values();

        $nextCursor = $payload->isNotEmpty() ? $payload->last()['id'] : null;

        return response()->json([
            'success'     => true,
            'activities'  => $payload,
            'next_cursor' => $nextCursor,
        ]);
    }

    /**
     * POST /api/student/activities/mark-read
     */
    public function markStudentActivitiesRead(Request $request): JsonResponse
    {
        $student = $request->user();
        if (!$student instanceof Student) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $validated = $request->validate([
            'activity_ids' => ['required', 'array'],
            'activity_ids.*' => ['integer'],
        ]);

        $updated = $this->activityService->markTargetActivitiesAsRead(
            LearningActivity::TARGET_STUDENT,
            (int) $student->id,
            (string) $student->academic_id,
            $validated['activity_ids']
        );

        return response()->json([
            'success' => true,
            'updated' => $updated,
        ]);
    }

    /**
     * POST /api/teacher/activities/mark-read
     */
    public function markTeacherActivitiesRead(Request $request): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher instanceof Teacher) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $validated = $request->validate([
            'activity_ids' => ['required', 'array'],
            'activity_ids.*' => ['integer'],
        ]);

        $updated = $this->activityService->markTargetActivitiesAsRead(
            LearningActivity::TARGET_TEACHER,
            (int) $teacher->id,
            (string) $teacher->teacher_code,
            $validated['activity_ids']
        );

        return response()->json([
            'success' => true,
            'updated' => $updated,
        ]);
    }

    protected function formatActivity(LearningActivity $activity): array
    {
        return [
            'id'                  => $activity->id,
            'actor_type'          => $activity->actor_type,
            'actor_id'            => $activity->actor_id,
            'actor_code'          => $activity->actor_code,
            'actor_name'          => $activity->actor_name,
            'target_type'         => $activity->target_type,
            'target_id'           => $activity->target_id,
            'target_code'         => $activity->target_code,
            'class_section_id'    => $activity->class_section_id,
            'subject_id'          => $activity->subject_id,
            'lesson_id'           => $activity->lesson_id,
            'exercise_set_id'     => $activity->exercise_set_id,
            'exercise_attempt_id' => $activity->exercise_attempt_id,
            'event_type'          => $activity->event_type,
            'title'               => $activity->title,
            'body'                => $activity->body,
            'meta'                => $activity->meta ?? [],
            'read_at'             => optional($activity->read_at)?->toISOString(),
            'created_at'          => optional($activity->created_at)?->toISOString(),
        ];
    }
}
