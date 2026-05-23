<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_query_count()
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
            'name' => 'Admin User',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 20 class sections with students
        for ($i = 0; $i < 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . ($i + 1),
                'section' => 'A',
                'name' => 'Class ' . ($i + 1),
            ]);

            for ($j = 0; $j < 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ACAD-$i-$j",
                    'attendance_rate' => rand(70, 100),
                ]);
            }
        }

        $this->actingAs($user);

        // Warm up cache or ensure it's cleared (DashboardController uses Cache::remember)
        $this->get('/dashboard');

        // Measure queries
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get('/dashboard');

        $response->assertStatus(200);
        $queryCount = count(DB::getQueryLog());

        // Currently, it's expected to have an N+1 issue for attendance calculation
        // for 20 sections, we expect at least 20 queries + other queries.
        // Once optimized, it should be much lower.
        // Logging for now to see the baseline.
        echo "\nQuery count for dashboard index (after optimization): $queryCount\n";

        // Baseline was 37. Optimized should be around 11-15.
        $this->assertLessThan(20, $queryCount, "Query count should be significantly lower after optimization");
    }
}
