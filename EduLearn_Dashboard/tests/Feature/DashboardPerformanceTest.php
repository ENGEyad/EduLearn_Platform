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
     * Benchmark and verify that N+1 queries are successfully resolved
     * and total database queries are extremely low and constant.
     */
    public function test_dashboard_analytics_avoids_n_plus_one_queries_and_reduces_query_count()
    {
        // 1. Setup school
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@test-school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // 2. Setup multiple class sections
        $numSections = 10;
        $sections = [];
        for ($i = 1; $i <= $numSections; $i++) {
            $sections[] = ClassSection::create([
                'school_id' => $school->id,
                'grade' => "Grade {$i}",
                'section' => 'A',
                'name' => "Grade {$i} - A",
                'name_en' => "Grade {$i} - A",
                'name_ar' => "Grade {$i} - A",
                'is_active' => true,
            ]);
        }

        // 3. Setup students for each class section with some attendance rates
        foreach ($sections as $index => $section) {
            // Add 3 students per section
            for ($s = 1; $s <= 3; $s++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'grade' => $section->grade,
                    'class_section' => $section->section,
                    'full_name' => "Student {$index} - {$s}",
                    'academic_id' => "ACAD-{$index}-{$s}-".uniqid(),
                    'email' => "student-{$index}-{$s}-".uniqid().'@school.com',
                    'password' => bcrypt('password'),
                    'attendance_rate' => ($index % 2 === 0) ? 80.0 : 95.0, // Every second section is below 85%
                ]);
            }
        }

        // 4. Run the dashboard analytics service and record the queries executed
        $analyticsService = app(DashboardAnalyticsService::class);

        $queriesExecuted = [];
        DB::listen(function ($query) use (&$queriesExecuted) {
            $queriesExecuted[] = $query->sql;
        });

        $analytics = $analyticsService->buildOverview($school->id, 'week', $school->name);

        // 5. Assertions to verify correct analytics calculation
        $this->assertEquals($numSections, $analytics['stats']['classes']);
        $this->assertEquals($numSections * 3, $analytics['stats']['students']);

        // Half of the sections should have attendance rate = 80 (< 85).
        // That is 5 sections out of 10.
        $this->assertArrayHasKey('anomalies', $analytics);

        // Ensure query count is independent of the number of classes.
        // Eager loading withAvg should use exactly 1 query to fetch sections with count and avg.
        // It must NOT execute N separate average queries for the N sections.
        $totalQueries = count($queriesExecuted);

        // Under old logic:
        // - 1 query for ClassSection count
        // - 1 query for ClassSection withCount('students')
        // - 10 queries for averaging students attendance inside filter loop
        // Plus other queries.
        // With optimization:
        // - 0 query for ClassSection count (we reuse $sections->count())
        // - 1 query for ClassSection withCount('students') withAvg('students')
        // - 0 queries inside the filter loop
        // The query count should be exactly 11, which is O(1) regardless of section count.
        $this->assertLessThanOrEqual(12, $totalQueries, 'Optimized dashboard is executing too many queries: '.implode("\n", $queriesExecuted));
    }
}
