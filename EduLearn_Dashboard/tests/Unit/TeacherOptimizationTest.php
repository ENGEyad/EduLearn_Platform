<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Tests\TestCase;

class TeacherOptimizationTest extends TestCase
{
    public function test_get_total_assigned_students_deduplicates_class_sections(): void
    {
        $teacher = new Teacher();

        $cs1 = new ClassSection();
        $cs1->id = 1;
        $cs1->students_count = 25;

        $cs2 = new ClassSection();
        $cs2->id = 2;
        $cs2->students_count = 15;

        $tcs1 = new TeacherClassSubject();
        $tcs1->class_section_id = 1;
        $tcs1->setRelation('classSection', $cs1);

        // Second assignment for the SAME class section (e.g. different subject)
        $tcs2 = new TeacherClassSubject();
        $tcs2->class_section_id = 1;
        $tcs2->setRelation('classSection', $cs1);

        // Assignment for second class section
        $tcs3 = new TeacherClassSubject();
        $tcs3->class_section_id = 2;
        $tcs3->setRelation('classSection', $cs2);

        $teacher->setRelation('assignments', collect([$tcs1, $tcs2, $tcs3]));

        // Total should be 25 + 15 = 40 (NOT 25 + 25 + 15 = 65)
        $this->assertEquals(40, $teacher->total_assigned_students);
    }

    public function test_get_assigned_subjects_returns_display_name(): void
    {
        $teacher = new Teacher();

        $subject1 = new Subject();
        $subject1->name_en = 'Mathematics';
        $subject1->name_ar = 'الرياضيات';

        $tcs1 = new TeacherClassSubject();
        $tcs1->setRelation('subject', $subject1);

        $teacher->setRelation('assignments', collect([$tcs1]));

        $this->assertContains('Mathematics', $teacher->assigned_subjects);
    }
}
