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
        $app = parent::createApplication();

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite.database', ':memory:');
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        DB::extend('app_mysql', fn () => DB::connection('sqlite'));

        return $app;
    }

    public function test_teacher_total_assigned_students_deduplicates_class_sections_and_counts_correctly(): void
    {
        $school = School::create([
            'name' => 'Performance Test School',
            'slug' => 'perf-test-school',
            'email' => 'perf@school.edu',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '10',
            'section' => 'A',
            'name' => '10-A',
            'name_en' => 'Grade 10 - A',
            'name_ar' => 'الصف 10 - أ',
            'stage' => 'High',
            'is_active' => true,
        ]);

        // Create 15 students in this class section
        for ($i = 1; $i <= 15; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student {$i}",
                'academic_id' => "STU100{$i}",
            ]);
        }

        $subject1 = Subject::create([
            'name_en' => 'Mathematics',
            'name_ar' => 'الرياضيات',
            'code' => 'MATH101',
        ]);

        $subject2 = Subject::create([
            'name_en' => 'Physics',
            'name_ar' => 'الفيزياء',
            'code' => 'PHYS101',
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Teacher Alpha',
            'teacher_code' => 'T-001',
        ]);

        // Assign teacher to BOTH subjects in the same class section
        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject1->id,
            'is_active' => true,
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject2->id,
            'is_active' => true,
        ]);

        // Prior to optimization, total_assigned_students would return 30 (15 * 2) due to duplicate section counting.
        // With optimization, class sections are deduplicated and return exactly 15.
        $this->assertEquals(15, $teacher->total_assigned_students);
    }

    public function test_teacher_list_uses_preloaded_students_count_if_available(): void
    {
        $school = School::create([
            'name' => 'Performance Test School 2',
            'slug' => 'perf-test-school-2',
            'email' => 'perf2@school.edu',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '11',
            'section' => 'B',
            'name' => '11-B',
            'name_en' => 'Grade 11 - B',
            'name_ar' => 'الصف 11 - ب',
            'stage' => 'High',
            'is_active' => true,
        ]);

        for ($i = 1; $i <= 5; $i++) {
            Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student {$i}",
                'academic_id' => "STU200{$i}",
            ]);
        }

        $subject = Subject::create([
            'name_en' => 'Chemistry',
            'name_ar' => 'الكيمياء',
            'code' => 'CHEM101',
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Teacher Beta',
            'teacher_code' => 'T-002',
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject->id,
            'is_active' => true,
        ]);

        $response = $this->actingAs($user)->getJson(route('teachers.list'));

        $response->assertStatus(200);
        $data = $response->json();

        $this->assertCount(1, $data);
        $this->assertEquals(5, $data[0]['total_assigned_students']);
    }
}
