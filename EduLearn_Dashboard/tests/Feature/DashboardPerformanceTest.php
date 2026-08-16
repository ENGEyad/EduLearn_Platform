<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Services\DashboardAnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__ . '/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
            'database.connections.mysql' => config('database.connections.sqlite'),
            'database.connections.app_mysql' => config('database.connections.sqlite'),
        ]);

        DB::extend('app_mysql', function ($config, $name) {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_dashboard_analytics_service_executes_efficiently_without_n_plus_one_queries()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-' . uniqid(),
            'email' => 'test' . uniqid() . '@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher',
        ]);

        // Create 20 class sections
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Class ' . $i,
                'name_en' => 'Class En ' . $i,
            ]);

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'Student ' . $i,
                'academic_id' => 'STU' . $i . '_' . uniqid(),
                'attendance_rate' => 80.0,
            ]);
        }

        DB::enableQueryLog();

        /** @var DashboardAnalyticsService $service */
        $service = app(DashboardAnalyticsService::class);
        $overview = $service->buildOverview($school->id, 'week', $school->name);

        $executedQueries = DB::getQueryLog();
        DB::disableQueryLog();

        $this->assertEquals(20, $overview['stats']['classes']);
        // Query log count should be strictly small and constant regardless of class sections count (O(1) database queries wrt class count)
        $this->assertLessThan(15, count($executedQueries), 'Dashboard overview generated too many database queries! Query count: ' . count($executedQueries));
    }
}
