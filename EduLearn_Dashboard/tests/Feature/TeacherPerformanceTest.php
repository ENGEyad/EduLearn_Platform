<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use App\Models\User;
use App\Models\Subject;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_measures_query_count_for_teacher_list()
    {
        // 1. Setup data
        $teacherCount = 5;
        $sectionsPerTeacher = 2;
        $studentsPerSection = 3;

        $subject = Subject::create(['name_en' => 'Math', 'name_ar' => 'رياضيات', 'code' => 'MATH101']);

        for ($t = 0; $t < $teacherCount; $t++) {
            $teacher = Teacher::create([
                'full_name' => "Teacher $t",
                'teacher_code' => "T-$t",
                'email' => "teacher$t@example.com",
                'status' => 'Active'
            ]);

            for ($i = 0; $i < $sectionsPerTeacher; $i++) {
                $section = ClassSection::create([
                    'grade' => "Grade " . ($t * 2 + $i),
                    'section' => 'A',
                    'name' => "Grade " . ($t * 2 + $i) . " - A",
                ]);

                for ($s = 0; $s < $studentsPerSection; $s++) {
                    Student::create([
                        'full_name' => "Student $t-$i-$s",
                        'academic_id' => "S-$t-$i-$s",
                        'class_section_id' => $section->id,
                        'grade' => $section->grade,
                        'class_section' => $section->section,
                    ]);
                }

                TeacherClassSubject::create([
                    'teacher_id' => $teacher->id,
                    'class_section_id' => $section->id,
                    'subject_id' => $subject->id,
                    'is_active' => true,
                ]);
            }
        }

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin'
        ]);
        $this->actingAs($user);

        // 2. Measure queries
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->getJson(route('teachers.list'));

        $queryLog = DB::getQueryLog();
        $queryCount = count($queryLog);

        echo "\nTotal queries for teacher list: " . $queryCount . "\n";

        $response->assertStatus(200);

        // After optimization, it should be 4 queries total regardless of teacher count:
        // 1. SELECT * FROM teachers
        // 2. SELECT * FROM teacher_class_subjects WHERE teacher_id IN (...)
        // 3. SELECT * FROM subjects WHERE id IN (...)
        // 4. SELECT *, (SELECT COUNT(*) FROM students WHERE ...) AS students_count FROM class_sections WHERE id IN (...)

        $this->assertEquals(4, $queryCount, "N+1 query issue detected in teacher list!");
    }
}
