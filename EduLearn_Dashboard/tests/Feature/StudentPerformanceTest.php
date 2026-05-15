<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\ClassSection;
use App\Models\ClassSectionSubject;
use App\Models\Lesson;
use App\Models\LessonExerciseSet;
use App\Models\LessonExerciseVersion;
use App\Models\StudentLessonProgress;
use App\Models\StudentExerciseAttempt;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class StudentPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
    }

    protected function refreshTestDatabase()
    {
        config(['database.connections.mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);
        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);
        config(['database.default' => 'sqlite']);

        Artisan::call('migrate:fresh');
        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_show_performance_query_count_and_data_integrity()
    {
        // 1. Setup Data
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $admin = User::create([
            'name' => 'School Admin',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '10',
            'section' => 'A',
            'name' => 'Grade 10 - A',
            'is_active' => true
        ]);

        $student = Student::create([
            'school_id' => $school->id,
            'full_name' => 'Test Student',
            'academic_id' => 'STU001',
            'class_section_id' => $classSection->id,
            'grade' => '10',
            'class_section' => 'A'
        ]);

        // Create 10 subjects
        for ($i = 1; $i <= 10; $i++) {
            $sub = Subject::create([
                'name_en' => "Subject $i",
                'name_ar' => "المادة $i",
                'code' => "SUB$i",
                'school_id' => $school->id
            ]);

            ClassSectionSubject::create([
                'class_section_id' => $classSection->id,
                'subject_id' => $sub->id,
                'is_active' => true
            ]);

            // Create 2 lessons per subject
            for ($j = 1; $j <= 2; $j++) {
                $lesson = Lesson::create([
                    'teacher_id' => 1,
                    'subject_id' => $sub->id,
                    'class_section_id' => $classSection->id,
                    'title' => "Lesson $i-$j",
                    'status' => 'published'
                ]);

                $exerciseSet = LessonExerciseSet::create([
                    'lesson_id' => $lesson->id,
                    'school_id' => $school->id,
                    'subject_id' => $sub->id,
                    'teacher_id' => 1,
                    'title' => "Exercise $i-$j",
                    'status' => 'published'
                ]);

                $version = LessonExerciseVersion::create([
                    'exercise_set_id' => $exerciseSet->id,
                    'version_no' => 1,
                    'is_active' => true
                ]);

                // Create progress
                StudentLessonProgress::create([
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'status' => 'completed',
                    'time_spent_seconds' => 600
                ]);

                // Create attempt
                StudentExerciseAttempt::create([
                    'student_id' => $student->id,
                    'lesson_id' => $lesson->id,
                    'exercise_set_id' => $exerciseSet->id,
                    'exercise_version_id' => $version->id,
                    'score' => 85,
                    'total_points' => 100
                ]);
            }
        }

        // 2. Act & Measure
        $this->actingAs($admin);

        $queries = [];
        DB::connection('app_mysql')->listen(function ($query) use (&$queries) {
            $queries[] = $query->sql;
        });
        DB::connection('mysql')->listen(function ($query) use (&$queries) {
            $queries[] = $query->sql;
        });

        $response = $this->get(route('students.performance', $student));

        // 3. Assert
        $response->assertStatus(200);

        $queriesCount = count($queries);
        echo "\nTotal queries for 10 subjects (optimized): " . $queriesCount . "\n";

        $this->assertLessThan(40, $queriesCount);

        // Verify Data in View
        $performanceList = $response->viewData('performanceList');
        $this->assertCount(10, $performanceList);

        foreach ($performanceList as $item) {
            $this->assertEquals(2, $item['total_lessons']);
            $this->assertEquals(2, $item['completed_lessons']);
            $this->assertEquals(100, $item['progress_percent']);
            $this->assertEquals(20, $item['total_study_time']); // (600+600)/60 = 20 mins
            $this->assertEquals(85, $item['avg_score']);
            $this->assertCount(2, $item['attempts']);
        }
    }
}
