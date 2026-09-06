<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = parent::createApplication();
        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));
        DB::extend('app_mysql', fn() => DB::connection('sqlite'));
        return $app;
    }

    public function test_reports_list_executes_minimal_queries_for_standard_list()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        for ($i = 1; $i <= 5; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                $grade = "Grade {$i}";
                $section = "Section {$j}";

                ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $grade,
                    'section' => $section,
                    'name' => "{$grade} - {$section}",
                    'name_en' => "{$grade} - {$section}",
                ]);

                for ($k = 1; $k <= 3; $k++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student {$i}-{$j}-{$k}",
                        'academic_id' => "STU-{$i}{$j}{$k}",
                        'grade' => $grade,
                        'class_section' => $section,
                    ]);
                }
            }
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);
        $response->assertJsonCount(10, 'data');
        $this->assertEquals(3, $response->json('data.0.students_count'));

        // Query count for list should be <= 2 queries
        $this->assertLessThanOrEqual(2, $queryCount);
    }

    public function test_reports_list_executes_minimal_queries_when_searching()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        for ($i = 1; $i <= 5; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                $grade = "Grade {$i}";
                $section = "Section {$j}";

                ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $grade,
                    'section' => $section,
                    'name' => "{$grade} - {$section}",
                    'name_en' => "{$grade} - {$section}",
                ]);

                for ($k = 1; $k <= 3; $k++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student {$i}-{$j}-{$k}",
                        'academic_id' => "STU-{$i}{$j}{$k}",
                        'grade' => $grade,
                        'class_section' => $section,
                    ]);
                }
            }
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->actingAs($user)->getJson(route('reports.list', ['search' => 'Grade 1']));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        $response->assertStatus(200);
        $response->assertJsonCount(2, 'data');

        // Query count with search should be <= 3 queries (including matching student query)
        $this->assertLessThanOrEqual(3, $queryCount);
    }
}
