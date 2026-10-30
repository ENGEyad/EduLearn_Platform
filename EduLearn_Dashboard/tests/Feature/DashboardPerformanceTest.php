<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Services\DashboardAnalyticsService;
use App\Services\DashboardInsightPayloadBuilder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        DB::extend('app_mysql', function () {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_build_overview_executes_fixed_queries_regardless_of_class_section_count(): void
    {
        $school = School::create([
            'name' => 'Performance Test School',
            'slug' => 'perf-test-school',
            'email' => 'admin@perftest.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // Create 20 class sections with students
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade 1',
                'section' => "Sec $i",
                'name' => "Section $i",
                'name_en' => "Section $i",
                'is_active' => true,
            ]);

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => "Student $i",
                'academic_id' => "STD-$i",
                'attendance_rate' => 80.0,
            ]);
        }

        $service = new DashboardAnalyticsService(new DashboardInsightPayloadBuilder);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $overview = $service->buildOverview($school->id, 'week', $school->name);

        $queryCount = count(DB::getQueryLog());

        $this->assertEquals(20, $overview['stats']['classes']);
        $this->assertEquals(20, $overview['stats']['students']);

        // Prior to optimization, 20 sections resulted in 30+ queries (1 query per section for attendance).
        // With optimization, total queries are 11.
        $this->assertLessThanOrEqual(13, $queryCount, "Query count was {$queryCount}, expected 13 or fewer queries.");
    }
}
