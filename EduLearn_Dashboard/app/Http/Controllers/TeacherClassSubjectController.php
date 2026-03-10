<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use App\Models\Subject;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use Illuminate\Http\Request;

class TeacherClassSubjectController extends Controller
{
    public function index()
    {
        return view('assignments', [
            'pageTitle' => 'Assignments',
            'pageSubtitle' => 'Link teachers with classes and subjects',
            'ASSIGN_ROUTES' => [
                'list' => route('assignments.list'),
                'store' => route('assignments.store'),
                'destroy' => route('assignments.destroy', ['assignment' => '__ID__']),
            ],
            'TEACHERS_API' => route('teachers.list'),
            'CLASSES_API' => route('classes.list'),
            'SUBJECTS_API' => route('subjects.list'),
        ]);
    }

    public function list()
    {
        $items = TeacherClassSubject::with(['teacher', 'classSection', 'subject'])
            ->orderBy('id', 'desc')
            ->get();

        return response()->json($items);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'teacher_id' => 'required|exists:teachers,id',
            'class_section_id' => 'required|exists:class_sections,id',
            'subject_id' => 'required|exists:subjects,id',
            'weekly_load' => 'nullable|integer|min:0|max:40',
            'is_active' => 'nullable|boolean',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);

        // منع تكرار نفس الربط
        $exists = TeacherClassSubject::where('teacher_id', $data['teacher_id'])
            ->where('class_section_id', $data['class_section_id'])
            ->where('subject_id', $data['subject_id'])
            ->first();

        if ($exists) {
            return response()->json([
                'message' => 'This assignment already exists',
                'assignment' => $exists,
            ], 409);
        }

        $assignment = TeacherClassSubject::create($data);
        $assignment->load(['teacher', 'classSection', 'subject']);

        \App\Models\DashboardNotification::logEvent(
            'assignment_event',
            'ربط معلم بفصل ومادة',
            "تم ربط المعلم: {$assignment->teacher->full_name} بالمادة: {$assignment->subject->name_ar} للفصل: {$assignment->classSection->grade}/{$assignment->classSection->section}.",
            'النظام',
            'bi-link'
        );

        return response()->json([
            'message' => 'Assignment created successfully',
            'assignment' => $assignment,
        ]);
    }

    public function destroy(TeacherClassSubject $assignment)
    {
        $teacherName = $assignment->teacher->full_name ?? 'معلم';
        $subjectName = $assignment->subject->name_ar ?? 'مادة';
        $assignment->delete();

        \App\Models\DashboardNotification::logEvent(
            'assignment_event',
            'إلغاء ربط معلم',
            "تم إلغاء ربط المعلم: {$teacherName} بمادة: {$subjectName}.",
            'النظام',
            'bi-link-45deg'
        );

        return response()->json([
            'message' => 'Assignment deleted successfully',
        ]);
    }
}
