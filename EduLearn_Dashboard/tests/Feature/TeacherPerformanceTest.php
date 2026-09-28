<?php

namespace Tests\Feature;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';
        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');

        DB::extend('app_mysql', fn () => DB::connection('sqlite'));
        DB::extend('mysql', fn () => DB::connection('sqlite'));

        return $app;
    }

    public function test_teacher_accessors_and_list_performance()
    {
        $school = School::create([
            'name' => 'Performance School',
            'slug' => 'perf-school',
            'email' => 'admin@perf.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::create([
            'school_id' => $school->id,
            'name' => 'Admin User',
            'email' => 'admin@perf.com',
            'password' => bcrypt('password'),
            'role' => 'school_admin',
        ]);

        $this->actingAs($user);

        $subject1 = Subject::create(['name_en' => 'Mathematics', 'name_ar' => 'رياضيات', 'code' => 'MATH']);
        $subject2 = Subject::create(['name_en' => 'Science', 'name_ar' => 'علوم', 'code' => 'SCI']);

        $section1 = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 1 - Section A',
            'name_en' => 'Grade 1 - Section A',
            'grade' => 1,
            'section' => 'A',
        ]);

        $section2 = ClassSection::create([
            'school_id' => $school->id,
            'name' => 'Grade 2 - Section A',
            'name_en' => 'Grade 2 - Section A',
            'grade' => 2,
            'section' => 'A',
        ]);

        // 10 students in section 1
        for ($i = 1; $i <= 10; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section1->id,
                'full_name' => "Student S1-$i",
                'academic_id' => "STU-1-$i",
            ]);
        }

        // 15 students in section 2
        for ($i = 1; $i <= 15; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $section2->id,
                'full_name' => "Student S2-$i",
                'academic_id' => "STU-2-$i",
            ]);
        }

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Teacher One',
            'teacher_code' => 'T-001',
        ]);

        // Assign teacher to section1 for Math AND Science, and section2 for Math
        TeacherClassSubject::create(['teacher_id' => $teacher->id, 'class_section_id' => $section1->id, 'subject_id' => $subject1->id, 'is_active' => true]);
        TeacherClassSubject::create(['teacher_id' => $teacher->id, 'class_section_id' => $section1->id, 'subject_id' => $subject2->id, 'is_active' => true]);
        TeacherClassSubject::create(['teacher_id' => $teacher->id, 'class_section_id' => $section2->id, 'subject_id' => $subject1->id, 'is_active' => true]);

        DB::enableQueryLog();

        $response = $this->getJson(route('teachers.list'));

        $response->assertStatus(200);

        $data = $response->json();
        $this->assertCount(1, $data);

        // Verify correct display names for assigned subjects (default locale is ar)
        $this->assertEqualsCanonicalizing(['رياضيات', 'علوم'], $data[0]['assigned_subjects']);

        // Verify total assigned students count is deduplicated (10 + 15 = 25, not 10 + 10 + 15 = 35)
        $this->assertEquals(25, $data[0]['total_assigned_students']);

        // Ensure database queries executed remain low (e.g. 5 or fewer queries)
        $executedQueries = DB::getQueryLog();
        $this->assertLessThanOrEqual(5, count($executedQueries));
    }
}
