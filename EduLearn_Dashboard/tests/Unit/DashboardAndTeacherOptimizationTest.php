<?php

namespace Tests\Unit;

use App\Models\ClassSection;
use App\Models\Teacher;
use App\Models\TeacherClassSubject;
use Tests\TestCase;

class DashboardAndTeacherOptimizationTest extends TestCase
{
    /**
     * Test that getTotalAssignedStudentsAttribute deduplicates class sections
     * when a teacher is assigned multiple subjects for the same class section.
     */
    public function test_teacher_total_assigned_students_deduplicates_class_sections(): void
    {
        $teacher = new Teacher;

        $section1 = new ClassSection(['id' => 1]);
        $section1->id = 1;
        $section1->students_count = 25;

        $section2 = new ClassSection(['id' => 2]);
        $section2->id = 2;
        $section2->students_count = 30;

        // Assignment 1: Section 1, Subject A
        $assignment1 = new TeacherClassSubject;
        $assignment1->class_section_id = 1;
        $assignment1->setRelation('classSection', $section1);

        // Assignment 2: Section 1, Subject B (same section!)
        $assignment2 = new TeacherClassSubject;
        $assignment2->class_section_id = 1;
        $assignment2->setRelation('classSection', $section1);

        // Assignment 3: Section 2, Subject A
        $assignment3 = new TeacherClassSubject;
        $assignment3->class_section_id = 2;
        $assignment3->setRelation('classSection', $section2);

        $teacher->setRelation('assignments', collect([$assignment1, $assignment2, $assignment3]));

        // Expected total should be 25 + 30 = 55 (not 25 + 25 + 30 = 80)
        $this->assertEquals(55, $teacher->total_assigned_students);
    }

    /**
     * Test that in-memory filtering with students_avg_attendance_rate works correctly.
     */
    public function test_sections_filter_with_avg_attendance_rate(): void
    {
        $section1 = new ClassSection(['id' => 1]);
        $section1->students_avg_attendance_rate = 92.5;

        $section2 = new ClassSection(['id' => 2]);
        $section2->students_avg_attendance_rate = 81.0; // below 85

        $section3 = new ClassSection(['id' => 3]);
        $section3->students_avg_attendance_rate = 84.9; // below 85

        $section4 = new ClassSection(['id' => 4]);
        $section4->students_avg_attendance_rate = null; // no students / no attendance

        $sections = collect([$section1, $section2, $section3, $section4]);

        $lowAttendanceClasses = $sections
            ->filter(function ($section) {
                $avgAttendance = $section->students_avg_attendance_rate;

                return $avgAttendance !== null && (float) $avgAttendance < 85;
            })
            ->count();

        $this->assertEquals(2, $lowAttendanceClasses);
    }
}
