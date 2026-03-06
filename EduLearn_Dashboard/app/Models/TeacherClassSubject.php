<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TeacherClassSubject extends Model
{
    use HasFactory;

    protected $fillable = [
        'teacher_id',
        'class_section_id',
        'subject_id',
        'weekly_load',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function teacher()
    {
        return $this->belongsTo(\App\Models\Teacher::class);
    }

    public function classSection()
    {
        return $this->belongsTo(\App\Models\ClassSection::class);
    }

    public function subject()
    {
        return $this->belongsTo(\App\Models\Subject::class);
    }
}
