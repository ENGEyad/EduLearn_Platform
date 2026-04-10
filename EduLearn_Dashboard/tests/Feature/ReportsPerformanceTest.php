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

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we are using sqlite for both connections in tests
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);
    }

    public function test_reports_list_has_constant_query_count()
    {
        // Seed some data
        $this->seedData(2, 'Batch1');

        DB::connection('mysql')->enableQueryLog();
        DB::connection('mysql')->flushQueryLog();

        $response1 = $this->getJson(route('reports.list'));
        $queryCount1 = count(DB::connection('mysql')->getQueryLog());

        // Seed more data
        $this->seedData(5, 'Batch2');

        DB::connection('mysql')->flushQueryLog();

        $response2 = $this->getJson(route('reports.list'));
        $queryCount2 = count(DB::connection('mysql')->getQueryLog());

        $this->assertEquals($queryCount1, $queryCount2, "Query count increased with more data! N+1 detected. Initial: $queryCount1, After seeding more: $queryCount2");
    }

    private function seedData(int $classCount, string $prefix = '')
    {
        for ($i = 0; $i < $classCount; $i++) {
            $grade = "Grade " . ($i + 1);
            $section = "A";

            ClassSection::create([
                'grade' => ($i + 1),
                'section' => $section,
                'name' => "$grade - $section",
                'is_active' => true,
            ]);

            for ($j = 0; $j < 3; $j++) {
                Student::create([
                    'full_name' => "Student $prefix-$i-$j",
                    'academic_id' => "S-$prefix-$i-$j",
                    'grade' => $grade,
                    'class_section' => $section,
                    'status' => 'Active',
                ]);
            }
        }
    }
}
