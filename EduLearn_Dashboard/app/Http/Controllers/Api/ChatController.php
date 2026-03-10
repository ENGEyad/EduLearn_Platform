<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Student;
use App\Models\Teacher;
use App\Events\MessageSent;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    /**
     * فتح / إنشاء محادثة بين أستاذ وطالب
     * POST /api/chat/conversations/open
     */
    public function openConversation(Request $request)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
            'academic_id' => 'required|string',
            'class_section_id' => 'nullable|integer',
            'subject_id' => 'nullable|integer',
            'as' => 'nullable|in:teacher,student',
        ]);

        $as = $validated['as'] ?? 'teacher';
        $forTeacher = $as === 'teacher';

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->first();
        if (!$teacher) {
            return response()->json([
                'success' => false,
                'message' => 'Teacher not found.',
            ], 404);
        }

        $student = Student::where('academic_id', $validated['academic_id'])->first();
        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Student not found.',
            ], 404);
        }

        $classSectionId = $validated['class_section_id'] ?? $student->class_section_id;
        $subjectId = $validated['subject_id'] ?? null;

        // ملاحظة: نُبقي المنطق كما هو (بدون تغيير DB)
        $conversation = Conversation::firstOrCreate(
        [
            'teacher_id' => $teacher->id,
            'student_id' => $student->id,
            'class_section_id' => $classSectionId,
            'subject_id' => $subjectId,
        ],
        [
            'last_message' => null,
            'last_message_at' => null,
            'unread_for_teacher' => 0,
            'unread_for_student' => 0,
        ]
        );

        // تحميل الطرفين مرة واحدة لتفادي تكرار الاستعلامات
        [$teacherMap, $studentMap, $classMap] = $this->loadActorsForConversations(collect([$conversation]));

        return response()->json([
            'success' => true,
            'conversation' => $this->formatConversation($conversation, $forTeacher, $teacherMap, $studentMap, $classMap),
        ]);
    }

    /**
     * قائمة محادثات الأستاذ
     * GET /api/chat/conversations/teacher?teacher_code=...
     */
    public function teacherConversations(Request $request)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->first();
        if (!$teacher) {
            return response()->json([
                'success' => false,
                'message' => 'Teacher not found.',
            ], 404);
        }

        $conversations = Conversation::where('teacher_id', $teacher->id)
            ->orderByDesc('last_message_at')
            ->orderByDesc('updated_at')
            ->get();

        [$teacherMap, $studentMap, $classMap] = $this->loadActorsForConversations($conversations);

        return response()->json([
            'success' => true,
            'conversations' => $conversations->map(
        fn(Conversation $c) => $this->formatConversation($c, true, $teacherMap, $studentMap, $classMap)
        ),
        ]);
    }

    /**
     * قائمة محادثات الطالب
     * GET /api/chat/conversations/student?academic_id=...
     */
    public function studentConversations(Request $request)
    {
        $validated = $request->validate([
            'academic_id' => 'required|string',
        ]);

        $student = Student::where('academic_id', $validated['academic_id'])->first();
        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Student not found.',
            ], 404);
        }

        $conversations = Conversation::where('student_id', $student->id)
            ->orWhere(function ($q) use ($student) {
            $q->whereNull('student_id')->where('class_section_id', $student->class_section_id);
        })
            ->orderByDesc('last_message_at')
            ->orderByDesc('updated_at')
            ->get();

        [$teacherMap, $studentMap, $classMap] = $this->loadActorsForConversations($conversations);

        return response()->json([
            'success' => true,
            'conversations' => $conversations->map(
        fn(Conversation $c) => $this->formatConversation($c, false, $teacherMap, $studentMap, $classMap)
        ),
        ]);
    }

    /**
     * فتح / إنشاء محادثة جماعية للفصل
     * POST /api/chat/conversations/open-group
     */
    public function openGroupConversation(Request $request)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
            'class_section_id' => 'required|integer',
            'as' => 'nullable|in:teacher,student',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->first();
        if (!$teacher)
            return response()->json(['success' => false, 'message' => 'Teacher not found.'], 404);

        $conversation = Conversation::firstOrCreate(
        [
            'teacher_id' => $teacher->id,
            'student_id' => null, // Null means Group
            'class_section_id' => $validated['class_section_id'],
        ],
        [
            'last_message' => null,
            'last_message_at' => null,
        ]
        );

        [$teacherMap, $studentMap, $classMap] = $this->loadActorsForConversations(collect([$conversation]));

        return response()->json([
            'success' => true,
            'conversation' => $this->formatConversation($conversation, ($validated['as'] ?? 'teacher') === 'teacher', $teacherMap, $studentMap, $classMap),
        ]);
    }

    /**
     * جلب رسائل محادثة معيّنة
     * GET /api/chat/conversations/{conversation}/messages?as=teacher|student
     *
     * تحسين UX بدون كسر: إذا أرسلت limit يرجّع صفحة + next_cursor
     * - limit (اختياري): عدد الرسائل (مثلاً 30)
     * - before_id (اختياري): لجلب رسائل أقدم من هذا الـ id
     */
    public function messages(Request $request, Conversation $conversation)
    {
        $validated = $request->validate([
            'as' => 'required|in:teacher,student',
            'teacher_code' => 'nullable|string',
            'academic_id' => 'nullable|string',

            'limit' => 'nullable|integer|min:1|max:200',
            'before_id' => 'nullable|integer|min:1',
        ]);

        // تحقق صلاحية الطرف على المحادثة + جلب actor
        $actor = $this->resolveAndAuthorizeActor($validated, $conversation);

        // تعليم الرسائل كمقروءة (حسب الطرف)
        DB::transaction(function () use ($validated, $conversation) {
            if ($validated['as'] === 'teacher') {
                $updated = Message::where('conversation_id', $conversation->id)
                    ->where('sender_type', 'student')
                    ->whereNull('read_at')
                    ->update(['read_at' => now()]);

                if ($updated > 0) {
                    $conversation->update(['unread_for_teacher' => 0]);
                }
            }
            else {
                $updated = Message::where('conversation_id', $conversation->id)
                    ->where('sender_type', 'teacher')
                    ->whereNull('read_at')
                    ->update(['read_at' => now()]);

                if ($updated > 0) {
                    $conversation->update(['unread_for_student' => 0]);
                }
            }
        });

        // الاستعلام الأساسي
        $query = Message::where('conversation_id', $conversation->id)->orderBy('created_at');

        // Pagination اختياري (بدون كسر القديم)
        $limit = $validated['limit'] ?? null;
        $beforeId = $validated['before_id'] ?? null;

        if ($beforeId) {
            $query->where('id', '<', $beforeId);
        }

        if ($limit) {
            // نجيب الأقدم/الأحدث حسب ترتيبك الحالي (created_at ASC).
            // بما أن ASC، "before_id" يعني أقدم، فسنحافظ على ASC ونأخذ limit من النهاية؟
            // لتبسيط وعدم كسر: سنغيّر على id DESC ثم نعكس النتائج.
            $paged = Message::where('conversation_id', $conversation->id)
                ->when($beforeId, fn($q) => $q->where('id', '<', $beforeId))
                ->orderByDesc('id')
                ->limit($limit + 1)
                ->get();

            $hasMore = $paged->count() > $limit;
            if ($hasMore) {
                $paged = $paged->take($limit);
            }

            $messages = $paged->reverse()->values();
            $nextCursor = $hasMore ? $messages->first()->id : null;

            return response()->json([
                'success' => true,
                'messages' => $messages->map(fn(Message $m) => $this->formatMessage($m)),
                'next_cursor' => $nextCursor, // استخدمه كـ before_id لجلب الأقدم
            ]);
        }

        // السلوك القديم: كل الرسائل
        $messages = $query->get();

        // تحميل أسماء المرسلين بكفاءة
        $senderMaps = $this->loadSenderNames($messages);

        return response()->json([
            'success' => true,
            'messages' => $messages->map(fn(Message $m) => $this->formatMessage(
        $m,
        $senderMaps[$m->sender_type][$m->sender_id] ?? 'Unknown'
        )),
        ]);
    }

    /**
     * إرسال رسالة جديدة
     * POST /api/chat/conversations/{conversation}/messages
     */
    public function sendMessage(Request $request, Conversation $conversation)
    {
        $validated = $request->validate([
            'sender_type' => 'required|in:teacher,student',
            'teacher_code' => 'nullable|string',
            'academic_id' => 'nullable|string',
            'body' => 'required|string|min:1|max:5000',
        ]);

        // تحقق صلاحية المرسل على المحادثة + sender_id
        $sender = $this->resolveAndAuthorizeSender($validated, $conversation);
        $senderId = $sender['id'];

        $now = Carbon::now();

        // Transaction لضمان عدم حصول inconsistency
        $result = DB::transaction(function () use ($validated, $conversation, $senderId, $now) {
            $message = Message::create([
                'conversation_id' => $conversation->id,
                'sender_type' => $validated['sender_type'],
                'sender_id' => $senderId,
                'body' => $validated['body'],
                'sent_at' => $now,
            ]);

            // تحديث المحادثة
            $conversation->last_message = $validated['body'];
            $conversation->last_message_at = $now;

            if ($validated['sender_type'] === 'teacher') {
                $conversation->unread_for_student = (int)$conversation->unread_for_student + 1;
            }
            else {
                $conversation->unread_for_teacher = (int)$conversation->unread_for_teacher + 1;
            }

            $conversation->save();
            $conversation->refresh();

            return [$message, $conversation];
        });


        /** @var Conversation $freshConversation */
        /** @var Message $message */
        [$message, $freshConversation] = $result;

        // بثّ الرسالة للطرف الآخر (للوصول الفوري)
        broadcast(new MessageSent($message, $freshConversation))->toOthers();

        // تجهيز خرائط الطرفين للمحادثة
        [$teacherMap, $studentMap, $classMap] = $this->loadActorsForConversations(collect([$freshConversation]));

        return response()->json([
            'success' => true,
            'message' => $this->formatMessage($message, $sender['full_name'] ?? 'Unknown'),
            'conversation' => $this->formatConversation(
            $freshConversation,
            $validated['sender_type'] === 'teacher',
            $teacherMap,
            $studentMap,
            $classMap
        ),
        ]);
    }

    /**
     * تحميل بيانات المعلمين والطلاب لمجموعة محادثات مرة واحدة لتفادي N+1
     * @return array{0: array<int,Teacher>, 1: array<int,Student>, 2: array<int,ClassSection>}
     */
    protected function loadActorsForConversations($conversations): array
    {
        $teacherIds = $conversations->pluck('teacher_id')->filter()->unique()->values();
        $studentIds = $conversations->pluck('student_id')->filter()->unique()->values();
        $classIds = $conversations->pluck('class_section_id')->filter()->unique()->values();

        $teachers = Teacher::whereIn('id', $teacherIds)->get()->keyBy('id');
        $students = Student::whereIn('id', $studentIds)->get()->keyBy('id');
        $classes = \App\Models\ClassSection::whereIn('id', $classIds)->get()->keyBy('id');

        return [$teachers->all(), $students->all(), $classes->all()];
    }

    /**
     * توحيد التحقق من هوية الطرف الذي يطلب الرسائل (as)
     * يعيد الكائن (Teacher/Student) أو يرمي 403
     */
    protected function resolveAndAuthorizeActor(array $validated, Conversation $conversation)
    {
        if (($validated['as'] ?? null) === 'teacher') {
            $teacherCode = $validated['teacher_code'] ?? null;
            $teacher = $teacherCode ?Teacher::where('teacher_code', $teacherCode)->first() : null;

            if (!$teacher || $teacher->id !== $conversation->teacher_id) {
                abort(response()->json([
                    'success' => false,
                    'message' => 'Unauthorized teacher.',
                ], 403));
            }

            return $teacher;
        }

        $academicId = $validated['academic_id'] ?? null;
        $student = $academicId ?Student::where('academic_id', $academicId)->first() : null;

        if ($conversation->student_id === null) {
            // Group Chat: Check if student belongs to the class
            if (!$student || $student->class_section_id != $conversation->class_section_id) {
                abort(response()->json(['success' => false, 'message' => 'Unauthorized student for this group.'], 403));
            }
        }
        else {
            if (!$student || $student->id !== $conversation->student_id) {
                abort(response()->json(['success' => false, 'message' => 'Unauthorized student.'], 403));
            }
        }

        return $student;
    }

    /**
     * توحيد التحقق من هوية المرسل عند الإرسال
     * @return array{id:int,type:string}
     */
    protected function resolveAndAuthorizeSender(array $validated, Conversation $conversation): array
    {
        if ($validated['sender_type'] === 'teacher') {
            $teacherCode = $validated['teacher_code'] ?? null;
            $teacher = $teacherCode ?Teacher::where('teacher_code', $teacherCode)->first() : null;

            if (!$teacher || $teacher->id !== $conversation->teacher_id) {
                abort(response()->json([
                    'success' => false,
                    'message' => 'Unauthorized teacher.',
                ], 403));
            }

            return ['id' => $teacher->id, 'type' => 'teacher', 'full_name' => $teacher->full_name];
        }

        $academicId = $validated['academic_id'] ?? null;
        $student = $academicId ?Student::where('academic_id', $academicId)->first() : null;

        if ($conversation->student_id === null) {
            if (!$student || $student->class_section_id != $conversation->class_section_id) {
                abort(response()->json(['success' => false, 'message' => 'Unauthorized student for this group.'], 403));
            }
        }
        else {
            if (!$student || $student->id !== $conversation->student_id) {
                abort(response()->json(['success' => false, 'message' => 'Unauthorized student.'], 403));
            }
        }

        return ['id' => $student->id, 'type' => 'student', 'full_name' => $student->full_name];
    }

    /**
     * تحميل أسماء المرسلين بكفاءة لمجموعة رسائل
     */
    protected function loadSenderNames($messages)
    {
        $teacherIds = $messages->where('sender_type', 'teacher')->pluck('sender_id')->unique();
        $studentIds = $messages->where('sender_type', 'student')->pluck('sender_id')->unique();

        return [
            'teacher' => Teacher::whereIn('id', $teacherIds)->pluck('full_name', 'id'),
            'student' => Student::whereIn('id', $studentIds)->pluck('full_name', 'id'),
        ];
    }

    /**
     * تنسيق بيانات المحادثة
     */
    protected function formatConversation(
        Conversation $c,
        bool $forTeacher = true,
        array $teacherMap = [],
        array $studentMap = [],
        array $classMap = []
        ): array
    {
        $teacher = $c->teacher_id ? ($teacherMap[$c->teacher_id] ?? null) : null;
        $student = $c->student_id ? ($studentMap[$c->student_id] ?? null) : null;
        $class = $c->class_section_id ? ($classMap[$c->class_section_id] ?? null) : null;

        $isGroup = ($c->student_id === null);

        return [
            'id' => $c->id,
            'is_group' => $isGroup,
            'group_name' => $isGroup && $class ? "فصل {$class->name}" : null,
            'teacher_id' => $c->teacher_id,
            'student_id' => $c->student_id,
            'class_section_id' => $c->class_section_id,
            'subject_id' => $c->subject_id,
            'last_message' => $c->last_message,
            'last_message_at' => optional($c->last_message_at)->toIso8601String(),

            'unread_count' => $forTeacher
            ? (int)$c->unread_for_teacher
            : (int)$c->unread_for_student,

            'teacher' => $teacher ? [
                'id' => $teacher->id,
                'full_name' => $teacher->full_name,
                'teacher_code' => $teacher->teacher_code,
                'image' => $teacher->image ?? null,
            ] : null,

            'student' => $student ? [
                'id' => $student->id,
                'full_name' => $student->full_name,
                'academic_id' => $student->academic_id,
                'image' => $student->image ?? null,
                'grade' => $student->grade,
                'class_section' => $student->class_section,
            ] : null,
        ];
    }

    /**
     * تنسيق بيانات الرسالة
     */
    protected function formatMessage(Message $m, string $senderName = null): array
    {
        return [
            'id' => $m->id,
            'conversation_id' => $m->conversation_id,
            'sender_type' => $m->sender_type,
            'sender_id' => $m->sender_id,
            'sender_name' => $senderName,
            'body' => $m->body,
            'sent_at' => optional($m->sent_at)->toIso8601String(),
            'read_at' => optional($m->read_at)->toIso8601String(),
        ];
    }
}
