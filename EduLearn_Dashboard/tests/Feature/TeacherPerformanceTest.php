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
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        DB::extend('app_mysql', function ($config, $name) {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_teacher_list_performance_and_calculation_accuracy()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@testschool.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '10',
            'section' => 'A',
            'name' => 'Grade 10 - A',
            'name_en' => 'Grade 10 - A',
        ]);

        // Create 25 students in classSection
        for ($i = 1; $i <= 25; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student $i",
                'academic_id' => "STU-$i",
            ]);
        }

        $subject1 = Subject::create([
            'name_en' => 'Mathematics',
            'name_ar' => 'الرياضيات',
            'code' => 'MATH101',
        ]);

        $subject2 = Subject::create([
            'name_en' => 'Physics',
            'name_ar' => 'الفيزياء',
            'code' => 'PHYS101',
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'John Doe',
            'teacher_code' => 'EDU1-T-2025-0001',
        ]);

        // Assign teacher to subject1 and subject2 for the SAME classSection
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

        $teacherData = $data[0];

        // Assert subject names are properly retrieved via display_name / name_en / name_ar
        $this->assertTrue(
            in_array('Mathematics', $teacherData['assigned_subjects']) || in_array('الرياضيات', $teacherData['assigned_subjects']),
            'Assigned subjects should contain Mathematics or الرياضيات. Got: '.json_encode($teacherData['assigned_subjects'])
        );

        // Assert total assigned students count is 25 (NOT 50 due to duplicated sum per assignment)
        $this->assertEquals(25, $teacherData['total_assigned_students']);
    }
}
