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
            'pageTitle' => __('Assignments'),
            'pageSubtitle' => __('Link teachers with classes and subjects'),
            'ASSIGN_ROUTES' => [
                'list' => route('assignments.list'),
                'store' => route('assignments.store'),
                'update' => route('assignments.update', ['assignment' => '__ID__']),
                'destroy' => route('assignments.destroy', ['assignment' => '__ID__']),
            ],
            'TEACHERS_API' => route('teachers.list'),
            'CLASSES_API' => route('classes.list'),
            'SUBJECTS_API' => route('subjects.list'),
        ]);
    }

    public function list()
    {
        $schoolId = auth()->user()->school_id;

        $items = TeacherClassSubject::whereHas('teacher', function ($query) use ($schoolId) {
                $query->where('school_id', $schoolId);
            })
            ->with(['teacher', 'classSection', 'subject'])
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

        $schoolId = auth()->user()->school_id;

        // Verify ownership
        $teacher = Teacher::where('id', $data['teacher_id'])->where('school_id', $schoolId)->firstOrFail();
        $class = ClassSection::where('id', $data['class_section_id'])->where('school_id', $schoolId)->firstOrFail();

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
            'Teacher Assignment',
            'notifications.teacher_assigned',
            'System',
            'bi-link',
            auth()->user()->school_id,
            [
                'teacher' => $assignment->teacher->full_name,
                'subject_en' => $assignment->subject->name_en,
                'subject_ar' => $assignment->subject->name_ar,
                'grade' => $assignment->classSection->grade,
                'section' => $assignment->classSection->section
            ]
        );

        return response()->json([
            'message' => 'Assignment created successfully',
            'assignment' => $assignment,
        ]);
    }

    public function update(Request $request, TeacherClassSubject $assignment)
    {
        $data = $request->validate([
            'teacher_id' => 'required|exists:teachers,id',
            'class_section_id' => 'required|exists:class_sections,id',
            'subject_id' => 'required|exists:subjects,id',
            'weekly_load' => 'nullable|integer|min:0|max:40',
            'is_active' => 'nullable|boolean',
        ]);

        $schoolId = auth()->user()->school_id;

        $teacher = Teacher::where('id', $data['teacher_id'])->where('school_id', $schoolId)->firstOrFail();
        $class = ClassSection::where('id', $data['class_section_id'])->where('school_id', $schoolId)->firstOrFail();

        $data['is_active'] = $request->boolean('is_active', true);

        // Check conflicts
        $exists = TeacherClassSubject::where('teacher_id', $data['teacher_id'])
            ->where('class_section_id', $data['class_section_id'])
            ->where('subject_id', $data['subject_id'])
            ->where('id', '!=', $assignment->id)
            ->first();

        if ($exists) {
            return response()->json([
                'message' => 'This assignment already exists',
                'assignment' => $exists,
            ], 409);
        }

        $assignment->update($data);
        $assignment->load(['teacher', 'classSection', 'subject']);

        return response()->json([
            'message' => 'Assignment updated successfully',
            'assignment' => $assignment,
        ]);
    }

    public function destroy(TeacherClassSubject $assignment)
    {
        if ($assignment->teacher->school_id !== auth()->user()->school_id) {
            abort(403, 'Unauthorized access to teacher assignment.');
        }

        $teacherName = $assignment->teacher->full_name ?? 'معلم';
        $subjectName = $assignment->subject->name_ar ?? 'مادة';
        $assignment->delete();

        \App\Models\DashboardNotification::logEvent(
            'assignment_event',
            'Assignment Removed',
            'notifications.teacher_unassigned',
            'System',
            'bi-link-45deg',
            auth()->user()->school_id,
            [
                'teacher' => $teacherName,
                'subject_en' => $assignment->subject->name_en ?? 'Subject',
                'subject_ar' => $assignment->subject->name_ar ?? 'مادة'
            ]
        );

        return response()->json([
            'message' => 'Assignment deleted successfully',
        ]);
    }

    public function import(Request $request)
    {
        $request->validate([
            'csv_file' => 'required|file|mimes:csv,txt'
        ]);

        $file = $request->file('csv_file');
        $handle = fopen($file->getPathname(), 'r');
        $header = fgetcsv($handle);

        $schoolId = auth()->user()->school_id;
        $count = 0;

        \Illuminate\Support\Facades\DB::beginTransaction();

        try {
            // Preload maps to minimize queries
            $teachers = Teacher::where('school_id', $schoolId)->get()->keyBy('full_name');
            $classes = ClassSection::where('school_id', $schoolId)->get()->filter(function($c) { return isset($c->grade) && isset($c->section); });
            $subjects = \App\Models\Subject::all()->keyBy('name_en');

            while (($row = fgetcsv($handle)) !== false) {
                if (count($row) < 4) continue;

                $teacherName = $row[0];
                $grade = $row[1];
                $section = $row[2];
                $subjectName = $row[3];

                $teacher = $teachers->get($teacherName);
                if (!$teacher) continue;

                $classObj = $classes->first(function ($val, $key) use ($grade, $section) {
                    return $val->grade == $grade && $val->section == $section;
                });
                if (!$classObj) continue;

                $subjectObj = $subjects->get($subjectName);
                if (!$subjectObj) continue;

                TeacherClassSubject::updateOrCreate(
                    [
                        'teacher_id' => $teacher->id,
                        'class_section_id' => $classObj->id,
                        'subject_id' => $subjectObj->id,
                    ],
                    [
                        'weekly_load' => 4,
                        'is_active' => true
                    ]
                );
                $count++;
            }
            \Illuminate\Support\Facades\DB::commit();
            fclose($handle);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            fclose($handle);
            return response()->json(['error' => $e->getMessage()], 422);
        }

        \App\Models\DashboardNotification::logEvent(
            'assignment_event',
            __('Assignments Imported'),
            'notifications.assignments_imported',
            'System',
            'bi-link-45deg',
            $schoolId,
            ['count' => $count]
        );

        return response()->json([
            'message' => __(':count assignments imported successfully', ['count' => $count]),
        ]);
    }
}
