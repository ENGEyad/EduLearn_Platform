<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    /**
     * 👈 مهم: هذه نفس القاعدة اللي استخدمتها لباقي جداول التطبيق (students / teachers / messages)
     */
    protected $connection = 'app_mysql';

    /**
     * اسم الجدول (اختياري لو الاسم conversations فعلاً)
     */
    protected $table = 'conversations';

    protected $fillable = [
        'teacher_id',
        'student_id',
        'class_section_id',
        'subject_id',
        'last_message',
        'last_message_at',
        'unread_for_teacher',
        'unread_for_student',
    ];

    protected $casts = [
        'last_message_at'    => 'datetime',
        'unread_for_teacher' => 'integer',
        'unread_for_student' => 'integer',
    ];

    /**
     * علاقة مع الأستاذ
     */
    public function teacher(): BelongsTo
    {
        // نوضح مفتاح الربط بشكل صريح (مع أنه افتراضياً نفس الشي)
        return $this->belongsTo(Teacher::class, 'teacher_id');
    }

    /**
     * علاقة مع الطالب
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class, 'student_id');
    }

    /**
     * علاقة مع الرسائل التابعة للمحادثة
     */
    public function messages(): HasMany
    {
        return $this->hasMany(Message::class, 'conversation_id');
    }
}
