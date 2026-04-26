<?php

namespace Tests\Feature;

use App\Models\ClassSection;
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

        // Set up in-memory sqlite for both connections
        config([
            'database.connections.mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
            'database.connections.app_mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
        ]);
    }

    protected function refreshTestDatabase()
    {
        if (! $this->app) {
            $this->refreshApplication();
        }

        // Force sqlite for both connections during migration
        config([
            'database.default' => 'sqlite',
            'database.connections.mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
            'database.connections.app_mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
        ]);

        $this->artisan('migrate:fresh');

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_reports_list_is_efficient()
    {
        // Create a user for authentication
        $user = User::factory()->create();

        // Seed 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            $grade = "Grade $i";
            $section = "A";

            $cs = ClassSection::create([
                'grade' => $i,
                'section' => $section,
                'name' => "$grade - $section",
                'is_active' => true,
            ]);

            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $j in Class $i",
                    'academic_id' => "S-$i-$j",
                    'grade' => $grade,
                    'class_section' => $section,
                    'class_section_id' => $cs->id,
                ]);
            }
        }

        $queryCount = 0;
        DB::listen(function ($query) use (&$queryCount) {
            // Filter out internal Laravel/PHPUnit queries if any
            if (str_contains($query->sql, 'students') || str_contains($query->sql, 'class_sections')) {
                $queryCount++;
            }
        });

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $response->assertStatus(200);
        $response->assertJsonCount(10, 'data');

        // Optimized should be 1 query for students with count and group by.
        $this->assertEquals(1, $queryCount, "Reports list performed more than 1 student query: $queryCount");
    }

    public function test_reports_list_search_is_efficient()
    {
        $user = User::factory()->create();

        // Seed 5 classes
        for ($i = 1; $i <= 5; $i++) {
            $grade = "Grade $i";
            $section = "A";
            $cs = ClassSection::create(['grade' => $i, 'section' => $section, 'name' => "$grade - $section", 'is_active' => true]);
            Student::create(['full_name' => "Student $i", 'academic_id' => "S-$i", 'grade' => $grade, 'class_section' => $section, 'class_section_id' => $cs->id]);
        }

        $queryCount = 0;
        DB::listen(function ($query) use (&$queryCount) {
            if (str_contains($query->sql, 'students') || str_contains($query->sql, 'class_sections')) {
                $queryCount++;
            }
        });

        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 1']));

        $response->assertStatus(200);

        // Optimized search:
        // 1 query for classes matching search (with count)
        // 1 query for students matching search
        $this->assertLessThanOrEqual(2, $queryCount, "Reports list search performed too many queries: $queryCount");
    }
}
