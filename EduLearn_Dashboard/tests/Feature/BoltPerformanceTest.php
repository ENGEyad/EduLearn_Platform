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
            'name' => 'Admin User',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create some data to trigger N+1
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Section ' . $i,
            ]);

            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ACAD-$i-$j",
                    'attendance_rate' => 80,
                ]);
            }
        }

        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get('/dashboard');

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nDashboard Query Count: " . $queryCount . "\n";

        $response->assertStatus(200);
    }
}
