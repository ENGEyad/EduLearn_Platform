<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();

        // Dynamically override DB connections for dual-database SQLite in-memory testing
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        DB::extend('app_mysql', function () {
            return DB::connection('sqlite');
        });
        DB::extend('mysql', function () {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_reports_list_executes_minimal_queries_for_multiple_classes(): void
    {
        $school = School::create([
            'name' => 'Test Performance School',
            'slug' => 'test-perf-school-' . uniqid(),
            'email' => 'school-' . uniqid() . '@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin-' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 distinct classes (10 grades x 2 sections) with 2 students each
        for ($g = 1; $g <= 10; $g++) {
            foreach (['A', 'B'] as $sec) {
                for ($s = 1; $s <= 2; $s++) {
                    Student::create([
                        'school_id' => $school->id,
                        'academic_id' => 'STU-' . $g . $sec . $s . '-' . uniqid(),
                        'full_name' => "Student {$g}-{$sec}-{$s}",
                        'grade' => "Grade {$g}",
                        'class_section' => $sec,
                        'attendance_rate' => 90.0,
                    ]);
                }
            }
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        $queryCount = count(DB::getQueryLog());

        // Standard list without search must execute in at most 2 queries (1 main group by query + session query)
        $this->assertLessThanOrEqual(2, $queryCount, "ReportsController::list executed {$queryCount} queries, expected <= 2");

        // Test search mode query count
        DB::flushQueryLog();
        $searchResponse = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 1']));

        $searchResponse->assertStatus(200);
        $searchQueryCount = count(DB::getQueryLog());

        // Search mode must execute in at most 3 queries
        $this->assertLessThanOrEqual(3, $searchQueryCount, "ReportsController::list with search executed {$searchQueryCount} queries, expected <= 3");
    }
}
