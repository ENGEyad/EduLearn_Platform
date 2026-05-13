<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonAiRun extends Model
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
        'ai_source_id',
        'action_type',
        'target_stable_key',
        'instruction_key',
        'instruction_text',
        'status',
        'input_snapshot',
        'output_snapshot',
        'error_message',
    ];

    /**
     * ============================================================
     * ✅ التحويلات (Casting)
     * ============================================================
     */
    protected $casts = [
        'input_snapshot' => 'array',
        'output_snapshot' => 'array',
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

    public function source()
    {
        return $this->belongsTo(LessonAiSource::class, 'ai_source_id');
    }

    public function affectedBlocks()
    {
        return $this->hasMany(LessonBlock::class, 'ai_last_run_id')->orderBy('position');
    }

    /**
     * ============================================================
     * ✅ Scopes
     * ============================================================
     */
    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeFailed($query)
    {
        return $query->where('status', 'failed');
    }
}
