<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Manual cleanup for secondary connection as RefreshDatabase only handles default
        if (config('database.default') === 'sqlite' && config('database.connections.mysql.driver') === 'sqlite') {
            Schema::connection('mysql')->dropAllTables();
            Schema::connection('app_mysql')->dropAllTables();

            $this->artisan('migrate');
        }
    }

    public function test_list_performance_is_efficient()
    {
        $school = School::create([
            'name' => 'Test School '.uniqid(),
            'slug' => 'test-school-'.uniqid(),
            'email' => 'test'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin'.uniqid().'@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 20 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            foreach (['A', 'B'] as $section) {
                for ($j = 1; $j <= 5; $j++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student $i$section$j",
                        'academic_id' => "ID$i$section$j".uniqid(),
                        'grade' => "Grade $i",
                        'class_section' => $section,
                    ]);
                }
            }
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queryLog = DB::getQueryLog();
        $queryCount = count($queryLog);

        // Before optimization, for 20 classes, it would be:
        // 1. User fetch (auth)
        // 2. Select distinct classes
        // 3. 20 count queries (one per class)
        // Total: ~22 queries

        // After optimization, it should be:
        // 1. User fetch (auth)
        // 2. Grouped query with count
        // Total: ~2 queries

        $response->assertStatus(200);
        $this->assertLessThan(10, $queryCount, "Too many queries: $queryCount");

        $data = $response->json('data');
        $this->assertCount(20, $data);
        $this->assertEquals(5, $data[0]['students_count']);
    }

    public function test_list_search_performance_is_efficient()
    {
        $school = School::create([
            'name' => 'Test School '.uniqid(),
            'slug' => 'test-school-'.uniqid(),
            'email' => 'test'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin'.uniqid().'@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 classes
        for ($i = 1; $i <= 10; $i++) {
            Student::create([
                'school_id' => $school->id,
                'full_name' => "Student $i",
                'academic_id' => "ID$i".uniqid(),
                'grade' => "Grade $i",
                'class_section' => 'A',
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        // Search for a specific student
        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Student 1']));

        $queryLog = DB::getQueryLog();
        $queryCount = count($queryLog);

        // Before optimization, searching would still iterate through all classes and check exists()
        // for each class, plus the final search for students.

        $response->assertStatus(200);
        $this->assertLessThan(10, $queryCount, "Too many queries during search: $queryCount");
    }
}
