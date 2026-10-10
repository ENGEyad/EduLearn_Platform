<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Tests\TestCase;

class TeacherPerformanceTest extends TestCase
{
    public function test_total_assigned_students_deduplicates_class_sections(): void
    {
        $teacher = new Teacher;

        // Create mock class sections
        $section1 = new ClassSection;
        $section1->id = 10;
        $section1->students_count = 30;

        $section2 = new ClassSection;
        $section2->id = 20;
        $section2->students_count = 25;

        // Create 3 assignments: 2 for section1 (different subjects), 1 for section2
        $a1 = new TeacherClassSubject(['class_section_id' => 10, 'subject_id' => 1]);
        $a1->setRelation('classSection', $section1);

        $a2 = new TeacherClassSubject(['class_section_id' => 10, 'subject_id' => 2]);
        $a2->setRelation('classSection', $section1);

        $a3 = new TeacherClassSubject(['class_section_id' => 20, 'subject_id' => 1]);
        $a3->setRelation('classSection', $section2);

        $teacher->setRelation('assignments', collect([$a1, $a2, $a3]));

        // Total unique students across sections should be 30 + 25 = 55 (not 30+30+25 = 85)
        $this->assertEquals(55, $teacher->total_assigned_students);
    }
}
