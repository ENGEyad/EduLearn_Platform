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
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

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
