<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Tests\TestCase;

class TeacherTotalStudentsTest extends TestCase
{
    public function test_total_assigned_students_deduplicates_class_sections()
    {
        $teacher = new Teacher(['id' => 1]);

        $cs = new ClassSection(['id' => 10]);
        $cs->students_count = 25;

        $as1 = new TeacherClassSubject(['teacher_id' => 1, 'class_section_id' => 10, 'subject_id' => 1]);
        $as1->setRelation('classSection', $cs);

        $as2 = new TeacherClassSubject(['teacher_id' => 1, 'class_section_id' => 10, 'subject_id' => 2]);
        $as2->setRelation('classSection', $cs);

        $teacher->setRelation('assignments', collect([$as1, $as2]));

        $this->assertEquals(25, $teacher->total_assigned_students);
    }
}
