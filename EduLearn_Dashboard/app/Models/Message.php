<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    /**
     * مهم: هذا الجدول موجود على قاعدة بيانات التطبيق (app_mysql)
     */
    protected $connection = 'app_mysql';

    /**
     * لو جدولك اسمه "messages" اتركها كما هي.
     * (لا داعي لتعريف $table)
     */

    protected $fillable = [
        'conversation_id',
        'sender_type',   // teacher | student
        'sender_id',     // teacher_id أو student_id
        'body',
        'sent_at',       // نستخدمها كوقت الإرسال الرسمي
        'read_at',       // وقت القراءة
    ];

    protected $casts = [
        'sent_at' => 'datetime',
        'read_at' => 'datetime',
    ];

    /**
     * العلاقات
     */
    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    /**
     * ملاحظة مهمة:
     * بما أن Student/Teacher غالباً على قاعدة بيانات أخرى (الداشبورد الافتراضية)،
     * نحن لا نعتمد على هذه العلاقات داخل الـ API (نقوم بعمل format في ChatController).
     * لذلك نتركها اختيارية فقط.
     */

    public function senderStudent(): BelongsTo
    {
        // هذه العلاقة ستعمل فقط إذا كان موديل Student على نفس الاتصال أو كان مضبوط بشكل صحيح.
        return $this->belongsTo(Student::class, 'sender_id');
    }

    public function senderTeacher(): BelongsTo
    {
        // هذه العلاقة ستعمل فقط إذا كان موديل Teacher على نفس الاتصال أو كان مضبوط بشكل صحيح.
        return $this->belongsTo(Teacher::class, 'sender_id');
    }
}
