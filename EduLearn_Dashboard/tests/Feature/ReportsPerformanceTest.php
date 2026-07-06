<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_reports_list_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'school_id' => $school->id,
            'name' => 'Admin User',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
        ]);

        // Create 20 class sections with students
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => (string) $i,
                'section' => 'A',
                'name' => "Grade $i - A",
                'name_en' => "Grade $i - A",
            ]);

            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student $j in Class $i",
                    'academic_id' => "STU-$i-$j-".uniqid(),
                    'grade' => (string) $i,
                    'class_section' => 'A',
                    'class_section_id' => $section->id,
                ]);
            }
        }

        $this->actingAs($user);

        // Start counting queries
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $response->assertStatus(200);

        $queryCount = count(DB::getQueryLog());

        // Output query count for Bolt to see
        echo "\nTotal queries for 20 classes: ".$queryCount."\n";

        // Optimization: We now expect only 2 queries (one for classes with counts, one for notifications in AppServiceProvider)
        $this->assertLessThanOrEqual(2, $queryCount);
    }
}
