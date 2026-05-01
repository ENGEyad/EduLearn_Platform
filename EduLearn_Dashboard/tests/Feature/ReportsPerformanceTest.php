<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\ClassSection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Contracts\Console\Kernel;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function refreshTestDatabase()
    {
        // Override connections to use sqlite :memory: BEFORE migrations run
        config(['database.connections.mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);
        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);

        $this->artisan('migrate:fresh');

        $this->app[Kernel::class]->setArtisan(null);
    }

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure connections are still overridden for the test execution
        config(['database.connections.mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);
        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);
    }

    /**
     * Test query count for ReportsController::list
     */
    public function test_list_query_count()
    {
        // 1. Seed 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            $grade = "Grade $i";
            $section = "A";

            Student::factory()->count(5)->create([
                'grade' => $grade,
                'class_section' => $section,
            ]);
        }

        // 2. Measure query count
        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        // Currently it does:
        // 1 query to get distinct classes
        // 10 queries to count students for each class
        // Total should be around 11 queries without search

        $queryCount = count($queries);
        dump("Query count for 10 classes: " . $queryCount);

        // Optimized: Should be exactly 1 query
        $this->assertEquals(1, $queryCount);
    }

    /**
     * Test search performance
     */
    public function test_search_query_count()
    {
        // Seed some data
        Student::factory()->create([
            'full_name' => 'John Doe',
            'grade' => 'Grade 1',
            'class_section' => 'A',
        ]);

        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'John']));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);
        $queryCount = count($queries);
        dump("Query count for search: " . $queryCount);

        // Optimized: Should be exactly 2 queries (one for classes, one for matching students)
        $this->assertEquals(2, $queryCount);

        // Verify data structure and content
        $data = $response->json();
        $this->assertCount(1, $data['data']);
        $this->assertEquals('Grade 1', $data['data'][0]['grade']);
        $this->assertEquals(1, $data['data'][0]['students_count']);
        $this->assertCount(1, $data['students']);
        $this->assertEquals('John Doe', $data['students'][0]['full_name']);
    }
}
