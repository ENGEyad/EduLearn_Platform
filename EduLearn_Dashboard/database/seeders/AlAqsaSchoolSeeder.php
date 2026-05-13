<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\School;
use App\Models\Subject;
use App\Models\ClassSection;
use App\Models\Teacher;
use App\Models\Student;
use App\Models\SchoolSubject;
use App\Models\TeacherClassSubject;

class AlAqsaSchoolSeeder extends Seeder
{
    public function run()
    {
        // 1. العثور على المدرسة أو إنشاؤها
        $schoolName = 'مدارس الأقصى الحديثة';
        $school = School::firstOrCreate(
            ['name' => $schoolName],
            [
                'slug' => 'al-aqsa-modern-schools',
                'email' => 'contact@alaqsa.edu',
                'status' => 'active',
                'is_initialized' => true,
                'academic_year' => now()->year . '/' . (now()->year + 1),
                'school_type' => 'Private',
                'country' => 'Yemen',
                'city' => 'Sanaa'
            ]
        );

        echo "School ID: " . $school->id . PHP_EOL;

        // 2. تفعيل المواد الدراسية الأساسية
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

        $subjectIds = [];
        foreach ($commonSubjects as $sData) {
            $subject = Subject::firstOrCreate(
                ['name_ar' => $sData['ar']],
                ['name_en' => $sData['en'], 'code' => $sData['code'], 'is_active' => true]
            );
            $subjectIds[] = $subject->id;

            SchoolSubject::updateOrCreate(
                ['school_id' => $school->id, 'subject_id' => $subject->id],
                ['is_active' => true]
            );
        }

        // 3. إنشاء الصفوف (1-12) مع شعبة "أبجد"
        $classes = [];
        for ($gradeNum = 1; $gradeNum <= 12; $gradeNum++) {
            $class = ClassSection::updateOrCreate(
                [
                    'school_id' => $school->id,
                    'grade' => $gradeNum,
                    'section' => 'أبجد'
                ],
                [
                    'name' => "Grade {$gradeNum} - أبجد",
                    'stage' => ($gradeNum <= 6) ? 'Primary' : (($gradeNum <= 9) ? 'Middle' : 'Secondary'),
                    'is_active' => true
                ]
            );
            $classes[] = $class;
        }

        // 4. إنشاء مدرسين لكل مادة وتعيينهم للصفوف
        $prefix = strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $school->name), 0, 3));
        if (empty($prefix))
            $prefix = "AQS";
        $year = now()->year;

        foreach ($subjectIds as $index => $subId) {
            $subject = Subject::find($subId);
            $teacherCode = sprintf("%s-%d-T-%04d", $prefix, $year, $index + 1);

            $teacher = Teacher::updateOrCreate(
                ['school_id' => $school->id, 'teacher_code' => $teacherCode],
                [
                    'full_name' => "Teacher of " . ($subject->name_ar ?? $subject->name_en),
                    'email' => "teacher" . ($index + 1) . "@alaqsa.edu",
                    'status' => 'Active',
                    'join_date' => now()->subMonths(6),
                    'qualification' => 'Bachelor of Education'
                ]
            );

            // تعيين المدرس لكل الصفوف لهذه المادة
            foreach ($classes as $class) {
                TeacherClassSubject::updateOrCreate([
                    'teacher_id' => $teacher->id,
                    'class_section_id' => $class->id,
                    'subject_id' => $subId
                ], [
                    'is_active' => true,
                    'weekly_load' => 4
                ]);
            }
        }

        // 5. توليد 100 طالب لكل صف (إجمالي 1200 طالب)
        echo "Generating 1200 students... please wait." . PHP_EOL;

        foreach ($classes as $class) {
            $studentBaseCount = Student::where('school_id', $school->id)
                ->where('class_section_id', $class->id)
                ->count();

            if ($studentBaseCount >= 100) {
                echo "Skipping Grade " . $class->grade . " as it already has enough students." . PHP_EOL;
                continue;
            }

            $studentsToCreate = [];
            $allSchoolStudentsCount = Student::where('school_id', $school->id)->count();

            for ($i = 1; $i <= (100 - $studentBaseCount); $i++) {
                $academicId = sprintf("%s-%d-S-%04d", $prefix, $year, $allSchoolStudentsCount + $i);

                $studentsToCreate[] = [
                    'school_id' => $school->id,
                    'full_name' => "Student " . ($studentBaseCount + $i) . " - Grade " . $class->grade,
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
            echo "Finished Grade " . $class->grade . PHP_EOL;
        }

        echo "Seeding completed for " . $schoolName . PHP_EOL;
    }
}
