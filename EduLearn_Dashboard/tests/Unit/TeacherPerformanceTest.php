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

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();

        $app['config']->set('database.default', 'sqlite');
        $app['config']->set('database.connections.sqlite.database', ':memory:');
        $app['config']->set('database.connections.mysql', $app['config']->get('database.connections.sqlite'));
        $app['config']->set('database.connections.app_mysql', $app['config']->get('database.connections.sqlite'));

        return $app;
    }

    public function test_total_assigned_students_deduplicates_class_sections_and_counts_correctly(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 1A',
            'name_en' => 'Grade 1A',
            'grade' => '1',
            'section' => 'A',
            'is_active' => true,
        ]);

        // Create 3 students in this class section
        for ($i = 1; $i <= 3; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student $i",
                'academic_id' => "STU00$i",
            ]);
        }

        $subject1 = Subject::create(['name_ar' => 'Math', 'name_en' => 'Math', 'code' => 'MATH101']);
        $subject2 = Subject::create(['name_ar' => 'Science', 'name_en' => 'Science', 'code' => 'SCI101']);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'John Doe',
            'teacher_code' => 'T101',
        ]);

        // Assign teacher to TWO subjects in the SAME class section
        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject1->id,
            'is_active' => true,
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject2->id,
            'is_active' => true,
        ]);

        $teacher->refresh();

        // Expect exactly 3 total assigned students (not 6 due to duplicated class section assignments)
        $this->assertEquals(3, $teacher->total_assigned_students);
    }
}
