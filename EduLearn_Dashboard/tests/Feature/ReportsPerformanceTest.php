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
    // We use a manual setup instead of RefreshDatabase to handle dual SQLite connections more reliably in this environment
    protected function setUp(): void
    {
        parent::setUp();

        // Ensure we are using sqlite for tests
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);

        // Also mock the app connection
        config(['database.connections.app_sqlite' => [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]]);

        DB::connection('sqlite')->getSchemaBuilder()->create('schools', function ($table) {
            $table->id();
            $table->string('name');
            $table->string('status')->default('active');
            $table->boolean('is_initialized')->default(true);
            $table->timestamps();
        });

        DB::connection('sqlite')->getSchemaBuilder()->create('users', function ($table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->string('role')->nullable();
            $table->unsignedBigInteger('school_id')->nullable();
            $table->timestamps();
        });

        DB::connection('sqlite')->getSchemaBuilder()->create('students', function ($table) {
            $table->id();
            $table->unsignedBigInteger('school_id');
            $table->string('full_name');
            $table->string('academic_id')->nullable();
            $table->string('grade')->nullable();
            $table->string('class_section')->nullable();
            $table->unsignedBigInteger('class_section_id')->nullable();
            $table->decimal('attendance_rate')->nullable();
            $table->string('photo_path')->nullable();
            $table->timestamps();
        });
    }

    public function test_reports_list_performance()
    {
        $school = School::create(['name' => 'Test School']);
        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        // Create 20 classes (10 grades, 2 sections each)
        // Each class has 5 students
        for ($g = 1; $g <= 10; $g++) {
            for ($s = 1; $s <= 2; $s++) {
                $section = ($s == 1) ? 'أ' : 'ب';
                for ($st = 1; $st <= 5; $st++) {
                    Student::create([
                        'school_id' => $school->id,
                        'full_name' => "Student $g-$section-$st",
                        'grade' => (string)$g,
                        'class_section' => $section,
                    ]);
                }
            }
        }

        $this->actingAs($user);

        DB::enableQueryLog();
        DB::flushQueryLog();

        $response = $this->json('GET', route('reports.list'));

        $queryLog = DB::getQueryLog();
        $queryCount = count($queryLog);

        $response->assertStatus(200);
        $response->assertJsonCount(20, 'data');

        // Without optimization, it should be at least 1 (distinct grades) + 20 (count per class) = 21 queries
        // Plus maybe some auth/setup queries.
        echo "\nTotal queries for ReportsController@list: $queryCount\n";

        // We expect much fewer queries after optimization (ideally 1 or 2)
        $this->assertLessThan(10, $queryCount, "Too many queries! N+1 detected.");
    }

    public function test_reports_list_search_by_class_name()
    {
        $school = School::create(['name' => 'Test School']);
        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        Student::create(['school_id' => $school->id, 'full_name' => 'S1', 'grade' => '1', 'class_section' => 'أ']);
        Student::create(['school_id' => $school->id, 'full_name' => 'S2', 'grade' => '2', 'class_section' => 'ب']);

        $this->actingAs($user);

        $response = $this->json('GET', route('reports.list'), ['search' => '1 - أ']);
        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonFragment(['grade' => '1', 'class_section' => 'أ']);
    }

    public function test_reports_list_search_by_student_name()
    {
        $school = School::create(['name' => 'Test School']);
        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
            'school_id' => $school->id,
        ]);

        Student::create(['school_id' => $school->id, 'full_name' => 'Target Student', 'grade' => '1', 'class_section' => 'أ']);
        Student::create(['school_id' => $school->id, 'full_name' => 'Other', 'grade' => '2', 'class_section' => 'ب']);

        $this->actingAs($user);

        // Search for student name should return the class that student belongs to
        $response = $this->json('GET', route('reports.list'), ['search' => 'Target']);
        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data');
        $response->assertJsonFragment(['grade' => '1', 'class_section' => 'أ']);

        // And should also return the matching student in the 'students' array
        $response->assertJsonFragment(['full_name' => 'Target Student']);
    }
}
