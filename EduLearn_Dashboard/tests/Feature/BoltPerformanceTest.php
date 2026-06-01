<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we are using sqlite for testing with actual files for persistence across connections
        $dbPath = base_path('database/test_database.sqlite');
        $appDbPath = base_path('database/test_app_database.sqlite');

        if (! file_exists($dbPath)) {
            touch($dbPath);
        }
        if (! file_exists($appDbPath)) {
            touch($appDbPath);
        }

        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => $dbPath]);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => $appDbPath]);

        // Manual cleanup and migration for both connections
        Schema::connection('mysql')->dropAllTables();
        Schema::connection('app_mysql')->dropAllTables();

        $this->artisan('migrate', ['--database' => 'mysql', '--force' => true]);
        // The migrations themselves target connections, but we need to make sure both are ready.
        // Actually Laravel migrations usually handle the connection specified in the migration file.
    }

    public function test_reports_list_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 classes (10 grades * 2 sections)
        for ($g = 1; $g <= 10; $g++) {
            for ($s = 1; $s <= 2; $s++) {
                Student::create([
                    'school_id' => $school->id,
                    'grade' => "Grade $g",
                    'class_section' => "Section $s",
                    'first_name' => 'Student',
                    'last_name' => "$g-$s",
                    'full_name' => "Student $g-$s",
                    'academic_id' => "ACAD-$g-$s",
                ]);
            }
        }

        $this->actingAs($user);

        // Measure queries for listing without search
        DB::connection('mysql')->enableQueryLog();
        $response = $this->getJson(route('reports.list'));
        $queryCount = count(DB::connection('mysql')->getQueryLog());
        DB::connection('mysql')->disableQueryLog();

        $response->assertStatus(200);

        echo "\nReports List Queries without search for 20 classes: $queryCount\n";

        // Measure queries with search
        DB::connection('mysql')->flushQueryLog();
        DB::connection('mysql')->enableQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'Student']));
        $queryCountSearch = count(DB::connection('mysql')->getQueryLog());
        DB::connection('mysql')->disableQueryLog();

        $response->assertStatus(200);
        echo "Reports List Queries with search for 20 classes: $queryCountSearch\n";

        // Post-optimization, we expect a constant number of queries
        $this->assertLessThan(10, $queryCount, 'Reports list should be optimized');
        $this->assertLessThan(10, $queryCountSearch, 'Reports list search should be optimized');
    }

    public function test_dashboard_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 class sections
        for ($i = 1; $i <= 20; $i++) {
            \App\Models\ClassSection::create([
                'school_id' => $school->id,
                'grade' => "Grade $i",
                'section' => 'A',
                'name' => "Class $i",
            ]);
        }

        $this->actingAs($user);

        // We clear cache to ensure we hit the DB
        \Illuminate\Support\Facades\Cache::flush();

        DB::connection('mysql')->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();
        $response = $this->get('/dashboard');
        $queryCount = count(DB::connection('mysql')->getQueryLog()) + count(DB::connection('app_mysql')->getQueryLog());
        DB::connection('mysql')->disableQueryLog();
        DB::connection('app_mysql')->disableQueryLog();

        $response->assertStatus(200);
        echo "\nDashboard queries for 20 classes: $queryCount\n";

        // Post-optimization, we expect a significantly lower number
        $this->assertLessThan(25, $queryCount, 'Dashboard query count should be optimized');
    }
}
