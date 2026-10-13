<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Tests\TestCase;

class TeacherModelTest extends TestCase
{
    public function test_total_assigned_students_deduplicates_class_sections()
    {
        $teacher = new Teacher;

        $cs1 = new ClassSection;
        $cs1->id = 10;
        $cs1->students_count = 25;

        $cs2 = new ClassSection;
        $cs2->id = 20;
        $cs2->students_count = 30;

        $as1 = new TeacherClassSubject;
        $as1->setRelation('classSection', $cs1);

        $as2 = new TeacherClassSubject;
        $as2->setRelation('classSection', $cs1); // Same class section assigned twice

        $as3 = new TeacherClassSubject;
        $as3->setRelation('classSection', $cs2);

        $teacher->setRelation('assignments', collect([$as1, $as2, $as3]));

        // cs1 (25) + cs2 (30) = 55 (deduplicated)
        $this->assertEquals(55, $teacher->total_assigned_students);
    }
}
