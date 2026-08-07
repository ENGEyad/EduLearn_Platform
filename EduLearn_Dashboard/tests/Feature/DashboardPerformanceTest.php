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

        // Override database connections to sqlite in-memory for testing
        $app['config']->set('database.connections.mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);

        $app['config']->set('database.connections.app_mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);

        $app['config']->set('database.default', 'mysql');

        return $app;
    }

    public function test_dashboard_analytics_avoids_n_plus_one_queries()
    {
        // 1. Setup School
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'approved',
        ]);

        // 2. Setup multiple Class Sections
        $sections = [];
        for ($i = 1; $i <= 5; $i++) {
            $sections[] = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Grade '.$i.' Section A',
                'name_en' => 'Grade '.$i.' Section A',
            ]);
        }

        // 3. Create Students and associate with sections
        foreach ($sections as $section) {
            for ($j = 1; $j <= 3; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student {$j} in Section {$section->id}",
                    'academic_id' => 'ACAD-'.uniqid(),
                    'class_section_id' => $section->id,
                    'attendance_rate' => 90.0,
                    'gender' => 'Male',
                    'birthdate' => '2010-01-01',
                    'guardian_name' => 'Guardian',
                    'guardian_phone' => '1234567890',
                ]);
            }
        }

        $analyticsService = app(DashboardAnalyticsService::class);

        // Record queries when running with 5 sections
        DB::flushQueryLog();
        DB::enableQueryLog();

        $analyticsService->buildOverview($school->id, 'week', $school->name);

        $queriesCountFor5 = count(DB::getQueryLog());
        DB::disableQueryLog();

        // 4. Create more Class Sections to test scalability
        for ($i = 6; $i <= 15; $i++) {
            $newSection = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Grade '.$i.' Section A',
                'name_en' => 'Grade '.$i.' Section A',
            ]);

            for ($j = 1; $j <= 3; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student {$j} in Section {$newSection->id}",
                    'academic_id' => 'ACAD-'.uniqid(),
                    'class_section_id' => $newSection->id,
                    'attendance_rate' => 90.0,
                    'gender' => 'Male',
                    'birthdate' => '2010-01-01',
                    'guardian_name' => 'Guardian',
                    'guardian_phone' => '1234567890',
                ]);
            }
        }

        // Record queries with 15 sections
        DB::flushQueryLog();
        DB::enableQueryLog();

        $analyticsService->buildOverview($school->id, 'week', $school->name);

        $queriesCountFor15 = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Assert that the number of queries is independent of the number of sections (O(1) complexity)
        $this->assertEquals($queriesCountFor5, $queriesCountFor15, "Query count increased from {$queriesCountFor5} to {$queriesCountFor15}, indicating an N+1 query problem.");
    }
}
