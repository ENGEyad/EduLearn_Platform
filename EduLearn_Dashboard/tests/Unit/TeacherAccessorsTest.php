<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Database\Eloquent\Collection;
use Tests\TestCase;

class TeacherAccessorsTest extends TestCase
{
    public function test_assigned_subjects_resolves_display_name_when_subject_name_is_absent()
    {
        $teacher = new Teacher;

        $subject1 = new Subject([
            'name_en' => 'Mathematics',
            'name_ar' => 'الرياضيات',
        ]);
        $subject2 = new Subject([
            'name_en' => 'Physics',
            'name_ar' => 'الفيزياء',
        ]);

        $assignment1 = new TeacherClassSubject;
        $assignment1->setRelation('subject', $subject1);

        $assignment2 = new TeacherClassSubject;
        $assignment2->setRelation('subject', $subject2);

        $teacher->setRelation('assignments', new Collection([$assignment1, $assignment2]));

        $assignedSubjects = $teacher->assigned_subjects;

        $this->assertCount(2, $assignedSubjects);
        $this->assertTrue(in_array('الرياضيات', $assignedSubjects) || in_array('Mathematics', $assignedSubjects));
        $this->assertTrue(in_array('الفيزياء', $assignedSubjects) || in_array('Physics', $assignedSubjects));
    }

    public function test_total_assigned_students_deduplicates_class_sections()
    {
        $teacher = new Teacher;

        $classSection1 = new ClassSection(['grade' => '10', 'section' => 'A']);
        $classSection1->id = 101;
        $classSection1->students_count = 25;

        // Same class section assigned twice (e.g. teaching Math and Physics to 10-A)
        $assignment1 = new TeacherClassSubject(['class_section_id' => 101, 'subject_id' => 1]);
        $assignment1->setRelation('classSection', $classSection1);

        $assignment2 = new TeacherClassSubject(['class_section_id' => 101, 'subject_id' => 2]);
        $assignment2->setRelation('classSection', $classSection1);

        // Different class section
        $classSection2 = new ClassSection(['grade' => '10', 'section' => 'B']);
        $classSection2->id = 102;
        $classSection2->students_count = 30;

        $assignment3 = new TeacherClassSubject(['class_section_id' => 102, 'subject_id' => 1]);
        $assignment3->setRelation('classSection', $classSection2);

        $teacher->setRelation('assignments', new Collection([$assignment1, $assignment2, $assignment3]));

        // Total should be 25 + 30 = 55 (NOT 25 + 25 + 30 = 80)
        $this->assertEquals(55, $teacher->total_assigned_students);
    }

    public function test_total_assigned_students_uses_loaded_students_relation_without_querying()
    {
        $teacher = new Teacher;

        $classSection = new ClassSection(['grade' => '9', 'section' => 'A']);
        $classSection->id = 90;
        $student1 = new Student(['full_name' => 'Alice']);
        $student2 = new Student(['full_name' => 'Bob']);
        $classSection->setRelation('students', new Collection([$student1, $student2]));

        $assignment = new TeacherClassSubject(['class_section_id' => 90]);
        $assignment->setRelation('classSection', $classSection);

        $teacher->setRelation('assignments', new Collection([$assignment]));

        $this->assertEquals(2, $teacher->total_assigned_students);
    }
}
