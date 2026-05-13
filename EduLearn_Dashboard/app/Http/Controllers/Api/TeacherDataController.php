<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\Teacher;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TeacherDataController extends Controller
{
    /**
     * GET /api/teacher/assignments-summary
     */
    public function assignmentsSummary(Request $request): JsonResponse
    {
        $teacher = $request->user();

        if (!$teacher || !($teacher instanceof Teacher)) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $teacher->load(['assignments.subject', 'assignments.classSection']);

        $summary = [];
        foreach ($teacher->assignments as $assignment) {
            if (isset($assignment->is_active) && !$assignment->is_active) {
                continue;
            }

            $classSection = $assignment->classSection;
            $subject = $assignment->subject;
            if (!$classSection || !$subject) {
                continue;
            }

            $studentsCount = Student::where('class_section_id', $classSection->id)->count();

            $subjectName = $subject->name_en
                ?? $subject->name_ar
                ?? $subject->name
                ?? '';

            $summary[] = [
                'assignment_id'    => (int) $assignment->id,
                'subject_id'       => (int) $subject->id,
                'subject_name'     => $subjectName,
                'subject_name_en'  => $subject->name_en ?? null,
                'subject_name_ar'  => $subject->name_ar ?? null,
                'subject_code'     => $subject->code ?? null,
                'class_section_id' => (int) $classSection->id,
                'class_grade'      => $classSection->grade ?? $classSection->grade_name ?? null,
                'class_section'    => $classSection->section ?? $classSection->section_name ?? null,
                'students_count'   => (int) $studentsCount,
            ];
        }

        return response()->json([
            'success' => true,
            'assignments' => array_values($summary),
        ]);
    }

    /**
     * GET /api/teacher/assignment/{assignment}/students
     */
    public function assignmentStudents(Request $request, $assignmentId): JsonResponse
    {
        $teacher = $request->user();

        if (!$teacher || !($teacher instanceof Teacher)) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $assignment = $teacher->assignments()
            ->with(['subject', 'classSection'])
            ->where('id', $assignmentId)
            ->first();

        if (!$assignment) {
            return response()->json(['success' => false, 'message' => 'Assignment not found'], 404);
        }

        if (isset($assignment->is_active) && !$assignment->is_active) {
            return response()->json([
                'success' => true,
                'students' => [],
            ]);
        }

        $classSection = $assignment->classSection;
        $subject = $assignment->subject;

        $students = Student::where('class_section_id', $assignment->class_section_id)
            ->orderBy('full_name')
            ->get(['id', 'full_name', 'academic_id', 'photo_path', 'class_section_id'])
            ->map(function (Student $student) use ($assignment, $classSection, $subject) {
                return [
                    'id' => (int) $student->id,
                    'student_id' => (int) $student->id,
                    'full_name' => $student->full_name,
                    'name' => $student->full_name,
                    'academic_id' => (string) $student->academic_id,
                    'image' => $student->image,
                    'photo_path' => $student->photo_path,
                    'assignment_id' => (int) $assignment->id,
                    'class_section_id' => (int) $assignment->class_section_id,
                    'subject_id' => (int) $assignment->subject_id,
                    'subject_name' => $subject
                        ? ($subject->name_en ?? $subject->name_ar ?? $subject->name ?? '')
                        : null,
                    'class_grade' => $classSection
                        ? ($classSection->grade ?? $classSection->grade_name ?? null)
                        : null,
                    'class_section' => $classSection
                        ? ($classSection->section ?? $classSection->section_name ?? null)
                        : null,
                ];
            })
            ->values();

        return response()->json([
            'success' => true,
            'students' => $students,
        ]);
    }
}
