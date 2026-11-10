<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Illuminate\Database\Eloquent\Collection;
use Tests\TestCase;

class TeacherModelPerformanceTest extends TestCase
{
    public function test_assigned_subjects_resolves_display_name_and_avoids_null()
    {
        $teacher = new Teacher;

        $sub1 = new Subject(['name_en' => 'Mathematics', 'name_ar' => 'رياضيات']);
        $sub2 = new Subject(['name_en' => 'Physics', 'name_ar' => 'فيزياء']);

        $as1 = new TeacherClassSubject;
        $as1->setRelation('subject', $sub1);

        $as2 = new TeacherClassSubject;
        $as2->setRelation('subject', $sub2);

        $as3 = new TeacherClassSubject;
        $as3->setRelation('subject', $sub1); // duplicate subject assignment

        $teacher->setRelation('assignments', new Collection([$as1, $as2, $as3]));

        $subjects = $teacher->assigned_subjects;
        $this->assertCount(2, $subjects);
        $this->assertContains('Mathematics', $subjects);
        $this->assertContains('Physics', $subjects);
    }

    public function test_total_assigned_students_deduplicates_class_sections()
    {
        $teacher = new Teacher;

        // Section 1 has 30 students
        $cs1 = new ClassSection;
        $cs1->id = 10;
        $cs1->students_count = 30;

        // Section 2 has 20 students
        $cs2 = new ClassSection;
        $cs2->id = 20;
        $cs2->students_count = 20;

        // Teacher teaches 2 different subjects to section 1, and 1 subject to section 2
        $as1 = new TeacherClassSubject(['class_section_id' => 10]);
        $as1->setRelation('classSection', $cs1);

        $as2 = new TeacherClassSubject(['class_section_id' => 10]);
        $as2->setRelation('classSection', $cs1);

        $as3 = new TeacherClassSubject(['class_section_id' => 20]);
        $as3->setRelation('classSection', $cs2);

        $teacher->setRelation('assignments', new Collection([$as1, $as2, $as3]));

        // Expected deduplicated total: 30 + 20 = 50 (instead of double counting 30 + 30 + 20 = 80)
        $this->assertEquals(50, $teacher->total_assigned_students);
    }
}
