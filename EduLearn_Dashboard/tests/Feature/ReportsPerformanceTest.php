<?php

namespace Tests\Feature;

use App\Models\Student;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function list_endpoint_performance_remains_stable_with_more_classes()
    {
        // 1. Setup with 2 classes
        $this->createStudentsForClass('Grade 1', 'A', 5);
        $this->createStudentsForClass('Grade 1', 'B', 5);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response1 = $this->getJson(route('reports.list'));
        $queryCount1 = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response1->assertStatus(200);

        // 2. Setup with 10 more classes (total 12)
        for ($i = 2; $i <= 11; $i++) {
            $this->createStudentsForClass("Grade $i", 'A', 5);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response2 = $this->getJson(route('reports.list'));
        $queryCount2 = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response2->assertStatus(200);

        // If it's N+1, queryCount2 should be significantly higher than queryCount1
        // Currently:
        // 1 query to get distinct classes
        // 1 query per class to count students
        // total = 1 + N

        // With 2 classes: 1 + 2 = 3 queries
        // With 12 classes: 1 + 12 = 13 queries

        // We expect it to be 1 query for the main list, or 2 if we consider some overhead but it should NOT be 13
        $this->assertEquals($queryCount1, $queryCount2, "Query count should be constant regardless of number of classes");
        $this->assertLessThan(5, $queryCount2, "Query count should be low (no N+1)");
    }

    /** @test */
    public function search_logic_works_correctly()
    {
        $this->createStudentsForClass('Grade 1', 'A', 2); // Student 0 for Grade 1 A, Student 1 for Grade 1 A
        $this->createStudentsForClass('Grade 2', 'B', 2);

        // Search by class name
        $response = $this->getJson(route('reports.list', ['search' => 'Grade 1']));
        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Grade 1', $response->json('data.0.grade'));

        // Search by student name
        $response = $this->getJson(route('reports.list', ['search' => 'Student 0 for Grade 2 B']));
        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Grade 2', $response->json('data.0.grade'));
        $this->assertEquals('B', $response->json('data.0.class_section'));
    }

    private function createStudentsForClass($grade, $section, $count)
    {
        for ($i = 0; $i < $count; $i++) {
            Student::create([
                'full_name' => "Student $i for $grade $section",
                'academic_id' => "ID-$grade-$section-$i",
                'grade' => $grade,
                'class_section' => $section,
                'status' => 'Active',
            ]);
        }
    }
}
