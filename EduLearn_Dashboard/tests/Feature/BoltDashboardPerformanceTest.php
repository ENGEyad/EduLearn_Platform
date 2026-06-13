<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltDashboardPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Manual cleanup for SQLite since RefreshDatabase might struggle with multi-connection
        \Illuminate\Support\Facades\Schema::connection('mysql')->dropAllTables();
        \Illuminate\Support\Facades\Schema::connection('app_mysql')->dropAllTables();

        $this->artisan('migrate', ['--force' => true]);
    }

    public function test_dashboard_query_count()
    {
        // Setup
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
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Grade ' . $i . ' - A',
                'is_active' => true,
            ]);

            // Add 5 students to each section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student {$i}-{$j}",
                    'last_name' => "Last",
                    'first_name' => "Student {$i}-{$j}",
                    'academic_id' => "ACAD-{$i}-{$j}",
                    'attendance_rate' => 80 + $j, // Some will be below 85
                ]);
            }
        }

        $this->actingAs($user);

        // Warm up cache or ensure we are testing the right thing
        // We want to measure the queries when cache is EMPTY first, then maybe when it's FULL.
        // But the N+1 is inside the cache closure.
        \Illuminate\Support\Facades\Cache::flush();

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('dashboard'));

        $response->assertStatus(200);

        $queryCount = count(DB::getQueryLog());

        // With 10 sections:
        // 1. Session/User (auth)
        // 2. School
        // 3. Student pluck IDs
        // 4. ClassSection withCount students
        // 5. Performance overall (avg score)
        // 6. Attendance overall (avg rate)
        // 7. Teacher count
        // 8. ClassSection count (REDUNDANT)
        // 9. Subjects count (whereHas)
        // 10. Dangling students count
        // 11. Current performance avg
        // 12. Previous performance avg
        // 13. Low attendance students count
        // 14. Low performance students (groupBy student_id)
        // 15-24. Low attendance classes (N queries for N sections) - THIS IS THE N+1
        // 25. Latest report
        // 26. Latest report (REDUNDANT)

        // Plus some Laravel boilerplate (session, etc.)

        dump("Total queries for dashboard: " . $queryCount);

        // We expect it to be high now. We'll optimize it to be constant or significantly lower.
        $this->assertLessThan(40, $queryCount);
    }
}
