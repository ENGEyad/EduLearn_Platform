<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\ClassSection;
use App\Models\Subject;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class BoltOptimizationTest extends TestCase
{
    use RefreshDatabase;

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    protected function setUp(): void
    {
        parent::setUp();

        // Use sqlite :memory: for both connections
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        // Create a school first
        $this->school = School::create([
            'id' => 1,
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'test@school.com',
            'status' => 'active'
        ]);

        // Setup a user
        $this->user = User::factory()->create([
            'school_id' => $this->school->id,
        ]);
    }

    /** @test */
    public function dashboard_stats_are_cached_and_shared_with_ai_insight()
    {
        $this->actingAs($this->user);

        // Create some data
        Student::create([
            'full_name' => 'Test Student',
            'academic_id' => 'S1',
            'status' => 'Active',
            'class_section_id' => 1,
            'attendance_rate' => 90,
            'performance_avg' => 85,
        ]);

        Teacher::create([
            'full_name' => 'Test Teacher',
            'teacher_code' => 'T1',
            'status' => 'Active'
        ]);

        // 1. Visit dashboard to prime cache
        $response = $this->get(route('dashboard'));
        $response->assertStatus(200);

        $cacheKey = "dashboard_stats_school_1";
        $this->assertTrue(Cache::has($cacheKey), "Dashboard stats should be cached");
        $cachedStats = Cache::get($cacheKey);
        $this->assertEquals(1, (int)$cachedStats['students']);
        $this->assertEquals(90, (int)$cachedStats['attendance']);

        // 2. Call AI insight and ensure it uses the cache
        \Illuminate\Support\Facades\Http::fake([
            '127.0.0.1:8001/*' => \Illuminate\Support\Facades\Http::response(['reply' => 'AI Response'], 200),
        ]);

        $response = $this->get(route('api.dashboard.ai-insight'));
        $response->assertStatus(200);
        $this->assertEquals('AI Response', $response->json('aiInsight'));
    }

    /** @test */
    public function reports_list_returns_correct_student_counts()
    {
        $this->actingAs($this->user);

        // Create specific classes and students
        $cs1 = ClassSection::create(['grade' => '5', 'section' => 'A', 'name' => '5-A']);
        $cs2 = ClassSection::create(['grade' => '6', 'section' => 'B', 'name' => '6-B']);

        Student::create([
            'full_name' => 'Student 1',
            'academic_id' => 'S1',
            'grade' => '5',
            'class_section' => 'A',
            'class_section_id' => $cs1->id
        ]);
        Student::create([
            'full_name' => 'Student 2',
            'academic_id' => 'S2',
            'grade' => '5',
            'class_section' => 'A',
            'class_section_id' => $cs1->id
        ]);
        Student::create([
            'full_name' => 'Student 3',
            'academic_id' => 'S3',
            'grade' => '6',
            'class_section' => 'B',
            'class_section_id' => $cs2->id
        ]);

        $response = $this->getJson(route('reports.list'));
        $response->assertStatus(200);

        $data = $response->json('data');
        $this->assertCount(2, $data);

        $class5A = collect($data)->firstWhere('grade', '5');
        $this->assertEquals(2, $class5A['students_count']);

        $class6B = collect($data)->firstWhere('grade', '6');
        $this->assertEquals(1, $class6B['students_count']);
    }
}
