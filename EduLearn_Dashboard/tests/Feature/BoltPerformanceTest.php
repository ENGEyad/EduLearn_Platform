<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Ensure both databases are migrated if using separate connections
        if (config('database.connections.app_mysql.driver') === 'sqlite') {
            \Illuminate\Support\Facades\Schema::connection('app_mysql')->dropAllTables();
            $this->artisan('migrate', [
                '--database' => 'app_mysql',
                '--path' => 'database/migrations',
                '--force' => true,
            ]);
        }
    }

    public function test_dashboard_overview_query_count()
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
            'name' => 'Admin',
            'email' => 'admin@school.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
        ]);

        // Create 20 class sections
        for ($i = 1; $i <= 20; $i++) {
            $section = ClassSection::create([
                'school_id' => $school->id,
                'grade' => 'Grade ' . $i,
                'section' => 'A',
                'name' => 'Grade ' . $i . ' Section A',
                'is_active' => true,
            ]);

            // Add 5 students to each section
            for ($j = 1; $j <= 5; $j++) {
                Student::create([
                    'school_id' => $school->id,
                    'class_section_id' => $section->id,
                    'full_name' => "Student $i-$j",
                    'academic_id' => "ID-$i-$j",
                    'attendance_rate' => 80 + ($i % 10), // Some will be < 85
                    'status' => 'active',
                ]);
            }
        }

        $this->actingAs($user);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $response = $this->get('/dashboard');

        $queryLog = DB::getQueryLog();
        $queryCount = count($queryLog);

        // Expected queries (roughly):
        // 1. Session/User load (if not cached)
        // 2. School load (auth middleware / controller)
        // 3. Student IDs pluck
        // 4. Class sections withCount students
        // 5. Performance overall avg
        // 6. Attendance overall avg
        // 7. Teachers count
        // 8. Subjects count
        // 9. Dangling students count
        // 10. Current performance avg
        // 11. Previous performance avg
        // 12. Low attendance students count
        // 13. Low performance students count
        // 14-33. Low attendance classes (N+1 bottleneck!) - 20 queries
        // 34. AiReport latest
        // 35. Redundant AiReport latest

        echo "\nTotal queries for dashboard: $queryCount\n";

        $response->assertStatus(200);
    }
}
