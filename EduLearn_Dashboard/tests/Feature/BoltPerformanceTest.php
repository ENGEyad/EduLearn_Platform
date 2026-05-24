<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    use \Illuminate\Foundation\Testing\RefreshDatabase;

    public function test_dashboard_performance()
    {
        // 1. Setup Data
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

        // Create 20 class sections
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Section '.$i.'A',
            ]);

            // Add 5 students to each section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "AC-$i-$j",
                    'attendance_rate' => 80 + rand(0, 20),
                    'grade' => 'Grade '.$i,
                    'class_section' => 'A',
                ]);
            }
        }

        // 2. Measure Performance
        $this->actingAs($user);

        DB::enableQueryLog();
        DB::flushQueryLog();

        $response = $this->get('/dashboard');

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nDashboard Query Count (Baseline): $queryCount\n";

        $response->assertStatus(200);
    }
}
