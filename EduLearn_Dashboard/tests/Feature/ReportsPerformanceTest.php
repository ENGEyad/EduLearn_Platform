<?php

namespace Tests\Feature;

use App\Models\Student;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we are using sqlite in memory for both connections during tests
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);
    }

    public function test_list_endpoint_performance()
    {
        // Create 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            Student::factory()->count(5)->create([
                'grade' => "Grade $i",
                'class_section' => 'A'
            ]);
        }

        DB::flushQueryLog();
        DB::connection('mysql')->enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $response->assertStatus(200);
        $queries = DB::connection('mysql')->getQueryLog();

        // Before optimization, it was at least 1 (list classes) + 10 (count students per class) = 11 queries.
        // We aim for 1 query (or a small constant number).
        $this->assertLessThan(11, count($queries), "Too many queries: " . count($queries));

        $data = $response->json('data');
        $this->assertCount(10, $data);
        foreach ($data as $item) {
            $this->assertEquals(5, $item['students_count']);
        }
    }

    public function test_list_endpoint_with_search_performance()
    {
        // Create some data
        Student::factory()->create([
            'full_name' => 'Specific Student Name',
            'grade' => 'Grade 1',
            'class_section' => 'A'
        ]);

        Student::factory()->count(20)->create();

        DB::flushQueryLog();
        DB::connection('mysql')->enableQueryLog();

        $response = $this->getJson(route('reports.list', ['search' => 'Specific Student Name']));

        $response->assertStatus(200);
        $queries = DB::connection('mysql')->getQueryLog();

        // We want to ensure search doesn't trigger N+1 either
        $this->assertLessThan(10, count($queries), "Search triggered too many queries: " . count($queries));

        $students = $response->json('students');
        $this->assertNotEmpty($students);
        $this->assertEquals('Specific Student Name', $students[0]['full_name']);
    }
}
