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
use Tests\TestCase;

class TeacherListPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';
        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));

        \Illuminate\Support\Facades\DB::extend('app_mysql', function ($config, $name) {
            return \Illuminate\Support\Facades\DB::connection('sqlite');
        });

        return $app;
    }

    public function test_teacher_total_assigned_students_deduplication()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $cs1 = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 1 A',
            'name_en' => 'Grade 1 A',
            'grade' => '1',
            'section' => 'A',
        ]);

        for ($s = 1; $s <= 10; $s++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $cs1->id,
                'full_name' => "Student $s",
                'academic_id' => "STU-$s",
                'gender' => 'male',
                'status' => 'active',
            ]);
        }

        $subject1 = Subject::create(['name_ar' => 'Math', 'name_en' => 'Math', 'code' => 'MATH101']);
        $subject2 = Subject::create(['name_ar' => 'Science', 'name_en' => 'Science', 'code' => 'SCI101']);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Teacher 1',
            'teacher_code' => 'T001',
        ]);

        // Assign teacher to the same class section twice for 2 different subjects
        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $cs1->id,
            'subject_id' => $subject1->id,
        ]);
        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $cs1->id,
            'subject_id' => $subject2->id,
        ]);

        $teacher->load(['assignments.classSection' => function ($q) {
            $q->withCount('students');
        }]);

        // Verify deduplicated total count (10, not 20)
        $this->assertEquals(10, $teacher->total_assigned_students);
    }

    public function test_teacher_list_response_and_performance()
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

        $cs = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 1 A',
            'name_en' => 'Grade 1 A',
            'grade' => '1',
            'section' => 'A',
        ]);

        $subject = Subject::create(['name_ar' => 'Math', 'name_en' => 'Math', 'code' => 'MATH101']);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Teacher 1',
            'teacher_code' => 'T001',
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $cs->id,
            'subject_id' => $subject->id,
        ]);

        $response = $this->actingAs($user)->getJson(route('teachers.list'));

        $response->assertStatus(200);
        $data = $response->json();
        $this->assertCount(1, $data);
        $this->assertEquals('Teacher 1', $data[0]['full_name']);
        $this->assertArrayHasKey('total_assigned_students', $data[0]);
    }
}
