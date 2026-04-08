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
    use RefreshDatabase;

    public function test_reports_list_query_count()
    {
        // Setup: Create a school and a user
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'status' => 'active',
            'email' => 'school@test.com',
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
        ]);

        // Seed students in 10 different classes (Grade/Section combinations)
        for ($i = 1; $i <= 10; $i++) {
            Student::create([
                'full_name' => "Student $i-1",
                'academic_id' => "S$i-1",
                'grade' => "Grade $i",
                'class_section' => "Section 1",
                'status' => 'Active',
            ]);
            Student::create([
                'full_name' => "Student $i-2",
                'academic_id' => "S$i-2",
                'grade' => "Grade $i",
                'class_section' => "Section 1",
                'status' => 'Active',
            ]);
        }

        // Ensure we are logged in if middleware requires it
        $this->actingAs($user);

        // Enable query log
        DB::enableQueryLog();

        // Execution
        $response = $this->getJson(route('reports.list'));

        // Assertions
        $response->assertStatus(200);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // Current implementation is expected to have N+1 issue.
        // There are 10 classes. Each class triggers a count query in the loop.
        // Plus the initial distinct query.

        dump("Total queries for reports.list: " . $queryCount);

        // After optimization, it should be exactly 1 query (grouped count)
        $this->assertEquals(1, $queryCount, "Expected optimized query count to be 1");

        // Verify data integrity
        $data = $response->json('data');
        $this->assertCount(10, $data);
        foreach ($data as $item) {
            $this->assertEquals(2, $item['students_count'], "Each class should have 2 students");
        }
    }

    public function test_reports_list_search_performance()
    {
        $school = School::create(['name' => 'Test', 'slug' => 'test', 'status' => 'active', 'email' => 't@t.com']);
        $user = User::factory()->create(['school_id' => $school->id]);

        Student::create(['full_name' => 'John Doe', 'academic_id' => 'JD001', 'grade' => 'Grade 1', 'class_section' => 'A']);
        Student::create(['full_name' => 'Jane Smith', 'academic_id' => 'JS002', 'grade' => 'Grade 2', 'class_section' => 'B']);

        $this->actingAs($user);
        DB::enableQueryLog();

        // Search for student name
        $response = $this->getJson(route('reports.list', ['search' => 'John']));
        $response->assertStatus(200);

        $queries = DB::getQueryLog();
        // 1 for reports list, 1 for matching students
        $this->assertLessThanOrEqual(2, count($queries), "Search should be efficient");

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('Grade 1', $data[0]['grade']);
    }
}
