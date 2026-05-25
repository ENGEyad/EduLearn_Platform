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

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we use sqlite for testing
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);
    }

    public function test_reports_list_performance()
    {
        // 1. Setup Data
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 10 classes with 2 sections each = 20 class sections
        for ($i = 1; $i <= 10; $i++) {
            foreach (['A', 'B'] as $section) {
                // Create some students for each class
                for ($j = 1; $j <= 5; $j++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student $j Class $i$section",
                        'academic_id' => "STU-$i-$section-$j",
                        'grade' => "Grade $i",
                        'class_section' => $section,
                        'gender' => 'Male',
                        'birthdate' => '2010-01-01',
                        'guardian_name' => 'Guardian',
                        'guardian_phone' => '123456789',
                    ]);
                }
            }
        }

        $this->actingAs($user);

        // 2. Measure Baseline
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queryLog = DB::getQueryLog();
        $queryCount = count($queryLog);

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        echo "\nOptimized Query Count for 20 classes: ".$queryCount."\n";

        // 3. Test with Search
        DB::flushQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'Student 1']));
        $queryCountWithSearch = count(DB::getQueryLog());

        echo 'Optimized Query Count with Search: '.$queryCountWithSearch."\n";

        $this->assertLessThanOrEqual(5, $queryCount, 'Query count should be constant and low');
        $this->assertLessThanOrEqual(5, $queryCountWithSearch, 'Query count with search should also be low');

        // Verify Data
        $data = $response->json('data');
        $this->assertEquals('Grade 1', $data[0]['grade']);
        $this->assertEquals(5, $data[0]['students_count']);
    }
}
