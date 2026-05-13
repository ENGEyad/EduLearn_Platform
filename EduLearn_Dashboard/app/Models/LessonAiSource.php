<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonAiSource extends Model
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
        'teacher_id',
        'source_type',
        'source_file_path',
        'source_file_name',
        'source_text',
        'extracted_text',
        'content_hash',
        'is_active',
    ];

    /**
     * ============================================================
     * ✅ التحويلات (Casting)
     * ============================================================
     */
    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * ============================================================
     * ✅ العلاقات
     * ============================================================
     */
    public function lesson()
    {
        return $this->belongsTo(Lesson::class, 'lesson_id');
    }

    public function teacher()
    {
        return $this->belongsTo(\App\Models\Teacher::class, 'teacher_id');
    }

    public function runs()
    {
        return $this->hasMany(LessonAiRun::class, 'ai_source_id')->orderByDesc('id');
    }

    public function blocks()
    {
        return $this->hasMany(LessonBlock::class, 'ai_source_id')->orderBy('position');
    }

    /**
     * ============================================================
     * ✅ Scopes
     * ============================================================
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
