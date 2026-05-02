<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\RefreshDatabaseState;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Force sqlite for both connections in tests to avoid connection errors
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);

        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);
    }

    protected function refreshTestDatabase()
    {
        if (! RefreshDatabaseState::$migrated) {
            // Override connections to sqlite for migrations
            config(['database.connections.mysql.driver' => 'sqlite']);
            config(['database.connections.mysql.database' => ':memory:']);
            config(['database.connections.app_mysql.driver' => 'sqlite']);
            config(['database.connections.app_mysql.database' => ':memory:']);

            $this->artisan('migrate:fresh', [
                '--force' => true,
            ]);

            $this->app[Kernel::class]->setArtisan(null);

            RefreshDatabaseState::$migrated = true;
        }

        $this->beginDatabaseTransaction();
    }

    public function test_list_reports_performance()
    {
        // Create a user and authenticate
        $user = User::factory()->create();
        $this->actingAs($user);

        // Create 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            Student::factory()->count(5)->create([
                'grade' => "Grade $i",
                'class_section' => 'A',
            ]);
        }

        // Record queries
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);
        $response->assertJsonCount(10, 'data');

        // Optimized: Only 1 query for counting and grouping
        echo "\nQuery count for listing 10 classes: $queryCount\n";

        $this->assertEquals(1, $queryCount, "Expected exactly 1 query after optimization");
    }

    public function test_list_reports_search_performance()
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        // Create some data
        Student::factory()->create([
            'full_name' => 'John Doe',
            'grade' => 'Grade 1',
            'class_section' => 'A',
        ]);

        Student::factory()->count(10)->create([
            'grade' => 'Grade 2',
            'class_section' => 'B',
        ]);

        DB::enableQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'John']));
        $queryCount = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);
        // Should find the class and the student
        $response->assertJsonFragment(['grade' => 'Grade 1', 'class_section' => 'A']);

        echo "Query count for search: $queryCount\n";
    }
}
