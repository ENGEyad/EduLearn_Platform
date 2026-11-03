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
    public function test_assigned_subjects_uses_display_name_and_filters_correctly(): void
    {
        $teacher = new Teacher;
        $sub1 = new Subject(['name_en' => 'Math', 'name_ar' => 'رياضيات']);
        $sub2 = new Subject(['name_en' => 'Science', 'name_ar' => 'علوم']);

        $as1 = new TeacherClassSubject;
        $as1->setRelation('subject', $sub1);

        $as2 = new TeacherClassSubject;
        $as2->setRelation('subject', $sub2);

        $as3 = new TeacherClassSubject; // duplicate subject
        $as3->setRelation('subject', $sub1);

        $teacher->setRelation('assignments', new Collection([$as1, $as2, $as3]));

        $subjects = $teacher->assigned_subjects;
        $this->assertCount(2, $subjects);
        $this->assertContains($sub1->display_name, $subjects);
        $this->assertContains($sub2->display_name, $subjects);
    }

    public function test_total_assigned_students_deduplicates_class_sections(): void
    {
        $teacher = new Teacher;

        $cs1 = new ClassSection(['id' => 10, 'name' => '10-A']);
        $cs1->id = 10;
        $cs1->students_count = 25;

        // Same section 10 assigned to teacher for another subject
        $cs1_dup = new ClassSection(['id' => 10, 'name' => '10-A']);
        $cs1_dup->id = 10;
        $cs1_dup->students_count = 25;

        $cs2 = new ClassSection(['id' => 20, 'name' => '10-B']);
        $cs2->id = 20;
        $cs2->students_count = 30;

        $as1 = new TeacherClassSubject;
        $as1->setRelation('classSection', $cs1);

        $as2 = new TeacherClassSubject;
        $as2->setRelation('classSection', $cs1_dup);

        $as3 = new TeacherClassSubject;
        $as3->setRelation('classSection', $cs2);

        $teacher->setRelation('assignments', new Collection([$as1, $as2, $as3]));

        // Deduplication: 25 + 30 = 55 (instead of 25 + 25 + 30 = 80)
        $this->assertEquals(55, $teacher->total_assigned_students);
    }

    public function test_total_assigned_students_uses_loaded_students_relation_without_rehydrating(): void
    {
        $teacher = new Teacher;

        $cs1 = new ClassSection(['id' => 10, 'name' => '10-A']);
        $cs1->id = 10;
        $cs1->setRelation('students', new Collection(['student1', 'student2']));

        $as1 = new TeacherClassSubject;
        $as1->setRelation('classSection', $cs1);

        $teacher->setRelation('assignments', new Collection([$as1]));

        $this->assertEquals(2, $teacher->total_assigned_students);
    }
}
