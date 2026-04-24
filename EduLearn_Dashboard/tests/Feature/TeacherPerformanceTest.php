<?php

namespace Tests\Feature;

use App\Models\Teacher;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use App\Models\Subject;
use App\Models\Student;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    protected function refreshTestDatabase()
    {
        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);
        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        $this->artisan('migrate:fresh');

        $this->app[ \Illuminate\Contracts\Console\Kernel::class]->setArtisan(null);
    }

    public function test_list_teachers_query_count_is_optimized()
    {
        // 1. Setup data: 1 teacher with 5 class assignments
        $teacher = Teacher::create([
            'full_name' => 'Test Teacher',
            'teacher_code' => 'T101',
            'status' => 'active',
        ]);

        $subject = Subject::create(['name_en' => 'Math', 'code' => 'MATH101']);

        for ($i = 1; $i <= 5; $i++) {
            $cs = ClassSection::create([
                'grade' => '5',
                'section' => "Sec $i",
                'name' => "Grade 5 - Sec $i",
                'is_active' => true,
            ]);

            TeacherClassSubject::create([
                'teacher_id' => $teacher->id,
                'class_section_id' => $cs->id,
                'subject_id' => $subject->id,
                'is_active' => true,
            ]);

            // Add some students to each section
            for ($j = 1; $j <= 3; $j++) {
                Student::create([
                    'full_name' => "Student $j in Sec $i",
                    'class_section_id' => $cs->id,
                    'grade' => 'Grade 5',
                    'class_section' => "Sec $i",
                    'status' => 'active',
                ]);
            }
        }

        // 2. Measure queries
        DB::enableQueryLog();
        $this->getJson(route('teachers.list'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $queryCount = count($queries);

        // Expected with optimization:
        // 1. SELECT * FROM teachers
        // 2. SELECT * FROM teacher_class_subjects WHERE teacher_id IN (...)
        // 3. SELECT * FROM subjects WHERE id IN (...)
        // 4. SELECT *, (SELECT COUNT(*) FROM students WHERE students.class_section_id = class_sections.id) AS students_count FROM class_sections WHERE id IN (...)
        // Total should be exactly 4 queries.

        $this->assertEquals(4, $queryCount, "Query count should be 4 (optimized) regardless of the number of assignments.");
    }
}
