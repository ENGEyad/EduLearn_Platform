<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\ClassSectionSubject;
use App\Models\Lesson;
use App\Models\LessonExerciseSet;
use App\Models\School;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\StudentLessonProgress;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class StudentPerformancePerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_show_performance_query_count()
    {
        // Setup
        $school = School::create([
            'name' => 'Performance School',
            'slug' => 'perf-school',
            'email' => 'perf@example.com',
            'status' => 'active',
            'is_initialized' => true
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id
        ]);

        $this->actingAs($user);

        $class = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '10',
            'section' => 'A',
            'name' => '10 - A'
        ]);

        $student = Student::create([
            'school_id' => $school->id,
            'class_section_id' => $class->id,
            'full_name' => 'Test Student',
            'academic_id' => 'STU001',
            'grade' => '10',
            'class_section' => 'A'
        ]);

        $subjectCount = 10;
        for ($i = 1; $i <= $subjectCount; $i++) {
            $subject = Subject::create([
                'name_en' => "Subject $i",
                'code' => "SUB$i"
            ]);

            ClassSectionSubject::create([
                'class_section_id' => $class->id,
                'subject_id' => $subject->id,
                'is_active' => true
            ]);

            // Create 2 lessons per subject
            for ($j = 1; $j <= 2; $j++) {
                $lesson = Lesson::on('app_mysql')->create([
                    'subject_id' => $subject->id,
                    'teacher_id' => 1,
                    'title' => "Lesson $i-$j",
                    'status' => 'published'
                ]);

                $exerciseSet = LessonExerciseSet::on('app_mysql')->create([
                    'lesson_id' => $lesson->id,
                    'teacher_id' => 1,
                    'title' => "Exercise Set $i-$j",
                    'status' => 'published'
                ]);

                // 1 completed progress
                StudentLessonProgress::on('app_mysql')->create([
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'status' => 'completed',
                    'time_spent_seconds' => 300
                ]);

                // 1 attempt
                StudentExerciseAttempt::on('app_mysql')->create([
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'exercise_set_id' => $exerciseSet->id,
                    'exercise_version_id' => 1,
                    'score' => 80,
                    'total_points' => 100
                ]);
            }
        }

        DB::connection('mysql')->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        $response = $this->get(route('students.performance', $student));

        $mysqlQueries = count(DB::connection('mysql')->getQueryLog());
        $appMysqlQueries = count(DB::connection('app_mysql')->getQueryLog());
        $totalQueries = $mysqlQueries + $appMysqlQueries;

        echo "\nTotal queries for $subjectCount subjects: $totalQueries\n";
        // Detailed log for debugging
        foreach (DB::connection('app_mysql')->getQueryLog() as $log) {
            echo "SQL: " . $log['query'] . "\n";
        }

        $response->assertStatus(200);
        $data = $response->viewData('performanceList');
        $this->assertCount(10, $data);
        foreach ($data as $perf) {
            $this->assertEquals(2, $perf['total_lessons']);
            $this->assertEquals(2, $perf['completed_lessons']);
            $this->assertEquals(100, $perf['progress_percent']);
            $this->assertEquals(10.0, $perf['total_study_time']); // (300*2)/60
            $this->assertEquals(80.0, $perf['avg_score']);
            $this->assertCount(2, $perf['attempts']);
        }
    }
}
