<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $fillable = [
        'full_name',
        'academic_id',
        'gender',
        'birthdate',
        'email',
        'password',
        'status',
        'grade',
        'class_section',
        'class_section_id', // 🔹 ربط الطالب بالصف/الشعبة الحقيقي
        'address_governorate',
        'address_city',
        'address_street',
        'guardian_name',
        'guardian_relation',
        'guardian_relation_other',
        'guardian_phone',
        'performance_avg',
        'attendance_rate',
        'photo_path',
        'guardian_phones',
        'notes',
    ];

    protected $casts = [
        'birthdate'       => 'date',
        'guardian_phones' => 'array',
        'performance_avg' => 'decimal:2',
        'attendance_rate' => 'decimal:2',
    ];

    protected $hidden = [
        'password',
    ];



    public function getImageAttribute()
{
    if (!$this->photo_path) {
        return null;
    }

    // تأكد إنك مشغّل `php artisan storage:link`
    return asset('storage/' . $this->photo_path);
}

    /**
     * ربط الطالب بالصف/الشعبة الحقيقي (ClassSection)
     */
    public function classSection()
    {
        return $this->belongsTo(\App\Models\ClassSection::class);
    }

    /**
     * إرجاع قائمة المواد + الأستاذ لكل مادة
     * الآن مبنية على:
     * - class_section_id للطالب
     * - جدول teacher_class_subjects
     * - جدول subjects
     * - وجدول class_section_subjects (في حال مواد مفعّلة بدون أستاذ بعد)
     */
    public function getSubjectsAttribute()
    {
        if (!$this->class_section_id) {
            return [];
        }

        $classSection = $this->classSection()
            ->with([
                'assignments.subject',
                'assignments.teacher',
                'subjects', // المواد المفعّلة عبر class_section_subjects (بدون أستاذ)
            ])
            ->first();

        if (!$classSection) {
            return [];
        }

        $subjects = [];

        // 1) المواد التي لها أستاذ مسند عبر TeacherClassSubject
        foreach ($classSection->assignments as $assignment) {
            if (!$assignment->is_active) {
                continue;
            }

            $subject = $assignment->subject;
            if (!$subject) {
                continue;
            }

            $subjects[] = [
                'subject_id'       => $subject->id,
                'subject_code'     => $subject->code,
                'subject_name_en'  => $subject->name_en,
                'subject_name_ar'  => $subject->name_ar,
                'teacher_id'       => $assignment->teacher_id,
                'teacher_name'     => optional($assignment->teacher)->full_name,
            ];
        }

        // 2) لو ما في أستاذ، نرجع المواد المفعّلة للصف/الشعبة فقط
        if (empty($subjects)) {
            foreach ($classSection->subjects as $subject) {
                $subjects[] = [
                    'subject_id'       => $subject->id,
                    'subject_code'     => $subject->code,
                    'subject_name_en'  => $subject->name_en,
                    'subject_name_ar'  => $subject->name_ar,
                    'teacher_id'       => null,
                    'teacher_name'     => null,
                ];
            }
        }

        return $subjects;
    }
}
