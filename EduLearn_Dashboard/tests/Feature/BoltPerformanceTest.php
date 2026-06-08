<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    // We'll handle database state manually to avoid dual-connection SQLite issues with RefreshDatabase
    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we are using a clean state for the connections we care about
        // This is a bit hacky but necessary for this environment
        if (config('database.default') === 'mysql' && config('database.connections.mysql.driver') === 'sqlite') {
            \Illuminate\Support\Facades\Schema::connection('mysql')->dropAllTables();
            \Illuminate\Support\Facades\Schema::connection('app_mysql')->dropAllTables();

            $this->artisan('migrate', ['--force' => true]);
        }
    }

    public function test_dashboard_analytics_performance()
    {
        // Setup data
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Grade '.$i.' A',
                'is_active' => true,
            ]);

            // Create 5 students per section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'first_name' => "Student $i-$j",
                    'last_name' => 'Last',
                    'full_name' => "Student $i-$j Last",
                    'academic_id' => "ID-$i-$j",
                    'attendance_rate' => 80 + $i, // Some will be below 85
                    'grade' => 'Grade '.$i,
                    'class_section' => 'A',
                ]);
            }
        }

        $this->actingAs($user);

        // Clear cache to ensure we are actually running the service
        \Illuminate\Support\Facades\Cache::flush();

        DB::enableQueryLog();
        $startTime = microtime(true);

        $response = $this->get(route('dashboard'));

        $endTime = microtime(true);
        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);

        echo "\nTotal Queries for Dashboard: ".$queryCount."\n";
        echo 'Execution Time: '.round(($endTime - $startTime) * 1000, 2)."ms\n";

        // With 10 sections, we expect at least 10 queries for attendance in the loop
        // Plus other queries (auth, school, subjects, stats, etc.)
        // Baseline should be around 20-30 queries
    }
}
