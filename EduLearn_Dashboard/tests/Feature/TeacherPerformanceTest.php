<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use App\Models\User;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication(): Application
    {
        $app = parent::createApplication();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));

        // Dynamically override app_mysql to use the sqlite connection in memory
        DB::extend('app_mysql', function ($config, $name) {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_teacher_total_assigned_students_deduplicates_class_sections(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher',
            'teacher_code' => 'TEST-001',
            'gender' => 'Male',
            'shift' => 'Morning',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 1 - A',
            'name_en' => 'Grade 1 - A',
            'grade' => '1',
            'section' => 'A',
            'capacity' => 30,
        ]);

        $subject1 = Subject::create(['name_ar' => 'Math', 'name_en' => 'Math', 'code' => 'MATH101']);
        $subject2 = Subject::create(['name_ar' => 'Science', 'name_en' => 'Science', 'code' => 'SCI101']);

        // Create 2 assignments for the same teacher in the same class section
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

        $teacher->load(['assignments.classSection']);

        // Manually attach student count attribute to the loaded relationship models to simulate withCount('students')
        foreach ($teacher->assignments as $as) {
            $as->classSection->students_count = 25;
        }

        // Without deduplication, this would have returned 50 (25 + 25)
        $this->assertEquals(25, $teacher->total_assigned_students);
    }

    public function test_teacher_list_endpoint_returns_teachers_with_deduplicated_counts(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'school_id' => $school->id,
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher List',
            'teacher_code' => 'TEST-002',
            'gender' => 'Female',
            'shift' => 'Morning',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 2 - B',
            'name_en' => 'Grade 2 - B',
            'grade' => '2',
            'section' => 'B',
            'capacity' => 30,
        ]);

        // Add 3 students to class section
        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $classSection->id,
            'full_name' => 'Student 1',
            'academic_id' => 'S101',
            'gender' => 'Male',
            'birthdate' => '2015-01-01',
            'status' => 'Active',
            'grade' => 'Grade 2',
            'class_section' => 'B',
            'guardian_name' => 'Guardian 1',
            'guardian_phone' => '123456789',
        ]);
        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $classSection->id,
            'full_name' => 'Student 2',
            'academic_id' => 'S102',
            'gender' => 'Female',
            'birthdate' => '2015-02-02',
            'status' => 'Active',
            'grade' => 'Grade 2',
            'class_section' => 'B',
            'guardian_name' => 'Guardian 2',
            'guardian_phone' => '123456789',
        ]);

        $subject1 = Subject::create(['name_ar' => 'History', 'name_en' => 'History', 'code' => 'HIST101']);
        $subject2 = Subject::create(['name_ar' => 'Geography', 'name_en' => 'Geography', 'code' => 'GEO101']);

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
        $this->assertEquals(2, $data[0]['total_assigned_students']);
    }
}
