<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Manual cleanup for dual connections
        // We use fresh database files for each run anyway, but let's be sure.
        foreach (['mysql', 'app_mysql'] as $conn) {
            try {
                Schema::connection($conn)->dropAllTables();
            } catch (\Exception $e) {
            }
            $this->artisan('migrate', ['--database' => $conn, '--force' => true]);
        }
    }

    public function test_baseline_performance()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin'.uniqid().'@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Create 20 class sections
        for ($i = 1; $i <= 10; $i++) {
            foreach (['A', 'B'] as $section) {
                $cs = ClassSection::create([
                    'school_id' => $school->id,
                    'grade' => (string) $i,
                    'section' => $section,
                    'name' => "Grade $i - $section",
                    'is_active' => true,
                ]);

                // Add 5 students to each section
                for ($j = 1; $j <= 5; $j++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student $i$section$j",
                        'academic_id' => "ID-$i$section-$j-".uniqid(),
                        'grade' => (string) $i,
                        'class_section' => $section,
                        'class_section_id' => $cs->id,
                        'attendance_rate' => 90,
                    ]);
                }
            }
        }

        $this->actingAs($user);

        // 1. Measure Reports List
        DB::connection('sqlite')->flushQueryLog();
        DB::connection('mysql')->flushQueryLog();
        DB::connection('sqlite')->enableQueryLog();
        DB::connection('mysql')->enableQueryLog();

        $this->getJson(route('reports.list'));

        $reportsQueryCount = count(DB::connection('sqlite')->getQueryLog()) + count(DB::connection('mysql')->getQueryLog());
        echo "\nReports List Query Count (20 classes): ".$reportsQueryCount."\n";

        DB::connection('sqlite')->disableQueryLog();
        DB::connection('mysql')->disableQueryLog();

        // 2. Measure Dashboard
        DB::connection('sqlite')->flushQueryLog();
        DB::connection('mysql')->flushQueryLog();
        DB::connection('sqlite')->enableQueryLog();
        DB::connection('mysql')->enableQueryLog();

        $this->get(route('dashboard'));

        $dashboardQueryCount = count(DB::connection('sqlite')->getQueryLog()) + count(DB::connection('mysql')->getQueryLog());
        echo 'Dashboard Query Count (20 sections): '.$dashboardQueryCount."\n";

        DB::connection('sqlite')->disableQueryLog();
        DB::connection('mysql')->disableQueryLog();

        $this->assertTrue(true);
    }
}
