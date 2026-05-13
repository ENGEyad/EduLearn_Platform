<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Broadcast;

use App\Models\Teacher;
use App\Models\Student;

class BroadcastAuthController extends Controller
{
    public function auth(Request $request)
    {
        $role = $request->header('X-Chat-As');

        if ($role === 'teacher') {
            $code = $request->header('X-Teacher-Code');

            $teacher = Teacher::where('teacher_code', $code)->first();

            if (!$teacher) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            // 👇 نحقن المستخدم يدوياً
            $request->setUserResolver(function () use ($teacher) {
                return (object)[
                    'id' => $teacher->id,
                    'role' => 'teacher',
                ];
            });
        }

        elseif ($role === 'student') {
            $academicId = $request->header('X-Academic-Id');

            $student = Student::where('academic_id', $academicId)->first();

            if (!$student) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $request->setUserResolver(function () use ($student) {
                return (object)[
                    'id' => $student->id,
                    'role' => 'student',
                ];
            });
        }

        else {
            return response()->json(['message' => 'Invalid role'], 403);
        }

        return Broadcast::auth($request);
    }
}