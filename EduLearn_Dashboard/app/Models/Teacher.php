<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Teacher extends Model
{
    use HasFactory;

    protected $fillable = [
        'full_name',
        'teacher_code',
        'email',
        'phone',

        'password', // كلمة السر (لتطبيق الأستاذ لاحقاً)

        'birth_governorate',
        'birthdate',
        'age',

        'qualification',
        'qualification_date',
        'current_school',
        'join_date',
        'current_role',
        'weekly_load',
        'salary',

        'shift',
        'national_id',

        'marital_status',
        'children',
        'district',
        'neighborhood',
        'street',

        'stage',
        'subjects',
        'grades',

        'experience_years',
        'experience_place',

        'status',
        'students_count',
        'avg_student_score',
        'attendance_rate',

        // مسار صورة الأستاذ
        'photo_path',
    ];

    protected $casts = [
        'subjects'           => 'array',
        'grades'             => 'array',
        'birthdate'          => 'date',
        'qualification_date' => 'date',
        'join_date'          => 'date',
        'avg_student_score'  => 'decimal:2',
        'attendance_rate'    => 'decimal:2',
    ];

    protected $hidden = [
        'password',
    ];

    protected $appends = [
        'assigned_subjects',
        'assigned_class_sections',
        'total_assigned_students',
    ];

    // assignments: الربط بين الأستاذ والصف/الشعبة والمادة
    public function assignments()
    {
        return $this->hasMany(\App\Models\TeacherClassSubject::class);
    }

    // المواد التي يدرّسها عبر جدول الربط
    public function teachingSubjects()
    {
        return $this->belongsToMany(
            \App\Models\Subject::class,
            'teacher_class_subjects',
            'teacher_id',
            'subject_id'
        )->withPivot('class_section_id');
    }


    public function getImageAttribute()
{
    if (!$this->photo_path) {
        return null;
    }

    return asset('storage/' . $this->photo_path);
}

    /** أسماء المواد من جدول الربط */
    public function getAssignedSubjectsAttribute()
    {
        $this->loadMissing('assignments.subject');

        return $this->assignments
            ->map(fn($as) => optional($as->subject)->name)
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    /** الصفوف/الشُعب التي يدرّسها */
    public function getAssignedClassSectionsAttribute()
    {
        $this->loadMissing('assignments.classSection');

        return $this->assignments
            ->map(function ($as) {
                $cs = $as->classSection;
                if (!$cs) return null;

                $grade   = $cs->grade_name ?? $cs->grade ?? null;
                $section = $cs->section_name ?? $cs->section ?? null;

                if ($grade && $section) return "{$grade} - {$section}";
                return $cs->name ?? null;
            })
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    /** إجمالي الطلاب في الصفوف المسندة للأستاذ */
    public function getTotalAssignedStudentsAttribute()
    {
        $this->loadMissing('assignments.classSection');

        return $this->assignments->reduce(function ($carry, $as) {
            $cs = $as->classSection;
            if (!$cs) return $carry;

            if (isset($cs->students_count)) {
                return $carry + (int) $cs->students_count;
            }

            if (method_exists($cs, 'students')) {
                return $carry + $cs->students->count();
            }

            return $carry;
        }, 0);
    }
}
