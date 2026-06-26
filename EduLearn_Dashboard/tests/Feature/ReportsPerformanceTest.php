<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Support\Str;

class ReportsPerformanceTest extends TestCase
{
    public function test_list_performance_and_query_count()
    {
        // 1. Setup Data
        $school = School::create([
            'name' => 'Test School ' . uniqid(),
            'slug' => 'test-school-' . Str::random(10),
            'email' => 'school-' . uniqid() . '@example.com',
            'is_initialized' => true,
            'status' => 'active',
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        $numberOfClasses = 20;
        $studentsPerClass = 5;

        for ($i = 1; $i <= $numberOfClasses; $i++) {
            $grade = "Grade $i";
            $section = "A";

            ClassSection::create([
                'school_id' => $school->id,
                'grade' => $grade,
                'section' => $section,
                'name' => "$grade - $section",
            ]);

            for ($j = 1; $j <= $studentsPerClass; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'grade' => $grade,
                    'class_section' => $section,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ACAD-$i-$j-" . uniqid(),
                    'email' => "student$i$j" . uniqid() . "@example.com",
                ]);
            }
        }

        // 2. Measure Performance
        DB::enableQueryLog();

        $response = $this->actingAs($user)
            ->getJson(route('reports.list'));

        $queryLog = DB::getQueryLog();

        // 3. Assertions
        $response->assertStatus(200);
        $response->assertJsonCount($numberOfClasses, 'data');

        $studentQueries = collect($queryLog)->filter(function($log) {
            return str_contains($log['query'], '"students"') || str_contains($log['query'], 'students');
        })->count();

        echo "\nStudent related queries for $numberOfClasses classes: $studentQueries\n";

        // With optimization, we expect exactly 1 query to students table (the main grouped query)
        $this->assertEquals(1, $studentQueries, "Query count should be exactly 1 after optimization.");
    }

    public function test_list_search_performance()
    {
        $school = School::create([
            'name' => 'Search School ' . uniqid(),
            'slug' => 'search-school-' . Str::random(10),
            'email' => 'search-' . uniqid() . '@example.com',
            'is_initialized' => true,
            'status' => 'active',
        ]);
        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin'
        ]);

        for ($i = 1; $i <= 5; $i++) {
            Student::create([
                'school_id' => $school->id,
                'grade' => "Grade $i",
                'class_section' => 'A',
                'full_name' => "Searchable Student $i",
                'academic_id' => "S-ACAD-$i-" . uniqid(),
                'email' => "search$i" . uniqid() . "@example.com",
            ]);
        }

        DB::enableQueryLog();

        $response = $this->actingAs($user)
            ->getJson(route('reports.list', ['search' => 'Searchable']));

        $queryLog = DB::getQueryLog();
        $studentQueries = collect($queryLog)->filter(function($log) {
            return str_contains($log['query'], '"students"') || str_contains($log['query'], 'students');
        })->count();

        $response->assertStatus(200);
        $response->assertJsonCount(5, 'students');
        echo "Student queries for search: $studentQueries\n";

        // 2 student queries: one for $items (grouped classes) and one for $matchingStudents
        $this->assertEquals(2, $studentQueries, "Query count for search should be 2 after optimization.");
    }

    public function test_list_search_filtering()
    {
        $school = School::create([
            'name' => 'Filter School ' . uniqid(),
            'slug' => 'filter-school-' . Str::random(10),
            'email' => 'filter-' . uniqid() . '@example.com',
            'is_initialized' => true,
            'status' => 'active',
        ]);
        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin'
        ]);

        Student::create([
            'school_id' => $school->id,
            'grade' => 'Grade 10',
            'class_section' => 'A',
            'full_name' => 'John Doe',
            'academic_id' => 'JD001' . uniqid(),
            'email' => 'john' . uniqid() . '@example.com',
        ]);

        Student::create([
            'school_id' => $school->id,
            'grade' => 'Grade 11',
            'class_section' => 'B',
            'full_name' => 'Jane Smith',
            'academic_id' => 'JS002' . uniqid(),
            'email' => 'jane' . uniqid() . '@example.com',
        ]);

        // Search by class name
        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 10']));
        $response->assertStatus(200);
        $response->assertJsonFragment(['grade' => 'Grade 10', 'class_section' => 'A']);
        $response->assertJsonMissing(['grade' => 'Grade 11', 'class_section' => 'B']);

        // Search by student name
        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Jane']));
        $response->assertStatus(200);
        $response->assertJsonFragment(['grade' => 'Grade 11', 'class_section' => 'B']);
        $response->assertJsonCount(1, 'students');
        $this->assertStringContainsString('Jane Smith', $response->json('students.0.full_name'));

        // Filter by class
        $response = $this->actingAs($user)->getJson(route('reports.list', ['class' => 'Grade 11-B']));
        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonFragment(['grade' => 'Grade 11', 'class_section' => 'B']);
    }
}
