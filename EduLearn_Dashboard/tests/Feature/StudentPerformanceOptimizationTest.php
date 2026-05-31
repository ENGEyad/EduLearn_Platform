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

class StudentPerformanceOptimizationTest extends TestCase
{
    // use RefreshDatabase; // Disabled because of multi-connection SQLite issues

    protected function setUp(): void
    {
        parent::setUp();

        // Setup SQLite for app_mysql connection as well if needed,
        // but for this test we'll just use the default connection if configured.
    }

    public function test_student_performance_query_count()
    {
        // 1. Create a school and a user
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        $teacher = \App\Models\Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher',
            'email' => 'teacher@test.com',
            'teacher_code' => 'T123',
        ]);

        // 2. Create a class section
        $section = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 1 - A',
            'grade' => 'Grade 1',
            'section' => 'A',
        ]);

        // 3. Create a student
        $student = Student::create([
            'school_id' => $school->id,
            'class_section_id' => $section->id,
            'first_name' => 'John',
            'last_name' => 'Doe',
            'full_name' => 'John Doe',
            'academic_id' => 'ST123',
            'attendance_rate' => 90,
        ]);

        // 4. Create 5 subjects and assign to section
        $subjects = [];
        for ($i = 1; $i <= 5; $i++) {
            $subject = Subject::create([
                'name_en' => "Subject $i",
                'code' => "SUB$i",
            ]);
            $subjects[] = $subject;

            ClassSectionSubject::create([
                'class_section_id' => $section->id,
                'subject_id' => $subject->id,
                'school_id' => $school->id,
            ]);

            // Create 3 lessons per subject
            for ($j = 1; $j <= 3; $j++) {
                $lesson = Lesson::create([
                    'teacher_id' => $teacher->id,
                    'subject_id' => $subject->id,
                    'title' => "Lesson $j for Subject $i",
                    'school_id' => $school->id,
                ]);

                $exerciseSet = \App\Models\LessonExerciseSet::create([
                    'lesson_id' => $lesson->id,
                    'teacher_id' => $teacher->id,
                    'subject_id' => $subject->id,
                    'title' => 'Test Exercise Set',
                ]);

                $exerciseVersion = \App\Models\LessonExerciseVersion::create([
                    'exercise_set_id' => $exerciseSet->id,
                    'version_no' => 1,
                    'status' => 'published',
                ]);

                // Create progress for student
                StudentLessonProgress::create([
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'status' => 'completed',
                    'time_spent_seconds' => 600,
                ]);

                // Create attempt for student
                StudentExerciseAttempt::create([
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'exercise_set_id' => $exerciseSet->id,
                    'exercise_version_id' => $exerciseVersion->id,
                    'score' => 80,
                    'total_points' => 100,
                ]);
            }
        }

        $this->actingAs($user);

        // Enable query logging
        DB::connection('mysql')->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        $response = $this->get("/students/{$student->id}/performance");

        $response->assertStatus(200);

        $mysqlQueries = count(DB::connection('mysql')->getQueryLog());
        $appMysqlQueries = count(DB::connection('app_mysql')->getQueryLog());
        $totalQueries = $mysqlQueries + $appMysqlQueries;

        dump("Total queries for 5 subjects: $totalQueries (MySQL: $mysqlQueries, App MySQL: $appMysqlQueries)");

        // Currently it's roughly:
        // 1 query for subjects
        // Then for each subject (5 times):
        //   - 1 query for lessons
        //   - 1 query for progress
        //   - 1 query for attempts (with eager loads maybe?)
        // Plus some overhead for user, student, school, etc.
    }
}
