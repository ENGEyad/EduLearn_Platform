<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\Subject;
use App\Models\Lesson;
use App\Models\StudentLessonProgress;
use App\Models\StudentExerciseAttempt;
use App\Models\ClassSectionSubject;

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

        // ⚡ Bolt Optimization: Bulk fetch all related data to avoid N+1 queries in the loop.
        // This reduces database queries from O(N) to a constant number.
        $allLessons = Lesson::on('app_mysql')
            ->whereIn('subject_id', $subjectIds)
            ->get()
            ->groupBy('subject_id');

        $relevantLessonIds = $allLessons->flatten()->pluck('id');

        $allProgressItems = StudentLessonProgress::on('app_mysql')
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $relevantLessonIds)
            ->get()
            ->groupBy('lesson_id');

        $allAttempts = StudentExerciseAttempt::on('app_mysql')
            ->with(['exerciseSet', 'lesson'])
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $relevantLessonIds)
            ->orderBy('id', 'desc')
            ->get();

        $performance = [];

        foreach($subjects as $sub) {
            $lessons = $allLessons->get($sub->id, collect());
            $lessonIds = $lessons->pluck('id')->toArray();
            $lessonIdsSet = array_flip($lessonIds);
            
            // Filter progress items in memory for this subject's lessons
            $subjectProgressItems = collect();
            foreach($lessonIds as $lid) {
                if ($allProgressItems->has($lid)) {
                    $subjectProgressItems = $subjectProgressItems->merge($allProgressItems->get($lid));
                }
            }
            
            // Filter attempts in memory (maintaining global ID desc order from $allAttempts)
            $subjectAttempts = $allAttempts->filter(fn($attempt) => isset($lessonIdsSet[$attempt->lesson_id]));

            $completedCount = $subjectProgressItems->where('status', 'completed')->count();
            $totalCount = $lessons->count();
            
            $progressPercent = $totalCount > 0 ? round(($completedCount / $totalCount) * 100) : 0;

            $avgScore = 0;
            if ($subjectAttempts->count() > 0) {
                $avgScore = round($subjectAttempts->avg(function($a) {
                    return $a->total_points > 0 ? ($a->score / $a->total_points) * 100 : 0;
                }), 1);
            }

            $performance[] = [
                'subject' => $sub,
                'total_lessons' => $totalCount,
                'completed_lessons' => $completedCount,
                'progress_percent' => $progressPercent,
                'total_study_time' => round($subjectProgressItems->sum('time_spent_seconds') / 60, 1),
                'attempts' => $subjectAttempts->values(),
                'avg_score' => $avgScore,
            ];
        }

        return view('student_performance', [
            'pageTitle' => __('Student Performance') . ': ' . $student->full_name,
            'pageSubtitle' => __('Academic ID') . ': ' . $student->academic_id,
            'student' => $student,
            'performanceList' => $performance,
        ]);
    }
}
