<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\TeacherClassSubject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class StudentAuthController extends Controller
{
    public function auth(Request $request)
    {
        $validated = $request->validate([
            'full_name'   => 'required|string|max:255',
            'academic_id' => 'required|string|max:255',
            'email'       => 'nullable|email|max:255',
            'password'    => 'nullable|string|min:6',
        ]);

        $student = Student::where('academic_id', $validated['academic_id'])
            ->where('full_name', $validated['full_name'])
            ->first();

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Student not found.',
            ], 404);
        }

        // تحديث بيانات الدخول
        $updated = false;

        if (!empty($validated['email']) && $student->email !== $validated['email']) {
            $student->email = $validated['email'];
            $updated = true;
        }

        if (!empty($validated['password'])) {
            $student->password = Hash::make($validated['password']);
            $updated = true;
        }

        if ($updated) {
            $student->save();
        }

        // ✅ المواد + صورة الأستاذ
        $realSubjects = [];

        if ($student->class_section_id) {
            $assignments = TeacherClassSubject::with(['subject', 'teacher'])
                ->where('class_section_id', $student->class_section_id)
                ->get();

            $realSubjects = $assignments->map(function ($as) {
                return [
                    'subject_id'    => $as->subject?->id,
                    'subject_name'  => $as->subject?->name_en ?? $as->subject?->name,
                    'subject_code'  => $as->subject?->code ?? null,

                    'teacher_id'    => $as->teacher?->id,
                    'teacher_name'  => $as->teacher?->full_name,
                    'teacher_image' => $as->teacher?->image ?? null, // ✅ صورة الأستاذ
                ];
            })->values()->all();
        }

        return response()->json([
            'success' => true,
            'student' => [
                'id'            => $student->id,
                'full_name'     => $student->full_name,
                'academic_id'   => $student->academic_id,
                'email'         => $student->email,
                'grade'         => $student->grade,
                'class_section' => $student->class_section,
                'class_section_id' => $student->class_section_id,

                // ✅ صورة الطالب نفسه
                'image'         => $student->image ?? null,

                'status'        => $student->status,

                // ✅ المواد مع الأستاذ وصورته
                'assigned_subjects' => $realSubjects,
            ],
        ]);
    }
}
