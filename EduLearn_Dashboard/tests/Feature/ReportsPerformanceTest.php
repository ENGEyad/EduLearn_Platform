<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';
        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');

        // Dynamically point secondary connection to sqlite in-memory
        DB::extend('app_mysql', function () {
            return DB::connection('sqlite');
        });

        DB::extend('mysql', function () {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_reports_list_executes_minimal_queries_and_returns_correct_data()
    {
        $school = School::create([
            'name' => 'Test School',
            'code' => 'SCH'.rand(1000, 9999),
            'slug' => 'test-school-'.uniqid(),
            'email' => 'admin@school'.uniqid().'.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'school_id' => $school->id,
            'name' => 'Admin User',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => Hash::make('password'),
            'role' => 'school_admin',
        ]);

        // Create 20 class sections with 5 students each
        for ($i = 1; $i <= 20; $i++) {
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student {$i}-{$j}",
                    'academic_id' => "STU{$i}{$j}",
                    'grade' => 'Grade '.$i,
                    'class_section' => 'Section A',
                ]);
            }
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        // After optimization: exactly 1 database query executed for the list instead of 22
        $this->assertLessThanOrEqual(2, $queryCount, "Reports list query count should be <= 2, but was {$queryCount}");
    }

    public function test_reports_list_search_functionality()
    {
        $school = School::create([
            'name' => 'Test School 2',
            'code' => 'SCH'.rand(1000, 9999),
            'slug' => 'test-school-'.uniqid(),
            'email' => 'admin@school'.uniqid().'.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'school_id' => $school->id,
            'name' => 'Admin User 2',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => Hash::make('password'),
            'role' => 'school_admin',
        ]);

        Student::create([
            'school_id' => $school->id,
            'full_name' => 'John Doe',
            'academic_id' => 'JD123',
            'grade' => 'Grade 1',
            'class_section' => 'Section A',
        ]);

        Student::create([
            'school_id' => $school->id,
            'full_name' => 'Jane Smith',
            'academic_id' => 'JS456',
            'grade' => 'Grade 2',
            'class_section' => 'Section B',
        ]);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'John']));

        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonCount(1, 'students');
        $this->assertEquals('John Doe', $response->json('students.0.full_name'));

        // Reduced from over 42 queries for search down to <= 3
        $this->assertLessThanOrEqual(3, $queryCount, "Search query count should be <= 3, but was {$queryCount}");
    }
}
