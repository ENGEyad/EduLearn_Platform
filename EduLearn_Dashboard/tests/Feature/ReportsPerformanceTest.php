<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use App\Models\ClassSection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // Manual cleanup for SQLite files to avoid migration issues with dual connections
        \Illuminate\Support\Facades\Schema::connection('mysql')->dropAllTables();
        \Illuminate\Support\Facades\Schema::connection('app_mysql')->dropAllTables();
        $this->artisan('migrate');
    }

    public function test_list_performance()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 20 classes (10 grades, 2 sections each)
        for ($g = 1; $g <= 10; $g++) {
            for ($s = 1; $s <= 2; $s++) {
                $section = 'Section ' . $s;
                ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $g,
                    'section' => $section,
                    'name' => "Grade $g - $section",
                    'is_active' => true,
                ]);

                // Add 5 students per class
                for ($st = 1; $st <= 5; $st++) {
                    Student::create([
                        'school_id' => $school->id,
                        'grade' => $g,
                        'class_section' => $section,
                        'full_name' => "Student $st Grade $g $section",
                        'academic_id' => "ACAD-$g-$s-$st-" . uniqid(),
                        'status' => 'active',
                    ]);
                }
            }
        }

        $this->actingAs($admin);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queryCount = count(DB::getQueryLog());

        // Baseline check
        echo "\nTotal queries for reports list (no search): " . $queryCount . "\n";

        DB::flushQueryLog();
        $responseSearch = $this->getJson(route('reports.list', ['search' => 'Student']));
        $queryCountSearch = count(DB::getQueryLog());
        echo "Total queries for reports list (with search): " . $queryCountSearch . "\n";

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');
        $this->assertEquals(5, $response->json('data.0.students_count'));

        $responseSearch->assertStatus(200);
        // All students have 'Student' in their name, so all classes should be returned
        $responseSearch->assertJsonCount(20, 'data');

        // Test class name search
        $responseClassName = $this->getJson(route('reports.list', ['search' => '1 - Section 1']));
        $responseClassName->assertStatus(200);
        $responseClassName->assertJsonCount(1, 'data');
        $this->assertEquals(1, $responseClassName->json('data.0.grade'));
        $this->assertEquals('Section 1', $responseClassName->json('data.0.class_section'));

        $this->assertLessThanOrEqual(5, $queryCount, "Query count without search is too high!");
        $this->assertLessThanOrEqual(5, $queryCountSearch, "Query count with search is too high!");
    }
}
