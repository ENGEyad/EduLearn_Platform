<?php

namespace App\Http\Controllers;

use App\Models\ClassSectionSubject;
use App\Models\Lesson;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\StudentLessonProgress;
use App\Models\Subject;

class StudentPerformanceController extends Controller
{
    public function show(Student $student)
    {
        // verify school
        if ($student->school_id !== auth()->user()->school_id) {
            abort(403);
        }

        $classSectionId = $student->class_section_id;
        $subjectIds = ClassSectionSubject::where('class_section_id', $classSectionId)->pluck('subject_id');
        $subjects = Subject::whereIn('id', $subjectIds)->get();

        // Optimized: Bulk fetch all data from app_mysql to avoid N+1 queries
        $allLessons = Lesson::on('app_mysql')
            ->whereIn('subject_id', $subjectIds)
            ->where('class_section_id', $classSectionId)
            ->get();

        $lessonIds = $allLessons->pluck('id');

        $allProgressItems = StudentLessonProgress::on('app_mysql')
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $lessonIds)
            ->get();

        $allAttempts = StudentExerciseAttempt::on('app_mysql')
            ->with(['exerciseSet', 'lesson'])
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $lessonIds)
            ->orderBy('id', 'desc')
            ->get();

        $performance = [];

        foreach ($subjects as $sub) {
            // Filter in memory for each subject
            $subjectLessons = $allLessons->where('subject_id', $sub->id);
            $subjectLessonIds = $subjectLessons->pluck('id');

            $subjectProgressItems = $allProgressItems->whereIn('lesson_id', $subjectLessonIds);
            $subjectAttempts = $allAttempts->whereIn('lesson_id', $subjectLessonIds);

            $completedCount = $subjectProgressItems->where('status', 'completed')->count();
            $totalCount = $subjectLessons->count();

            $progressPercent = $totalCount > 0 ? round(($completedCount / $totalCount) * 100) : 0;

            $avgScore = 0;
            if ($subjectAttempts->count() > 0) {
                $avgScore = round($subjectAttempts->avg(function ($a) {
                    return $a->total_points > 0 ? ($a->score / $a->total_points) * 100 : 0;
                }), 1);
            }

            $performance[] = [
                'subject' => $sub,
                'total_lessons' => $totalCount,
                'completed_lessons' => $completedCount,
                'progress_percent' => $progressPercent,
                'total_study_time' => round($subjectProgressItems->sum('time_spent_seconds') / 60, 1),
                'attempts' => $subjectAttempts,
                'avg_score' => $avgScore,
            ];
        }

        return view('student_performance', [
            'pageTitle' => __('Student Performance').': '.$student->full_name,
            'pageSubtitle' => __('Academic ID').': '.$student->academic_id,
            'student' => $student,
            'performanceList' => $performance,
        ]);
    }
}
