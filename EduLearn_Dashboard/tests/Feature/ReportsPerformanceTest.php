<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function refreshTestDatabase()
    {
        // Ensure connections are set to sqlite
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        \Illuminate\Support\Facades\DB::purge('mysql');
        \Illuminate\Support\Facades\DB::purge('app_mysql');

        // Running migrate:fresh once should handle all tables since we switched all to sqlite :memory:
        $this->artisan('migrate:fresh');

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    protected function setUp(): void
    {
        parent::setUp();

        // Create a user and authenticate
        $user = User::factory()->create([
            'email' => 'admin@edulearn.com',
            'password' => bcrypt('password'),
        ]);
        $this->actingAs($user);
    }

    /**
     * Measure query count for ReportsController::list
     */
    public function test_reports_list_performance()
    {
        // Setup 20 classes with 2 students each
        for ($i = 1; $i <= 20; $i++) {
            Student::factory()->count(2)->create([
                'grade' => "Grade $i",
                'class_section' => 'A',
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $startTime = microtime(true);
        $response = $this->getJson(route('reports.list'));
        $endTime = microtime(true);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);
        $duration = ($endTime - $startTime) * 1000;

        echo "\nReports List Performance (No Search):\n";
        echo "Query Count: $queryCount\n";
        echo "Duration: " . round($duration, 2) . "ms\n";

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        // If query count is > 20, it confirms N+1
        $this->assertLessThan(40, $queryCount, "Too many queries detected in Reports list!");
    }

    /**
     * Measure query count for ReportsController::list with search
     */
    public function test_reports_list_search_performance()
    {
        // Setup 20 classes
        for ($i = 1; $i <= 20; $i++) {
            Student::factory()->create([
                'grade' => "Grade $i",
                'class_section' => 'A',
                'full_name' => "Student $i",
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $startTime = microtime(true);
        $response = $this->getJson(route('reports.list', ['search' => 'Student 1']));
        $endTime = microtime(true);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);
        $duration = ($endTime - $startTime) * 1000;

        echo "\nReports List Performance (With Search):\n";
        echo "Query Count: $queryCount\n";
        echo "Duration: " . round($duration, 2) . "ms\n";

        $response->assertStatus(200);

        // If query count is high, it confirms N+1 in search too
        $this->assertLessThan(60, $queryCount, "Too many queries detected in Reports search!");
    }
}
