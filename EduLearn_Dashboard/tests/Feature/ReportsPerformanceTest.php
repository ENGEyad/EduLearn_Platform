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

    /**
     * Test that the ReportsController::list endpoint resolves N+1 query issues.
     * We create multiple classes with students, then benchmark query count.
     */
    public function test_reports_list_avoids_n_plus_one_queries()
    {
        // 1. Setup School, User, and actingAs
        $school = School::create([
            'name' => 'Al-Aqsa School',
            'slug' => 'al-aqsa-'.uniqid(),
            'email' => 'contact-'.uniqid().'@al-aqsa.edu',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'School Admin',
            'email' => 'admin-'.uniqid().'@al-aqsa.edu',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // 2. Create multiple classes and students to verify query scaling
        $classCount = 20;
        for ($i = 1; $i <= $classCount; $i++) {
            $classSection = ClassSection::create([
                'school_id' => $school->id,
                'grade' => "Grade {$i}",
                'section' => 'A',
                'name' => "Grade {$i} - A",
                'name_en' => "Grade {$i} - A",
            ]);

            // Add 2 students to each class
            for ($s = 1; $s <= 2; $s++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student {$s} in Class {$i}",
                    'academic_id' => "ST-{$i}-{$s}-".uniqid(),
                    'gender' => 'male',
                    'email' => "student-{$i}-{$s}-".uniqid().'@al-aqsa.edu',
                    'grade' => "Grade {$i}",
                    'class_section' => 'A',
                    'class_section_id' => $classSection->id,
                ]);
            }
        }

        // 3. Clear database query log and enable it
        DB::flushQueryLog();
        DB::enableQueryLog();

        // 4. Request the reports list endpoint
        $response = $this->actingAs($user)
            ->withHeaders([
                'Accept' => 'application/json',
                'X-Requested-With' => 'XMLHttpRequest',
            ])
            ->get(route('reports.list'));

        // 5. Assert the request was successful
        $response->assertStatus(200);

        // 6. Assert JSON response structure and correct total counts
        $responseData = $response->json();
        $this->assertArrayHasKey('data', $responseData);
        $this->assertCount($classCount, $responseData['data']);

        // Check that each class has students_count = 2
        foreach ($responseData['data'] as $classItem) {
            $this->assertEquals(2, $classItem['students_count']);
        }

        // 7. Check query log count to ensure O(1) query complexity
        $queryLog = DB::getQueryLog();
        $totalQueries = count($queryLog);

        // Without the optimization, we would have 1 query to fetch class sections,
        // and 1 extra student count query per class section inside the loop, resulting in 21+ queries.
        // With database-level grouping, it should be only 1 main query for the list, plus any user authentication queries.
        // Let's assert that the queries count is extremely low (less than 5 queries).
        $this->assertLessThan(5, $totalQueries, "N+1 query issue detected! Total queries: {$totalQueries}");
    }

    /**
     * Test search and filter functionality with high performance.
     */
    public function test_reports_list_search_and_filters_are_correct()
    {
        $school = School::create([
            'name' => 'Al-Aqsa School',
            'slug' => 'al-aqsa-'.uniqid(),
            'email' => 'contact-'.uniqid().'@al-aqsa.edu',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'School Admin',
            'email' => 'admin-'.uniqid().'@al-aqsa.edu',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        $classSection1 = ClassSection::create([
            'school_id' => $school->id,
            'grade' => 'Grade 10',
            'section' => 'A',
            'name' => 'Grade 10 - A',
            'name_en' => 'Grade 10 - A',
        ]);

        $classSection2 = ClassSection::create([
            'school_id' => $school->id,
            'grade' => 'Grade 11',
            'section' => 'B',
            'name' => 'Grade 11 - B',
            'name_en' => 'Grade 11 - B',
        ]);

        // Student 1: Grade 10 - A
        Student::create([
            'school_id' => $school->id,
            'full_name' => 'Ahmad Khalid',
            'academic_id' => 'ST-1001',
            'gender' => 'male',
            'email' => 'ahmad-'.uniqid().'@al-aqsa.edu',
            'grade' => 'Grade 10',
            'class_section' => 'A',
            'class_section_id' => $classSection1->id,
        ]);

        // Student 2: Grade 11 - B
        Student::create([
            'school_id' => $school->id,
            'full_name' => 'Mustafa Omar',
            'academic_id' => 'ST-1002',
            'gender' => 'male',
            'email' => 'mustafa-'.uniqid().'@al-aqsa.edu',
            'grade' => 'Grade 11',
            'class_section' => 'B',
            'class_section_id' => $classSection2->id,
        ]);

        // Scenario A: Search matches a class name ("Grade 10")
        $response = $this->actingAs($user)
            ->withHeaders([
                'Accept' => 'application/json',
                'X-Requested-With' => 'XMLHttpRequest',
            ])
            ->get(route('reports.list', ['search' => 'Grade 10']));

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('Grade 10', $data[0]['grade']);

        // Scenario B: Search matches a student name ("Mustafa")
        $response = $this->actingAs($user)
            ->withHeaders([
                'Accept' => 'application/json',
                'X-Requested-With' => 'XMLHttpRequest',
            ])
            ->get(route('reports.list', ['search' => 'Mustafa']));

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('Grade 11', $data[0]['grade']);
        $this->assertEquals('B', $data[0]['class_section']);

        // Students array in response should contain Mustafa
        $students = $response->json('students');
        $this->assertCount(1, $students);
        $this->assertEquals('Mustafa Omar', $students[0]['full_name']);
    }
}
