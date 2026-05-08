<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\User;
use App\Models\School;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Support\Facades\Artisan;

class ReportsPerformanceTest extends TestCase
{
    // We will handle refresh manually due to dual sqlite in-memory issue
    // use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        Artisan::call('migrate:fresh');

        // Setup a school and a school admin user
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
        ]);

        $this->user = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);
    }

    public function test_list_method_query_count()
    {
        // Seed 10 classes with 2 students each (total 20 students, 10 distinct classes)
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                Student::create([
                    'full_name' => "Student $j Class $i",
                    'academic_id' => "S100$i$j",
                    'grade' => "Grade $i",
                    'class_section' => $j == 1 ? "A" : "B",
                    'status' => 'Active',
                ]);
            }
        }

        DB::enableQueryLog();

        $response = $this->actingAs($this->user)
            ->getJson(route('reports.list'));

        $response->assertStatus(200);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nTotal queries for 20 classes (10 grades * 2 sections): $queryCount\n";

        // Current implementation:
        // 1. Student::select('grade', 'class_section')->distinct()...->get() -> 1 query
        // 2. Loop over classes:
        //    For each class: Student::where('grade', ...)->where('class_section', ...)->count() -> 1 query
        // Optimized: Should be exactly 1 query

        $this->assertLessThanOrEqual(2, $queryCount, "Query count should be low after optimization");
    }

    public function test_list_method_with_search_query_count()
    {
        // Seed some data
        for ($i = 1; $i <= 5; $i++) {
            Student::create([
                'full_name' => "Student $i",
                'academic_id' => "S200$i",
                'grade' => "Grade 1",
                'class_section' => "A",
                'status' => 'Active',
            ]);
        }

        DB::enableQueryLog();

        $response = $this->actingAs($this->user)
            ->getJson(route('reports.list', ['search' => 'Student']));

        $response->assertStatus(200);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "Total queries with search: $queryCount\n";
    }
}
