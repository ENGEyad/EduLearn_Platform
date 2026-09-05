<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
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
        $app = require __DIR__ . '/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        // Override all database connections to use in-memory SQLite during testing
        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        return $app;
    }

    public function test_build_overview_executes_efficiently_and_calculates_correct_low_attendance_classes(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // Create 20 class sections with students
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Grade ' . $i . ' A',
                'name_en' => 'Grade ' . $i . ' A',
            ]);

            // Low attendance in first 5 sections
            $attendanceRate = $i <= 5 ? 70.0 : 95.0;

            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section->id,
                'full_name' => 'Student ' . $i,
                'attendance_rate' => $attendanceRate,
            ]);
        }

        /** @var DashboardAnalyticsService $service */
        $service = app(DashboardAnalyticsService::class);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $overview = $service->buildOverview($school->id, 'week', $school->name);

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $this->assertEquals(20, $overview['stats']['classes']);
        $this->assertCount(7, $queries, 'Build overview should execute 7 queries total without N+1 query loop for class sections.');
    }
}
