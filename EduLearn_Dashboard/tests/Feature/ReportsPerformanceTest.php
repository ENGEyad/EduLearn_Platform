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
    protected function setUp(): void
    {
        parent::setUp();

        // Manual cleanup for SQLite file databases since RefreshDatabase might not handle dual connections well
        \Illuminate\Support\Facades\Schema::connection('mysql')->dropAllTables();
        \Illuminate\Support\Facades\Schema::connection('app_mysql')->dropAllTables();

        $this->artisan('migrate', [
            '--database' => 'mysql',
            '--force' => true,
        ]);
    }

    public function test_list_method_query_count()
    {
        // 1. Setup
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 classes (grade/section pairs) with students
        for ($i = 1; $i <= 20; $i++) {
            $grade = "Grade $i";
            $section = "A";

            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student $j in $grade-$section",
                    'academic_id' => "ACAD-$i-$j",
                    'grade' => $grade,
                    'class_section' => $section,
                    'status' => 'active',
                ]);
            }
        }

        $this->actingAs($user);

        // 2. Measure baseline
        DB::enableQueryLog();
        DB::flushQueryLog();

        $response = $this->get(route('reports.list'), [
            'HTTP_X-Requested-With' => 'XMLHttpRequest',
            'Accept' => 'application/json',
        ]);

        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        if ($response->status() !== 200) {
            fwrite(STDERR, "Response status: " . $response->status() . "\n");
            fwrite(STDERR, "Response content: " . $response->content() . "\n");
        }

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        echo "\nOptimized query count for 20 classes: $queryCount\n";

        // Optimized query count should be constant (around 2 total queries)
        $this->assertLessThanOrEqual(5, $queryCount);
    }

    public function test_list_method_with_search_query_count()
    {
        // 1. Setup
        $school = School::create([
            'name' => 'Search School',
            'slug' => 'search-school',
            'email' => 'search@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin Search',
            'email' => 'admin-search@example.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        for ($i = 1; $i <= 20; $i++) {
            $grade = "Grade $i";
            $section = "A";
            for ($j = 1; $j <= 2; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student $j in $grade-$section",
                    'academic_id' => "ACAD-S-$i-$j",
                    'grade' => $grade,
                    'class_section' => $section,
                    'status' => 'active',
                ]);
            }
        }

        $this->actingAs($user);

        // 2. Measure search baseline
        DB::enableQueryLog();
        DB::flushQueryLog();

        $response = $this->get(route('reports.list', ['search' => 'NonExistent']), [
            'HTTP_X-Requested-With' => 'XMLHttpRequest',
            'Accept' => 'application/json',
        ]);

        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);

        echo "\nOptimized search query count for 20 classes: $queryCount\n";

        // Optimized query count should be constant (around 3 total queries)
        $this->assertLessThanOrEqual(5, $queryCount);
    }
}
