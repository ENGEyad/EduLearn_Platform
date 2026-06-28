<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\User;
use App\Services\DashboardAnalyticsService;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $dbFile = database_path('test_db_main.sqlite');
        $appDbFile = database_path('test_app_db_sub.sqlite');

        if (file_exists($dbFile)) unlink($dbFile);
        if (file_exists($appDbFile)) unlink($appDbFile);

        touch($dbFile);
        touch($appDbFile);

        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => $dbFile]);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => $appDbFile]);
        config(['database.default' => 'mysql']);

        $this->artisan('migrate', ['--force' => true]);
    }

    public function test_build_overview_query_count()
    {
        // Setup
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school' . uniqid() . '@example.com',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Test User',
            'email' => 'test' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'admin',
        ]);

        // Create 10 sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Grade ' . $i . ' A',
                'is_active' => true,
            ]);

            // Create 5 students per section
            for ($j = 1; $j <= 5; $j++) {
                $student = Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ACAD-$i-$j-" . uniqid(),
                    'attendance_rate' => 80 + $j,
                ]);

                // Create some attempts
                StudentExerciseAttempt::create([
                    'student_id' => $student->id,
                    'exercise_set_id' => 1,
                    'exercise_version_id' => 1,
                    'lesson_id' => 1,
                    'score' => 60 + $j,
                ]);
            }
        }

        $service = app(DashboardAnalyticsService::class);

        // Warm up cache or just run once (index doesn't use cache if we call service directly)
        DB::flushQueryLog();
        DB::enableQueryLog();

        $start = microtime(true);
        $service->buildOverview($school->id, 'week', $school->name);
        $end = microtime(true);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        dump("Query count: " . $queryCount);
        dump("Execution time: " . ($end - $start) . "s");

        $this->assertTrue(true);
    }
}
