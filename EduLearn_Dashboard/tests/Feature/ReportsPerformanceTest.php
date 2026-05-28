<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use App\Models\ClassSection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we use sqlite for testing
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);

        // Override both mysql and app_mysql to use the same in-memory sqlite connection
        config(['database.connections.mysql' => config('database.connections.sqlite')]);
        config(['database.connections.app_mysql' => config('database.connections.sqlite')]);
    }

    public function test_reports_list_performance()
    {
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

        // Create 10 classes, each with 2 sections, and 5 students per section
        // Total 20 class sections, 100 students
        for ($i = 1; $i <= 10; $i++) {
            foreach (['A', 'B'] as $section) {
                // We create ClassSection if it exists in the system
                $cs = ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => $i,
                    'section' => $section,
                    'name' => "Grade $i - $section",
                ]);

                for ($j = 1; $j <= 5; $j++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student $i-$section-$j",
                        'academic_id' => "AC-$i-$section-$j",
                        'grade' => "Grade $i",
                        'class_section' => $section,
                        'class_section_id' => $cs->id,
                        'attendance_rate' => 90,
                    ]);
                }
            }
        }

        $this->actingAs($user);

        DB::connection()->enableQueryLog();
        $response = $this->getJson(route('reports.list'));
        $queries = DB::getQueryLog();

        $response->assertStatus(200);

        $count = count($queries);
        dump("Total queries for reports.list (no search): " . $count);

        // Optimized: 1 (grouped query) + 1 (auth user) = 2 queries
        $this->assertLessThan(5, $count, "Too many queries in reports.list (no search)");

        // Test with search
        DB::flushQueryLog();
        $response = $this->getJson(route('reports.list', ['search' => 'Student 1-A-1']));
        $queries = DB::getQueryLog();

        $response->assertStatus(200);
        $countSearch = count($queries);
        dump("Total queries for reports.list (with search): " . $countSearch);

        // Optimized: 1 (grouped query with whereExists) + 1 (student search query) + 1 (auth user) = 3 queries
        $this->assertLessThan(10, $countSearch, "Too many queries in reports.list (with search)");
    }
}
