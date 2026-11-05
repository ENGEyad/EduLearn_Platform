<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Tests\TestCase;

class TeacherModelPerformanceTest extends TestCase
{
    public function test_assigned_subjects_resolves_subject_display_name_correctly(): void
    {
        $teacher = new Teacher;

        $subject1 = new Subject;
        $subject1->name_en = 'Mathematics';
        $subject1->name_ar = 'الرياضيات';

        $subject2 = new Subject;
        $subject2->name_en = 'Science';
        $subject2->name_ar = 'العلوم';

        $assignment1 = new TeacherClassSubject;
        $assignment1->setRelation('subject', $subject1);

        $assignment2 = new TeacherClassSubject;
        $assignment2->setRelation('subject', $subject2);

        $teacher->setRelation('assignments', collect([$assignment1, $assignment2]));

        $assignedSubjects = $teacher->assigned_subjects;

        $this->assertCount(2, $assignedSubjects);
        $this->assertContains('Mathematics', $assignedSubjects);
        $this->assertContains('Science', $assignedSubjects);
    }

    public function test_total_assigned_students_deduplicates_class_sections(): void
    {
        $teacher = new Teacher;

        $classSection = new ClassSection;
        $classSection->id = 101;
        $classSection->students_count = 25;

        // Teacher is assigned to two different subjects for the same class section
        $assignment1 = new TeacherClassSubject;
        $assignment1->class_section_id = 101;
        $assignment1->setRelation('classSection', $classSection);

        $assignment2 = new TeacherClassSubject;
        $assignment2->class_section_id = 101;
        $assignment2->setRelation('classSection', $classSection);

        $teacher->setRelation('assignments', collect([$assignment1, $assignment2]));

        // Should count 25 students once, not 50
        $this->assertEquals(25, $teacher->total_assigned_students);
    }

    public function test_total_assigned_students_sums_distinct_sections_with_preloaded_count(): void
    {
        $teacher = new Teacher;

        $class1 = new ClassSection;
        $class1->id = 1;
        $class1->students_count = 20;

        $class2 = new ClassSection;
        $class2->id = 2;
        $class2->students_count = 30;

        $assignment1 = new TeacherClassSubject;
        $assignment1->class_section_id = 1;
        $assignment1->setRelation('classSection', $class1);

        $assignment2 = new TeacherClassSubject;
        $assignment2->class_section_id = 2;
        $assignment2->setRelation('classSection', $class2);

        $teacher->setRelation('assignments', collect([$assignment1, $assignment2]));

        $this->assertEquals(50, $teacher->total_assigned_students);
    }

    public function test_total_assigned_students_handles_loaded_students_relation(): void
    {
        $teacher = new Teacher;

        $class1 = new ClassSection;
        $class1->id = 1;
        $class1->setRelation('students', collect([
            (object) ['id' => 1],
            (object) ['id' => 2],
            (object) ['id' => 3],
        ]));

        $assignment1 = new TeacherClassSubject;
        $assignment1->class_section_id = 1;
        $assignment1->setRelation('classSection', $class1);

        $teacher->setRelation('assignments', collect([$assignment1]));

        $this->assertEquals(3, $teacher->total_assigned_students);
    }
}
