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
    use RefreshDatabase;

    public function test_reports_list_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 10 classes with 2 sections each = 20 classes
        for ($i = 1; $i <= 10; $i++) {
            foreach (['A', 'B'] as $section) {
                ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => (string)$i,
                    'section' => $section,
                    'name' => "Grade $i - $section",
                    'is_active' => true,
                ]);

                // Add 5 students to each class
                for ($j = 1; $j <= 5; $j++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student $i-$section-$j",
                        'academic_id' => "ACAD-$i-$section-$j",
                        'grade' => (string)$i,
                        'class_section' => $section,
                        'status' => 'Active',
                        'gender' => 'Male',
                        'birthdate' => '2010-01-01',
                        'guardian_name' => 'Guardian',
                        'guardian_phone' => '123456',
                    ]);
                }
            }
        }

        $this->actingAs($user);

        // --- Test 1: Normal List ---
        DB::connection('sqlite')->flushQueryLog();
        DB::connection('sqlite')->enableQueryLog();

        $response = $this->getJson(route('reports.list'));
        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        $queries = DB::connection('sqlite')->getQueryLog();
        $queryCountNormal = count($queries);

        echo "\nTotal queries for reports.list (20 classes): " . $queryCountNormal;

        // --- Test 2: List with Search ---
        DB::connection('sqlite')->flushQueryLog();

        $response = $this->getJson(route('reports.list') . '?search=Student');
        $response->assertStatus(200);

        $queries = DB::connection('sqlite')->getQueryLog();
        $queryCountSearch = count($queries);

        echo "\nTotal queries for reports.list with search: " . $queryCountSearch . "\n";

        // Asserting massive improvement
        // Baseline was 22+ for normal and 43+ for search.
        // New expected: 1 for normal, 2 for search (plus auth check)
        $this->assertLessThan(5, $queryCountNormal);
        $this->assertLessThan(5, $queryCountSearch);
    }
}
