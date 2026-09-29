<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));

        DB::extend('app_mysql', fn () => DB::connection('sqlite'));

        return $app;
    }

    public function test_total_assigned_students_deduplicates_class_sections()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 10 - A',
            'name_en' => 'Grade 10 - A',
            'grade' => '10',
            'section' => 'A',
        ]);

        // Create 25 students in this class section
        for ($i = 1; $i <= 25; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student {$i}",
                'academic_id' => "STU{$i}",
            ]);
        }

        $subjectMath = Subject::create([
            'name_en' => 'Mathematics',
            'name_ar' => 'الرياضيات',
            'code' => 'MATH101',
        ]);

        $subjectPhysics = Subject::create([
            'name_en' => 'Physics',
            'name_ar' => 'الفيزياء',
            'code' => 'PHYS101',
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'John Doe',
            'teacher_code' => 'EDU1-T-2025-0001',
            'gender' => 'Male',
            'shift' => 'Morning',
        ]);

        // Teacher is assigned TWO subjects for the SAME class section
        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subjectMath->id,
            'is_active' => true,
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subjectPhysics->id,
            'is_active' => true,
        ]);

        $teacher->refresh();

        // 1. Total assigned students should be 25 (deduplicated), NOT 50
        $this->assertEquals(25, $teacher->total_assigned_students);

        // 2. Assigned subjects should correctly return display names
        $this->assertContains('Mathematics', $teacher->assigned_subjects);
        $this->assertContains('Physics', $teacher->assigned_subjects);
        $this->assertCount(2, $teacher->assigned_subjects);
    }
}
