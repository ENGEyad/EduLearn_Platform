<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Services\DashboardAnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Configure a clean, zero-interference dual-database SQLite :memory: testing environment.
     */
    public function createApplication()
    {
        $app = parent::createApplication();

        // Map mysql connection to sqlite :memory:
        $app['config']->set('database.connections.mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);

        // Set default database connection to mysql
        $app['config']->set('database.default', 'mysql');

        // Extend app_mysql to use the same mysql sqlite in-memory connection
        $app['db']->extend('app_mysql', function () use ($app) {
            return $app['db']->connection('mysql');
        });

        return $app;
    }

    /**
     * Test that building overview dashboard analytics does not trigger N+1 queries for class section average attendance.
     */
    public function test_dashboard_analytics_avoids_n_plus_one_queries(): void
    {
        // 1. Create a school
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-'.uniqid(),
            'email' => 'admin-'.uniqid().'@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // 2. Create multiple class sections
        $sections = collect();
        for ($i = 1; $i <= 5; $i++) {
            $sections->push(ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'name' => 'Grade '.$i,
                'name_en' => 'Grade '.$i,
                'section' => 'A',
            ]));
        }

        // 3. Create students for each class section with custom attendance rates
        foreach ($sections as $section) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'Low Student '.uniqid(),
                'academic_id' => 'AC-'.uniqid(),
                'grade' => $section->grade,
                'class_section' => $section->section,
                'attendance_rate' => 80.0,
                'status' => 'active',
            ]);

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'High Student '.uniqid(),
                'academic_id' => 'AC-'.uniqid(),
                'grade' => $section->grade,
                'class_section' => $section->section,
                'attendance_rate' => 90.0,
                'status' => 'active',
            ]);
        }

        // Let's count queries executed during buildOverview
        DB::flushQueryLog();
        DB::enableQueryLog();

        $service = app(DashboardAnalyticsService::class);
        $analytics = $service->buildOverview($school->id, 'week', $school->name);

        $queryLog = DB::getQueryLog();
        DB::disableQueryLog();

        // 4. Assert correctness of the stats
        $this->assertEquals(5, $analytics['stats']['classes']);
        $this->assertArrayHasKey('stats', $analytics);

        // Let's inspect the queries
        $queries = collect($queryLog)->pluck('query');

        // If it was N+1, there would be a student attendance query for each class section (5 queries).
        // With optimization, we expect exactly 1 query to get the grouped attendance.
        $groupedAttendanceQueries = $queries->filter(function ($query) {
            return str_contains(strtolower($query), 'avg(attendance_rate)') || str_contains(strtolower($query), 'avg("attendance_rate")') || str_contains(strtolower($query), 'avg(`attendance_rate`)');
        });

        // Eager-loaded grouped query should be executed at most once, and overall average once
        $this->assertLessThanOrEqual(2, $groupedAttendanceQueries->count());

        // Ensure there are no individual queries with class_section_id in the where clause looking for avg(attendance_rate)
        $individualQueries = $queries->filter(function ($query) {
            return (str_contains(strtolower($query), 'avg(attendance_rate)') || str_contains(strtolower($query), 'avg("attendance_rate")') || str_contains(strtolower($query), 'avg(`attendance_rate`)'))
                && str_contains(strtolower($query), 'where "class_section_id" =');
        });
        $this->assertEquals(0, $individualQueries->count());
    }
}
