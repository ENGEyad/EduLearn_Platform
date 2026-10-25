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
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        DB::extend('app_mysql', fn () => DB::connection('sqlite'));

        return $app;
    }

    public function test_total_assigned_students_deduplicates_sections_and_counts_correctly()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'John Doe',
            'gender' => 'Male',
            'shift' => 'Morning',
            'teacher_code' => 'T101',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 10A',
            'name_en' => 'Grade 10A',
            'grade' => '10',
            'section' => 'A',
        ]);

        // Create 5 students in this class section
        for ($i = 1; $i <= 5; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student $i",
                'academic_id' => "ST100$i",
                'status' => 'active',
            ]);
        }

        $subject1 = Subject::create(['name_ar' => 'Math', 'name_en' => 'Math', 'code' => 'MATH101']);
        $subject2 = Subject::create(['name_ar' => 'Physics', 'name_en' => 'Physics', 'code' => 'PHYS101']);

        // Teacher is assigned to 2 subjects in the same class section
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

        // Assert total_assigned_students is 5 (not 10 due to duplicate section assignments)
        $this->assertEquals(5, $teacher->total_assigned_students);
    }
}
