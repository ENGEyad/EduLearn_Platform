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

    public function test_reports_list_performance_and_correctness()
    {
        // 1. Setup school, user, and students
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-'.uniqid(),
            'email' => 'admin@testschool-'.uniqid().'.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $admin = User::create([
            'name' => 'School Admin',
            'email' => 'admin-'.uniqid().'@testschool.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
            'is_temp_password' => false,
        ]);

        // Create 5 different class sections across students
        $classes = [
            ['grade' => 'Grade 1', 'section' => 'A'],
            ['grade' => 'Grade 1', 'section' => 'B'],
            ['grade' => 'Grade 2', 'section' => 'A'],
            ['grade' => 'Grade 2', 'section' => 'B'],
            ['grade' => 'Grade 3', 'section' => 'A'],
        ];

        foreach ($classes as $idx => $class) {
            // Create some students in each class
            for ($s = 1; $s <= 3; $s++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student {$s} in ".$class['grade'].' '.$class['section'],
                    'academic_id' => 'AC-'.$idx.'-'.$s.'-'.uniqid(),
                    'email' => "student-{$idx}-{$s}-".uniqid().'@testschool.com',
                    'grade' => $class['grade'],
                    'class_section' => $class['section'],
                ]);
            }
        }

        // 2. Enable Query Logging to count DB queries
        DB::enableQueryLog();
        DB::flushQueryLog();

        // 3. Act: Request reports list as the admin
        $response = $this->actingAs($admin)
            ->get(route('reports.list'));

        // 4. Assert response is successful and has expected structure
        $response->assertStatus(200);
        $data = $response->json();

        $this->assertArrayHasKey('data', $data);
        $this->assertCount(5, $data['data']); // Should have 5 distinct classes
        $this->assertEquals(3, $data['data'][0]['students_count']); // Each class should have 3 students

        // 5. Assert performance: Query count should be very low (ideally 1 count query + standard session/auth queries, total <= 5)
        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // Before optimization, for 5 classes, we would have:
        // 1 distinct class query + 5 student count queries + 1 matching student check query per class = 11+ queries
        // With Bolt optimization, we have 1 optimized GROUP BY query.
        $this->assertLessThan(10, $queryCount, "Performance Bottleneck! Query count is too high: {$queryCount}");

        // 6. Test Search: search for specific student name
        DB::flushQueryLog();
        $searchResponse = $this->actingAs($admin)
            ->get(route('reports.list', ['search' => 'Student 1 in Grade 2 A']));

        $searchResponse->assertStatus(200);
        $searchData = $searchResponse->json();

        // The specific class 'Grade 2 - A' matches because a student matches
        $this->assertCount(1, $searchData['data']);
        $this->assertEquals('Grade 2', $searchData['data'][0]['grade']);
        $this->assertEquals('A', $searchData['data'][0]['class_section']);

        // The matching student is returned in 'students' array
        $this->assertCount(1, $searchData['students']);
        $this->assertEquals('Student 1 in Grade 2 A', $searchData['students'][0]['full_name']);
    }
}
