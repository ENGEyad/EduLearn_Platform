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
        $user = User::create([
            'name' => 'Test User',
            'email' => 'test' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
        ]);

        // Create 10 class sections with 1 student each
        for ($i = 1; $i <= 10; $i++) {
            Student::create([
                'full_name' => "Student $i",
                'academic_id' => "ACAD-$i",
                'grade' => "Grade $i",
                'class_section' => "Section A",
            ]);
        }

        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);

        // Should be around 1 query for data (and maybe 1 for session/auth)
        // Baseline was 11. Optimized should be much less and constant.
        $this->assertLessThan(5, $queryCount, "Expected optimized constant queries. Found: $queryCount");

        fwrite(STDERR, "\nOptimized Query Count: $queryCount\n");

        $response->assertJsonCount(10, 'data');
    }

    public function test_list_with_search_performance_optimized()
    {
        $user = User::create([
            'name' => 'Test User',
            'email' => 'test' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
        ]);

        for ($i = 1; $i <= 10; $i++) {
            Student::create([
                'full_name' => "Student $i",
                'academic_id' => "ACAD-S-$i",
                'grade' => "Grade $i",
                'class_section' => "Section A",
            ]);
        }

        DB::enableQueryLog();

        // Search that matches a class name
        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 1']));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);
        $this->assertLessThan(5, $queryCount, "Expected optimized constant queries with search. Found: $queryCount");

        fwrite(STDERR, "\nOptimized Search Query Count: $queryCount\n");

        // "Grade 1 - Section A" should match
        $response->assertJsonFragment(['grade' => 'Grade 1', 'class_section' => 'Section A', 'students_count' => 1]);
    }
}
