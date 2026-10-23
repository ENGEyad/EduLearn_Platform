<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\School;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
        config()->set('database.connections.mysql', config('database.connections.sqlite'));
        config()->set('database.connections.app_mysql', config('database.connections.sqlite'));

        \Illuminate\Support\Facades\DB::extend('app_mysql', fn () => \Illuminate\Support\Facades\DB::connection('sqlite'));

        return $app;
    }

    public function test_total_assigned_students_deduplicates_class_sections(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school',
            'email' => 'admin@testschool.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher',
            'teacher_code' => 'TEST-T-2025-0001',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '5',
            'section' => 'A',
            'name' => 'Grade 5 - A',
            'name_en' => 'Grade 5 - A',
            'name_ar' => 'الصف الخامس - أ',
            'is_active' => true,
        ]);

        // Create 25 actual students in the class section
        for ($i = 1; $i <= 25; $i++) {
            \App\Models\Student::create([
                'school_id' => $school->id,
                'class_section_id' => $classSection->id,
                'full_name' => "Student {$i}",
                'academic_id' => 'TEST-S-2025-G5-A-'.sprintf('%04d', $i),
                'grade' => 'Grade 5',
                'class_section' => 'A',
                'guardian_name' => "Guardian {$i}",
                'guardian_phone' => '0500000000',
            ]);
        }

        $subject1 = Subject::create([
            'name_en' => 'Mathematics',
            'name_ar' => 'الرياضيات',
            'code' => 'MATH',
            'is_active' => true,
        ]);

        $subject2 = Subject::create([
            'name_en' => 'Science',
            'name_ar' => 'العلوم',
            'code' => 'SCI',
            'is_active' => true,
        ]);

        // Teacher assigned to 2 subjects in the SAME class section
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

        $teacher->load(['assignments.subject', 'assignments.classSection' => fn ($q) => $q->withCount('students')]);

        // Without deduplication, student count would be 25 + 25 = 50.
        // With deduplication, student count must be 25.
        $this->assertEquals(25, $teacher->total_assigned_students);
    }

    public function test_assigned_subjects_returns_subject_names(): void
    {
        $school = School::create([
            'name' => 'Test School',
            'slug' => 'test-school-2',
            'email' => 'admin2@testschool.com',
            'status' => 'active',
            'is_initialized' => true,
        ]);

        $teacher = Teacher::create([
            'school_id' => $school->id,
            'full_name' => 'Test Teacher 2',
            'teacher_code' => 'TEST-T-2025-0002',
        ]);

        $classSection = ClassSection::create([
            'school_id' => $school->id,
            'grade' => '6',
            'section' => 'B',
            'name' => 'Grade 6 - B',
            'name_en' => 'Grade 6 - B',
            'name_ar' => 'الصف السادس - ب',
            'is_active' => true,
        ]);

        $subject = Subject::create([
            'name_en' => 'English Language',
            'name_ar' => 'اللغة الإنجليزية',
            'code' => 'ENG',
            'is_active' => true,
        ]);

        TeacherClassSubject::create([
            'teacher_id' => $teacher->id,
            'class_section_id' => $classSection->id,
            'subject_id' => $subject->id,
            'is_active' => true,
        ]);

        $teacher->load(['assignments.subject', 'assignments.classSection']);

        $assignedSubjects = $teacher->assigned_subjects;
        $this->assertNotEmpty($assignedSubjects);
        $this->assertContains('English Language', $assignedSubjects);
    }
}
