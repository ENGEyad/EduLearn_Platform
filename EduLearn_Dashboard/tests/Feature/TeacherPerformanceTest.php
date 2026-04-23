<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config(['database.connections.mysql.driver' => 'sqlite']);
        config(['database.connections.mysql.database' => ':memory:']);

        config(['database.connections.app_mysql.driver' => 'sqlite']);
        config(['database.connections.app_mysql.database' => ':memory:']);

        config(['database.default' => 'mysql']);

        $this->artisan('migrate', ['--database' => 'mysql'])->run();
    }

    /** @test */
    public function listing_teachers_uses_constant_number_of_queries()
    {
        // 1. Create baseline data
        $subject = Subject::create([
            'name_en' => 'Math',
            'code' => 'MATH-01'
        ]);
        $section = ClassSection::create([
            'grade' => '1',
            'section' => 'A',
            'name' => '1 - A'
        ]);

        // Manual student creation since factory is missing
        for ($i = 0; $i < 5; $i++) {
            Student::create([
                'full_name' => "Student $i",
                'academic_id' => "ACAD-$i",
                'grade' => '1',
                'class_section' => 'A',
                'class_section_id' => $section->id
            ]);
        }

        $teacher1 = Teacher::create(['full_name' => 'Teacher 1', 'teacher_code' => 'T1']);
        TeacherClassSubject::create([
            'teacher_id' => $teacher1->id,
            'class_section_id' => $section->id,
            'subject_id' => $subject->id
        ]);

        $teacher2 = Teacher::create(['full_name' => 'Teacher 2', 'teacher_code' => 'T2']);
        TeacherClassSubject::create([
            'teacher_id' => $teacher2->id,
            'class_section_id' => $section->id,
            'subject_id' => $subject->id
        ]);

        DB::enableQueryLog();
        $response = $this->getJson(route('teachers.list'));
        $response->assertStatus(200);
        $queryCountBaseline = count(DB::getQueryLog());
        DB::disableQueryLog();

        // 2. Add more teachers and assignments
        $teacher3 = Teacher::create(['full_name' => 'Teacher 3', 'teacher_code' => 'T3']);
        TeacherClassSubject::create([
            'teacher_id' => $teacher3->id,
            'class_section_id' => $section->id,
            'subject_id' => $subject->id
        ]);

        DB::flushQueryLog();
        DB::enableQueryLog();
        $response = $this->getJson(route('teachers.list'));
        $response->assertStatus(200);
        $queryCountWithMoreData = count(DB::getQueryLog());
        DB::disableQueryLog();

        $this->assertEquals($queryCountBaseline, $queryCountWithMoreData, "Query count increased from {$queryCountBaseline} to {$queryCountWithMoreData}! N+1 problem detected.");

        // Typical query count: teachers, assignments, subjects, class_sections(with student count)
        $this->assertLessThanOrEqual(4, $queryCountWithMoreData, "Unexpectedly high query count.");

        $data = $response->json();
        $t1 = collect($data)->firstWhere('id', $teacher1->id);
        $this->assertEquals(5, $t1['total_assigned_students']);
        $this->assertArrayHasKey('students_count', $t1['assignments'][0]['class_section']);
    }
}
