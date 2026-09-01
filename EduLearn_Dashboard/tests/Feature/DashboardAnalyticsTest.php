<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Services\DashboardAnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardAnalyticsTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config([
            'database.default' => 'mysql',
            'database.connections.mysql.driver' => 'sqlite',
            'database.connections.mysql.database' => ':memory:',
        ]);

        DB::extend('app_mysql', function () {
            return DB::connection('mysql');
        });

        return $app;
    }

    public function test_build_overview_calculates_low_attendance_classes_with_fixed_queries(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'name' => 'Section '.$i,
                'name_en' => 'Section '.$i,
                'grade' => 'Grade '.$i,
                'section' => 'A',
            ]);

            $attendance = ($i <= 2) ? 75.0 : 90.0;
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'Student '.$i,
                'attendance_rate' => $attendance,
            ]);
        }

        /** @var DashboardAnalyticsService $service */
        $service = app(DashboardAnalyticsService::class);

        DB::enableQueryLog();
        $overview = $service->buildOverview($school->id, 'week', $school->name);
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $anomalies = $overview['anomalies'];
        $hasLowAttendanceClassesAnomaly = false;
        foreach ($anomalies as $anomaly) {
            if (str_contains($anomaly, '2 classes below the attendance threshold')) {
                $hasLowAttendanceClassesAnomaly = true;
                break;
            }
        }

        $this->assertTrue($hasLowAttendanceClassesAnomaly, 'Should correctly identify 2 low attendance classes.');
        $this->assertLessThanOrEqual(13, count($queries), 'Query count should remain constant without N+1 queries per section.');
    }
}
