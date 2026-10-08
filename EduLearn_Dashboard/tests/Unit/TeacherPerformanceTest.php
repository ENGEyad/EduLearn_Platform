<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Database\Eloquent\Collection;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    /**
     * Test that getTotalAssignedStudentsAttribute deduplicates class sections
     * when a teacher is assigned to multiple subjects in the same section.
     */
    public function test_total_assigned_students_deduplicates_class_sections(): void
    {
        $teacher = new Teacher();

        // Section with 30 students
        $sectionA = new ClassSection();
        $sectionA->id = 1;
        $sectionA->students_count = 30;

        // Section with 20 students
        $sectionB = new ClassSection();
        $sectionB->id = 2;
        $sectionB->students_count = 20;

        // Teacher has 3 assignments in Section A (e.g., Math, Science, English)
        // and 2 assignments in Section B (e.g., Math, Science)
        $as1 = new TeacherClassSubject();
        $as1->setRelation('classSection', $sectionA);

        $as2 = new TeacherClassSubject();
        $as2->setRelation('classSection', $sectionA);

        $as3 = new TeacherClassSubject();
        $as3->setRelation('classSection', $sectionA);

        $as4 = new TeacherClassSubject();
        $as4->setRelation('classSection', $sectionB);

        $as5 = new TeacherClassSubject();
        $as5->setRelation('classSection', $sectionB);

        $teacher->setRelation('assignments', new Collection([$as1, $as2, $as3, $as4, $as5]));

        // Expected total unique assigned students = 30 (Section A) + 20 (Section B) = 50
        $this->assertEquals(50, $teacher->total_assigned_students);
    }

    /**
     * Test that getAssignedSubjectsAttribute retrieves display_name or fallback name attributes.
     */
    public function test_assigned_subjects_resolves_subject_display_name(): void
    {
        $teacher = new Teacher();

        $subject1 = new Subject();
        $subject1->name_en = 'Mathematics';
        $subject1->name_ar = 'الرياضيات';

        $subject2 = new Subject();
        $subject2->name_en = 'Science';
        $subject2->name_ar = 'العلوم';

        $as1 = new TeacherClassSubject();
        $as1->setRelation('subject', $subject1);

        $as2 = new TeacherClassSubject();
        $as2->setRelation('subject', $subject2);

        $teacher->setRelation('assignments', new Collection([$as1, $as2]));

        $assignedSubjects = $teacher->assigned_subjects;

        $this->assertCount(2, $assignedSubjects);
        $this->assertContains('Mathematics', $assignedSubjects);
        $this->assertContains('Science', $assignedSubjects);
    }
}
