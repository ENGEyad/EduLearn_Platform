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

    protected $school;

    protected $user;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        // Redirect 'mysql' and 'app_mysql' connections to sqlite memory database for this test class only
        $app['config']->set('database.connections.mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => false,
        ]);

        $app['config']->set('database.connections.app_mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => false,
        ]);

        return $app;
    }

    protected function setUp(): void
    {
        parent::setUp();

        // Create an active initialized school
        $this->school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-'.uniqid(),
            'email' => 'admin-'.uniqid().'@school.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        // Create a school admin user
        $this->user = User::create([
            'name' => 'School Admin',
            'email' => 'admin-'.uniqid().'@school.com',
            'password' => bcrypt('password'),
            'school_id' => $this->school->id,
            'role' => 'school_admin',
        ]);
    }

    public function test_it_returns_classes_and_student_counts_with_no_n_plus_one_queries()
    {
        // 1. Create multiple ClassSections and Students
        $grades = ['Grade 1', 'Grade 2', 'Grade 3'];
        $sections = ['A', 'B'];

        foreach ($grades as $grade) {
            foreach ($sections as $section) {
                // Create ClassSection first to satisfy any foreign keys if present
                ClassSection::create([
                    'school_id' => $this->school->id,
                    'grade' => $grade,
                    'section' => $section,
                    'name' => "{$grade} - {$section}",
                    'name_en' => "{$grade} - {$section}",
                    'is_active' => true,
                ]);

                // Create some students in this class
                for ($i = 1; $i <= 3; $i++) {
                    Student::create([
                        'school_id' => $this->school->id,
                        'full_name' => "Student {$i} of {$grade} {$section}",
                        'academic_id' => 'ACAD-'.uniqid(),
                        'email' => 'student-'.uniqid().'@school.com',
                        'grade' => $grade,
                        'class_section' => $section,
                    ]);
                }
            }
        }

        // Enable query log
        DB::flushQueryLog();
        DB::enableQueryLog();

        // 2. Perform the request
        $response = $this->actingAs($this->user)
            ->getJson(route('reports.list'));

        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        // 3. Verify response structure and data
        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertCount(6, $data); // 3 grades * 2 sections = 6 classes
        foreach ($data as $classItem) {
            $this->assertEquals(3, $classItem['students_count']);
        }

        // 4. Assert optimized query count.
        // N+1 would trigger a COUNT(*) query for each class (at least 6 extra queries).
        // With our subquery optimization, we fetch everything in a single list query.
        // There might be 1 or 2 other queries for session/auth/user lookup, but total database queries
        // should be extremely low (e.g., <= 5).
        $totalQueries = count($queries);
        $this->assertLessThanOrEqual(5, $totalQueries, "Total queries performed is higher than expected: {$totalQueries}");
    }

    public function test_it_successfully_searches_by_class_name_or_student_identity()
    {
        // Create ClassSection
        ClassSection::create([
            'school_id' => $this->school->id,
            'grade' => 'Grade 10',
            'section' => 'Z',
            'name' => 'Grade 10 - Z',
            'name_en' => 'Grade 10 - Z',
            'is_active' => true,
        ]);

        // Create a unique student to search for
        $targetStudent = Student::create([
            'school_id' => $this->school->id,
            'full_name' => 'Ahmed Al-Farsi',
            'academic_id' => 'ALFARSI99',
            'email' => 'ahmed-'.uniqid().'@school.com',
            'grade' => 'Grade 10',
            'class_section' => 'Z',
        ]);

        // 1. Search matching student's full name
        $response = $this->actingAs($this->user)
            ->getJson(route('reports.list', ['search' => 'Ahmed']));

        $response->assertStatus(200);
        $students = $response->json('students');
        $this->assertCount(1, $students);
        $this->assertEquals('Ahmed Al-Farsi', $students[0]['full_name']);

        // 2. Search matching student's academic ID
        $response2 = $this->actingAs($this->user)
            ->getJson(route('reports.list', ['search' => 'ALFARSI99']));

        $response2->assertStatus(200);
        $students2 = $response2->json('students');
        $this->assertCount(1, $students2);

        // 3. Search matching class name representation
        $response3 = $this->actingAs($this->user)
            ->getJson(route('reports.list', ['search' => '10 - Z']));

        $response3->assertStatus(200);
        $data3 = $response3->json('data');
        $this->assertCount(1, $data3);
        $this->assertEquals('Grade 10', $data3[0]['grade']);
        $this->assertEquals('Z', $data3[0]['class_section']);
    }
}
