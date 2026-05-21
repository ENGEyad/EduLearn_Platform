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
        $db1 = database_path('test_mysql.sqlite');
        $db2 = database_path('test_app_mysql.sqlite');

        if (file_exists($db1)) unlink($db1);
        if (file_exists($db2)) unlink($db2);

        touch($db1);
        touch($db2);

        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => $db1]);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => $db2]);

        $this->artisan('migrate', [
            '--force' => true,
        ]);

        \Illuminate\Support\Facades\DB::purge('mysql');
        \Illuminate\Support\Facades\DB::purge('app_mysql');

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_dashboard_overview_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 classes
        $sections = [];
        for ($i = 1; $i <= 10; $i++) {
            $sections[] = ClassSection::create([
                'school_id' => $school->id,
                'grade' => $i,
                'section' => 'A',
                'name' => "Class $i-A",
            ]);
        }

        // Create students and attempts
        foreach ($sections as $section) {
            for ($j = 1; $j <= 5; $j++) {
                $student = Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student {$section->id}-{$j}",
                    'attendance_rate' => rand(70, 100),
                ]);

                StudentExerciseAttempt::create([
                    'student_id' => $student->id,
                    'score' => rand(50, 100),
                    'created_at' => now(),
                    'exercise_set_id' => 1,
                    'exercise_version_id' => 1,
                    'lesson_id' => 1,
                ]);
            }
        }

        $service = app(DashboardAnalyticsService::class);

        DB::connection('mysql')->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        DB::connection('mysql')->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        DB::connection('mysql')->flushQueryLog();
        DB::connection('app_mysql')->flushQueryLog();

        $analytics = $service->buildOverview($school->id, 'week', $school->name);

        $mysqlQueries = DB::connection('mysql')->getQueryLog();
        $appMysqlQueries = DB::connection('app_mysql')->getQueryLog();

        $totalQueries = count($mysqlQueries) + count($appMysqlQueries);

        $this->assertLessThan(50, $totalQueries);
    }
}
