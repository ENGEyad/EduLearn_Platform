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

    public function test_reports_list_avoids_n_plus_one_queries()
    {
        // 1. Create a school in active and initialized state
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@testschool.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // 2. Create an admin user for the school
        $user = User::create([
            'name' => 'School Admin',
            'email' => 'schooladmin@testschool.com',
            'password' => bcrypt('password123'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // 3. Create 20 class sections and populate them with students
        for ($i = 1; $i <= 20; $i++) {
            $gradeName = "Grade {$i}";
            $sectionName = 'Section A';

            // Create students in each class section
            for ($s = 1; $s <= 2; $s++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student {$s} of Grade {$i}",
                    'academic_id' => 'ACAD-'.$i.'-'.$s.'-'.uniqid(),
                    'email' => "student-{$i}-{$s}-".uniqid().'@testschool.com',
                    'status' => 'active',
                    'grade' => $gradeName,
                    'class_section' => $sectionName,
                    'attendance_rate' => 95.0,
                ]);
            }
        }

        // 4. Authenticate the user and request the reports list endpoint
        $this->actingAs($user);

        // Enable query log
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // 5. Verify the response format and content
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data',
            'students',
            'meta' => ['total'],
        ]);

        $data = $response->json('data');
        $this->assertCount(20, $data);
        $this->assertEquals(2, $data[0]['students_count']);

        // Assert that query count is extremely low (specifically, <= 4 queries to fetch distinct classes & count students including auth checks)
        // With N+1, it would be at least 1 + 20 = 21 queries just for the classes list.
        $this->assertLessThan(6, $queryCount, "Query count was {$queryCount}, which indicates N+1 query issue is still present.");

        // Clear query log for search verification
        DB::flushQueryLog();

        // 6. Test searching by student name
        $searchResponse = $this->getJson(route('reports.list', ['search' => 'Student 1 of Grade 5']));
        $searchResponse->assertStatus(200);

        $searchQueries = DB::getQueryLog();
        $searchQueryCount = count($searchQueries);

        // Assert search matches student
        $searchStudents = $searchResponse->json('students');
        $this->assertNotEmpty($searchStudents);
        $this->assertEquals('Student 1 of Grade 5', $searchStudents[0]['full_name']);

        // Ensure search query count is also extremely low and doesn't trigger N+1
        $this->assertLessThan(8, $searchQueryCount, "Search query count was {$searchQueryCount}, which indicates N+1 query issue on search.");
    }
}
