<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ReportsPerformanceTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Override createApplication to redirect both mysql and app_mysql connections to sqlite in tests.
     */
    public function createApplication()
    {
        $app = parent::createApplication();

        // Direct 'mysql' and 'app_mysql' connections to the SQLite connection for dual connection support
        config([
            'database.default' => 'sqlite',
            'database.connections.mysql' => config('database.connections.sqlite'),
            'database.connections.app_mysql' => config('database.connections.sqlite'),
        ]);

        return $app;
    }

    public function test_reports_list_performs_zero_n_plus_one_queries()
    {
        // 1. Setup a valid School
        $school = School::create([
            'name' => 'Al-Aqsa School',
            'slug' => 'al-aqsa',
            'email' => 'contact@al-aqsa.edu',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // 2. Setup User associated with School
        $user = User::create([
            'name' => 'School Admin User',
            'email' => 'admin@al-aqsa.edu',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // 3. Create 20 classes / sections and associated students
        for ($i = 1; $i <= 20; $i++) {
            $grade = 'Grade '.$i;
            $section = 'A';

            // Create matching Student instances
            Student::create([
                'school_id' => $school->id,
                'full_name' => 'Student '.$i,
                'academic_id' => 'ACAD-'.$i,
                'grade' => $grade,
                'class_section' => $section,
            ]);
        }

        // 4. Authenticate and hit the endpoint
        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get(route('reports.list'));

        DB::disableQueryLog();
        $queries = DB::getQueryLog();

        // 5. Verify the response is successful and has 20 classes
        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(20, $data);

        // 6. Assert query count - without optimization, we would have 1 query to fetch distinct,
        // plus for each class: 1 query to check search and 1 query to count students, resulting in 40+ queries.
        // With optimization, we run exactly 1 query in the controller to get all 20 classes with their counts!
        // Total queries logged including user/auth query should be extremely small (<= 4).
        $this->assertLessThanOrEqual(4, count($queries), 'Reports list performed too many queries, N+1 query problem detected!');
    }
}
