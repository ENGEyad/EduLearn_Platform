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
    public function test_dashboard_query_count()
    {
        $unique = uniqid();
        // 1. Setup Data
        $school = School::create([
            'name' => 'Bolt Performance School '.$unique,
            'slug' => 'bolt-school-'.$unique,
            'email' => 'admin'.$unique.'@bolt.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Bolt Admin',
            'email' => 'bolt'.$unique.'@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => (string) $i,
                'section' => 'A',
                'name' => 'Section '.$unique.' '.$i,
                'is_active' => true,
            ]);

            // Add 5 students to each section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $unique $i-$j",
                    'academic_id' => "ACAD-$unique-$i-$j",
                    'attendance_rate' => 80 + $j, // Some below 85
                    'grade' => (string) $i,
                    'class_section' => 'A',
                ]);
            }
        }

        // 2. Measure Performance
        $this->actingAs($user);

        DB::connection('mysql')->enableQueryLog();
        DB::connection('mysql')->flushQueryLog();

        $response = $this->get(route('dashboard'));

        $queries = DB::connection('mysql')->getQueryLog();
        $queryCount = count($queries);

        echo "\n⚡ Bolt Dashboard Query Count: $queryCount\n";

        $response->assertStatus(200);
    }
}
