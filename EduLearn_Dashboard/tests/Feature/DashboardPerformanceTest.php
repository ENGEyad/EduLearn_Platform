<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardPerformanceTest extends TestCase
{
    // Removing RefreshDatabase for now to avoid migration issues with dual sqlite
    // use RefreshDatabase;

    public function test_dashboard_index_query_count()
    {
        // Cleanup
        DB::statement('DELETE FROM students');
        DB::statement('DELETE FROM class_sections');
        DB::statement('DELETE FROM users');
        DB::statement('DELETE FROM schools');

        // Setup
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-' . uniqid(),
            'email' => 'test' . uniqid() . '@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $admin = User::create([
            'name' => 'Admin',
            'email' => 'admin' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 class sections
        for ($i = 1; $i <= 10; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'name' => "Class $i",
                'grade' => "Grade $i",
                'section' => "A",
                'is_active' => true,
            ]);

            // Create some students for each section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'first_name' => "Student $j",
                    'last_name' => "Section $i",
                    'full_name' => "Student $j Section $i",
                    'academic_id' => "SEC{$i}STU{$j}" . uniqid(),
                    'attendance_rate' => 80 + $j, // Some will be < 85
                ]);
            }
        }

        $this->actingAs($admin);

        // Track queries
        DB::enableQueryLog();
        $response = $this->get(route('dashboard'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $response->assertStatus(200);

        $queryCount = count($queries);
        dump("Total queries for dashboard with 10 sections: " . $queryCount);

        foreach($queries as $query) {
            // dump($query['query']);
        }
    }
}
