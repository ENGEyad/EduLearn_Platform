<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\Student;
use App\Models\StudentLessonProgress;
use Illuminate\Http\Request;

class StudentLessonController extends Controller
{
    /**
     * ============================================================
     * 🔹 جلب دروس مادة معيّنة لطالب معيّن (قائمة)
     * ============================================================
     *
     * ✅ قواعد المرحلة الأولى:
     * - نعرض فقط الدروس المنشورة published
     * - مطابقة صارمة لشعبة الطالب class_section_id
     * - مطابقة لمادة subject_id
     * - نعتمد على class_module_id لعمل Grouping في الواجهة
     *
     * GET /api/student/lessons?academic_id=12345&subject_id=10
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'academic_id' => 'required|string',
            'subject_id'  => 'required|integer',
        ]);

        // 🧑‍🎓 الطالب من قاعدة edulearn_db (الافتراضية)
        $student = Student::where('academic_id', $validated['academic_id'])->first();

        if (! $student) {
            return response()->json([
                'success' => false,
                'message' => 'Student not found',
            ], 404);
        }

        $classSectionId = $student->class_section_id;

        if (! $classSectionId) {
            return response()->json([
                'success' => false,
                'message' => 'Student has no class_section_id',
            ], 422);
        }

        /**
         * ============================================================
         * ✅ الدروس المنشورة فقط من app_mysql
         * - with(classModule) لتوفير class_module_title
         * - ترتيب مناسب للتجميع: class_module_id ثم published_at
         * ============================================================
         */
        $lessons = Lesson::on('app_mysql')
            ->with('classModule')
            ->where('class_section_id', $classSectionId)
            ->where('subject_id', $validated['subject_id'])
            ->where('status', 'published')
            ->orderBy('class_module_id')
            ->orderBy('published_at', 'asc')
            ->get();

        if ($lessons->isEmpty()) {
            return response()->json([
                'success' => true,
                'lessons' => [],
            ]);
        }

        /**
         * ============================================================
         * ✅ تقدّم الطالب في هذه الدروس
         * ============================================================
         */
        $progress = StudentLessonProgress::on('app_mysql')
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $lessons->pluck('id'))
            ->get()
            ->keyBy('lesson_id');

        $responseLessons = $lessons->values()->map(function (Lesson $lesson, $index) use ($progress) {
            $p = $progress->get($lesson->id);

            // إذا ما في سجل -> not_started
            $status = $p ? ($p->status ?? 'draft') : 'not_started'; // not_started | draft | completed

            if (! in_array($status, ['not_started', 'draft', 'completed'], true)) {
                $status = 'draft';
            }

            $moduleTitle = optional($lesson->classModule)->title ?? 'Lessons';

            return [
                'id'               => $lesson->id,
                'title'            => $lesson->title,

                // ✅ أكثر أمانًا من $lesson->meta['duration_label'] إذا meta ليست array
                'duration_label'   => data_get($lesson->meta, 'duration_label'),

                'status'           => $status,
                'number'           => $index + 1,

                // ✅ مفاتيح ثابتة للواجهة (Grouping by ClassModule)
                'class_module_id'    => $lesson->class_module_id,
                'class_module_title' => $moduleTitle,

                // ✅ Alias مؤقت لتوافق أي شاشة قديمة كانت تقرأ module_title
                'module_title'     => $moduleTitle,
            ];
        });

        return response()->json([
            'success' => true,
            'lessons' => $responseLessons,
        ]);
    }

    /**
     * ============================================================
     * 🔹 تفاصيل درس للطالب (Lesson + Blocks)
     * ============================================================
     *
     * ✅ قواعد المرحلة الأولى:
     * - الطالب لا يرى إلا المنشور published
     * - مطابقة صارمة لشعبة الطالب
     * - البلوكات تُعرض بترتيب position فقط
     * - media_url يُبنَى دائمًا من media_path (للعرض)
     *
     * GET /api/student/lessons/{lesson}?academic_id=12345
     */
    public function show(Request $request, $lesson)
    {
        $validated = $request->validate([
            'academic_id' => 'required|string',
        ]);

        // 🧑‍🎓 الطالب من قاعدة edulearn_db (الافتراضية)
        $student = Student::where('academic_id', $validated['academic_id'])->first();
        if (! $student) {
            return response()->json([
                'success' => false,
                'message' => 'Student not found',
            ], 404);
        }

        if (! $student->class_section_id) {
            return response()->json([
                'success' => false,
                'message' => 'Student has no class_section_id',
            ], 422);
        }

        /**
         * ============================================================
         * ✅ نحمّل الدرس من app_mysql مع:
         * - classModule (للعنوان/التجميع)
         * - blocks مرتبة على position
         * ============================================================
         */
        $lessonRow = Lesson::on('app_mysql')
            ->with([
                'classModule',
                'blocks' => function ($q) {
                    $q->orderBy('position');
                },
            ])
            ->find($lesson);

        if (! $lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        // ✅ حماية: الدرس لنفس شعبة الطالب
        if ((int) $lessonRow->class_section_id !== (int) $student->class_section_id) {
            return response()->json([
                'success' => false,
                'message' => 'This lesson does not belong to the student class section',
            ], 403);
        }

        // ✅ حماية: الطالب لا يرى إلا المنشور
        if (($lessonRow->status ?? null) !== 'published') {
            return response()->json([
                'success' => false,
                'message' => 'Lesson is not published',
            ], 403);
        }

        /**
         * ============================================================
         * ✅ Normalize blocks:
         * - نعتمد position فقط (مصدر الحقيقة للترتيب)
         * - نبني media_url من media_path (بدون تخزينه)
         * ============================================================
         */
        $blocksPayload = collect($lessonRow->blocks ?? [])->map(function ($b) {
            $path = $b->media_path;
            $url  = null;

            if (is_string($path) && $path !== '') {
                $p = ltrim($path, '/');

                // إذا وصل storage/... نحذف prefix ونرجع asset(storage/...)
                if (str_starts_with($p, 'storage/')) {
                    $p = substr($p, 8);
                }

                $url = asset('storage/' . $p);
            }

            return [
                'id'             => $b->id,
                'lesson_id'       => $b->lesson_id,

                // ✅ المرحلة الأولى: لا تقسيم داخلي
                'module_id'       => null,
                'topic_id'        => null,

                'type'            => $b->type,
                'body'            => $b->body,
                'caption'         => $b->caption,

                // ✅ الترتيب الصحيح
                'position'        => (int) ($b->position ?? 0),

                // ✅ الميديا
                'media_path'      => $b->media_path,
                'media_url'       => $url,
                'media_mime'      => $b->media_mime,
                'media_size'      => $b->media_size,
                'media_duration'  => $b->media_duration,

                'meta'            => $b->meta,
                'created_at'      => $b->created_at,
                'updated_at'      => $b->updated_at,
            ];
        })->values();

        /**
         * ============================================================
         * ✅ حالة الطالب لهذا الدرس (مفيدة للـ Viewer)
         * ============================================================
         */
        $p = StudentLessonProgress::on('app_mysql')
            ->where('student_id', $student->id)
            ->where('lesson_id', $lessonRow->id)
            ->first();

        $status = $p ? ($p->status ?? 'draft') : 'not_started';
        if (! in_array($status, ['not_started', 'draft', 'completed'], true)) {
            $status = 'draft';
        }

        $moduleTitle = optional($lessonRow->classModule)->title ?? 'Lessons';

        return response()->json([
            'success' => true,
            'lesson'  => [
                'id'                => $lessonRow->id,
                'title'             => $lessonRow->title,
                'status'            => $status,
                'duration_label'    => data_get($lessonRow->meta, 'duration_label'),
                'published_at'      => $lessonRow->published_at,

                'subject_id'        => $lessonRow->subject_id,
                'class_section_id'  => $lessonRow->class_section_id,

                // ✅ للتجميع في واجهة الطالب
                'class_module_id'    => $lessonRow->class_module_id,
                'class_module_title' => $moduleTitle,

                // ✅ Alias مؤقت (إن كانت شاشة قديمة تعتمد module_title)
                'module_title'      => $moduleTitle,

                // ✅ Blocks مرتبة على position
                'blocks'            => $blocksPayload,
            ],
        ]);
    }

    /**
     * ============================================================
     * 🔹 تحديث حالة الدرس للطالب (not_started / draft / completed)
     * ============================================================
     *
     * POST /api/student/lessons/update-status
     * body: { academic_id, lesson_id, status }
     */
    public function updateStatus(Request $request)
    {
        $validated = $request->validate([
            'academic_id' => 'required|string',
            'lesson_id'   => 'required|integer',
            'status'      => 'required|in:not_started,draft,completed',
        ]);

        // الطالب (edulearn_db الافتراضية)
        $student = Student::where('academic_id', $validated['academic_id'])->first();

        if (! $student) {
            return response()->json([
                'success' => false,
                'message' => 'Student not found',
            ], 404);
        }

        if (! $student->class_section_id) {
            return response()->json([
                'success' => false,
                'message' => 'Student has no class_section_id',
            ], 422);
        }

        // الدرس من app_mysql
        $lesson = Lesson::on('app_mysql')->find($validated['lesson_id']);
        if (! $lesson) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        // ✅ حماية: الدرس يجب أن يكون لنفس شعبة الطالب
        if ((int) $lesson->class_section_id !== (int) $student->class_section_id) {
            return response()->json([
                'success' => false,
                'message' => 'This lesson does not belong to the student class section',
            ], 403);
        }

        // ✅ حماية: الطالب لا يتعامل إلا مع الدروس المنشورة
        if (($lesson->status ?? null) !== 'published') {
            return response()->json([
                'success' => false,
                'message' => 'Lesson is not published',
            ], 403);
        }

        $status = $validated['status'];

        // not_started = Reset: نحذف سجل التقدم
        if ($status === 'not_started') {
            StudentLessonProgress::on('app_mysql')
                ->where('lesson_id', $lesson->id)
                ->where('student_id', $student->id)
                ->delete();

            return response()->json([
                'success' => true,
                'status'  => 'not_started',
            ]);
        }

        $existing = StudentLessonProgress::on('app_mysql')
            ->where('lesson_id', $lesson->id)
            ->where('student_id', $student->id)
            ->first();

        // ✅ لا نرجع draft بعد completed
        if ($status === 'draft' && $existing && $existing->status === 'completed') {
            return response()->json([
                'success' => true,
                'status'  => 'completed',
                'message' => 'Lesson already completed',
            ]);
        }

        $progress = StudentLessonProgress::on('app_mysql')->updateOrCreate(
            [
                'lesson_id'  => $lesson->id,
                'student_id' => $student->id,
            ],
            [
                'status'         => $status,
                'last_opened_at' => now(),
                'completed_at'   => $status === 'completed' ? now() : null,
            ]
        );

        return response()->json([
            'success' => true,
            'status'  => $progress->status,
        ]);
    }
}
