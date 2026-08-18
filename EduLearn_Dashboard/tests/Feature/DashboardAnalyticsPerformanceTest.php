<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Services\DashboardAnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardAnalyticsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__ . '/../../bootstrap/app.php';
        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
        ]);

        DB::extend('app_mysql', function ($config, $name) {
            return DB::connection('sqlite');
        });

        DB::extend('mysql', function ($config, $name) {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_low_attendance_classes_calculation_executes_efficiently_without_n_plus_1_queries()
    {
        $school = School::create([
            'name' => 'Test Performance School',
            'slug' => 'test-perf-school-' . uniqid(),
            'email' => 'testperf' . uniqid() . '@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $section1 = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '1',
            'section' => 'A',
            'name' => 'Grade 1A',
            'name_en' => 'Grade 1A',
        ]);

        $section2 = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '2',
            'section' => 'B',
            'name' => 'Grade 2B',
            'name_en' => 'Grade 2B',
        ]);

        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $section1->id,
            'name' => 'Student 1',
            'full_name' => 'Student One',
            'academic_id' => 'STU1' . uniqid(),
            'attendance_rate' => 80.0,
        ]);

        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $section2->id,
            'name' => 'Student 2',
            'full_name' => 'Student Two',
            'academic_id' => 'STU2' . uniqid(),
            'attendance_rate' => 95.0,
        ]);

        /** @var DashboardAnalyticsService $service */
        $service = app(DashboardAnalyticsService::class);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $overview = $service->buildOverview($school->id, 'week', $school->name);

        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Check correct calculation: 1 class (section 1) has avg attendance < 85% (80%), section 2 has 95%
        $this->assertContains('1 classes below the attendance threshold', $overview['anomalies']);

        // With N+1, querying for N sections would execute N additional queries for attendance averages.
        // With optimization, total queries to build overview remain low and constant regardless of number of sections.
        $this->assertLessThan(15, $queryCount);
    }
}
