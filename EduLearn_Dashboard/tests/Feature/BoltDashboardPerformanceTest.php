<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\User;
use App\Models\ClassSection;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\AiReport;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltDashboardPerformanceTest extends TestCase
{
    // We don't use RefreshDatabase because we have a custom dual-connection setup
    // and manual migrations already handled.

    protected function setUp(): void
    {
        parent::setUp();

        DB::connection('mysql')->table('users')->delete();
        DB::connection('mysql')->table('schools')->delete();
        DB::connection('mysql')->table('class_sections')->delete();
        DB::connection('mysql')->table('students')->delete();
        DB::connection('mysql')->table('teachers')->delete();
        DB::connection('mysql')->table('subjects')->delete();
        DB::connection('mysql')->table('ai_reports')->delete();
    }

    public function test_dashboard_index_query_count()
    {
        $school = School::create([
            'name' => 'Bolt Performance Academy',
            'slug' => 'bolt-academy',
            'email' => 'bolt@academy.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Flash Gordon',
            'email' => 'flash@example.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => "Grade $i - A",
                'is_active' => true,
            ]);

            // Create 5 students per section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'first_name' => "Student",
                    'last_name' => "$i-$j",
                    'academic_id' => "ACAD-$i-$j",
                    'attendance_rate' => 90,
                ]);
            }
        }

        AiReport::create([
            'school_id' => $school->id,
            'user_id' => $user->id,
            'title' => 'Test Report',
            'status' => 'completed',
            'dashboard_summary' => 'Everything is fast!',
        ]);

        $this->actingAs($user);

        // Enable query logging
        DB::connection('mysql')->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        $response = $this->get('/dashboard');

        $response->assertStatus(200);

        $queries_mysql = DB::connection('mysql')->getQueryLog();
        $queries_app_mysql = DB::connection('app_mysql')->getQueryLog();

        $total_queries = count($queries_mysql) + count($queries_app_mysql);

        echo "\nTotal Queries for Dashboard: " . $total_queries . "\n";

        // Assert that the total queries are within the optimized threshold.
        // Pre-optimization was 32 queries for 10 class sections.
        // Post-optimization is 20 queries.
        $this->assertLessThan(21, $total_queries, "Dashboard query count is too high!");
        foreach ($queries_mysql as $q) {
            echo "[mysql] " . $q['query'] . "\n";
        }
        foreach ($queries_app_mysql as $q) {
            echo "[app_mysql] " . $q['query'] . "\n";
        }

        // We will assert against this number later after optimization
        // Baseline for 10 class sections:
        // 1. Session user
        // 2. School relation
        // 3. AiReport latest (repeated?)
        // 4. Student pluck IDs
        // 5. ClassSection withCount
        // 6. StudentExerciseAttempt avg overall
        // 7. Student attendance avg overall
        // 8. Teacher count
        // 9. ClassSection count (redundant)
        // 10. Subject count
        // 11. Student count (for dangling)
        // 12. StudentExerciseAttempt avg current period
        // 13. StudentExerciseAttempt avg previous period
        // 14. Student low attendance count
        // 15. Student low performance count
        // 16-25. Student avg attendance for EACH section (N+1 bottleneck)
    }
}
