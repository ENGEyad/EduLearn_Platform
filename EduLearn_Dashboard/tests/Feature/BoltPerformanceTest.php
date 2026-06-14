<?php

namespace Tests\Feature;

use App\Models\AiReport;
use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    // Removing RefreshDatabase and implementing manual setup to avoid dual sqlite connection issues

    protected function setUp(): void
    {
        parent::setUp();

        // Manual cleanup if needed, but for now we'll rely on unique IDs
    }

    public function test_dashboard_query_count()
    {
        $school = $this->createFullSchoolData();
        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        AiReport::create([
            'school_id' => $school->id,
            'user_id' => $user->id,
            'status' => 'completed',
            'title' => 'Test Report',
            'dashboard_summary' => 'Summary',
        ]);

        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('dashboard'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nDashboard Query Count: ".$queryCount."\n";

        $response->assertStatus(200);
        $this->assertNotEmpty($queries);

        // We expect a high number of queries initially due to N+1
        // Baseline identified in memory was 28 for 10 sections.
    }

    public function test_reports_list_query_count()
    {
        // For Reports list, we don't need attempts table from app_mysql if we don't create them
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-'.uniqid(),
            'email' => 'test'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        for ($i = 1; $i <= 5; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                $section = ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $i,
                    'section' => $j == 1 ? 'أ' : 'ب',
                    'name' => "Class $i-".($j == 1 ? 'A' : 'B'),
                    'is_active' => true,
                ]);
                for ($k = 1; $k <= 2; $k++) {
                    Student::create([
                        'school_id' => $school->id,
                        'class_section_id' => $section->id,
                        'full_name' => "Student $i-$j-$k",
                        'academic_id' => "ACAD-$i-$j-$k-".uniqid(),
                        'grade' => $i,
                        'class_section' => $section->section,
                    ]);
                }
            }
        }

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin'.uniqid().'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('reports.list'));

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nReports List Query Count: ".$queryCount."\n";

        $response->assertStatus(200);

        // Baseline identified in memory was 22 for 20 classes.
    }

    private function createFullSchoolData()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-'.uniqid(),
            'email' => 'test'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // Create 10 class sections
        for ($i = 1; $i <= 5; $i++) {
            for ($j = 1; $j <= 2; $j++) {
                $section = ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $i,
                    'section' => $j == 1 ? 'أ' : 'ب',
                    'name' => "Class $i-".($j == 1 ? 'A' : 'B'),
                    'is_active' => true,
                ]);

                // Create 5 students per section
                for ($k = 1; $k <= 5; $k++) {
                    $student = Student::create([
                        'school_id' => $school->id,
                        'class_section_id' => $section->id,
                        'full_name' => "Student $i-$j-$k",
                        'academic_id' => "ACAD-$i-$j-$k-".uniqid(),
                        'grade' => $i,
                        'class_section' => $section->section,
                        'attendance_rate' => rand(70, 100),
                    ]);

                    // Create some attempts
                    StudentExerciseAttempt::create([
                        'student_id' => $student->id,
                        'exercise_set_id' => 1,
                        'exercise_version_id' => 1,
                        'lesson_id' => 1,
                        'score' => rand(50, 100),
                        'created_at' => now(),
                    ]);
                }
            }
        }

        return $school;
    }
}
