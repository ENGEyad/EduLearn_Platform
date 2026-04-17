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
        // Create 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $j of Class $i",
                    'academic_id' => "ACAD-$i-$j",
                    'grade' => "Grade $i",
                    'class_section' => "Section A",
                    'status' => 'Active',
                ]);
            }
        }

        DB::enableQueryLog();

        $response = $this->get(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // Optimized query count should be exactly 1 for the base list
        $response->assertStatus(200);
        $this->assertEquals(1, $queryCount);

        // Verify response structure and data
        $data = $response->json('data');
        $this->assertCount(10, $data);
        $this->assertEquals(5, $data[0]['students_count']);
    }

    public function test_reports_list_with_search_performance()
    {
        // Create some data
        Student::create([
            'full_name' => "John Doe",
            'academic_id' => "ACAD-1",
            'grade' => "Grade 1",
            'class_section' => "Section A",
            'status' => 'Active',
        ]);

        DB::enableQueryLog();

        // Searching for "John"
        $response = $this->get(route('reports.list') . '?search=John');

        $queries = DB::getQueryLog();
        // 1 query for classes, 1 query for matching students = 2 queries
        $queryCount = count($queries);

        $response->assertStatus(200);
        $this->assertLessThanOrEqual(3, $queryCount); // Allowing some wiggle room for potential middleware/auth queries
        $this->assertCount(1, $response->json('data'));
        $this->assertCount(1, $response->json('students'));
    }
}
