<?php

namespace App\Http\Controllers;

use App\Models\Subject;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    public function index()
    {
        return view('subjects', [
            'pageTitle' => 'Subjects',
            'pageSubtitle' => 'Manage subjects data',
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
            'إضافة مادة تعليمية',
            "تمت إضافة المادة الجديدة: {$subject->name_ar} ({$subject->name_en}).",
            'النظام',
            'bi-book'
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
            'تحديث مادة تعليمية',
            "تم تحديث بيانات المادة: {$subject->name_ar}.",
            'النظام',
            'bi-pencil-square'
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
            'حذف مادة تعليمية',
            "تم حذف المادة: {$name} من النظام.",
            'النظام',
            'bi-journal-x'
        );

        return response()->json([
            'message' => 'Subject deleted successfully',
        ]);
    }
}
