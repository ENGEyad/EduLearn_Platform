<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Services\DashboardAnalyticsService;
use App\Services\DashboardInsightPayloadBuilder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardAnalyticsServiceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();

        // Dynamically map connections to sqlite memory to prevent dual-database connection issues during testing
        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));
        DB::extend('app_mysql', fn () => DB::connection('sqlite'));

        return $app;
    }

    public function test_build_overview_computes_stats_and_low_attendance_classes_efficiently(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher',
        ]);

        $sectionHigh = ClassSection::create([
            'school_id' => $school->id,
            'grade' => 'Grade 1',
            'section' => 'A',
            'name' => 'Grade 1 - A',
            'name_en' => 'Grade 1 - A',
        ]);

        $sectionLow = ClassSection::create([
            'school_id' => $school->id,
            'grade' => 'Grade 1',
            'section' => 'B',
            'name' => 'Grade 1 - B',
            'name_en' => 'Grade 1 - B',
        ]);

        Student::create([
            'school_id' => $school->id,
            'full_name' => 'High Attendance Student',
            'class_section_id' => $sectionHigh->id,
            'attendance_rate' => 95.0,
        ]);

        Student::create([
            'school_id' => $school->id,
            'full_name' => 'Low Attendance Student',
            'class_section_id' => $sectionLow->id,
            'attendance_rate' => 70.0,
        ]);

        // Track executed queries during buildOverview to ensure no N+1 query is fired for sections
        $queries = [];
        DB::listen(function ($query) use (&$queries) {
            $queries[] = $query->sql;
        });

        $service = new DashboardAnalyticsService(new DashboardInsightPayloadBuilder);
        $analytics = $service->buildOverview($school->id, 'week', $school->name);

        $this->assertEquals(2, $analytics['stats']['classes']);
        $this->assertEquals(2, $analytics['stats']['students']);
        $this->assertEquals(1, $analytics['stats']['teachers']);
        $this->assertContains('1 classes below the attendance threshold', $analytics['anomalies']);

        // Verify that no individual student query per section was executed
        $individualSectionAvgQueries = array_filter($queries, function ($sql) {
            return stripos($sql, 'avg("attendance_rate")') !== false && stripos($sql, '"class_section_id" =') !== false;
        });

        $this->assertEmpty($individualSectionAvgQueries, 'No N+1 queries per section should be executed.');
    }
}
