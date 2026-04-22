<?php

namespace Tests\Feature;

use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\Student;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected array $connectionsToTransact = ['mysql'];

    protected function setUp(): void
    {
        parent::setUp();
        // Setup SQLite in-memory for testing
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);

        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        $this->artisan('migrate');
    }

    /** @test */
    public function it_lists_teachers_efficiently()
    {
        // Create some data
        $subject = Subject::create(['name' => 'Math', 'code' => 'M101', 'name_en' => 'Math', 'name_ar' => 'رياضيات']);
        $teachers = Teacher::factory()->count(5)->create();

        foreach ($teachers as $teacher) {
            $sections = ClassSection::factory()->count(2)->create();
            foreach ($sections as $section) {
                Student::factory()->count(10)->create(['class_section_id' => $section->id]);
                TeacherClassSubject::create([
                    'teacher_id' => $teacher->id,
                    'class_section_id' => $section->id,
                    'subject_id' => $subject->id,
                    'is_active' => true,
                ]);
            }
        }

        // Enable query logging
        DB::connection()->enableQueryLog();

        $response = $this->getJson(route('teachers.list'));

        $response->assertStatus(200);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        // Expected queries:
        // 1. select * from teachers
        // 2. select * from teacher_class_subjects where teacher_id in (...)
        // 3. select * from subjects where id in (...)
        // 4. select * from class_sections (with count subquery) where id in (...)

        $this->assertLessThanOrEqual(4, $queryCount, "Too many queries detected. N+1 issue might be present.");

        // Verify students_count is actually in the response
        $data = $response->json();
        $this->assertNotEmpty($data);
        $this->assertEquals(20, $data[0]['total_assigned_students']);
    }
}
