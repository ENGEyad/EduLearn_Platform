<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Services\DashboardAnalyticsService;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\DB;

class DashboardPerformanceTest extends BaseTestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';
        $app->make(Kernel::class)->bootstrap();

        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);
        config(['database.connections.mysql' => config('database.connections.sqlite')]);
        DB::extend('app_mysql', fn () => DB::connection('sqlite'));

        return $app;
    }

    public function test_build_overview_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-'.uniqid(),
            'email' => 'test'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Grade '.$i.' A',
                'name_en' => 'Grade '.$i.' A',
            ]);

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'Student '.$i,
                'academic_id' => 'STU'.$i.'_'.uniqid(),
                'attendance_rate' => 80.0,
            ]);
        }

        /** @var DashboardAnalyticsService $service */
        $service = app(DashboardAnalyticsService::class);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $result = $service->buildOverview($school->id, 'week');

        $log = DB::getQueryLog();
        fwrite(STDERR, "\n[QUERIES EXECUTED]:\n");
        foreach ($log as $index => $q) {
            fwrite(STDERR, ($index + 1).'. '.$q['query']."\n");
        }
        fwrite(STDERR, '[TOTAL QUERIES]: '.count($log)."\n");

        $this->assertEquals(10, $result['stats']['classes']);
    }
}
