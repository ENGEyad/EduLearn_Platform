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

    public function test_dashboard_analytics_service_query_count_is_optimized()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@testschool.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Grade ' . $i . ' A',
            ]);

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'Student ' . $i,
                'academic_id' => 'STU' . $i,
                'attendance_rate' => 80 + $i,
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $service = app(DashboardAnalyticsService::class);
        $result = $service->buildOverview($school->id, 'week', $school->name);

        $queryCount = count(DB::getQueryLog());

        $this->assertEquals(10, $result['stats']['classes']);
        // Verify that query count stays flat and low (without N+1 query loop for 10 class sections)
        $this->assertLessThanOrEqual(15, $queryCount);
    }
}
