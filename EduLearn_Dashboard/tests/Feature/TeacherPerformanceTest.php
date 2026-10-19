<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();

        config([
            'database.default' => 'mysql',
            'database.connections.mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
            'database.connections.app_mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
        ]);

        DB::extend('app_mysql', function ($config, $name) {
            return DB::connection('mysql');
        });

        return $app;
    }

    public function test_assigned_subjects_and_deduplicated_total_assigned_students()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 10 - A',
            'name_en' => 'Grade 10 - A',
            'grade' => '10',
            'section' => 'A',
        ]);

        // Create 5 students in this class section
        for ($i = 1; $i <= 5; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student $i",
                'academic_id' => "STU100$i",
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
            'full_name' => 'Teacher John',
            'teacher_code' => 'T-001',
            'status' => 'Active',
        ]);

        // Assign teacher to BOTH subjects in the SAME class section
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

        // Test list endpoint / Teacher model attributes
        $teacher->refresh();

        // Assert assigned subjects are correctly mapped (not null)
        $assignedSubjects = $teacher->assigned_subjects;
        $this->assertCount(2, $assignedSubjects);
        $this->assertContains('Mathematics', $assignedSubjects);
        $this->assertContains('Physics', $assignedSubjects);

        // Assert total_assigned_students is deduplicated (5, NOT 10)
        $this->assertEquals(5, $teacher->total_assigned_students);
    }
}
