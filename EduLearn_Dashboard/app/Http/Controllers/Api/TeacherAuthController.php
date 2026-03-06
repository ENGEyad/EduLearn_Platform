<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Teacher;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class TeacherAuthController extends Controller
{
    public function auth(Request $request)
    {
        $validated = $request->validate([
            'full_name'    => 'required|string|max:255',
            'teacher_code' => 'required|string|max:255',
            'email'        => 'nullable|email|max:255',
            'password'     => 'nullable|string|min:6',
        ]);

        // ✅ نعتمد على teacher_code فقط لتحديد الأستاذ
        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])
            ->first();

        if (!$teacher) {
            return response()->json([
                'success' => false,
                'message' => 'Teacher not found.',
            ], 404);
        }

        // (اختياري) لو حاب تحدّث الاسم في قاعدة البيانات ليطابق اللي كتبه في التطبيق
        // بحيث لو كتب اسم مُحدّث يتم حفظه:
        if (!empty($validated['full_name']) && $teacher->full_name !== $validated['full_name']) {
            $teacher->full_name = $validated['full_name'];
        }

        // تحديث بيانات الدخول (إيميل + باسورد) إن وُجدت
        $updated = false;

        if (!empty($validated['email']) && $teacher->email !== $validated['email']) {
            $teacher->email = $validated['email'];
            $updated = true;
        }

        if (!empty($validated['password'])) {
            $teacher->password = Hash::make($validated['password']);
            $updated = true;
        }

        if ($updated) {
            $teacher->save();
        }

        // ✅ تحميل الإسنادات مع المادة والصف/الشعبة
        $teacher->load(['assignments.subject', 'assignments.classSection']);

        $assignments = [];

        foreach ($teacher->assignments as $as) {
            $cs = $as->classSection;

            $grade   = $cs?->grade ?? null;
            $section = $cs?->section ?? null;

            // ✅ الطلاب مع صورهم
            $students = Student::where('class_section_id', $cs?->id)->get();

            $assignments[] = [
                'assignment_id'    => $as->id,

                'subject_id'       => $as->subject?->id,
                'subject_name'     => $as->subject?->name_en ?? $as->subject?->name,
                'subject_code'     => $as->subject?->code ?? null,

                'class_section_id' => $cs?->id,
                'class_grade'      => $grade,
                'class_section'    => $section,

                // ✅ الطلاب مع صورهم
                'students_count'   => $students->count(),
                'students'         => $students->map(function ($st) {
                    return [
                        'id'          => $st->id,
                        'full_name'   => $st->full_name,
                        'academic_id' => $st->academic_id,
                        'image'       => $st->image ?? null,
                    ];
                })->values(),
            ];
        }

        return response()->json([
            'success' => true,
            'teacher' => [
                'id'           => $teacher->id,
                'full_name'    => $teacher->full_name,
                'teacher_code' => $teacher->teacher_code,
                'email'        => $teacher->email,

                // ✅ صورة الأستاذ نفسه
                'image'        => $teacher->image ?? null,

                'stage'        => $teacher->stage,
                'status'       => $teacher->status,

                // ✅ الإسنادات الكاملة
                'assignments'  => $assignments,
            ],
        ]);
    }
}
