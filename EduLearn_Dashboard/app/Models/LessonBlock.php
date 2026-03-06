<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonBlock extends Model
{
    /**
     * ============================================================
     * ✅ قاعدة بيانات التطبيق (app_mysql)
     * ============================================================
     */
    protected $connection = 'app_mysql';

    /**
     * ============================================================
     * ✅ الحقول القابلة للتعبئة
     * ============================================================
     */
    protected $fillable = [
        'lesson_id',

        // ⚠️ (مرحلة مستقبلية) تقسيم داخلي للدرس
        'module_id',
        'topic_id',

        'type',          // text | image | video | audio
        'body',
        'caption',

        // ✅ مصدر الحقيقة للتخزين
        'media_path',

        // ⚠️ لا نعتمد عليه في المرحلة الأولى
        'media_url',

        'media_mime',
        'media_size',
        'media_duration',

        // ✅ الحاكم لترتيب العرض
        'position',

        'meta',
    ];

    /**
     * ============================================================
     * ✅ التحويلات (Casting)
     * ============================================================
     */
    protected $casts = [
        'meta' => 'array',
    ];

    /**
     * ============================================================
     * ✅ علاقة البلوك بالدرس
     * ============================================================
     */
    public function lesson()
    {
        return $this->belongsTo(Lesson::class);
    }

    /**
     * ============================================================
     * ⚠️ علاقات مستقبلية (لا تُستخدم في المرحلة الأولى)
     * ============================================================
     */
    public function module()
    {
        return $this->belongsTo(LessonModule::class, 'module_id');
    }

    public function topic()
    {
        return $this->belongsTo(LessonTopic::class, 'topic_id');
    }

    /**
     * ============================================================
     * ✅ Scope ترتيب ثابت
     * ============================================================
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('position');
    }
}
