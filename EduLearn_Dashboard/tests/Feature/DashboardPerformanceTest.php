<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use App\Models\Subject;
use App\Models\StudentExerciseAttempt;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Setup school and user
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'is_initialized' => true,
            'status' => 'active',
        ]);
        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin'
        ]);
        $this->actingAs($user);

        // Create 10 classes, each with 20 students
        for ($i = 1; $i <= 10; $i++) {
            $class = ClassSection::create([
                'school_id' => $school->id,
                'grade' => $i,
                'section' => 'A',
                'name' => "Grade $i - A",
                'is_active' => true,
            ]);

            for ($j = 1; $j <= 20; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $class->id,
                    'full_name' => "Student $i-$j",
                    'attendance_rate' => 80, // trigger low attendance
                ]);
            }

            // Create some subjects for these classes
            $subject = Subject::create([
                'name' => "Subject $i",
                'name_en' => "Subject $i",
                'name_ar' => "المادة $i",
                'code' => "SUB-$i",
            ]);
            $class->subjects()->attach($subject->id, ['is_active' => true]);
        }

        // Create some teachers
        for ($i = 1; $i <= 5; $i++) {
            Teacher::create([
                'school_id' => $school->id,
                'full_name' => "Teacher $i",
                'teacher_code' => "T-$i",
                'status' => 'Active',
            ]);
        }

        // Create some attempts
        $students = Student::where('school_id', $school->id)->get();
        foreach ($students->take(50) as $student) {
            StudentExerciseAttempt::create([
                'student_id' => $student->id,
                'exercise_set_id' => 1,
                'exercise_version_id' => 1,
                'lesson_id' => 1,
                'score' => 60, // trigger low performance
            ]);
        }
    }

    public function test_dashboard_index_query_count()
    {
        DB::enableQueryLog();

        $response = $this->get(route('dashboard'));
        $response->assertStatus(200);

        $queryCount = count(DB::getQueryLog());
        dump("Dashboard Index Query Count: " . $queryCount);

        // We expect a high number initially due to N+1 in DashboardAnalyticsService
        $this->assertTrue($queryCount > 0);
    }
}
