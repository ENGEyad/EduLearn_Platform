<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Events\MessageStatusUpdated;
use App\Events\TypingStatusChanged;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Student;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    /**
     * فتح / إنشاء محادثة فردية بين أستاذ وطالب
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

        $forTeacher = ($validated['as'] ?? 'teacher') === 'teacher';

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

        [$teacherMap, $studentMap] = $this->loadActorsForConversations(collect([$conversation]));

        return response()->json([
            'success' => true,
            'conversation' => $this->formatConversation(
                $conversation,
                $forTeacher,
                $teacherMap,
                $studentMap
            ),
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

        [$teacherMap, $studentMap] = $this->loadActorsForConversations($conversations);

        return response()->json([
            'success' => true,
            'conversations' => $conversations->map(
                fn(Conversation $conversation) => $this->formatConversation(
                    $conversation,
                    true,
                    $teacherMap,
                    $studentMap
                )
            )->values(),
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
            ->orderByDesc('last_message_at')
            ->orderByDesc('updated_at')
            ->get();

        [$teacherMap, $studentMap] = $this->loadActorsForConversations($conversations);

        return response()->json([
            'success' => true,
            'conversations' => $conversations->map(
                fn(Conversation $conversation) => $this->formatConversation(
                    $conversation,
                    false,
                    $teacherMap,
                    $studentMap
                )
            )->values(),
        ]);
    }

    /**
     * جلب رسائل محادثة معيّنة
     * GET /api/chat/conversations/{conversation}/messages?as=teacher|student
     *
     * يدعم pagination اختياري:
     * - limit
     * - before_id
     *
     * مهم: هنا نعتبر الرسائل "وصلت" للطرف عند فتح المحادثة / تحميلها،
     * لكن لا نعتبرها "مقروءة" إلا عبر endpoint القراءة الصريح.
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

        $this->resolveAndAuthorizeActor($validated, $conversation);
        $this->markIncomingMessagesDelivered($conversation, $validated['as']);

        $limit = $validated['limit'] ?? null;
        $beforeId = $validated['before_id'] ?? null;

        if ($limit) {
            $paged = Message::where('conversation_id', $conversation->id)
                ->when($beforeId, fn($query) => $query->where('id', '<', $beforeId))
                ->orderByDesc('id')
                ->limit($limit + 1)
                ->get();

            $hasMore = $paged->count() > $limit;
            if ($hasMore) {
                $paged = $paged->take($limit);
            }

            $messages = $paged->reverse()->values();
            $nextCursor = $hasMore && $messages->isNotEmpty()
                ? $messages->first()->id
                : null;

            $senderMaps = $this->loadSenderNames($messages);

            return response()->json([
                'success' => true,
                'messages' => $messages->map(
                    fn(Message $message) => $this->formatMessage(
                        $message,
                        $senderMaps[$message->sender_type][$message->sender_id] ?? 'Unknown'
                    )
                )->values(),
                'next_cursor' => $nextCursor,
            ]);
        }

        $messages = Message::where('conversation_id', $conversation->id)
            ->orderBy('created_at')
            ->get();

        $senderMaps = $this->loadSenderNames($messages);

        return response()->json([
            'success' => true,
            'messages' => $messages->map(
                fn(Message $message) => $this->formatMessage(
                    $message,
                    $senderMaps[$message->sender_type][$message->sender_id] ?? 'Unknown'
                )
            )->values(),
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

        $sender = $this->resolveAndAuthorizeSender($validated, $conversation);
        $senderId = $sender['id'];

        $now = Carbon::now();

        [$message, $freshConversation] = DB::transaction(function () use (
            $validated,
            $conversation,
            $senderId,
            $now
        ) {
            $message = Message::create([
                'conversation_id' => $conversation->id,
                'sender_type' => $validated['sender_type'],
                'sender_id' => $senderId,
                'body' => trim($validated['body']),
                'sent_at' => $now,
            ]);

            $conversation->last_message = trim($validated['body']);
            $conversation->last_message_at = $now;

            if ($validated['sender_type'] === 'teacher') {
                $conversation->unread_for_student = (int) $conversation->unread_for_student + 1;
            } else {
                $conversation->unread_for_teacher = (int) $conversation->unread_for_teacher + 1;
            }

            $conversation->save();
            $conversation->refresh();

            return [$message->fresh(), $conversation];
        });

        broadcast(new MessageSent($message, $freshConversation))->toOthers();

        [$teacherMap, $studentMap] = $this->loadActorsForConversations(collect([$freshConversation]));

        return response()->json([
            'success' => true,
            'message' => $this->formatMessage(
                $message,
                $sender['full_name'] ?? 'Unknown'
            ),
            'conversation' => $this->formatConversation(
                $freshConversation,
                $validated['sender_type'] === 'teacher',
                $teacherMap,
                $studentMap,
                $message
            ),
        ]);
    }

    /**
     * تحديد الرسائل الواردة على أنها وصلت للطرف الحالي (double gray)
     * POST /api/chat/conversations/{conversation}/delivered
     */
    public function markDelivered(Request $request, Conversation $conversation)
    {
        $validated = $request->validate([
            'as' => 'required|in:teacher,student',
            'teacher_code' => 'nullable|string',
            'academic_id' => 'nullable|string',
        ]);

        $this->resolveAndAuthorizeActor($validated, $conversation);
        $updatedMessages = $this->markIncomingMessagesDelivered($conversation, $validated['as']);

        $freshConversation = $conversation->fresh();
        [$teacherMap, $studentMap] = $this->loadActorsForConversations(collect([$freshConversation]));
        $latestMessage = $this->findLatestMessageForConversation($freshConversation);

        return response()->json([
            'success' => true,
            'updated_count' => $updatedMessages->count(),
            'messages' => $updatedMessages->map(fn(Message $message) => $this->formatMessage($message))->values(),
            'conversation' => $this->formatConversation(
                $freshConversation,
                $validated['as'] === 'teacher',
                $teacherMap,
                $studentMap,
                $latestMessage
            ),
        ]);
    }

    /**
     * تحديد الرسائل الواردة على أنها مقروءة (double blue)
     * POST /api/chat/conversations/{conversation}/read
     */
    public function markRead(Request $request, Conversation $conversation)
    {
        $validated = $request->validate([
            'as' => 'required|in:teacher,student',
            'teacher_code' => 'nullable|string',
            'academic_id' => 'nullable|string',
        ]);

        $this->resolveAndAuthorizeActor($validated, $conversation);

        $incomingSenderType = $validated['as'] === 'teacher' ? 'student' : 'teacher';
        $now = now();

        $updatedMessages = DB::transaction(function () use ($conversation, $validated, $incomingSenderType, $now) {
            $messages = Message::where('conversation_id', $conversation->id)
                ->where('sender_type', $incomingSenderType)
                ->whereNull('read_at')
                ->orderBy('id')
                ->get();

            if ($messages->isEmpty()) {
                if ($validated['as'] === 'teacher' && (int) $conversation->unread_for_teacher !== 0) {
                    $conversation->update(['unread_for_teacher' => 0]);
                }

                if ($validated['as'] === 'student' && (int) $conversation->unread_for_student !== 0) {
                    $conversation->update(['unread_for_student' => 0]);
                }

                return collect();
            }

            $ids = $messages->pluck('id')->values();

            Message::whereIn('id', $ids)->update([
                'delivered_at' => DB::raw('COALESCE(delivered_at, CURRENT_TIMESTAMP)'),
                'read_at' => $now,
            ]);

            if ($validated['as'] === 'teacher') {
                $conversation->update(['unread_for_teacher' => 0]);
            } else {
                $conversation->update(['unread_for_student' => 0]);
            }

            return Message::whereIn('id', $ids)->orderBy('id')->get();
        });

        $freshConversation = $conversation->fresh();
        [$teacherMap, $studentMap] = $this->loadActorsForConversations(collect([$freshConversation]));
        $latestMessage = $this->findLatestMessageForConversation($freshConversation);
        $conversationPayload = $this->formatConversation(
            $freshConversation,
            $validated['as'] === 'teacher',
            $teacherMap,
            $studentMap,
            $latestMessage
        );

        if ($updatedMessages->isNotEmpty()) {
            broadcast(new MessageStatusUpdated(
                $freshConversation,
                $updatedMessages,
                'read',
                $conversationPayload
            ))->toOthers();
        }

        return response()->json([
            'success' => true,
            'updated_count' => $updatedMessages->count(),
            'messages' => $updatedMessages->map(fn(Message $message) => $this->formatMessage($message))->values(),
            'conversation' => $conversationPayload,
        ]);
    }

    /**
     * بدأ الكتابة
     * POST /api/chat/conversations/{conversation}/typing/start
     */
    public function typingStart(Request $request, Conversation $conversation)
    {
        $validated = $request->validate([
            'as' => 'required|in:teacher,student',
            'teacher_code' => 'nullable|string',
            'academic_id' => 'nullable|string',
        ]);

        $actor = $this->resolveAndAuthorizeActor($validated, $conversation);

        broadcast(new TypingStatusChanged(
            $conversation,
            $validated['as'],
            'start',
            $actor->full_name ?? null
        ))->toOthers();

        return response()->json([
            'success' => true,
            'typing' => true,
        ]);
    }

    /**
     * توقف الكتابة
     * POST /api/chat/conversations/{conversation}/typing/stop
     */
    public function typingStop(Request $request, Conversation $conversation)
    {
        $validated = $request->validate([
            'as' => 'required|in:teacher,student',
            'teacher_code' => 'nullable|string',
            'academic_id' => 'nullable|string',
        ]);

        $actor = $this->resolveAndAuthorizeActor($validated, $conversation);

        broadcast(new TypingStatusChanged(
            $conversation,
            $validated['as'],
            'stop',
            $actor->full_name ?? null
        ))->toOthers();

        return response()->json([
            'success' => true,
            'typing' => false,
        ]);
    }

    /**
     * تحميل بيانات المعلمين والطلاب لمجموعة محادثات مرة واحدة
     *
     * @return array{0: array<int, Teacher>, 1: array<int, Student>}
     */
    protected function loadActorsForConversations(Collection $conversations): array
    {
        $teacherIds = $conversations->pluck('teacher_id')->filter()->unique()->values();
        $studentIds = $conversations->pluck('student_id')->filter()->unique()->values();

        $teachers = Teacher::whereIn('id', $teacherIds)->get()->keyBy('id');
        $students = Student::whereIn('id', $studentIds)->get()->keyBy('id');

        return [$teachers->all(), $students->all()];
    }

    /**
     * التحقق من صلاحية الطرف الذي يطلب الرسائل
     */
    protected function resolveAndAuthorizeActor(array $validated, Conversation $conversation): Teacher|Student
    {
        if (($validated['as'] ?? null) === 'teacher') {
            $teacherCode = $validated['teacher_code'] ?? null;
            $teacher = $teacherCode
                ? Teacher::where('teacher_code', $teacherCode)->first()
                : null;

            if (!$teacher || $teacher->id !== $conversation->teacher_id) {
                abort(response()->json([
                    'success' => false,
                    'message' => 'Unauthorized teacher.',
                ], 403));
            }

            return $teacher;
        }

        $academicId = $validated['academic_id'] ?? null;
        $student = $academicId
            ? Student::where('academic_id', $academicId)->first()
            : null;

        if (!$student || $student->id !== $conversation->student_id) {
            abort(response()->json([
                'success' => false,
                'message' => 'Unauthorized student.',
            ], 403));
        }

        return $student;
    }

    /**
     * التحقق من صلاحية المرسل عند الإرسال
     *
     * @return array{id:int,type:string,full_name:string|null}
     */
    protected function resolveAndAuthorizeSender(array $validated, Conversation $conversation): array
    {
        if ($validated['sender_type'] === 'teacher') {
            $teacherCode = $validated['teacher_code'] ?? null;
            $teacher = $teacherCode
                ? Teacher::where('teacher_code', $teacherCode)->first()
                : null;

            if (!$teacher || $teacher->id !== $conversation->teacher_id) {
                abort(response()->json([
                    'success' => false,
                    'message' => 'Unauthorized teacher.',
                ], 403));
            }

            return [
                'id' => $teacher->id,
                'type' => 'teacher',
                'full_name' => $teacher->full_name,
            ];
        }

        $academicId = $validated['academic_id'] ?? null;
        $student = $academicId
            ? Student::where('academic_id', $academicId)->first()
            : null;

        if (!$student || $student->id !== $conversation->student_id) {
            abort(response()->json([
                'success' => false,
                'message' => 'Unauthorized student.',
            ], 403));
        }

        return [
            'id' => $student->id,
            'type' => 'student',
            'full_name' => $student->full_name,
        ];
    }

    /**
     * تحميل أسماء المرسلين بكفاءة لمجموعة رسائل
     *
     * @return array{
     *   teacher: \Illuminate\Support\Collection,
     *   student: \Illuminate\Support\Collection
     * }
     */
    protected function loadSenderNames(Collection $messages): array
    {
        $teacherIds = $messages->where('sender_type', 'teacher')->pluck('sender_id')->unique();
        $studentIds = $messages->where('sender_type', 'student')->pluck('sender_id')->unique();

        return [
            'teacher' => Teacher::whereIn('id', $teacherIds)->pluck('full_name', 'id'),
            'student' => Student::whereIn('id', $studentIds)->pluck('full_name', 'id'),
        ];
    }

    /**
     * تحديد الرسائل الواردة بأنها وصلت للطرف الحالي.
     */
    protected function markIncomingMessagesDelivered(Conversation $conversation, string $as): Collection
    {
        $incomingSenderType = $as === 'teacher' ? 'student' : 'teacher';
        $now = now();

        $messages = Message::where('conversation_id', $conversation->id)
            ->where('sender_type', $incomingSenderType)
            ->whereNull('delivered_at')
            ->orderBy('id')
            ->get();

        if ($messages->isEmpty()) {
            return collect();
        }

        $ids = $messages->pluck('id')->values();
        Message::whereIn('id', $ids)->update(['delivered_at' => $now]);

        $updatedMessages = Message::whereIn('id', $ids)->orderBy('id')->get();

        $freshConversation = $conversation->fresh();
        [$teacherMap, $studentMap] = $this->loadActorsForConversations(collect([$freshConversation]));
        $latestMessage = $this->findLatestMessageForConversation($freshConversation);

        $teacherConversationPayload = $this->formatConversation(
            $freshConversation,
            true,
            $teacherMap,
            $studentMap,
            $latestMessage
        );

        $studentConversationPayload = $this->formatConversation(
            $freshConversation,
            false,
            $teacherMap,
            $studentMap,
            $latestMessage
        );

        $conversationPayload = $as === 'teacher'
            ? $teacherConversationPayload
            : $studentConversationPayload;

        broadcast(new MessageStatusUpdated(
            $freshConversation,
            $updatedMessages,
            'delivered',
            $conversationPayload
        ))->toOthers();

        return $updatedMessages;
    }

    /**
     * تنسيق بيانات المحادثة
     */
    protected function formatConversation(
        Conversation $conversation,
        bool $forTeacher = true,
        array $teacherMap = [],
        array $studentMap = [],
        ?Message $lastMessage = null
    ): array {
        $teacher = $conversation->teacher_id
            ? ($teacherMap[$conversation->teacher_id] ?? null)
            : null;

        $student = $conversation->student_id
            ? ($studentMap[$conversation->student_id] ?? null)
            : null;

        $lastMessageModel = $lastMessage ?? $this->findLatestMessageForConversation($conversation);
        $lastMessageSenderType = $lastMessageModel?->sender_type;
        $lastMessageStatus = $lastMessageModel
            ? $this->resolveMessageStatus($lastMessageModel)
            : null;

        return [
            'id' => $conversation->id,
            'teacher_id' => $conversation->teacher_id,
            'student_id' => $conversation->student_id,
            'class_section_id' => $conversation->class_section_id,
            'subject_id' => $conversation->subject_id,
            'last_message' => $conversation->last_message,
            'last_message_at' => optional($conversation->last_message_at)->toIso8601String(),
            'last_message_sender_type' => $lastMessageSenderType,
            'last_message_status' => $lastMessageStatus,
            'unread_count' => $forTeacher
                ? (int) $conversation->unread_for_teacher
                : (int) $conversation->unread_for_student,
            'unread_for_teacher' => (int) $conversation->unread_for_teacher,
            'unread_for_student' => (int) $conversation->unread_for_student,
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


    protected function findLatestMessageForConversation(Conversation $conversation): ?Message
    {
        return Message::where('conversation_id', $conversation->id)
            ->latest('id')
            ->first();
    }

    protected function resolveMessageStatus(Message $message): string
    {
        if ($message->read_at) {
            return 'read';
        }

        if ($message->delivered_at) {
            return 'delivered';
        }

        if ($message->sent_at) {
            return 'sent';
        }

        return 'sending';
    }

    /**
     * تنسيق بيانات الرسالة
     */
    protected function formatMessage(Message $message, ?string $senderName = null): array
    {
        $status = $this->resolveMessageStatus($message);

        return [
            'id' => $message->id,
            'conversation_id' => $message->conversation_id,
            'sender_type' => $message->sender_type,
            'sender_id' => $message->sender_id,
            'sender_name' => $senderName,
            'body' => $message->body,
            'sent_at' => optional($message->sent_at)->toIso8601String(),
            'delivered_at' => optional($message->delivered_at)->toIso8601String(),
            'read_at' => optional($message->read_at)->toIso8601String(),
            'status' => $status,
        ];
    }
}
