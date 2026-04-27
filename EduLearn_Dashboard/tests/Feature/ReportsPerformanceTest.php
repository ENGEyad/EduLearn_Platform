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

    protected function setUp(): void
    {
        parent::setUp();
    }

    protected function refreshTestDatabase()
    {
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

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_reports_list_query_count()
    {
        $user = User::factory()->create();

        // Create 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $j Class $i",
                    'academic_id' => "S100$i$j",
                    'grade' => "Grade $i",
                    'class_section' => "A",
                    'status' => 'Active'
                ]);
            }
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\n[Optimized] Total queries for 10 classes: $queryCount\n";

        $response->assertStatus(200);
        // Optimized: Should be 1 query (grouped count)
        $this->assertLessThanOrEqual(2, $queryCount, "Expected at most 2 queries in optimized version");

        $data = $response->json('data');
        $this->assertCount(10, $data);
        $this->assertEquals(5, $data[0]['students_count']);
        $this->assertIsInt($data[0]['students_count']);
    }

    public function test_reports_list_with_search_query_count()
    {
        $user = User::factory()->create();

        // Create 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $j Class $i",
                    'academic_id' => "S100$i$j",
                    'grade' => "Grade $i",
                    'class_section' => "A",
                    'status' => 'Active'
                ]);
            }
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 1 - A']));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\n[Optimized] Total queries for 10 classes with search: $queryCount\n";

        $response->assertStatus(200);
        // Optimized: Should be max 2 queries (1 for classes, 1 for matching students)
        $this->assertLessThanOrEqual(3, $queryCount, "Expected at most 3 queries in optimized version with search");

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('Grade 1', $data[0]['grade']);
    }
}
