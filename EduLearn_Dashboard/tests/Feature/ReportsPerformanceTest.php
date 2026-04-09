<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\ClassSection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function refreshDatabase()
    {
        config(['database.connections.mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
        ]]);
        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
        ]]);
        config(['database.default' => 'mysql']);
        $this->artisan('migrate');
        $this->app[ \Illuminate\Contracts\Console\Kernel::class ]->setArtisan(null);
    }

    public function test_reports_list_performance_and_correctness()
    {
        $this->seedData(10);

        DB::connection('mysql')->enableQueryLog();
        $response = $this->getJson(route('reports.list'));
        $queries = DB::connection('mysql')->getQueryLog();

        echo "\n[Optimized] Total queries for 10 classes (no search): " . count($queries) . "\n";
        $response->assertStatus(200);
        $response->assertJsonCount(10, 'data');
        $response->assertJsonPath('data.0.students_count', 5);

        // Verify search by class name
        $response = $this->getJson(route('reports.list', ['search' => 'Grade 1 - A']));
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.grade', 'Grade 1');

        // Verify search by student name
        $response = $this->getJson(route('reports.list', ['search' => 'Student 2-3']));
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.grade', 'Grade 2');
        $response->assertJsonCount(1, 'students');
        $response->assertJsonPath('students.0.full_name', 'Student 2-3');
    }

    private function seedData($count)
    {
        for ($i = 1; $i <= $count; $i++) {
            $grade = "Grade $i";
            $section = "A";
            $cs = ClassSection::create(['grade' => $grade, 'section' => $section, 'name' => "$grade - $section"]);
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ID-$i-$j",
                    'class_section_id' => $cs->id,
                    'grade' => $grade,
                    'class_section' => $section
                ]);
            }
        }
    }
}
