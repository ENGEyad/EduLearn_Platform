<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClassSection extends Model
{
    protected $fillable = [
        'school_id',
        'grade',
        'section',
        'name',
        'name_en',
        'name_ar',
        'stage',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected $appends = ['section_label', 'display_name'];

    public function school()
    {
        return $this->belongsTo(\App\Models\School::class);
    }

    public function assignments()
    {
        return $this->hasMany(\App\Models\TeacherClassSubject::class);
    }

    /**
     * الطلاب المرتبطين لهذا الصف/الشعبة
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

    public function getSectionLabelAttribute()
    {
        if (app()->getLocale() == 'en') {
            $map = ['أ' => 'A', 'ب' => 'B', 'ج' => 'C', 'د' => 'D', 'هـ' => 'E', 'و' => 'F', 'ز' => 'G', 'ح' => 'H'];
            return $map[$this->section] ?? $this->section;
        }
        return $this->section;
    }

    public function getDisplayNameAttribute()
    {
        return (app()->getLocale() == 'en') ? ($this->name_en ?? $this->name) : ($this->name_ar ?? $this->name);
    }
}
