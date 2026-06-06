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

class BoltPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_analytics_query_count()
    {
        // Setup
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'name' => 'Grade ' . $i . ' A',
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'is_active' => true,
            ]);

            // Create 5 students per section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'first_name' => "Student $i-$j",
                    'last_name' => "Last",
                    'full_name' => "Student $i-$j Last",
                    'academic_id' => "ACAD-$i-$j",
                    'attendance_rate' => 80 + $j, // Some will be below 85
                ]);
            }
        }

        $service = app(DashboardAnalyticsService::class);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $service->buildOverview($school->id, 'week', $school->name);

        $queryCount = count(DB::getQueryLog());

        // Output query count for confirmation
        echo "\nFinal Query Count: $queryCount\n";

        // With 10 sections, the unoptimized lowAttendanceClasses should add 10 queries.
        // Total expected: baseline + 10
        $this->assertLessThan(15, $queryCount, "Query count is too high: $queryCount");
    }
}
