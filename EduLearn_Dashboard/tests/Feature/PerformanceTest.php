<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we use the sqlite database for testing
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        $this->artisan('migrate');
    }

    public function test_reports_list_performance_and_correctness()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test'.uniqid().'@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 20 classes with different student counts
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                // Grade i, Section j
                $count = ($i * 2) + $j;
                for ($k = 1; $k <= $count; $k++) {
                    Student::create([
                        'school_id' => $school->id,
                        'grade' => "Grade $i",
                        'class_section' => "Section $j",
                        'full_name' => "Student $i-$j-$k",
                        'academic_id' => "ID-$i-$j-$k",
                    ]);
                }
            }
        }

        $this->actingAs($user);

        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        $queryCount = count($queries);
        dump('Optimized query count for reports.list with 20 classes: '.$queryCount);

        // We expect only ~2 queries (1 for user, 1 for classes with counts)
        $this->assertLessThan(10, $queryCount, 'Optimization failed: too many queries');

        $data = $response->json('data');
        $this->assertCount(20, $data);

        // Verify data correctness for a sample
        // Grade 1, Section 1 should have (1*2)+1 = 3 students
        $grade1section1 = collect($data)->first(function ($item) {
            return $item['grade'] === 'Grade 1' && $item['class_section'] === 'Section 1';
        });
        $this->assertEquals(3, $grade1section1['students_count']);

        // Test search by class name
        $responseSearchClass = $this->getJson(route('reports.list', ['search' => 'Grade 5 - Section 2']));
        $responseSearchClass->assertStatus(200);
        $searchData = $responseSearchClass->json('data');
        $this->assertCount(1, $searchData);
        $this->assertEquals('Grade 5', $searchData[0]['grade']);
        $this->assertEquals('Section 2', $searchData[0]['class_section']);

        // Test search by student name
        $responseSearchStudent = $this->getJson(route('reports.list', ['search' => 'Student 7-1-4']));
        $responseSearchStudent->assertStatus(200);
        $searchDataStudent = $responseSearchStudent->json('data');
        // Should return Grade 7 - Section 1 because Student 7-1-4 is in it
        $this->assertCount(1, $searchDataStudent);
        $this->assertEquals('Grade 7', $searchDataStudent[0]['grade']);
        $this->assertEquals('Section 1', $searchDataStudent[0]['class_section']);
    }
}
