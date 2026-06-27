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
    // We don't use RefreshDatabase here because we have a complex dual-sqlite setup
    // that RefreshDatabase might not handle correctly for the secondary connection.

    protected function setUp(): void
    {
        parent::setUp();

        // Clean up
        DB::table('users')->delete();
        DB::table('schools')->delete();
        DB::table('students')->delete();
        DB::table('class_sections')->delete();
    }

    public function test_reports_list_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'phone' => '12345678',
            'address' => 'Test Address',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'super_admin',
        ]);

        // Create 20 class sections
        for ($i = 1; $i <= 20; $i++) {
            $cs = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Grade '.$i.' A',
            ]);

            // Add some students to each class
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "AC-$i-$j-".uniqid(),
                    'grade' => 'Grade '.$i,
                    'class_section' => 'A',
                    'class_section_id' => $cs->id,
                ]);
            }
        }

        $this->actingAs($user);

        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list'), [
            'Accept' => 'application/json',
            'X-Requested-With' => 'XMLHttpRequest',
        ]);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nTotal queries for Reports list (20 classes): $queryCount\n";

        $response->assertStatus(200);
        $this->assertLessThan(10, $queryCount, 'Reports list is making too many queries (N+1)');
    }

    public function test_reports_list_search_query_count()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'phone' => '12345678',
            'address' => 'Test Address',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'super_admin',
        ]);

        // Create 20 class sections
        for ($i = 1; $i <= 20; $i++) {
            $cs = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade '.$i,
                'section' => 'A',
                'name' => 'Grade '.$i.' A',
            ]);

            // Add some students to each class
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "AC-$i-$j-".uniqid(),
                    'grade' => 'Grade '.$i,
                    'class_section' => 'A',
                    'class_section_id' => $cs->id,
                ]);
            }
        }

        $this->actingAs($user);

        DB::enableQueryLog();

        $response = $this->getJson(route('reports.list', ['search' => 'Student 1-1']), [
            'Accept' => 'application/json',
            'X-Requested-With' => 'XMLHttpRequest',
        ]);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nTotal queries for Reports list SEARCH (20 classes): $queryCount\n";

        $response->assertStatus(200);
        $this->assertLessThan(10, $queryCount, 'Reports search is making too many queries (N+1)');
    }
}
