<?php

namespace Tests\Feature;

use App\Models\Teacher;
use App\Models\Student;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class BoltOptimizationTest extends TestCase
{
    use RefreshDatabase;

    protected array $connectionsToTransact = ['mysql', 'app_mysql'];

    protected function setUp(): void
    {
        $this->beforeApplicationDestroyed(function () {
            DB::disconnect('mysql');
            DB::disconnect('app_mysql');
        });

        parent::setUp();
    }

    /**
     * Test for N+1 query problem in TeacherController::list
     */
    public function test_teacher_list_has_constant_query_count()
    {
        // 1. Create a User for authentication
        $user = User::factory()->create();
        $this->actingAs($user);

        // 2. Create Subjects
        $subject = Subject::create(['name_en' => 'Math', 'name_ar' => 'رياضيات', 'code' => 'MATH101']);

        // 3. Setup Teachers and Assignments
        $this->createTeacherWithAssignments(1, 1, $subject);

        // Measure queries for 1 teacher
        DB::flushQueryLog();
        DB::enableQueryLog();
        $this->getJson(route('teachers.list'));
        $queryCount1 = count(DB::getQueryLog());
        DB::disableQueryLog();

        // 4. Create more Teachers and Assignments
        $this->createTeacherWithAssignments(2, 2, $subject);
        $this->createTeacherWithAssignments(3, 3, $subject);

        // Measure queries for multiple teachers
        DB::flushQueryLog();
        DB::enableQueryLog();
        $this->getJson(route('teachers.list'));
        $queryCount2 = count(DB::getQueryLog());
        DB::disableQueryLog();

        // If it's O(1), the query count should be the same
        $this->assertEquals($queryCount1, $queryCount2, "Query count increased from $queryCount1 to $queryCount2. N+1 detected!");
    }

    private function createTeacherWithAssignments($id, $count, $subject)
    {
        $teacher = Teacher::create([
            'full_name' => "Teacher $id",
            'teacher_code' => "T-$id",
            'status' => 'Active',
        ]);

        for ($i = 0; $i < $count; $i++) {
            $cs = ClassSection::create([
                'grade' => "Grade $id",
                'section' => "Sec $i",
                'name' => "Grade $id - Sec $i",
            ]);

            TeacherClassSubject::create([
                'teacher_id' => $teacher->id,
                'class_section_id' => $cs->id,
                'subject_id' => $subject->id,
                'is_active' => true,
            ]);

            // Add some students to each class
            for ($j = 0; $j < 3; $j++) {
                Student::create([
                    'full_name' => "Student $j in Class $i",
                    'academic_id' => "S-$id-$i-$j",
                    'class_section_id' => $cs->id,
                    'grade' => "Grade $id",
                    'class_section' => "Sec $i",
                ]);
            }
        }
    }
}
