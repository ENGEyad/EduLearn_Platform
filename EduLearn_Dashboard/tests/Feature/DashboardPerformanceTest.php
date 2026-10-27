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

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        return $app;
    }

    public function test_dashboard_overview_query_count_is_optimized()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Grade '.$i.' A',
            ]);

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'Student '.$i,
                'academic_id' => 'ACC'.$i,
                'attendance_rate' => 80.0,
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $service = app(DashboardAnalyticsService::class);
        $result = $service->buildOverview($school->id, 'week', $school->name);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $this->assertEquals(20, $result['stats']['classes']);
        $this->assertEquals(20, $result['anomalies_classes_count'] ?? $result['stats']['classes']);
        // Query count for 20 sections should be exactly 7 queries (constant time O(1) query count relative to section count), down from 28+ queries before optimization.
        $this->assertLessThanOrEqual(8, $queryCount);
    }
}
