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

    public function test_dashboard_query_count()
    {
        // Setup data
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

        // Create 10 classes, each with 2 sections (total 20 sections)
        for ($i = 1; $i <= 10; $i++) {
            foreach (['A', 'B'] as $sectionLabel) {
                $cs = ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $i,
                    'section' => $sectionLabel,
                    'name' => "Grade $i - $sectionLabel",
                    'is_active' => true,
                ]);

                // Create 5 students per section
                for ($j = 1; $j <= 5; $j++) {
                    $student = Student::create([
                        'school_id' => $school->id,
                        'class_section_id' => $cs->id,
                        'full_name' => "Student $i$sectionLabel$j",
                        'academic_id' => "ID$i$sectionLabel$j",
                        'attendance_rate' => 80 + $j, // Some below 85
                    ]);

                    // Create some exercise attempts
                    DB::connection('app_mysql')->table('student_exercise_attempts')->insert([
                        'student_id' => $student->id,
                        'exercise_set_id' => 1,
                        'exercise_version_id' => 1,
                        'lesson_id' => 1,
                        'score' => 75,
                        'total_points' => 100,
                        'status' => 'graded',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }
        }

        $this->actingAs($user);

        // Warm up cache or ensure it's clear
        \Illuminate\Support\Facades\Cache::flush();

        DB::connection()->enableQueryLog();
        DB::connection('app_mysql')->enableQueryLog();

        $startTime = microtime(true);

        $service = app(DashboardAnalyticsService::class);
        $result = $service->buildOverview($school->id, 'week', $school->name);

        $endTime = microtime(true);

        $mysqlQueries = DB::connection()->getQueryLog();
        $appMysqlQueries = DB::connection('app_mysql')->getQueryLog();
        $queriesCount = count($mysqlQueries) + count($appMysqlQueries);

        dump('Total Queries: '.$queriesCount);
        dump('MySQL Queries: '.count($mysqlQueries));
        dump('App MySQL Queries: '.count($appMysqlQueries));

        dump('Execution Time: '.round(($endTime - $startTime) * 1000, 2).'ms');

        // Optimized expectation:
        // 1. Students pluck ID
        // 2. ClassSections withCount students AND withAvg attendance_rate
        // 3. StudentExerciseAttempt avg score (overall)
        // 4. Students avg attendance (overall)
        // 5. Teacher count
        // 6. Subject count (whereHas classSections)
        // 7. Students whereNull class_section_id count
        // 8. StudentExerciseAttempt avg score (current period)
        // 9. StudentExerciseAttempt avg score (previous period)
        // 10. Students low attendance count
        // 11. StudentExerciseAttempt low performance (havingRaw)

        // Total should be around 11 queries (7 mysql + 4 app_mysql).
        $this->assertEquals(11, $queriesCount, 'Query count should be exactly 11 after optimization');
    }
}
