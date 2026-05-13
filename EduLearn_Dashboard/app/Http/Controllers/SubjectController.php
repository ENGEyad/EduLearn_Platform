<?php

namespace App\Http\Controllers;

use App\Models\Subject;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    public function index()
    {
        return view('subjects', [
            'pageTitle' => __('Subjects'),
            'pageSubtitle' => __('Manage subjects data'),
            'SUBJECTS_ROUTES' => [
                'list' => route('subjects.list'),
                'store' => route('subjects.store'),
                'update' => route('subjects.update', ['subject' => '__ID__']),
                'destroy' => route('subjects.destroy', ['subject' => '__ID__']),
            ],
            'CLASSES_API' => route('classes.list'),
        ]);
    }

    public function list()
    {
        $user = auth()->user();
        if (!$user) return response()->json([]);

        if ($user->role === 'super_admin') {
            $subjects = Subject::withCount(['teacherAssignments as teachers_count'])
                ->with('classSections')
                ->orderBy('id', 'desc')->get();
            return response()->json($subjects);
        }

        $schoolId = $user->school_id;
        if (!$schoolId) return response()->json([]);

        // Get subjects specifically enabled for this school using a more direct query
        $subjects = Subject::join('school_subjects', 'subjects.id', '=', 'school_subjects.subject_id')
            ->where('school_subjects.school_id', $schoolId)
            ->select('subjects.*', 'school_subjects.is_active as pivot_is_active')
            ->withCount(['teacherAssignments as teachers_count' => function ($q) use ($schoolId) {
                $q->whereHas('classSection', function ($subq) use ($schoolId) {
                    $subq->where('school_id', $schoolId);
                });
            }])
            ->with(['classSections' => function($q) use ($schoolId) {
                $q->where('school_id', $schoolId);
            }])
            ->orderBy('subjects.id', 'desc')
            ->get();

        // Map it to look like a standard relationship with pivot for JS compatibility
        $formatted = $subjects->map(function($subject) {
            $subject->pivot = (object)['is_active' => $subject->pivot_is_active];
            // Include teachers count explicitly if needed (it comes as an attribute)
            return $subject;
        });

        return response()->json($formatted);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name_en' => 'required|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'code' => 'required|string|max:50|unique:subjects,code',
            'is_active' => 'nullable|boolean',
            'class_section_ids' => 'nullable|array',
            'class_section_ids.*' => 'integer|exists:class_sections,id',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);
        $classSectionIds = $request->input('class_section_ids', []);

        $subject = Subject::create([
            'name_en' => $data['name_en'],
            'name_ar' => $data['name_ar'],
            'code' => $data['code'],
            'is_active' => $data['is_active'],
        ]);

        $user = auth()->user();
        if ($user && $user->role !== 'super_admin' && $user->school_id) {
            $user->school->subjects()->attach($subject->id, ['is_active' => true]);

            if (!empty($classSectionIds)) {
                $syncData = [];
                foreach ($classSectionIds as $cid) {
                    $syncData[$cid] = ['is_active' => true];
                }
                $subject->classSections()->sync($syncData);
            }
        }

        \App\Models\DashboardNotification::logEvent(
            'subject_event',
            'Subject Added',
            'notifications.subject_added',
            'System',
            'bi-book',
            auth()->user()->school_id,
            ['name_en' => $subject->name_en, 'name_ar' => $subject->name_ar]
        );

        return response()->json([
            'message' => __('Subject created successfully'),
            'subject' => $subject,
        ]);
    }

    public function update(Request $request, Subject $subject)
    {
        $data = $request->validate([
            'name_en' => 'required|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'code' => 'required|string|max:50|unique:subjects,code,' . $subject->id,
            'is_active' => 'nullable|boolean',
            'class_section_ids' => 'nullable|array',
            'class_section_ids.*' => 'integer|exists:class_sections,id',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);
        $classSectionIds = $request->input('class_section_ids', []);

        $subject->update([
            'name_en' => $data['name_en'],
            'name_ar' => $data['name_ar'],
            'code' => $data['code'],
            'is_active' => $data['is_active'],
        ]);

        $user = auth()->user();
        if ($user && $user->role !== 'super_admin' && $user->school_id) {
            $syncData = [];
            foreach ($classSectionIds as $cid) {
                $syncData[$cid] = ['is_active' => true];
            }
            $subject->classSections()->sync($syncData);
        }

        \App\Models\DashboardNotification::logEvent(
            'subject_event',
            'Subject Updated',
            'notifications.subject_updated',
            'System',
            'bi-pencil-square',
            auth()->user()->school_id,
            ['name_en' => $subject->name_en, 'name_ar' => $subject->name_ar]
        );

        return response()->json([
            'message' => __('Subject updated successfully'),
            'subject' => $subject,
        ]);
    }

    public function destroy(Subject $subject)
    {
        $name = $subject->name_ar;
        $subject->delete();

        \App\Models\DashboardNotification::logEvent(
            'subject_event',
            'Subject Deleted',
            'notifications.subject_deleted',
            'System',
            'bi-journal-x',
            auth()->user()->school_id,
            ['name' => $name]
        );

        return response()->json([
            'message' => __('Subject deleted successfully'),
        ]);
    }

    public function content(Subject $subject)
    {
        $schoolId = auth()->user()->school_id;
        
        // Verify this subject is available to the school
        if (!auth()->user()->school->subjects()->where('subject_id', $subject->id)->exists()) {
            abort(403);
        }

        // Fetch teachers who teach this subject in this school
        $teacherIds = \App\Models\TeacherClassSubject::whereHas('classSection', function($q) use ($schoolId) {
            $q->where('school_id', $schoolId);
        })->where('subject_id', $subject->id)->pluck('teacher_id')->unique();

        // Fetch lessons for this subject created by these teachers
        $lessons = \App\Models\Lesson::on('app_mysql')
            ->where('subject_id', $subject->id)
            ->whereIn('teacher_id', $teacherIds)
            ->with(['exerciseSet'])
            ->orderBy('id', 'desc')
            ->get();

        return view('subject_content', [
            'pageTitle' => __('Curriculum') . ': ' . (app()->getLocale() == 'ar' ? $subject->name_ar : $subject->name_en),
            'pageSubtitle' => __('View lessons and exercises added by teachers'),
            'subject' => $subject,
            'lessons' => $lessons,
        ]);
    }
}
