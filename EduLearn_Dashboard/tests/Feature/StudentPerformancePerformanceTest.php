<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\ClassSectionSubject;
use App\Models\Lesson;
use App\Models\School;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\StudentLessonProgress;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class StudentPerformancePerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_show_performance_is_optimized()
    {
        // Setup
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin'.uniqid().'@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        $section = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '10',
            'section' => 'A',
            'name' => '10 - A',
            'is_active' => true,
        ]);

        $student = Student::create([
            'school_id' => $school->id,
            'class_section_id' => $section->id,
            'first_name' => 'John',
            'last_name' => 'Doe',
            'full_name' => 'John Doe',
            'academic_id' => 'ST123',
            'grade' => '10',
            'class_section' => 'A',
        ]);

        $teacher = \App\Models\Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher',
            'email' => 'teacher@school.com',
            'password' => bcrypt('password'),
        ]);

        // Create 10 subjects
        for ($i = 1; $i <= 10; $i++) {
            $subject = Subject::create([
                'name_en' => "Subject $i",
                'code' => "SUB$i",
            ]);

            ClassSectionSubject::create([
                'class_section_id' => $section->id,
                'subject_id' => $subject->id,
            ]);

            // Create 3 lessons per subject
            for ($j = 1; $j <= 3; $j++) {
                $lesson = Lesson::create([
                    'school_id' => $school->id,
                    'teacher_id' => $teacher->id,
                    'subject_id' => $subject->id,
                    'class_section_id' => $section->id,
                    'title' => "Lesson $j for Subject $i",
                ]);

                StudentLessonProgress::create([
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'status' => 'completed',
                    'time_spent_seconds' => 300,
                ]);

                StudentExerciseAttempt::create([
                    'exercise_set_id' => 1,
                    'exercise_version_id' => 1,
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'score' => 80,
                    'total_points' => 100,
                ]);
            }
        }

        $this->actingAs($user);

        // Measure queries
        DB::connection('mysql')->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        $response = $this->get(route('students.performance', $student));

        $response->assertStatus(200);

        $mysqlQueries = count(DB::connection('mysql')->getQueryLog());
        $appMysqlQueries = count(DB::connection('app_mysql')->getQueryLog());
        $totalQueries = $mysqlQueries + $appMysqlQueries;

        // Baseline:
        // 1. Auth user (mysql)
        // 2. Resolve school (mysql)
        // 3. ClassSectionSubject query (mysql)
        // 4. Subjects query (mysql)
        // 5. Loop 10 times:
        //    a. Lessons query (app_mysql)
        //    b. ProgressItems query (app_mysql)
        //    c. Attempts query (app_mysql)
        // Expected baseline: 4 (setup) + 10 * 3 = 34 queries + some framework overhead.

        echo "\nTotal queries: $totalQueries (MySQL: $mysqlQueries, App MySQL: $appMysqlQueries)\n";

        // After optimization, it should be much less.
        // We aim for < 10 queries total.
        $this->assertLessThan(40, $totalQueries, "Query count is too high: $totalQueries");
    }
}
