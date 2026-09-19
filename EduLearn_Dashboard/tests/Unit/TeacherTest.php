<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        DB::extend('mysql', function () {
            return DB::connection('sqlite');
        });
        DB::extend('app_mysql', function () {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_teacher_assigned_subjects_and_total_assigned_students()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@testschool.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '5',
            'section' => 'A',
            'name' => 'الصف الخامس - أ',
            'name_en' => 'Grade 5 - A',
        ]);

        // Add 2 students to the class section
        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $classSection->id,
            'full_name' => 'Student 1',
            'academic_id' => 'STU-001',
        ]);
        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $classSection->id,
            'full_name' => 'Student 2',
            'academic_id' => 'STU-002',
        ]);

        $subjectMath = Subject::create([
            'name_ar' => 'الرياضيات',
            'name_en' => 'Mathematics',
            'code' => 'MATH101',
        ]);

        $subjectScience = Subject::create([
            'name_ar' => 'العلوم',
            'name_en' => 'Science',
            'code' => 'SCI101',
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Teacher John',
            'teacher_code' => 'T-001',
        ]);

        // Teacher is assigned to BOTH Math and Science in the same ClassSection
        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subjectMath->id,
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subjectScience->id,
        ]);

        $teacher->refresh();

        // 1. Check assigned subjects returns display names (Arabic when locale is 'ar')
        app()->setLocale('ar');
        $assignedSubjectsAr = $teacher->assigned_subjects;
        $this->assertCount(2, $assignedSubjectsAr);
        $this->assertContains('الرياضيات', $assignedSubjectsAr);
        $this->assertContains('العلوم', $assignedSubjectsAr);

        // Check assigned subjects returns display names (English when locale is 'en')
        app()->setLocale('en');
        $teacher->unsetRelation('assignments');
        $assignedSubjectsEn = $teacher->assigned_subjects;
        $this->assertCount(2, $assignedSubjectsEn);
        $this->assertContains('Mathematics', $assignedSubjectsEn);
        $this->assertContains('Science', $assignedSubjectsEn);

        // 2. Check total assigned students deduplicates class sections and returns 2 (not 4)
        $this->assertEquals(2, $teacher->total_assigned_students);
    }
}
