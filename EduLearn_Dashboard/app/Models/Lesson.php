<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Lesson extends Model
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
        'teacher_id',
        'assignment_id',
        'class_module_id',     // ✅ الحاوية الحقيقية (Container)
        'class_section_id',
        'subject_id',
        'title',
        'status',              // draft | published
        'published_at',
        'meta',
    ];

    /**
     * ============================================================
     * ✅ التحويلات (Casting)
     * ============================================================
     */
    protected $casts = [
        'published_at' => 'datetime',
        'meta'         => 'array',
    ];

    /**
     * ============================================================
     * ✅ العلاقة الأساسية: الدرس ينتمي إلى ClassModule (الحاوية)
     * ============================================================
     */
    public function classModule()
    {
        return $this->belongsTo(ClassModule::class, 'class_module_id');
    }

    /**
     * ============================================================
     * ✅ العلاقة الأساسية: الدرس يحتوي Blocks مرتبة بـ position
     * ============================================================
     *
     * ملاحظة: هذا هو الأساس في المرحلة الأولى.
     */
    public function blocks()
    {
        return $this->hasMany(LessonBlock::class)->orderBy('position');
    }

    public function exercise()
    {
        return $this->hasOne(LessonExercise::class, 'lesson_id');
    }

    /**
     * ============================================================
     * ⚠️ علاقات مستقبلية (ليست جزءًا من المرحلة الأولى)
     * ============================================================
     *
     * LessonModule / LessonTopic تسبب لبس لأن كلمة "Module" مستخدمة
     * أيضًا بمعنى ClassModule (الحاوية).
     *
     * نُبقي العلاقات موجودة حتى لا نكسر أي كود قديم،
     * لكن لا نعتمد عليها في الحفظ/العرض الآن.
     */
    public function modules()
    {
        return $this->hasMany(LessonModule::class)->orderBy('position');
    }

    public function topics()
    {
        return $this->hasMany(LessonTopic::class)->orderBy('position');
    }

    /**
     * ============================================================
     * ✅ علاقات مرجعية (اختيارية للاستخدام الداخلي)
     * ============================================================
     */
    public function teacher()
    {
        return $this->belongsTo(\App\Models\Teacher::class, 'teacher_id');
    }

    public function classSection()
    {
        return $this->belongsTo(\App\Models\ClassSection::class, 'class_section_id');
    }

    public function subject()
    {
        return $this->belongsTo(\App\Models\Subject::class, 'subject_id');
    }

    /**
     * ============================================================
     * ✅ Scopes مفيدة لتثبيت المنطق
     * ============================================================
     */
    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }

    public function scopeForStudentTarget($query, int $classSectionId, int $subjectId)
    {
        return $query
            ->where('class_section_id', $classSectionId)
            ->where('subject_id', $subjectId);
    }
}
