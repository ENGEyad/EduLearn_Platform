<?php

namespace Tests\Feature;

use App\Models\ClassSection;
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

        // Manual cleanup to simulate RefreshDatabase across two connections
        Schema::connection('mysql')->dropAllTables();
        Schema::connection('app_mysql')->dropAllTables();

        $this->artisan('migrate', ['--force' => true]);
    }

    /** @test */
    public function it_measures_reports_list_query_count()
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

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => (string) $i,
                'section' => 'A',
                'name' => "Grade $i - A",
            ]);

            // Create 5 students per section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ACAD-$i-$j",
                    'grade' => $section->grade,
                    'class_section' => $section->section,
                    'attendance_rate' => 90,
                ]);
            }
        }

        $this->actingAs($user);

        DB::connection('mysql')->enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $queries = DB::connection('mysql')->getQueryLog();
        $queryCount = count($queries);

        echo "\nReports List Query Count: $queryCount\n";

        $response->assertStatus(200);
    }

    /** @test */
    public function it_measures_dashboard_index_query_count()
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

        // Create 5 class sections
        for ($i = 1; $i <= 5; $i++) {
            ClassSection::create([
                'school_id' => $school->id,
                'grade' => (string) $i,
                'section' => 'A',
                'name' => "Grade $i - A",
            ]);
        }

        $this->actingAs($user);

        // Clear cache to ensure buildOverview is called
        \Illuminate\Support\Facades\Cache::flush();

        DB::connection('mysql')->enableQueryLog();

        $response = $this->get(route('dashboard'));

        $queries = DB::connection('mysql')->getQueryLog();
        $queryCount = count($queries);

        echo "\nDashboard Index Query Count: $queryCount\n";

        $response->assertStatus(200);
    }
}
