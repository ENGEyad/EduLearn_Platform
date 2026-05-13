<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentDataController extends Controller
{
    /**
     * GET /api/student/subjects
     */
    public function subjects(Request $request): JsonResponse
    {
        $student = $request->user();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        $subjects = collect($student->subjects ?? [])
            ->map(function ($item) use ($request) {
                $item = is_array($item) ? $item : (array) $item;

                $subjectName = $item['subject_name']
                    ?? $item['subject_name_en']
                    ?? $item['subject_name_ar']
                    ?? $item['name_en']
                    ?? $item['name_ar']
                    ?? $item['name']
                    ?? '';

                $photoPath = $item['teacher_photo_path']
                    ?? $item['photo_path']
                    ?? null;

                $teacherImage = $item['teacher_image']
                    ?? $item['image']
                    ?? $this->buildStorageUrl($request, $photoPath);

                return array_merge($item, [
                    'subject_name' => $subjectName,
                    'teacher_name' => $item['teacher_name'] ?? $item['full_name'] ?? null,
                    'teacher_code' => $item['teacher_code'] ?? null,
                    'teacher_image' => $teacherImage,
                ]);
            })
            ->values();

        return response()->json([
            'success' => true,
            'subjects' => $subjects,
        ]);
    }

    /**
     * GET /api/student/teachers
     */
    public function teachers(Request $request): JsonResponse
    {
        $student = $request->user();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        if (!$student->class_section_id) {
            return response()->json([
                'success' => true,
                'teachers' => [],
            ]);
        }

        $classSection = $student->classSection()
            ->with(['assignments.teacher', 'assignments.subject'])
            ->first();

        if (!$classSection) {
            return response()->json([
                'success' => true,
                'teachers' => [],
            ]);
        }

        $teachers = [];

        foreach ($classSection->assignments as $assignment) {
            if (isset($assignment->is_active) && !$assignment->is_active) {
                continue;
            }

            $teacher = $assignment->teacher;
            $subject = $assignment->subject;

            if (!$teacher || empty($teacher->teacher_code)) {
                continue;
            }

            $teacherCode = (string) $teacher->teacher_code;
            $subjectName = $subject
                ? ($subject->name_en ?? $subject->name_ar ?? $subject->name ?? '')
                : '';

            if (!isset($teachers[$teacherCode])) {
                $teacherImage = $this->buildStorageUrl($request, $teacher->photo_path ?? null);

                $teachers[$teacherCode] = [
                    'id' => (int) $teacher->id,
                    'teacher_id' => (int) $teacher->id,
                    'teacher_code' => $teacherCode,
                    'full_name' => (string) ($teacher->full_name ?? ''),
                    'name' => (string) ($teacher->full_name ?? ''),
                    'image' => $teacherImage,
                    'teacher_image' => $teacherImage,
                    'photo_path' => $teacher->photo_path ?? null,

                    'assignment_id' => (int) $assignment->id,
                    'class_section_id' => (int) $assignment->class_section_id,
                    'subject_id' => (int) $assignment->subject_id,
                    'subject_name' => $subjectName,

                    'subjects' => [],
                ];
            }

            if ($subject) {
                $teachers[$teacherCode]['subjects'][] = [
                    'assignment_id' => (int) $assignment->id,
                    'subject_id' => (int) $subject->id,
                    'subject_name' => $subjectName,
                    'class_section_id' => (int) $assignment->class_section_id,
                ];
            }
        }

        return response()->json([
            'success' => true,
            'teachers' => array_values($teachers),
        ]);
    }

    /**
     * بناء رابط صورة آمن.
     */
    private function buildStorageUrl(Request $request, ?string $path): ?string
    {
        if (!is_string($path) || trim($path) === '') {
            return null;
        }

        $clean = ltrim(trim($path), '/');

        if (str_starts_with($clean, 'http://') || str_starts_with($clean, 'https://')) {
            return $clean;
        }

        if (str_starts_with($clean, 'storage/')) {
            $clean = substr($clean, 8);
        }

        $baseUrl = rtrim(config('app.url'), '/');
        return $baseUrl . '/storage/' . ltrim($clean, '/');
    }
}
