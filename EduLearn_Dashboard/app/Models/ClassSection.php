<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClassSection extends Model
{
    use HasFactory;

    protected $fillable = [
        'grade',
        'section',
        'name',
        'stage',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function assignments()
    {
        return $this->hasMany(\App\Models\TeacherClassSubject::class);
    }

    /**
     * الطلاب المرتبطين بهذا الصف/الشعبة
     */
    public function students()
    {
        return $this->hasMany(\App\Models\Student::class);
    }

    /**
     * الربط الوسيط: صف/شعبة ← مواد
     */
    public function classSubjects()
    {
        return $this->hasMany(\App\Models\ClassSectionSubject::class);
    }

    /**
     * المواد المفعّلة لهذا الصف/الشعبة عبر الجدول الوسيط
     */
    public function subjects()
    {
        return $this->belongsToMany(\App\Models\Subject::class, 'class_section_subjects')
            ->withPivot('is_active')
            ->wherePivot('is_active', true);
    }
}
