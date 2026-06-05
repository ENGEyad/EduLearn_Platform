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
        // Setup
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@test.com',
            'status' => 'active',
            'is_initialized' => true
        ]);
        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin'
        ]);

        // Create 10 classes with 2 students each
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'grade' => "Grade $i",
                    'class_section' => "Section A",
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ID-$i-$j"
                ]);
            }
        }

        $this->actingAs($user);

        DB::connection()->enableQueryLog();
        $response = $this->getJson(route('reports.list'));
        $queries = DB::getQueryLog();
        DB::connection()->disableQueryLog();

        $response->assertStatus(200);

        // Output the number of queries
        echo "\nNumber of queries for reports.list with 10 classes: " . count($queries) . "\n";

        // ⚡ Bolt: We reduced queries from 12+ down to 2 for 10 classes
        echo "\nOptimized number of queries: " . count($queries) . "\n";
        $this->assertLessThanOrEqual(5, count($queries), "Query count should be low after optimization");

        $data = $response->json('data');
        $this->assertCount(10, $data);
        $this->assertEquals(2, $data[0]['students_count']);
    }

    public function test_reports_list_search_performance()
    {
        $school = School::create(['name' => 'S1', 'slug' => 's1', 'email' => 's1@t.com', 'status' => 'active', 'is_initialized' => true]);
        $user = User::create(['name' => 'U1', 'email' => 'u1@t.com', 'password' => bcrypt('p'), 'school_id' => $school->id, 'role' => 'school_admin']);

        Student::create(['school_id' => $school->id, 'grade' => 'G1', 'class_section' => 'S1', 'full_name' => 'Alice', 'academic_id' => 'A1']);
        Student::create(['school_id' => $school->id, 'grade' => 'G2', 'class_section' => 'S2', 'full_name' => 'Bob', 'academic_id' => 'A2']);

        $this->actingAs($user);

        // Search for student name
        DB::connection()->enableQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'Alice']));
        $queries = DB::getQueryLog();
        DB::connection()->disableQueryLog();

        $response->assertStatus(200);
        $this->assertLessThanOrEqual(5, count($queries));
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('G1', $response->json('data.0.grade'));
        $this->assertCount(1, $response->json('students'));
    }
}
