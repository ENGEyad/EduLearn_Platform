<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\LessonBlock;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use App\Models\LessonExercise;
use App\Models\LessonExerciseQuestion;
use App\Models\LessonExerciseOption;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LessonController extends Controller
{
    /**
     * ============================================================
     * 🔹 حفظ أو تعديل درس (Draft / Published) — المرحلة الأولى
     * ============================================================
     *
     * ✅ Source of Truth:
     * - Lesson مرتبط بـ class_module_id (Container الحقيقي)
     * - الدرس يحتوي Blocks فقط (بدون LessonModule/LessonTopic حاليًا)
     * - ترتيب البلوكات يعتمد فقط على position
     *
     * POST /api/teacher/lessons/save
     */
    public function save(Request $request)
    {
        $validated = $request->validate([
            // هوية الأستاذ + الاستهداف
            'teacher_code' => 'required|string',
            'assignment_id' => 'required|integer',
            'class_module_id' => 'required|integer', // ✅ الآن مطلوب (لأنه Container الحقيقي)
            'class_section_id' => 'required|integer',
            'subject_id' => 'required|integer',

            // بيانات الدرس
            'lesson_id' => 'nullable|integer',
            'title' => 'required|string|max:255',
            'status' => 'required|in:draft,published',

            /**
     * ------------------------------------------------------------
     * ⚠️ Backward compatibility:
     * نستقبل modules/topics لو جاءت من Flutter القديمة،
     * لكننا لا نخزنها ولا نعتمد عليها في المرحلة الأولى.
     * ------------------------------------------------------------
     */
            'modules' => 'nullable|array',
            'topics' => 'nullable|array',

            // Exercises
            'exercises' => 'nullable|array',

            // Blocks فقط
            'blocks' => 'nullable|array',
            'blocks.*.id' => 'nullable|integer',
            'blocks.*.type' => 'required|in:text,image,video,audio',
            'blocks.*.body' => 'nullable|string',
            'blocks.*.caption' => 'nullable|string|max:255',

            // ✅ مصدر الحقيقة للتخزين: media_path فقط
            'blocks.*.media_path' => 'nullable|string',

            // (نستقبلها لكن لا نخزنها في DB)
            'blocks.*.media_url' => 'nullable|string',

            'blocks.*.media_mime' => 'nullable|string',
            'blocks.*.media_size' => 'nullable|integer',
            'blocks.*.media_duration' => 'nullable|integer',

            // ✅ في المرحلة الأولى: لا Module/Topic داخل الدرس
            // نقبلها لو جاءت لكن سنجعلها null عند التخزين
            'blocks.*.module_id' => 'nullable',
            'blocks.*.topic_id' => 'nullable',

            'blocks.*.position' => 'nullable|integer',
            'blocks.*.meta' => 'nullable|array',
        ]);

        // ============================================================
        // 🔍 التأكد من الأستاذ + التأكد من الإسناد (Assignment)
        // ============================================================
        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->first();
        if (!$teacher) {
            return response()->json([
                'success' => false,
                'message' => 'Teacher not found',
            ], 404);
        }

        $assignment = TeacherClassSubject::where('id', $validated['assignment_id'])
            ->where('teacher_id', $teacher->id)
            ->first();

        if (!$assignment) {
            return response()->json([
                'success' => false,
                'message' => 'Assignment not found for this teacher',
            ], 404);
        }

        $lessonId = null;

        // ============================================================
        // ✅ Transaction ذرّية: (Lesson + Blocks + Publish) كعملية واحدة
        // ============================================================
        DB::connection('app_mysql')->transaction(function () use ($validated, $teacher, $assignment, &$lessonId) {

            // 🔹 إنشاء أو تحديث الدرس
            if (!empty($validated['lesson_id'])) {
                $lesson = Lesson::on('app_mysql')
                    ->where('id', $validated['lesson_id'])
                    ->where('teacher_id', $teacher->id)
                    ->firstOrFail();
            }
            else {
                $lesson = new Lesson();
                $lesson->setConnection('app_mysql');
            }

            $lesson->teacher_id = $teacher->id;
            $lesson->assignment_id = $assignment->id;
            $lesson->class_module_id = $validated['class_module_id']; // ✅ إلزامي
            $lesson->class_section_id = $validated['class_section_id'];
            $lesson->subject_id = $validated['subject_id'];
            $lesson->title = $validated['title'];
            $lesson->status = $validated['status'];

            // ✅ أول مرة ينشر فقط
            if ($validated['status'] === 'published' && !$lesson->published_at) {
                $lesson->published_at = now();
            }

            $lesson->save();
            $lessonId = $lesson->id;

            // ============================================================
            // ✅ سياسة التحديث (مرحلة أولى آمنة):
            // نحذف Blocks فقط ثم نعيد إنشاءها.
            // (لا نلمس LessonModule/LessonTopic في المرحلة الأولى)
            // ============================================================
            $lesson->blocks()->delete();

            // ============================================================
            // 🔹 حفظ البلوكات مع تطبيع position
            // - لو position غير موجودة: نستخدم ترتيب المصفوفة
            // - نجعل module_id/topic_id = null دائمًا (مرحلة 1)
            // ============================================================
            $blocks = $validated['blocks'] ?? [];
            foreach ($blocks as $index => $blockData) {

                $pos = isset($blockData['position'])
                    ? (int)$blockData['position']
                    : ($index + 1);

                $block = new LessonBlock();
                $block->setConnection('app_mysql');

                $block->lesson_id = $lesson->id;
                $block->type = $blockData['type'];
                $block->body = $blockData['body'] ?? null;
                $block->caption = $blockData['caption'] ?? null;

                // ✅ نخزن path فقط
                $block->media_path = $blockData['media_path'] ?? null;

                // ✅ لا نخزن media_url
                $block->media_url = null;

                $block->media_mime = $blockData['media_mime'] ?? null;
                $block->media_size = $blockData['media_size'] ?? null;
                $block->media_duration = $blockData['media_duration'] ?? null;

                // ✅ ترتيب ثابت
                $block->position = $pos;

                $block->meta = $blockData['meta'] ?? null;

                // ✅ المرحلة الأولى: لا تقسيم داخلي
                $block->module_id = null;
                $block->topic_id = null;

                $block->save();
            }

            // ============================================================
            // ✅ Manual Exercises processing (Teacher's manual exercises)
            // ============================================================
            if (isset($validated['exercises']) && is_array($validated['exercises'])) {
                $exercise = LessonExercise::firstOrCreate(
                    ['lesson_id' => $lesson->id],
                    ['version' => clone $lesson->version ?? 1, 'is_active' => true] 
                );

                // Increment version if updating an existing exercise to break cache
                if (!$exercise->wasRecentlyCreated) {
                    $exercise->increment('version');
                }

                // Delete old questions to rebuild them easily 
                $exercise->questions()->delete();

                foreach ($validated['exercises'] as $index => $qData) {
                    $question = LessonExerciseQuestion::create([
                        'exercise_id' => $exercise->id,
                        'type' => $qData['type'],
                        'question_text' => $qData['question_text'],
                        'position' => $qData['position'] ?? ($index + 1),
                        'correct_bool' => isset($qData['correct_bool']) ? (bool)$qData['correct_bool'] : null,
                    ]);

                    if ($qData['type'] === 'mcq' && isset($qData['options']) && is_array($qData['options'])) {
                        foreach ($qData['options'] as $idx => $oData) {
                            LessonExerciseOption::create([
                                'question_id' => $question->id,
                                'option_text' => $oData['text'] ?? $oData['option_text'] ?? '',
                                'is_correct' => isset($oData['is_correct']) ? (bool)$oData['is_correct'] : false,
                                'position' => $oData['position'] ?? ($idx + 1),
                            ]);
                        }
                    }
                }
            }

            // ✅ التوليد التلقائي للتمارين عند النشر
            if ($validated['status'] === 'published') {
                try {
                    // استدعاء داخلي لتوليد التمارين
                    app(AiController::class)->generateExercises(new Request([
                        'lesson_id' => $lessonId,
                        'count' => 5,
                        'difficulty' => 'medium'
                    ]));
                }
                catch (\Exception $e) {
                    // لا نريد إيقاف حفظ الدرس إذا فشل الـ AI
                    \Log::error("AI Exercise Generation failed: " . $e->getMessage());
                }
            }
        });

        // ============================================================
        // ✅ Response موحّد: نرجّع lesson كامل (لحل mismatch مع Flutter)
        // ============================================================
        $lessonRow = Lesson::on('app_mysql')
            ->where('id', $lessonId)
            ->where('teacher_id', $teacher->id)
            ->with(['blocks' => function ($q) {
                $q->orderBy('position');
            }, 'exercise.questions.options'])
            ->first();

        if (!$lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson saved but not found',
            ], 500);
        }

        // ✅ توليد media_url للعرض فقط
        $blocksPayload = ($lessonRow->blocks ?? collect())->map(function ($b) {
            $path = $b->media_path;
            $url = null;

            if (is_string($path) && $path !== '') {
                $p = ltrim($path, '/');
                if (str_starts_with($p, 'storage/')) {
                    $p = substr($p, 8);
                }
                $url = asset('storage/' . $p);
            }

            return [
            'id' => $b->id,
            'lesson_id' => $b->lesson_id,
            'module_id' => null, // ✅ مرحلة 1
            'topic_id' => null, // ✅ مرحلة 1
            'type' => $b->type,
            'body' => $b->body,
            'caption' => $b->caption,
            'media_path' => $b->media_path,
            'media_url' => $url,
            'media_mime' => $b->media_mime,
            'media_size' => $b->media_size,
            'media_duration' => $b->media_duration,
            'position' => $b->position,
            'meta' => $b->meta,
            'created_at' => $b->created_at,
            'updated_at' => $b->updated_at,
            ];
        })->values();

        $lessonPayload = $lessonRow->toArray();
        $lessonPayload['blocks'] = $blocksPayload;

        // Log notification to dashboard
        $actionTitle = !empty($validated['lesson_id']) ? 'تحديث درس' : 'إضافة درس جديد';
        $statusAr = ($validated['status'] === 'published') ? 'ونشره' : 'كـ مسودة';
        \App\Models\DashboardNotification::logEvent(
            'teacher_event',
            $actionTitle,
            "قام المعلم {$teacher->full_name} بحفظ الدرس \"{$validated['title']}\" {$statusAr}.",
            $teacher->full_name,
            'bi-journal-plus'
        );

        return response()->json([
            'success' => true,
            'lesson' => $lessonPayload,
        ]);
    }

    /**
     * ============================================================
     * 🔹 دروس الأستاذ (مع فلترة اختيارية)
     * ============================================================
     *
     * GET /api/teacher/lessons?teacher_code=XXX
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
            'assignment_id' => 'nullable|integer',
            'class_section_id' => 'nullable|integer',
            'subject_id' => 'nullable|integer',
            'class_module_id' => 'nullable|integer',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->firstOrFail();

        $query = Lesson::on('app_mysql')
            ->where('teacher_id', $teacher->id);

        if (!empty($validated['assignment_id'])) {
            $query->where('assignment_id', $validated['assignment_id']);
        }

        if (!empty($validated['class_section_id'])) {
            $query->where('class_section_id', $validated['class_section_id']);
        }

        if (!empty($validated['subject_id'])) {
            $query->where('subject_id', $validated['subject_id']);
        }

        if (!empty($validated['class_module_id'])) {
            $query->where('class_module_id', $validated['class_module_id']);
        }

        $lessons = $query->orderByDesc('created_at')->get();

        return response()->json([
            'success' => true,
            'lessons' => $lessons,
        ]);
    }

    /**
     * ============================================================
     * 🔹 جلب درس واحد للأستاذ (Lesson + Blocks)
     * ============================================================
     *
     * GET /api/teacher/lessons/{lesson}?teacher_code=XXX
     */
    public function show(Request $request, $lesson)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->first();
        if (!$teacher) {
            return response()->json([
                'success' => false,
                'message' => 'Teacher not found',
            ], 404);
        }

        $lessonRow = Lesson::on('app_mysql')
            ->where('id', $lesson)
            ->where('teacher_id', $teacher->id)
            ->with(['blocks' => function ($q) {
                $q->orderBy('position');
            }, 'exercise.questions.options'])
            ->first();

        if (!$lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        $blocks = ($lessonRow->blocks ?? collect())->map(function ($b) {
            $path = $b->media_path;
            $url = null;

            if (is_string($path) && $path !== '') {
                $p = ltrim($path, '/');
                if (str_starts_with($p, 'storage/')) {
                    $p = substr($p, 8);
                }
                $url = asset('storage/' . $p);
            }

            return [
            'id' => $b->id,
            'lesson_id' => $b->lesson_id,
            'module_id' => null,
            'topic_id' => null,
            'type' => $b->type,
            'body' => $b->body,
            'caption' => $b->caption,
            'media_path' => $b->media_path,
            'media_url' => $url,
            'media_mime' => $b->media_mime,
            'media_size' => $b->media_size,
            'media_duration' => $b->media_duration,
            'position' => $b->position,
            'meta' => $b->meta,
            'created_at' => $b->created_at,
            'updated_at' => $b->updated_at,
            ];
        })->values();

        $lessonPayload = $lessonRow->toArray();
        $lessonPayload['blocks'] = $blocks;
        $lessonPayload['exercises'] = $lessonRow->exercise ? $lessonRow->exercise->questions->map(function ($q) {
            return [
                'id' => $q->id,
                'type' => $q->type,
                'question_text' => $q->question_text,
                'position' => $q->position,
                'correct_bool' => $q->correct_bool,
                'options' => $q->options->map(function ($o) {
                    return [
                        'id' => $o->id,
                        'text' => $o->option_text,
                        'is_correct' => (bool)$o->is_correct,
                        'position' => $o->position,
                    ];
                })->values()
            ];
        })->values() : null;

        return response()->json([
            'success' => true,
            'lesson' => $lessonPayload,
        ]);
    }

    /**
     * ============================================================
     * 🔹 حذف درس واحد (مع كل البلوكات التابعة)
     * ============================================================
     *
     * DELETE /api/teacher/lessons/{lesson}?teacher_code=XXX
     */
    public function destroy(Request $request, $lesson)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->first();
        if (!$teacher) {
            return response()->json([
                'success' => false,
                'message' => 'Teacher not found',
            ], 404);
        }

        $lessonRow = Lesson::on('app_mysql')
            ->where('id', $lesson)
            ->where('teacher_id', $teacher->id)
            ->first();

        if (!$lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        DB::connection('app_mysql')->transaction(function () use ($lessonRow) {
            $lessonRow->blocks()->delete();
            // ✅ المرحلة الأولى: لا نحذف modules/topics لأننا لا نستخدمها الآن
            $lessonRow->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Lesson deleted successfully',
        ]);
    }

    /**
     * ============================================================
     * 🔹 حذف مجموعة دروس (Bulk Delete)
     * ============================================================
     *
     * POST /api/teacher/lessons/bulk-delete
     * body: { teacher_code, lesson_ids: [1,2,3,...] }
     */
    public function bulkDelete(Request $request)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
            'lesson_ids' => 'required|array',
            'lesson_ids.*' => 'integer',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->first();
        if (!$teacher) {
            return response()->json([
                'success' => false,
                'message' => 'Teacher not found',
            ], 404);
        }

        DB::connection('app_mysql')->transaction(function () use ($validated, $teacher) {
            $lessons = Lesson::on('app_mysql')
                ->where('teacher_id', $teacher->id)
                ->whereIn('id', $validated['lesson_ids'])
                ->get();

            foreach ($lessons as $lesson) {
                $lesson->blocks()->delete();
                $lesson->delete();
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Lessons deleted successfully',
        ]);
    }
}
