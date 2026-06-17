<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use App\Models\Teacher;
use App\Models\Subject;
use App\Models\StudentExerciseAttempt;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_index_query_count()
    {
        // 1. Setup Data
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

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Grade ' . $i . ' A',
                'is_active' => true,
            ]);

            // Create 5 students per section to have some data for averages
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ACAD-$i-$j",
                    'attendance_rate' => 80 + $j, // Some below 85, some above
                ]);
            }
        }

        $this->actingAs($user);

        // 2. Measure Queries
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('dashboard'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // 3. Assertions
        $response->assertStatus(200);

        // Log the query count for reference
        echo "\nDashboard Index Query Count: " . $queryCount . "\n";

        // Baseline was around 28 queries for 10 sections in memory.
        // We expect it to be higher before optimization.
    }
}
