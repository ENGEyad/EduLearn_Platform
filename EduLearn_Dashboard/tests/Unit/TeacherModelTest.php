<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TeacherModelTest extends TestCase
{
    use RefreshDatabase;

    public function createApplication()
    {
        $app = require __DIR__.'/../../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        config()->set('database.default', 'mysql');
        config()->set('database.connections.mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);
        config()->set('database.connections.app_mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);

        DB::extend('app_mysql', function () {
            return DB::connection('mysql');
        });

        return $app;
    }

    public function test_assigned_subjects_uses_display_name()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'John Doe',
            'gender' => 'Male',
            'birthdate' => '1985-01-01',
            'shift' => 'Morning',
        ]);

        $subject = Subject::create([
            'name_en' => 'Mathematics',
            'name_ar' => 'الرياضيات',
            'code' => 'MATH101',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '1',
            'section' => 'A',
            'name' => 'Grade 1 - A',
            'name_en' => 'Grade 1 - A',
            'name_ar' => 'الصف الأول - أ',
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject->id,
            'is_active' => true,
        ]);

        $teacher->load('assignments.subject');

        $assignedSubjects = $teacher->assigned_subjects;

        $this->assertCount(1, $assignedSubjects);
        $this->assertContains('Mathematics', $assignedSubjects);
    }

    public function test_total_assigned_students_deduplicates_class_sections()
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'school@test.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Jane Doe',
            'gender' => 'Female',
            'birthdate' => '1988-01-01',
            'shift' => 'Morning',
        ]);

        $subject1 = Subject::create([
            'name_en' => 'Mathematics',
            'name_ar' => 'الرياضيات',
            'code' => 'MATH101',
        ]);

        $subject2 = Subject::create([
            'name_en' => 'Science',
            'name_ar' => 'العلوم',
            'code' => 'SCI101',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '1',
            'section' => 'A',
            'name' => 'Grade 1 - A',
            'name_en' => 'Grade 1 - A',
            'name_ar' => 'الصف الأول - أ',
        ]);

        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $classSection->id,
            'full_name' => 'Student 1',
            'academic_id' => 'STU-001',
            'status' => 'Active',
            'grade' => 'Grade 1',
            'class_section' => 'A',
        ]);

        Student::create([
            'school_id' => $school->id,
            'class_section_id' => $classSection->id,
            'full_name' => 'Student 2',
            'academic_id' => 'STU-002',
            'status' => 'Active',
            'grade' => 'Grade 1',
            'class_section' => 'A',
        ]);

        // Assign teacher to TWO subjects in the SAME class section
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

        $teacher->load(['assignments.classSection' => fn ($q) => $q->withCount('students')]);

        // Because the teacher is assigned to 1 unique class section with 2 students,
        // total_assigned_students MUST be 2, not 4 (double counted).
        $this->assertEquals(2, $teacher->total_assigned_students);
    }
}
