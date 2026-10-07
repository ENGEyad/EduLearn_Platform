<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
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

        $sqliteConfig = [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ];

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite' => $sqliteConfig,
            'database.connections.mysql' => $sqliteConfig,
            'database.connections.app_mysql' => $sqliteConfig,
        ]);

        DB::extend('app_mysql', function () {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_dashboard_analytics_service_build_overview_performance()
    {
        $school = School::create([
            'name' => 'Performance Test School',
            'slug' => 'perf-school',
            'email' => 'perf@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 class sections with students
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => '10',
                'section' => "Sec {$i}",
                'name' => "Grade 10 Sec {$i}",
                'name_en' => "Grade 10 Sec {$i}",
            ]);

            // Low attendance in odd sections (70%), high in even (90%)
            $attendance = ($i % 2 === 0) ? 90.0 : 70.0;

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => "Student {$i}",
                'academic_id' => "STU-{$i}",
                'grade' => '10',
                'class_section' => "Sec {$i}",
                'attendance_rate' => $attendance,
            ]);
        }

        Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Teacher 1',
            'teacher_code' => 'T-001',
        ]);

        $analyticsService = app(DashboardAnalyticsService::class);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $result = $analyticsService->buildOverview($school->id, 'week', $school->name);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // Verify query count is low and not N+1 (11 queries vs 32+ queries)
        $this->assertLessThanOrEqual(15, $queryCount, "Query count {$queryCount} exceeds 15, possible N+1 query issue.");

        // Verify correctness
        $this->assertEquals(20, $result['stats']['classes']);
        $this->assertEquals(20, $result['stats']['students']);
        $this->assertEquals(1, $result['stats']['teachers']);
        // 10 odd sections with 70% attendance (< 85%)
        $this->assertContains('10 classes below the attendance threshold', $result['anomalies']);
    }
}
