<?php

namespace Tests\Feature;

use App\Models\Teacher;
use App\Models\Subject;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use App\Models\Student;
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

        $this->artisan('migrate:fresh');
    }

    public function test_teacher_list_performance()
    {
        $subject = Subject::create(['name_en' => 'Math', 'code' => 'MATH101']);

        for ($i = 1; $i <= 5; $i++) {
            $teacher = Teacher::create([
                'full_name' => "Teacher $i",
                'teacher_code' => "T$i",
            ]);

            for ($j = 1; $j <= 3; $j++) {
                $cs = ClassSection::create([
                    'grade' => "Grade $i",
                    'section' => "Section $j",
                    'name' => "Grade $i - Section $j",
                ]);

                TeacherClassSubject::create([
                    'teacher_id' => $teacher->id,
                    'class_section_id' => $cs->id,
                    'subject_id' => $subject->id,
                    'is_active' => true,
                ]);

                // 2 students per section
                Student::create(['full_name' => "S1", 'class_section_id' => $cs->id, 'grade' => "G", 'class_section' => "S", 'academic_id' => "A$i-$j-1"]);
                Student::create(['full_name' => "S2", 'class_section_id' => $cs->id, 'grade' => "G", 'class_section' => "S", 'academic_id' => "A$i-$j-2"]);
            }
        }

        DB::enableQueryLog();
        $response = $this->json('GET', route('teachers.list'));
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        echo "\nTotal queries for teachers.list (5 teachers, 3 assignments each): " . count($queries) . "\n";

        $response->assertStatus(200);
    }
}
