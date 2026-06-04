<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_reports_list_performance()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 classes, each with 2 students
        for ($i = 1; $i <= 20; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'first_name' => "Student $i-$j",
                    'last_name' => "Last",
                    'full_name' => "Student $i-$j Last",
                    'academic_id' => "ACAD-$i-$j",
                    'grade' => "Grade $i",
                    'class_section' => "Section A",
                ]);
            }
        }

        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // Expectation:
        // 1. Get user (if not already loaded)
        // 2. Get distinct classes (1 query)
        // 3. For each class (10 classes), 1 query for student count = 10 queries
        // Total expected around 11-13 queries.

        echo "\nQuery Count: $queryCount\n";

        $response->assertStatus(200);
        // Expecting around 2-3 queries now (user/session + the optimized list query)
        $this->assertLessThan(5, $queryCount);
    }

    public function test_reports_list_search_performance()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 classes
        for ($i = 1; $i <= 20; $i++) {
            Student::create([
                'school_id' => $school->id,
                'first_name' => "Student $i",
                'last_name' => "Last",
                'full_name' => "Student $i Last",
                'academic_id' => "ACAD-$i",
                'grade' => "Grade $i",
                'class_section' => "Section A",
            ]);
        }

        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();

        // Search for a specific class
        $response = $this->getJson(route('reports.list', ['search' => 'Grade 10']));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nSearch Query Count: $queryCount\n";

        $response->assertStatus(200);
        // Search should also be efficient (around 2-3 queries)
        $this->assertLessThan(5, $queryCount);
    }
}
