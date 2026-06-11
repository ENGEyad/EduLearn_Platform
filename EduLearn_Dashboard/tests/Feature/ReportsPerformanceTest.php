<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Manual cleanup for dual connections as per project patterns
        Schema::connection('mysql')->dropAllTables();
        Schema::connection('app_mysql')->dropAllTables();

        $this->artisan('migrate');
    }

    public function test_list_classes_performance()
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

        // Create 20 class sections (10 grades * 2 sections each)
        for ($g = 1; $g <= 10; $g++) {
            for ($s = 1; $s <= 2; $s++) {
                $section = $s == 1 ? 'A' : 'B';
                ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $g,
                    'section' => $section,
                    'name' => "Grade $g - $section",
                    'is_active' => true,
                ]);

                // Create 5 students in each section
                for ($st = 1; $st <= 5; $st++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student $g-$section-$st",
                        'academic_id' => "ID-$g-$section-$st",
                        'grade' => "$g", // Current code expects number as string or similar
                        'class_section' => $section,
                        'status' => 'Active',
                    ]);
                }
            }
        }

        $this->actingAs($user);

        // 2. Measure WITHOUT search
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'));

        $response->assertStatus(200);
        $queriesWithoutSearch = count(DB::getQueryLog());
        DB::disableQueryLog();

        // 3. Measure WITH search
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list', ['search' => 'Student']));

        $response->assertStatus(200);
        $queriesWithSearch = count(DB::getQueryLog());
        DB::disableQueryLog();

        echo "\nPerformance metrics for ReportsController::list (20 classes):\n";
        echo "Queries without search: $queriesWithoutSearch\n";
        echo "Queries with search: $queriesWithSearch\n";

        // Baseline expectations:
        // Without search: 1 (base classes) + 20 (count) = 21 queries (+ maybe some auth/middleware)
        // With search: 1 (base classes) + 20 (exists) + 20 (count) + 1 (matching students) = 42 queries (+ maybe some auth/middleware)

        $this->assertTrue($queriesWithoutSearch < 5, "Optimization failed: too many queries without search ($queriesWithoutSearch)");
        $this->assertTrue($queriesWithSearch < 5, "Optimization failed: too many queries with search ($queriesWithSearch)");
    }
}
