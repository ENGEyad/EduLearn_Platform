<?php

namespace Tests\Feature;

use App\Models\Teacher;
use App\Models\ClassSection;
use App\Models\Student;
use App\Models\TeacherClassSubject;
use App\Models\Subject;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    public function test_list_teachers_performance()
    {
        // Create 20 teachers
        $teachers = [];
        for ($i = 1; $i <= 20; $i++) {
            $teachers[] = Teacher::create([
                'full_name' => "Teacher $i",
                'teacher_code' => "T$i",
                'status' => 'Active',
            ]);
        }

        // Create 20 class sections
        $classes = [];
        for ($i = 1; $i <= 20; $i++) {
            $classes[] = ClassSection::create([
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => "Grade $i - A",
            ]);
        }

        // Create a subject
        $subject = Subject::create([
            'name_en' => 'Math',
            'name_ar' => 'رياضيات',
            'code' => 'MATH101',
        ]);

        // Assign each teacher to 1 unique class section
        foreach ($teachers as $index => $teacher) {
            TeacherClassSubject::create([
                'teacher_id' => $teacher->id,
                'class_section_id' => $classes[$index]->id,
                'subject_id' => $subject->id,
                'is_active' => true,
            ]);
        }

        // Add some students to classes
        foreach ($classes as $class) {
            Student::create([
                'full_name' => "Student in Class " . $class->id,
                'academic_id' => "S" . $class->id,
                'class_section_id' => $class->id,
                'grade' => $class->grade,
                'class_section' => $class->section,
            ]);
        }

        // Record query count
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->getJson(route('teachers.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);

        echo "\nTotal queries for listing 20 teachers: $queryCount\n";

        // Post-optimization:
        // 1. select * from teachers
        // 2. select * from teacher_class_subjects where teacher_id in (...)
        // 3. select * from subjects where id in (...)
        // 4. select *, (select count(*) from students where class_sections.id = students.class_section_id) as students_count from class_sections where id in (...)
        // Total expected: 4 queries

        $this->assertEquals(4, $queryCount, "Should have exactly 4 queries after optimization");
    }
}
