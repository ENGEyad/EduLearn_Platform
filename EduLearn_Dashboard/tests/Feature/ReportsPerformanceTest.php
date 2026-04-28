<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\User;
use App\Models\ClassSection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Contracts\Console\Kernel;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function refreshTestDatabase()
    {
        config([
            'database.connections.mysql.driver' => 'sqlite',
            'database.connections.mysql.database' => ':memory:',
            'database.connections.app_mysql.driver' => 'sqlite',
            'database.connections.app_mysql.database' => ':memory:',
        ]);

        $this->artisan('migrate:fresh', [
            '--drop-views' => true,
        ]);

        $this->app[Kernel::class]->setArtisan(null);
    }

    protected function setUp(): void
    {
        parent::setUp();

        // Set up auth user
        $user = User::factory()->create();
        $this->actingAs($user);
    }

    /** @test */
    public function it_measures_query_count_for_reports_list()
    {
        // 1. Seed data: 20 classes with 5 students each
        for ($i = 1; $i <= 20; $i++) {
            $grade = "Grade $i";
            $section = "A";

            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $j in $grade $section",
                    'academic_id' => "S-$i-$j",
                    'grade' => $grade,
                    'class_section' => $section,
                    'status' => 'Active',
                ]);
            }
        }

        // 2. Clear query log and call the endpoint
        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        $queryCount = count($queries);

        echo "\nOptimized Query Count for 20 classes: $queryCount\n";

        // Should be exactly 1 query now
        $this->assertEquals(1, $queryCount, "Query count should be exactly 1 (optimized)");
        $this->assertCount(20, $response->json('data'), "Should return 20 classes");

        // Verify structure
        $firstItem = $response->json('data.0');
        $this->assertArrayHasKey('students_count', $firstItem);
        $this->assertEquals(5, $firstItem['students_count']);
    }

    /** @test */
    public function it_measures_query_count_with_search()
    {
        // Seed 20 classes
        for ($i = 1; $i <= 20; $i++) {
            Student::create([
                'full_name' => "Student $i",
                'academic_id' => "ACAD-$i",
                'grade' => "Grade $i",
                'class_section' => "B",
                'status' => 'Active',
            ]);
        }

        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'MATCH_NOTHING']));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);
        $queryCount = count($queries);

        echo "Optimized Query Count with Search: $queryCount\n";

        // Should be 2 queries: one for grouped classes, one for matching students
        $this->assertEquals(2, $queryCount, "Query count with search should be exactly 2 (optimized)");
    }
}
