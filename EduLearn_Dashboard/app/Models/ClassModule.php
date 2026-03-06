<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClassModule extends Model
{
    /**
     * ============================================================
     * ✅ هذا هو "الموديول الحقيقي" (Container)
     * ============================================================
     *
     * يحتوي Lessons متعددة، وكل Lesson يحتوي Blocks.
     */
    protected $connection = 'app_mysql';

    protected $fillable = [
        'teacher_id',
        'assignment_id',
        'class_section_id',
        'subject_id',
        'title',
        'position',
    ];

    /**
     * ============================================================
     * ✅ الدروس داخل هذا الـ ClassModule
     * ============================================================
     */
    public function lessons()
    {
        return $this->hasMany(Lesson::class, 'class_module_id');
    }

    /**
     * ============================================================
     * ✅ علاقات مرجعية اختيارية
     * ============================================================
     */
    public function teacher()
    {
        return $this->belongsTo(Teacher::class, 'teacher_id');
    }

    public function assignment()
    {
        return $this->belongsTo(TeacherClassSubject::class, 'assignment_id');
    }

    /**
     * ============================================================
     * ✅ Scope مفيد للفرز
     * ============================================================
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('position');
    }
}
