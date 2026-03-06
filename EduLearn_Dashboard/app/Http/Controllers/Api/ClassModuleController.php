<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ClassModule;
use App\Models\Lesson;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassModuleController extends Controller
{
    /**
     * 🔹 جلب وحدات (Modules) المعلم للفصل/المادة
     *
     * GET /api/teacher/class-modules?teacher_code=XXX
     *    &assignment_id=..
     *    &class_section_id=..
     *    &subject_id=..
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'teacher_code'     => 'required|string',
            'assignment_id'    => 'required|integer',
            'class_section_id' => 'required|integer',
            'subject_id'       => 'required|integer',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->firstOrFail();

        $modules = ClassModule::on('app_mysql')
            ->where('teacher_id', $teacher->id)
            ->where('assignment_id', $validated['assignment_id'])
            ->where('class_section_id', $validated['class_section_id'])
            ->where('subject_id', $validated['subject_id'])
            ->orderBy('position')
            ->orderBy('id')
            ->withCount('lessons') // يعطينا lessons_count
            ->get();

        return response()->json([
            'success' => true,
            'modules' => $modules,
        ]);
    }

    /**
     * 🔹 إنشاء موديول جديد
     *
     * POST /api/teacher/class-modules
     * body: { teacher_code, assignment_id, class_section_id, subject_id, title, (position) }
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'teacher_code'     => 'required|string',
            'assignment_id'    => 'required|integer',
            'class_section_id' => 'required|integer',
            'subject_id'       => 'required|integer',
            'title'            => 'required|string|max:255',
            'position'         => 'nullable|integer',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->firstOrFail();

        // تأكد أن الإسناد فعلاً لهذا الأستاذ (اختياري بس أفضل)
        $assignment = TeacherClassSubject::where('id', $validated['assignment_id'])
            ->where('teacher_id', $teacher->id)
            ->first();

        if (! $assignment) {
            return response()->json([
                'success' => false,
                'message' => 'Assignment not found for this teacher',
            ], 404);
        }

        $module = new ClassModule();
        $module->setConnection('app_mysql');
        $module->teacher_id     = $teacher->id;
        $module->assignment_id  = $validated['assignment_id'];
        $module->class_section_id = $validated['class_section_id'];
        $module->subject_id     = $validated['subject_id'];
        $module->title          = $validated['title'];
        $module->position       = $validated['position'] ?? 0;
        $module->save();

        $module->loadCount('lessons');

        return response()->json([
            'success' => true,
            'module'  => $module,
        ], 201);
    }

    /**
     * 🔹 تعديل اسم/ترتيب الموديول
     *
     * PUT /api/teacher/class-modules/{module}
     */
    public function update(Request $request, ClassModule $module)
    {
        $module->setConnection('app_mysql');

        $validated = $request->validate([
            'title'    => 'required|string|max:255',
            'position' => 'nullable|integer',
        ]);

        $module->title    = $validated['title'];
        $module->position = $validated['position'] ?? $module->position;
        $module->save();

        $module->loadCount('lessons');

        return response()->json([
            'success' => true,
            'module'  => $module,
        ]);
    }

    /**
     * 🔹 حذف موديول مع جميع دروسه ومحتواها
     *
     * DELETE /api/teacher/class-modules/{module}
     */
    public function destroy(ClassModule $module)
    {
        $module->setConnection('app_mysql');

        DB::connection('app_mysql')->transaction(function () use ($module) {
            // احذف الدروس التابعة لهذا الموديول مع البلوكات والموديولات الداخلية والتوبيكس
            $lessons = $module->lessons()->get();

            foreach ($lessons as $lesson) {
                $lesson->blocks()->delete();
                $lesson->topics()->delete();
                $lesson->modules()->delete();
                $lesson->delete();
            }

            $module->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Module and its lessons deleted successfully',
        ]);
    }

    /**
     * 🔹 جلب دروس موديول معيّن
     *
     * GET /api/teacher/class-modules/{module}/lessons
     */
    public function lessons(ClassModule $module)
    {
        $module->setConnection('app_mysql');

        $lessons = Lesson::on('app_mysql')
            ->where('class_module_id', $module->id)
            ->orderByDesc('created_at')
            ->get(['id', 'title', 'status', 'created_at']);

        return response()->json([
            'success' => true,
            'lessons' => $lessons,
        ]);
    }
}
