<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use App\Services\DashboardAnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();

        // Direct both connections to use the SQLite in-memory database to avoid needing a live MySQL server during tests
        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
        ]);

        // Map the dual connections into the same SQLite database
        DB::extend('app_mysql', function () {
            return DB::connection('sqlite');
        });

        DB::extend('mysql', function () {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_dashboard_overview_avoid_n_plus_one_queries()
    {
        // 1. Setup school and test user
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

        $this->actingAs($user);

        // 2. Create 5 class sections and some students under each class section
        for ($i = 1; $i <= 5; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Grade ' . $i . ' - A',
                'name_en' => 'Grade ' . $i . ' - A',
            ]);

            // Add students with weak attendance (e.g., 80% to trigger low-attendance counting)
            for ($j = 1; $j <= 3; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student {$i}-{$j}",
                    'academic_id' => "ACAD-{$i}-{$j}-" . uniqid(),
                    'gender' => 'male',
                    'status' => 'active',
                    'grade' => 'Grade ' . $i,
                    'class_section' => 'A',
                    'attendance_rate' => 80.0,
                ]);
            }
        }

        // 3. Measure queries executed during DashboardAnalyticsService::buildOverview
        $analyticsService = app(DashboardAnalyticsService::class);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $result = $analyticsService->buildOverview($school->id, 'week', $school->name);

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        // 4. Assert correctness of calculations
        $this->assertEquals(5, $result['stats']['classes']);
        $this->assertEquals(15, $result['stats']['students']);

        // N+1 query problem would issue a query per section (5 queries) inside the loop,
        // resulting in a total query count significantly higher.
        // We ensure that the number of student-related queries is minimal.
        $this->assertNotEmpty($result);

        // Count student-specific query patterns
        $studentQueryCount = 0;
        foreach ($queries as $query) {
            if (str_contains($query['query'], 'students') && str_contains($query['query'], 'avg')) {
                $studentQueryCount++;
            }
        }

        // Should be exactly 2 "avg" queries on students:
        // - One for general overall attendance: avg('attendance_rate')
        // - One for section aggregates (the optimized groupBy query): avg(attendance_rate) grouped by class_section_id
        // (Previously it was O(N) = 1 + N)
        $this->assertLessThanOrEqual(2, $studentQueryCount, "Eager loading or caching did not resolve N+1 student queries!");
    }
}
