<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\User;
use App\Models\Teacher;
use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\TeacherClassSubject;
use App\Models\Student;
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

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
            'database.connections.mysql' => config('database.connections.sqlite'),
            'database.connections.app_mysql' => config('database.connections.sqlite'),
        ]);

        DB::extend('mysql', fn() => DB::connection('sqlite'));
        DB::extend('app_mysql', fn() => DB::connection('sqlite'));

        return $app;
    }

    public function test_teacher_total_assigned_students_deduplicates_class_sections()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 5 - A',
            'name_en' => 'Grade 5 - A',
            'grade' => '5',
            'section' => 'A',
        ]);

        // Create 20 students in this class section
        for ($i = 1; $i <= 20; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student $i",
                'academic_id' => "STU-$i",
                'grade' => 'Grade 5',
                'class_section' => 'A',
            ]);
        }

        $subject1 = Subject::create(['name_en' => 'Math', 'name_ar' => 'رياضيات', 'code' => 'MATH101']);
        $subject2 = Subject::create(['name_en' => 'Science', 'name_ar' => 'علوم', 'code' => 'SCI101']);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'John Teacher',
            'teacher_code' => 'T101',
        ]);

        // Assign teacher to BOTH subjects in the SAME class section
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

        $response = $this->actingAs($user)->getJson(route('teachers.list'));

        $response->assertStatus(200);
        $data = $response->json();

        $this->assertCount(1, $data);
        // Before optimization, total_assigned_students was 40 (20 * 2 subjects) instead of 20 unique students
        $this->assertEquals(20, $data[0]['total_assigned_students']);
    }
}
