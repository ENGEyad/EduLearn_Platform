<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\User;
use App\Services\DashboardAnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function refreshTestDatabase()
    {
        $this->artisan('migrate:fresh', [
            '--force' => true,
        ]);

        // Override connections for test
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

        $this->artisan('migrate', [
            '--force' => true,
        ]);
    }

    public function test_dashboard_analytics_query_count()
    {
        // 1. Setup Data
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 classes
        $sections = [];
        for ($i = 1; $i <= 10; $i++) {
            $sections[] = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Class ' . $i . 'A',
            ]);
        }

        // Create 100 students (10 per class)
        foreach ($sections as $section) {
            for ($j = 1; $j <= 10; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student {$section->id}_{$j}",
                    'academic_id' => "ACAD_{$section->id}_{$j}",
                    'attendance_rate' => rand(70, 100),
                ]);
            }
        }

        // Create 5 teachers
        for ($i = 1; $i <= 5; $i++) {
            Teacher::create([
                'school_id' => $school->id,
                'full_name' => "Teacher {$i}",
                'teacher_code' => "T{$i}",
            ]);
        }

        // Create 5 subjects
        for ($i = 1; $i <= 5; $i++) {
            Subject::create([
                'name_en' => "Subject {$i}",
                'code' => "SUB{$i}",
            ]);
        }

        // 2. Profile Queries
        DB::connection()->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        $service = app(DashboardAnalyticsService::class);
        $overview = $service->buildOverview($school->id, 'week', $school->name);

        $defaultQueries = DB::connection()->getQueryLog();
        $appMysqlQueries = DB::connection('app_mysql')->getQueryLog();
        $totalQueries = count($defaultQueries) + count($appMysqlQueries);

        dump("Total Queries: " . $totalQueries);
        foreach ($defaultQueries as $q) {
            dump("[default] " . $q['query']);
        }
        foreach ($appMysqlQueries as $q) {
            dump("[app_mysql] " . $q['query']);
        }

        // Assertions
        $this->assertIsArray($overview);
        $this->assertEquals(100, $overview['stats']['students']);

        // We expect around 11-12 queries after optimization
        // 1 (pluck student ids)
        // 1 (sections with count students and avg attendance)
        // 1 (overall avg score)
        // 1 (overall avg attendance)
        // 1 (count teachers)
        // 1 (count subjects)
        // 1 (count dangling students)
        // 1 (current avg score)
        // 1 (previous avg score)
        // 1 (count low attendance students)
        // 1 (low performance students)
        // Total expected around 11-12 queries

        $this->assertLessThan(30, $totalQueries, "Query count should be reasonable");
    }
}
