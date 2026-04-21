<?php

namespace Tests\Feature;

use App\Models\Student;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Contracts\Console\Kernel;

class ReportsPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        // Manual migration to ensure fresh state
        $this->artisan('migrate:fresh');
        // Manual migration for app_mysql is handled by Laravel running ALL migrations,
        // but since some migrations specify a connection, they might run multiple times or on wrong connection
        // if we are not careful. However, with both mysql and app_mysql being :memory:,
        // and knowing how Laravel migrations work, it should be fine if we just run it once IF all migrations
        // are compatible.
    }

    public function test_list_endpoint_is_optimized()
    {
        // Create 2 classes with 5 students each
        $this->createClassData('Grade 1', 'A', 5);
        $this->createClassData('Grade 1', 'B', 5);

        // Record queries for 2 classes
        DB::enableQueryLog();
        $response1 = $this->getJson(route('reports.list'));
        $queries1 = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response1->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // Create 3 more classes
        $this->createClassData('Grade 2', 'A', 3);
        $this->createClassData('Grade 2', 'B', 3);
        $this->createClassData('Grade 2', 'C', 3);

        // Record queries for 5 classes
        DB::flushQueryLog();
        DB::enableQueryLog();
        $response2 = $this->getJson(route('reports.list'));
        $queries2 = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response2->assertStatus(200)
            ->assertJsonCount(5, 'data');

        // The number of queries should be constant (O(1)) not O(N)
        $this->assertEquals($queries1, $queries2, "Query count should be constant regardless of the number of classes.");

        // In the optimized version, we expect about 1-2 queries for the main list
        $this->assertLessThanOrEqual(5, $queries2, "Should perform fewer than 5 queries for the entire list.");
    }

    public function test_list_search_is_optimized()
    {
        $this->createClassData('Grade 1', 'A', 5, 'Target Student');
        $this->createClassData('Grade 1', 'B', 5);

        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'Target']));
        $queryCount = count(DB::getQueryLog());

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.grade', 'Grade 1')
            ->assertJsonPath('data.0.class_section', 'A');

        // Search should also be efficient
        $this->assertLessThanOrEqual(5, $queryCount, "Search should be performed efficiently in the database.");
    }

    private function createClassData($grade, $section, $count, $specialStudentName = null)
    {
        for ($i = 0; $i < $count; $i++) {
            Student::create([
                'full_name' => ($i === 0 && $specialStudentName) ? $specialStudentName : "Student $i in $grade-$section",
                'academic_id' => "ID-$grade-$section-$i",
                'grade' => $grade,
                'class_section' => $section,
            ]);
        }
    }
}
