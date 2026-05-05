<?php

namespace Tests\Feature;

use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Support\Facades\Artisan;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function refreshTestDatabase()
    {
        config(['database.connections.mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);

        config(['database.connections.app_mysql' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);

        DB::purge('mysql');
        DB::purge('app_mysql');

        Artisan::call('migrate:fresh');
        $this->app[\Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_list_performance_baseline()
    {
        // Create 10 classes with 2 students each
        for ($i = 1; $i <= 10; $i++) {
            Student::create([
                'full_name' => "Student $i-A",
                'academic_id' => "S$i-A",
                'grade' => "Grade $i",
                'class_section' => "A",
            ]);
            Student::create([
                'full_name' => "Student $i-B",
                'academic_id' => "S$i-B",
                'grade' => "Grade $i",
                'class_section' => "B",
            ]);
        }

        $user = User::factory()->create();

        // Start listening for queries
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queryCount = count(DB::getQueryLog());

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        // Output the query count to console
        fwrite(STDOUT, "\nQuery count for listing 20 classes: $queryCount\n");
    }

    public function test_list_with_search_performance_baseline()
    {
        // Create 10 classes with 2 students each
        for ($i = 1; $i <= 10; $i++) {
            Student::create([
                'full_name' => "Student $i-A",
                'academic_id' => "S$i-A",
                'grade' => "Grade $i",
                'class_section' => "A",
            ]);
            Student::create([
                'full_name' => "Student $i-B",
                'academic_id' => "S$i-B",
                'grade' => "Grade $i",
                'class_section' => "B",
            ]);
        }

        $user = User::factory()->create();

        // Start listening for queries
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list') . '?search=Student');

        $queryCount = count(DB::getQueryLog());

        $response->assertStatus(200);

        // Output the query count to console
        fwrite(STDOUT, "Query count for listing classes with search: $queryCount\n");
    }
}
