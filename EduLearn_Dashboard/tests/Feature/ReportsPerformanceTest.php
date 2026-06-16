<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Since we are using multiple connections and RefreshDatabase might not handle the second one perfectly in SQLite file mode
        // but here we are using RefreshDatabase which by default handles the default connection.
    }

    public function test_reports_list_performance()
    {
        // 1. Setup
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-' . uniqid(),
            'email' => 'test' . uniqid() . '@example.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin' . uniqid() . '@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 10 distinct classes and 5 students in each
        for ($i = 1; $i <= 10; $i++) {
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'first_name' => "Student $i $j",
                    'last_name' => "LastName",
                    'full_name' => "Student $i $j LastName",
                    'academic_id' => "ID-$i-$j-" . uniqid(),
                    'grade' => "Grade $i",
                    'class_section' => "Section A",
                ]);
            }
        }

        $this->actingAs($user);

        // 2. Measure without search
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('reports.list'));

        $queriesNoSearch = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);
        // We expect many queries: 1 for distinct classes, then 1 count query per class = 1 + 10 = 11 queries baseline

        // 3. Measure with search
        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('reports.list', ['search' => 'Student']));

        $queriesWithSearch = count(DB::getQueryLog());
        DB::disableQueryLog();

        $response->assertStatus(200);
        // With search: 1 for classes, then (1 exists + 1 count) per class = 1 + 20 = 21 queries

        echo "\nQueries without search: $queriesNoSearch\n";
        echo "Queries with search: $queriesWithSearch\n";
    }
}
