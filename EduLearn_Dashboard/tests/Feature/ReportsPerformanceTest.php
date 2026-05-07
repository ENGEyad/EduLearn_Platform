<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\User;
use App\Models\School;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    // Removing RefreshDatabase to handle it manually since we have multiple connections
    // and some migrations use hardcoded connection names.

    protected function setUp(): void
    {
        parent::setUp();

        // Use sqlite in-memory for testing
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);

        // Mock app_mysql and mysql to use same sqlite in-memory
        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);
        config(['database.connections.mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);

        // Manually run migrations on the sqlite in-memory connection
        $this->artisan('migrate:fresh', ['--database' => 'sqlite']);

        // Create a school and an admin user
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@test.com',
            'status' => 'active'
        ]);

        $this->user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id
        ]);
    }

    /** @test */
    public function it_measures_query_count_for_reports_list()
    {
        // Seed 10 classes with 2 sections each (20 distinct grade/section pairs)
        // and 5 students per section (100 students total)
        for ($g = 1; $g <= 10; $g++) {
            foreach (['A', 'B'] as $section) {
                Student::factory()->count(5)->create([
                    'grade' => "Grade $g",
                    'class_section' => $section
                ]);
            }
        }

        $queryCount = 0;
        DB::listen(function ($query) use (&$queryCount) {
            $queryCount++;
        });

        $response = $this->actingAs($this->user)->getJson(route('reports.list'));

        $response->assertStatus(200);

        // Optimized:
        // 1 query for grouped classes with counts
        $this->assertEquals(1, $queryCount, "Normal list query count: $queryCount");

        echo "\n[Performance] Reports list query count: $queryCount\n";
    }

    /** @test */
    public function it_measures_query_count_for_reports_search()
    {
        // Seed some data
        for ($g = 1; $g <= 10; $g++) {
            foreach (['A', 'B'] as $section) {
                Student::factory()->count(2)->create([
                    'grade' => "Grade $g",
                    'class_section' => $section
                ]);
            }
        }

        $queryCount = 0;
        DB::listen(function ($query) use (&$queryCount) {
            $queryCount++;
        });

        // Search for something
        $response = $this->actingAs($this->user)->getJson(route('reports.list', ['search' => 'Student']));

        $response->assertStatus(200);

        // Optimized with search:
        // 1 query for grouped classes with search subquery
        // 1 query for matchingStudents collection
        // Total = 2 queries

        $this->assertEquals(2, $queryCount, "Search list query count: $queryCount");

        echo "\n[Performance] Reports search query count: $queryCount\n";
    }
}
