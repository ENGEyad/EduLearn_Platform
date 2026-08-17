<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config([
            'database.default' => 'mysql',
            'database.connections.mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
            'database.connections.app_mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
        ]);

        DB::extend('app_mysql', function ($config, $name) {
            return DB::connection('mysql');
        });

        return $app;
    }

    public function test_reports_list_executes_efficient_queries_and_returns_correct_data()
    {
        // 1. Create School and User
        $school = School::create([
            'name' => 'Test High School',
            'slug' => 'test-high-school-'.uniqid(),
            'email' => 'admin-'.uniqid().'@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // 2. Create 20 distinct classes with 5 students each (100 students total)
        for ($i = 1; $i <= 20; $i++) {
            $grade = "Grade {$i}";
            $section = 'A';

            for ($s = 1; $s <= 5; $s++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student {$s} of {$grade}",
                    'academic_id' => "ACAD-{$i}-{$s}-".uniqid(),
                    'grade' => $grade,
                    'class_section' => $section,
                    'status' => 'Active',
                ]);
            }
        }

        // 3. Measure query count for full class listing
        DB::enableQueryLog();
        DB::flushQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertCount(20, $data);
        $this->assertEquals(5, $data[0]['students_count']);

        // Assert query count is optimized to <= 2 queries (down from 22 queries for 20 classes)
        $this->assertLessThanOrEqual(2, $queryCount, "Reports list query count should be <= 2, actual: {$queryCount}");

        // 4. Measure query count for search query
        DB::enableQueryLog();
        DB::flushQueryLog();

        $searchResponse = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 1']));

        $searchQueryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $searchResponse->assertStatus(200);

        // Assert search query count is optimized to <= 3 queries (down from 42 queries during search filtering)
        $this->assertLessThanOrEqual(3, $searchQueryCount, "Reports search query count should be <= 3, actual: {$searchQueryCount}");
    }
}
