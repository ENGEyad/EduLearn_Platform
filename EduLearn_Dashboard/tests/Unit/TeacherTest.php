<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Database\Eloquent\Collection;
use Tests\TestCase;

class TeacherTest extends TestCase
{
    public function test_assigned_subjects_uses_display_name_and_name_en(): void
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

        $teacher->setRelation('assignments', new Collection([$assignment1, $assignment2]));

        $subjects = $teacher->assigned_subjects;

        $this->assertCount(2, $subjects);
        $this->assertContains('Mathematics', $subjects);
        $this->assertContains('Science', $subjects);
    }

    public function test_total_assigned_students_deduplicates_class_sections(): void
    {
        $teacher = new Teacher;

        $classSection = new ClassSection;
        $classSection->id = 10;
        $classSection->students_count = 25;

        // Teacher has 2 assignments for the SAME class section (e.g. Math and Science)
        $assignment1 = new TeacherClassSubject;
        $assignment1->setRelation('classSection', $classSection);

        $assignment2 = new TeacherClassSubject;
        $assignment2->setRelation('classSection', $classSection);

        $teacher->setRelation('assignments', new Collection([$assignment1, $assignment2]));

        // Total should be 25, not 50 (no double counting)
        $this->assertEquals(25, $teacher->total_assigned_students);
    }
}
