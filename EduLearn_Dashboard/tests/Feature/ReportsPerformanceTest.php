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

    /**
     * Override createApplication() directly inside the feature test class to dynamically
     * set the 'mysql' and 'app_mysql' connections to in-memory SQLite.
     * This isolates the override to this specific test context without polluting global configuration.
     */
    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        // Dynamically override connections to use sqlite for dual database support in tests
        $app['config']->set('database.connections.mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);
        $app['config']->set('database.connections.app_mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);

        return $app;
    }

    protected function setUp(): void
    {
        parent::setUp();
    }

    public function test_list_performance_optimized()
    {
        $school = School::create([
            'name' => 'Performance Test School',
            'slug' => 'perf-school-'.uniqid(),
            'email' => 'admin-'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Test User',
            'email' => 'test'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 class sections with 1 student each
        for ($i = 1; $i <= 20; $i++) {
            Student::create([
                'school_id' => $school->id,
                'full_name' => "Student $i",
                'academic_id' => "ACAD-$i-".uniqid(),
                'grade' => "Grade $i",
                'class_section' => 'Section A',
            ]);
        }

        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);

        // N+1 baseline would execute 21 queries. With optimization, it should execute only 1 core query (+ some auth queries)
        $this->assertLessThan(6, $queryCount, "Expected optimized constant queries. Found: $queryCount");

        fwrite(STDERR, "\n[BOLT] Optimized Class List Query Count: $queryCount (Baseline: 21+)\n");

        $response->assertJsonCount(20, 'data');
    }

    public function test_list_with_search_performance_optimized()
    {
        $school = School::create([
            'name' => 'Performance Test School',
            'slug' => 'perf-school-'.uniqid(),
            'email' => 'admin-'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Test User',
            'email' => 'test'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        for ($i = 1; $i <= 20; $i++) {
            Student::create([
                'school_id' => $school->id,
                'full_name' => "Student $i",
                'academic_id' => "ACAD-S-$i-".uniqid(),
                'grade' => "Grade $i",
                'class_section' => 'Section A',
            ]);
        }

        DB::enableQueryLog();

        // Search that matches a class name
        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 1']));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);
        $this->assertLessThan(6, $queryCount, "Expected optimized constant queries with search. Found: $queryCount");

        fwrite(STDERR, "\n[BOLT] Optimized Class Search Query Count: $queryCount (Baseline: 42+)\n");

        // "Grade 1 - Section A" should match
        $response->assertJsonFragment(['grade' => 'Grade 1', 'class_section' => 'Section A', 'students_count' => 1]);
    }
}
