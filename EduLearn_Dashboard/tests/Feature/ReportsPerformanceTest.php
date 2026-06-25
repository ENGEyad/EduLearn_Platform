<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\ClassSectionSubject;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    public function test_list_performance_baseline()
    {
        // 1. Setup Data
        $school = School::create([
            'name' => 'Test School '.uniqid(),
            'slug' => 'test-school-'.uniqid(),
            'email' => 'test'.uniqid().'@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'School Admin',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 20 classes (Grade 1-10, Sections A and B)
        // Each class has 5 students
        for ($grade = 1; $grade <= 10; $grade++) {
            foreach (['A', 'B'] as $section) {
                for ($i = 1; $i <= 5; $i++) {
                    Student::create([
                        'school_id' => $school->id,
                        'first_name' => 'Student',
                        'last_name' => "{$grade}{$section}{$i}",
                        'full_name' => "Student {$grade}{$section}{$i}",
                        'academic_id' => 'AC'.uniqid(),
                        'grade' => (string) $grade,
                        'class_section' => $section,
                        'status' => 'active',
                    ]);
                }
            }
        }

        // 2. Measure Queries
        $queryCount = 0;
        DB::listen(function ($query) use (&$queryCount) {
            $queryCount++;
        });

        $response = $this->actingAs($user)
            ->getJson(route('reports.list'));

        $response->assertStatus(200);

        // Baseline expectation was ~22. Optimized should be ~2-3.

        echo "\nTotal queries for 20 classes: ".$queryCount."\n";

        $this->assertLessThanOrEqual(5, $queryCount, 'Optimization should reduce queries to O(1)');
    }

    public function test_list_performance_with_search_baseline()
    {
        $school = School::create([
            'name' => 'Search School '.uniqid(),
            'slug' => 'search-school-'.uniqid(),
            'email' => 'search'.uniqid().'@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'School Admin',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        for ($grade = 1; $grade <= 10; $grade++) {
            foreach (['A', 'B'] as $section) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Searchable Student {$grade}{$section}",
                    'academic_id' => 'SEARCH'.uniqid(),
                    'grade' => (string) $grade,
                    'class_section' => $section,
                ]);
            }
        }

        $queryCount = 0;
        DB::listen(function ($query) use (&$queryCount) {
            $queryCount++;
        });

        $response = $this->actingAs($user)
            ->getJson(route('reports.list', ['search' => 'NonExistent']));

        $response->assertStatus(200);

        // Search was ~23. Optimized should be ~2-3.

        echo "\nTotal queries for search: ".$queryCount."\n";
        $this->assertLessThanOrEqual(5, $queryCount, 'Search optimization should also be O(1)');
    }

    public function test_list_performance_with_subject_filter()
    {
        $school = School::create([
            'name' => 'Subject School '.uniqid(),
            'slug' => 'subject-school-'.uniqid(),
            'email' => 'subject'.uniqid().'@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'School Admin',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        $subject = Subject::create([
            'name_en' => 'Mathematics '.uniqid(),
            'code' => 'MATH'.uniqid(),
        ]);

        $cs = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '5',
            'section' => 'A',
            'name' => '5-A',
            'is_active' => true,
        ]);

        ClassSectionSubject::create([
            'class_section_id' => $cs->id,
            'subject_id' => $subject->id,
            'is_active' => true,
        ]);

        Student::create([
            'school_id' => $school->id,
            'full_name' => 'Math Student',
            'academic_id' => 'MATH'.uniqid(),
            'grade' => '5',
            'class_section' => 'A',
        ]);

        // Another class without the subject
        Student::create([
            'school_id' => $school->id,
            'full_name' => 'Other Student',
            'academic_id' => 'OTHER'.uniqid(),
            'grade' => '6',
            'class_section' => 'B',
        ]);

        $queryCount = 0;
        DB::listen(function ($query) use (&$queryCount) {
            $queryCount++;
        });

        $response = $this->actingAs($user)
            ->getJson(route('reports.list', ['subject' => $subject->id]));

        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.grade', '5');

        echo "\nTotal queries for subject filter: ".$queryCount."\n";
        $this->assertLessThanOrEqual(5, $queryCount);
    }
}
