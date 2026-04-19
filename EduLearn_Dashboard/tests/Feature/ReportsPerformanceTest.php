<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\ClassSection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
    }

    /**
     * Override to migrate both connections
     */
    protected function refreshTestDatabase()
    {
        // Use the connection named 'mysql' for migrations, but make sure it uses sqlite :memory:
        config(['database.connections.mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);

        // Define app_mysql too
        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);

        // Set default connection to mysql for the migration process
        \Illuminate\Support\Facades\DB::setDefaultConnection('mysql');

        $this->artisan('migrate:fresh');

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_list_performance()
    {
        // Seed 20 classes
        for ($i = 1; $i <= 20; $i++) {
            $grade = "Grade $i";
            $section = "A";

            // Seed 10 students per class
            Student::factory()->count(10)->create([
                'grade' => $grade,
                'class_section' => $section,
            ]);
        }

        DB::enableQueryLog();
        $startTime = microtime(true);

        $response = $this->getJson(route('reports.list'));

        $endTime = microtime(true);
        $queries = DB::getQueryLog();
        $queryCount = count($queries);
        $duration = ($endTime - $startTime) * 1000;

        $response->assertStatus(200);

        echo "\nPerformance Results for 20 classes (200 students):\n";
        echo "Query Count: $queryCount\n";
        echo "Duration: " . round($duration, 2) . "ms\n";

        // Optimized expectation: constant number of queries (1)
        $this->assertLessThanOrEqual(2, $queryCount, "Expected optimized constant query count");
    }

    public function test_list_performance_with_search()
    {
        // Seed 10 classes
        for ($i = 1; $i <= 10; $i++) {
            $grade = "Grade $i";
            $section = "A";
            Student::factory()->count(10)->create([
                'grade' => $grade,
                'class_section' => $section,
            ]);
        }

        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'nonexistent']));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);

        echo "\nPerformance Results with search (10 classes):\n";
        echo "Query Count: $queryCount\n";

        // Optimized expectation: constant number of queries (2: one for grouped classes, one for matching students)
        $this->assertLessThanOrEqual(3, $queryCount, "Expected optimized constant query count with search");
    }
}
