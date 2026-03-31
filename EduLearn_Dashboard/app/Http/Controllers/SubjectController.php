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
        ]);
    }

    public function list()
    {
        return response()->json(
            Subject::orderBy('id', 'desc')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name_en' => 'required|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'code' => 'required|string|max:50|unique:subjects,code',
            'is_active' => 'nullable|boolean',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);

        $subject = Subject::create($data);

        \App\Models\DashboardNotification::logEvent(
            'subject_event',
            'Subject Added',
            'notifications.subject_added',
            'System',
            'bi-book',
            ['name_en' => $subject->name_en, 'name_ar' => $subject->name_ar]
        );

        return response()->json([
            'message' => 'Subject created successfully',
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
        ]);

        $data['is_active'] = $request->boolean('is_active', true);

        $subject->update($data);

        \App\Models\DashboardNotification::logEvent(
            'subject_event',
            'Subject Updated',
            'notifications.subject_updated',
            'System',
            'bi-pencil-square',
            ['name_en' => $subject->name_en, 'name_ar' => $subject->name_ar]
        );

        return response()->json([
            'message' => 'Subject updated successfully',
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
            ['name' => $name]
        );

        return response()->json([
            'message' => 'Subject deleted successfully',
        ]);
    }
}
