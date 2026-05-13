<?php

namespace App\Services;

use App\Models\School;
use App\Models\Subject;
use App\Models\ClassSection;
use App\Models\Teacher;
use App\Models\Student;
use App\Models\SchoolSubject;
use App\Models\TeacherClassSubject;
use App\Models\DashboardNotification;
use Illuminate\Support\Facades\DB;

class SchoolInitializationService
{
    /**
     * Initializes a school with default classes, subjects, teachers, and students.
     */
    public function initialize(School $school)
    {
        if ($school->is_initialized) {
            return;
        }

        DB::beginTransaction();
        try {
            // 1. Enable Core Subjects
            $this->setupSubjects($school);

            // 2. Create Grades 1-12
            $classes = $this->setupClasses($school);

            // 3. Create Teachers for every subject and assign them
            $this->setupTeachers($school, $classes);

            // 4. Create 100 students per class
            $this->setupStudents($school, $classes);

            // 5. Mark as initialized
            $school->update(['is_initialized' => true]);

            // 6. Log final notification
            DashboardNotification::logEvent(
                'school_event',
                'School Setup Completed',
                "Institutional data for '{$school->name}' has been successfully generated.",
                'System',
                'bi-check-circle-fill',
                $school->id
            );

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    protected function setupSubjects(School $school)
    {
        $commonSubjects = [
            ['ar' => 'القرآن الكريم', 'en' => 'Holy Quran', 'code' => 'QR01'],
            ['ar' => 'التربية الإسلامية', 'en' => 'Islamic Education', 'code' => 'IS01'],
            ['ar' => 'اللغة العربية', 'en' => 'Arabic Language', 'code' => 'AR01'],
            ['ar' => 'اللغة الإنجليزية', 'en' => 'English Language', 'code' => 'EN01'],
            ['ar' => 'الرياضيات', 'en' => 'Mathematics', 'code' => 'MA01'],
            ['ar' => 'العلوم', 'en' => 'Science', 'code' => 'SC01'],
            ['ar' => 'الاجتماعيات', 'en' => 'Social Studies', 'code' => 'SO01'],
            ['ar' => 'الحاسوب', 'en' => 'Computer Science', 'code' => 'CS01'],
        ];

        foreach ($commonSubjects as $sData) {
            $subject = Subject::firstOrCreate(
                ['name_ar' => $sData['ar']],
                ['name_en' => $sData['en'], 'code' => $sData['code'], 'is_active' => true]
            );
            
            SchoolSubject::updateOrCreate(
                ['school_id' => $school->id, 'subject_id' => $subject->id],
                ['is_active' => true]
            );
        }
    }

    protected function setupClasses(School $school)
    {
        $classes = [];
        for ($gradeNum = 1; $gradeNum <= 12; $gradeNum++) {
            foreach (['أ', 'ب'] as $letter) {
                $class = ClassSection::updateOrCreate(
                    [
                        'school_id' => $school->id,
                        'grade' => $gradeNum,
                        'section' => $letter
                    ],
                    [
                        'name' => "Grade {$gradeNum} - {$letter}",
                        'stage' => ($gradeNum <= 6) ? 'Primary' : (($gradeNum <= 9) ? 'Middle' : 'Secondary'),
                        'is_active' => true
                    ]
                );
                $classes[] = $class;
            }
        }
        return $classes;
    }

    protected function setupTeachers(School $school, array $classes)
    {
        $prefix = $this->getSchoolPrefix($school);
        $year   = now()->year;
        $subjects = $school->subjects;

        foreach ($subjects as $index => $subject) {
            $teacherCode = sprintf("%s-%d-T-%04d", $prefix, $year, $index + 1);
            
            $teacher = Teacher::create([
                'school_id' => $school->id,
                'teacher_code' => $teacherCode,
                'full_name' => "Teacher of " . ($subject->name_ar ?? $subject->name_en),
                'email' => "teacher" . ($index + 1) . "@" . ($school->slug ?? 'school') . ".edu",
                'status' => 'Active',
                'join_date' => now(),
                'qualification' => 'Bachelor of Education'
            ]);

            foreach ($classes as $class) {
                TeacherClassSubject::create([
                    'teacher_id' => $teacher->id,
                    'class_section_id' => $class->id,
                    'subject_id' => $subject->id,
                    'is_active' => true,
                    'weekly_load' => 4
                ]);
            }
        }
    }

    protected function setupStudents(School $school, array $classes)
    {
        $prefix = $this->getSchoolPrefix($school);
        $year   = now()->year;

        foreach ($classes as $class) {
            $studentsToCreate = [];
            for ($i = 1; $i <= 100; $i++) {
                // النمط المحدث: [SchoolPrefix]-[S]-[Year]-[Grade]-[Section]-[Rank]
                $academicId = sprintf("%s-S-%d-G%d-%s-%04d", $prefix, $year, $class->grade, $class->section, $i);
                
                $studentsToCreate[] = [
                    'school_id' => $school->id,
                    'full_name' => "Student {$i} - Grade {$class->grade}",
                    'academic_id' => $academicId,
                    'gender' => ($i % 2 == 0) ? 'Male' : 'Female',
                    'status' => 'Active',
                    'grade' => 'Grade ' . $class->grade,
                    'class_section' => $class->section,
                    'class_section_id' => $class->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
            Student::insert($studentsToCreate);
        }
    }

    protected function getSchoolPrefix(School $school)
    {
        $prefix = strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $school->name), 0, 3));
        $prefix = empty($prefix) ? "EDU" : $prefix;
        return $prefix . $school->id;
    }
}
