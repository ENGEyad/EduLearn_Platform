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

    public function test_reports_list_performs_efficiently_and_correctly(): void
    {
        // 1. Setup School
        $school = School::create([
            'name' => 'Test Modern School',
            'slug' => 'test-modern-school-'.uniqid(),
            'email' => 'contact-'.uniqid().'@example.com',
            'status' => 'active',
            'is_initialized' => true,
            'academic_year' => '2025/2026',
            'school_type' => 'Private',
            'country' => 'Yemen',
            'city' => 'Sanaa',
        ]);

        // 2. Setup User (School Admin)
        $user = User::create([
            'name' => 'School Admin User',
            'email' => 'admin-'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // 3. Create Class Sections and Students to simulate an N+1 query scenario
        // Let's create 10 classes
        for ($i = 1; $i <= 10; $i++) {
            $grade = "Grade {$i}";
            $section = 'A';

            $classSection = ClassSection::create([
                'school_id' => $school->id,
                'grade' => $grade,
                'section' => $section,
                'name' => "{$grade} - Section {$section}",
                'name_en' => "{$grade} - Section {$section}",
                'is_active' => true,
            ]);

            // Add 2 students to each class
            for ($j = 1; $j <= 2; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $classSection->id,
                    'grade' => $grade,
                    'class_section' => $section,
                    'full_name' => "Student {$i} {$j}",
                    'academic_id' => 'ACAD-'.uniqid()."-{$i}-{$j}",
                    'gender' => 'Male',
                    'birthdate' => '2015-05-05',
                    'email' => 'student-'.uniqid()."-{$i}-{$j}@example.com",
                    'status' => 'active',
                    'attendance_rate' => 95.0,
                ]);
            }
        }

        // 4. Measure query count for getting the standard list
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)
            ->getJson(route('reports.list'));

        $queryLog = DB::getQueryLog();
        DB::disableQueryLog();

        // Check correctness of standard response
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data' => [
                '*' => [
                    'grade',
                    'class_section',
                    'students_count',
                ],
            ],
            'students',
            'meta' => ['total'],
        ]);

        $responseData = $response->json('data');
        $this->assertCount(10, $responseData);
        $this->assertEquals(2, $responseData[0]['students_count']);

        // Assert query count is optimized.
        // We expect only 2 queries: one for checking/retrieving session/user/school info if needed, or
        // 1 query for getting the classes and counts, and 1 for matching students.
        $this->assertLessThanOrEqual(5, count($queryLog), 'Expected optimized list endpoint to execute at most 5 queries, got '.count($queryLog));

        // 5. Measure query count for search query
        DB::flushQueryLog();
        DB::enableQueryLog();

        $responseSearch = $this->actingAs($user)
            ->getJson(route('reports.list', ['search' => 'Student 3']));

        $searchQueryLog = DB::getQueryLog();
        DB::disableQueryLog();

        $responseSearch->assertStatus(200);
        $searchData = $responseSearch->json('data');
        $searchStudents = $responseSearch->json('students');

        // It should match Grade 3 Class (as "Student 3" belongs to Grade 3) and direct student match
        $this->assertCount(1, $searchData);
        $this->assertEquals('Grade 3', $searchData[0]['grade']);
        $this->assertCount(2, $searchStudents); // matches both Student 3 1 and Student 3 2

        $this->assertLessThanOrEqual(5, count($searchQueryLog), 'Expected optimized search endpoint to execute at most 5 queries, got '.count($searchQueryLog));
    }
}
