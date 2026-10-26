<?php

namespace Tests\Feature;

use App\Models\ClassSection;
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
        $app = require __DIR__ . '/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
            'database.connections.mysql' => config('database.connections.sqlite'),
            'database.connections.app_mysql' => config('database.connections.sqlite'),
        ]);

        DB::extend('app_mysql', function ($config, $name) {
            return DB::connection('sqlite');
        });

        return $app;
    }

    public function test_reports_list_query_count()
    {
        // Setup school and user
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 classes with students
        for ($i = 1; $i <= 20; $i++) {
            $grade = "Grade {$i}";
            $section = "A";

            ClassSection::create([
                'school_id' => $school->id,
                'grade' => $grade,
                'section' => $section,
                'name' => "{$grade} - {$section}",
                'name_en' => "{$grade} - {$section}",
                'name_ar' => "{$grade} - {$section}",
                'is_active' => true,
            ]);

            Student::create([
                'school_id' => $school->id,
                'full_name' => "Student {$i}",
                'academic_id' => "STU{$i}",
                'grade' => $grade,
                'class_section' => $section,
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $response->assertStatus(200);
        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nReportsController::list Query Count (No Search): {$queryCount}\n";

        // Assert response has 20 classes and query count is 2 (User lookup/session + grouped query)
        $this->assertCount(20, $response->json('data'));
        $this->assertLessThanOrEqual(2, $queryCount);

        // Test with search term query count
        DB::flushQueryLog();
        $responseSearch = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Student 5']));
        $responseSearch->assertStatus(200);
        $searchQueries = count(DB::getQueryLog());

        echo "ReportsController::list Query Count (With Search): {$searchQueries}\n";
        $this->assertLessThanOrEqual(3, $searchQueries);
    }
}
