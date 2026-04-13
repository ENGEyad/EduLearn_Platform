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

    public function test_list_performance_optimized()
    {
        // Seed 10 classes with 2 sections each = 20 classes
        for ($i = 1; $i <= 10; $i++) {
            $grade = "Grade $i";
            for ($j = 1; $j <= 2; $j++) {
                $section = "Section $j";
                Student::factory()->count(5)->create([
                    'grade' => $grade,
                    'class_section' => $section,
                ]);
            }
        }

        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nOptimized Query Count for 20 classes: " . $queryCount . "\n";

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        // After optimization, it should be exactly 1 query (grouped count)
        $this->assertEquals(1, $queryCount, "Optimized query count should be 1");
    }

    public function test_list_performance_with_search_optimized()
    {
        // Seed some data
        Student::factory()->create(['full_name' => 'Searchable Student', 'grade' => 'G1', 'class_section' => 'S1']);
        Student::factory()->count(10)->create(['grade' => 'G2', 'class_section' => 'S2']);

        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list', ['search' => 'Searchable']));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nOptimized Query Count with search: " . $queryCount . "\n";

        $response->assertStatus(200);

        // 1 query for grouped classes + 1 query for matching students
        $this->assertEquals(2, $queryCount, "Optimized query count with search should be 2");
    }
}
