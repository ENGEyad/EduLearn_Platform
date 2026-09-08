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

        $performance = [];

        // Bolt performance boost: Batch fetch all lessons, progress, and attempts
        // across all student subjects into single database queries to eliminate N+1 loops.
        $allLessons = Lesson::on('app_mysql')
            ->whereIn('subject_id', $subjectIds)
            ->get()
            ->groupBy('subject_id');

        $allLessonIds = $allLessons->flatten()->pluck('id');

        $allProgressItems = StudentLessonProgress::on('app_mysql')
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $allLessonIds)
            ->get()
            ->groupBy('lesson_id');

        $allAttempts = StudentExerciseAttempt::on('app_mysql')
            ->with(['exerciseSet', 'lesson'])
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $allLessonIds)
            ->orderBy('id', 'desc')
            ->get()
            ->groupBy('lesson_id');

        foreach ($subjects as $sub) {
            $lessons = $allLessons->get($sub->id, collect());
            $lessonIds = $lessons->pluck('id');

            $progressItems = $lessonIds->flatMap(fn ($id) => $allProgressItems->get($id, collect()));
            $attempts = $lessonIds->flatMap(fn ($id) => $allAttempts->get($id, collect()))
                ->sortByDesc('id')
                ->values();

            $completedCount = $progressItems->where('status', 'completed')->count();
            $totalCount = $lessons->count();

            $progressPercent = $totalCount > 0 ? round(($completedCount / $totalCount) * 100) : 0;

            $avgScore = 0;
            if ($attempts->count() > 0) {
                $avgScore = round($attempts->avg(function ($a) {
                    return $a->total_points > 0 ? ($a->score / $a->total_points) * 100 : 0;
                }), 1);
            }

            $performance[] = [
                'subject' => $sub,
                'total_lessons' => $totalCount,
                'completed_lessons' => $completedCount,
                'progress_percent' => $progressPercent,
                'total_study_time' => round($progressItems->sum('time_spent_seconds') / 60, 1),
                'attempts' => $attempts,
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
