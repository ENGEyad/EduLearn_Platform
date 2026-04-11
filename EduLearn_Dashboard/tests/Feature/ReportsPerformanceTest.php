<?php

namespace Tests\Feature;

use App\Models\Student;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    public function test_list_performance_and_correctness()
    {
        // Seed some data
        // Create 10 classes, each with 5 students
        for ($i = 1; $i <= 10; $i++) {
            $grade = "Grade $i";
            $section = 'A';

            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $j of $grade $section",
                    'academic_id' => "ID-$i-$j",
                    'grade' => $grade,
                    'class_section' => $section,
                    'status' => 'Active',
                ]);
            }
        }

        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queryLog = DB::getQueryLog();
        $queryCount = count($queryLog);
        DB::disableQueryLog();

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertCount(10, $data, 'Should have 10 classes');
        $this->assertEquals(5, $data[0]['students_count'], 'Each class should have 5 students');

        dump('Query count before optimization: '.$queryCount);

        // Test search
        Student::create([
            'full_name' => 'UniqueSearchStudent',
            'academic_id' => 'SEARCH-ID',
            'grade' => 'Grade 1',
            'class_section' => 'A',
            'status' => 'Active',
        ]);

        DB::enableQueryLog();
        $responseSearch = $this->getJson(route('reports.list').'?search=UniqueSearchStudent');
        $searchQueryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $responseSearch->assertStatus(200);
        $this->assertNotEmpty($responseSearch->json('students'), 'Should find the matching student');
        dump('Query count with search before optimization: '.$searchQueryCount);
    }
}
