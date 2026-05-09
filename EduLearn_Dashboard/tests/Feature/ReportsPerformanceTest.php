<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\Teacher;
use App\Models\Subject;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);

        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        $this->artisan('migrate:fresh');
    }

    public function test_reports_list_performance()
    {
        // Seed data: 20 classes
        for ($i = 1; $i <= 10; $i++) {
            foreach (['A', 'B'] as $section) {
                $cs = ClassSection::create([
                    'grade' => "Grade $i",
                    'section' => $section,
                    'name' => "Grade $i - $section"
                ]);

                // Create 2 students per class
                for ($j = 1; $j <= 2; $j++) {
                    Student::create([
                        'full_name' => "Student $i-$section-$j",
                        'academic_id' => "ACAD-$i-$section-$j",
                        'grade' => "Grade $i",
                        'class_section' => $section,
                        'class_section_id' => $cs->id
                    ]);
                }
            }
        }

        DB::enableQueryLog();
        $response = $this->json('GET', route('reports.list'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        echo "\nTotal queries for reports.list (20 classes): " . count($queries) . "\n";

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        // Test search
        DB::enableQueryLog();
        $response = $this->json('GET', route('reports.list', ['search' => 'Grade 1']));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        echo "Total queries for reports.list with search: " . count($queries) . "\n";
        $response->assertStatus(200);
    }
}
