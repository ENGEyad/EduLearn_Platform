<?php

namespace Tests\Feature;

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

        // Ensure both connections use sqlite memory for tests
        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);
    }

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    protected function refreshTestDatabase()
    {
        $this->artisan('migrate:fresh');

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_list_performance()
    {
        // Setup: Create 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $i-$j",
                    'academic_id' => "S$i$j",
                    'grade' => "Grade $i",
                    'class_section' => "A",
                ]);
            }
        }

        $user = User::factory()->create();

        DB::enableQueryLog();
        $response = $this->actingAs($user)->getJson(route('reports.list'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        // Optimized: Should be exactly 1 query for students (+ maybe 1-2 for auth session/user)
        $this->assertLessThan(5, count($queries), "Too many queries: " . count($queries));

        $data = $response->json('data');
        $this->assertCount(10, $data);
        $this->assertEquals(5, $data[0]['students_count']);
    }

    public function test_list_with_search_performance()
    {
        // Setup: Create 10 classes with 5 students each
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'full_name' => "Student $i-$j",
                    'academic_id' => "S$i$j",
                    'grade' => "Grade $i",
                    'class_section' => "A",
                ]);
            }
        }

        $user = User::factory()->create();

        DB::enableQueryLog();
        // Search that doesn't match class name but matches some students
        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Student 1-1']));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        // Optimized search: Should also be very few queries
        $this->assertLessThan(10, count($queries), "Too many queries with search: " . count($queries));

        $students = $response->json('students');
        $this->assertNotEmpty($students);
    }
}
