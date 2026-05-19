<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use App\Services\DashboardAnalyticsService;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->artisan('migrate:fresh', ['--force' => true]);
    }

    public function test_dashboard_overview_query_count()
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

        // Create 10 classes
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Class ' . $i,
            ]);

            // Create 5 students per class
            for ($j = 1; $j <= 5; $j++) {
                $student = Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ID-$i-$j",
                    'attendance_rate' => 80 + $j, // Some below 85
                    'grade' => 'Grade ' . $i,
                    'class_section' => 'A',
                ]);

                // Create a few attempts
                \App\Models\StudentExerciseAttempt::create([
                    'student_id' => $student->id,
                    'exercise_set_id' => 1,
                    'exercise_version_id' => 1,
                    'lesson_id' => 1,
                    'score' => 75,
                    'status' => 'graded',
                ]);
            }
        }

        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();
        DB::connection('app_mysql')->flushQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        $service = app(DashboardAnalyticsService::class);
        $service->buildOverview($school->id, 'week', $school->name);

        $queryLog = array_merge(DB::getQueryLog(), DB::connection('app_mysql')->getQueryLog());
        $queryCount = count($queryLog);

        echo "\nTotal queries for dashboard overview: " . $queryCount . "\n";
        foreach ($queryLog as $query) {
            echo "QUERY: " . $query['query'] . "\n";
        }

        // Currently we expect it to be high due to N+1
        // 1 for student IDs
        // 1 for sections
        // 1 for performance overall
        // 1 for attendance overall
        // 1 for teachers count
        // 1 for classes count
        // 1 for subjects count
        // 1 for dangling students
        // 1 for current performance
        // 1 for previous performance
        // 1 for low attendance students
        // 1 for low performance students
        // N for low attendance classes (where N is number of sections)
        // Total should be around 12 + 10 = 22 queries.

        $this->assertLessThan(30, $queryCount);
    }
}
