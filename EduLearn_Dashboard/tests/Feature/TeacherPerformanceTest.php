<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Define connections to use sqlite for both
        $sqlite = [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ];
        config(['database.connections.mysql' => $sqlite]);
        config(['database.connections.app_mysql' => $sqlite]);
        config(['database.default' => 'mysql']);

        // Run migrations for the main connection
        $this->artisan('migrate');
    }

    public function test_teacher_list_eager_loads_students_count()
    {
        $teacher = Teacher::create([
            'full_name' => 'John Doe',
            'teacher_code' => 'T123',
            'status' => 'Active',
        ]);

        $subject = Subject::create([
            'name_en' => 'Math',
            'name_ar' => 'رياضيات',
            'code' => 'MATH101',
        ]);

        $classSection = ClassSection::create([
            'grade' => '10',
            'section' => 'A',
            'name' => 'Grade 10A',
        ]);

        Student::create([
            'full_name' => 'Student 1',
            'class_section_id' => $classSection->id,
            'academic_id' => 'S001',
        ]);

        Student::create([
            'full_name' => 'Student 2',
            'class_section_id' => $classSection->id,
            'academic_id' => 'S002',
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject->id,
        ]);

        $response = $this->getJson(route('teachers.list'));

        $response->assertStatus(200);
        $data = $response->json();

        $this->assertNotEmpty($data);
        $teacherData = $data[0];

        // Check if total_assigned_students accessor works
        $this->assertEquals(2, $teacherData['total_assigned_students']);

        // Verify that students_count is present in assignments (meaning eager loading worked)
        $this->assertArrayHasKey('students_count', $teacherData['assignments'][0]['class_section']);
        $this->assertEquals(2, $teacherData['assignments'][0]['class_section']['students_count']);
    }
}
