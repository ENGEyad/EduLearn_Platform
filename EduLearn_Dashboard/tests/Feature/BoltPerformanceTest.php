<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we are using sqlite for testing
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);
    }

    public function test_dashboard_index_performance()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'School Admin',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 20 class sections
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'name' => "Class $i",
                'grade' => 'Grade ' . ceil($i / 2),
                'section' => $i % 2 == 0 ? 'A' : 'B',
            ]);

            // Create 5 students per section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ACAD-$i-$j",
                    'attendance_rate' => rand(70, 100),
                ]);
            }
        }

        $this->actingAs($user);

        // Clear cache to ensure we measure the actual database queries
        \Illuminate\Support\Facades\Cache::flush();

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('dashboard'));

        $response->assertStatus(200);
        $queryCount = count(DB::getQueryLog());

        dump("Total queries for dashboard: " . $queryCount);

        // We expect a high number of queries due to N+1 (at least 20 for lowAttendanceClasses)
        // If it's already optimized in some memory I didn't see, this will tell us.
    }
}
