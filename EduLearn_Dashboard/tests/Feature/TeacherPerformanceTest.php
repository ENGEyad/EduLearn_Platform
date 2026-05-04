<?php

namespace Tests\Feature;

use App\Models\Teacher;
use App\Models\Student;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use App\Models\Subject;
use App\Models\User;
use App\Models\School;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);
        config(['database.connections.mysql' => config('database.connections.sqlite')]);
        config(['database.connections.app_mysql' => config('database.connections.sqlite')]);

        $this->artisan('migrate:fresh');
    }

    public function test_teacher_list_performance()
    {
        // Setup data
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active'
        ]);
        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'school_id' => $school->id,
            'role' => 'school_admin'
        ]);

        $this->actingAs($user);

        $subject = Subject::create(['name_en' => 'Math', 'code' => 'MATH101']);

        // Create 10 teachers, each with 2 class assignments
        for ($i = 1; $i <= 10; $i++) {
            $teacher = Teacher::create([
                'full_name' => "Teacher $i",
                'teacher_code' => "T$i",
                'status' => 'Active'
            ]);

            for ($j = 1; $j <= 2; $j++) {
                $cs = ClassSection::create([
                    'grade' => (string)$i,
                    'section' => chr(64 + $j),
                    'name' => "Grade $i - Section " . chr(64 + $j),
                    'is_active' => true
                ]);

                // Create some students in each class
                for ($k = 1; $k <= 5; $k++) {
                    Student::create([
                        'full_name' => "Student $i-$j-$k",
                        'academic_id' => "S$i$j$k",
                        'class_section_id' => $cs->id,
                        'grade' => (string)$i,
                        'class_section' => chr(64 + $j)
                    ]);
                }

                TeacherClassSubject::create([
                    'teacher_id' => $teacher->id,
                    'class_section_id' => $cs->id,
                    'subject_id' => $subject->id,
                    'is_active' => true
                ]);
            }
        }

        DB::enableQueryLog();

        $response = $this->getJson('/teachers/list');

        $response->assertStatus(200);

        $queries = DB::getQueryLog();
        $queryCount = count($queries);

        echo "\nTotal queries executed: $queryCount\n";

        // After optimization, it should be exactly 4 queries:
        // 1. select * from teachers ...
        // 2. select * from teacher_class_subjects where teacher_id in (...)
        // 3. select * from subjects where id in (...)
        // 4. select *, (select count(*) from students where class_sections.id = students.class_section_id) as students_count from class_sections where id in (...)
        $this->assertEquals(4, $queryCount, "Query count should be optimized to 4 queries");
    }
}
