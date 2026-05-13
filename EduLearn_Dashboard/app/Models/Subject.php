<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subject extends Model
{
    use HasFactory;

    protected $fillable = [
        'name_en',
        'name_ar',
        'code',
        'icon',
        'color',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected $appends = ['display_name'];

    public function getDisplayNameAttribute()
    {
        return (app()->getLocale() == 'en') ? ($this->name_en ?? $this->name_ar) : ($this->name_ar ?? $this->name_en);
    }

    public function teacherAssignments()
    {
        return $this->hasMany(\App\Models\TeacherClassSubject::class);
    }

    /**
     * الربط الوسيط مع الصفوف/الشعب
     */
    public function classSubjects()
    {
        return $this->hasMany(\App\Models\ClassSectionSubject::class);
    }

    /**
     * الصفوف/الشعب التي تنتمي لها هذه المادة (تفعيل المواد لكل صف)
     */
    public function classSections()
    {
        return $this->belongsToMany(\App\Models\ClassSection::class, 'class_section_subjects')
            ->withPivot('is_active');
    }
}
