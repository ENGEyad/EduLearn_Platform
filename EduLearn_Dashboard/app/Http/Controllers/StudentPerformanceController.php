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

        // ⚡ Bolt Optimization: Replace N+1 queries with bulk fetches
        // This reduces query count from O(3N) to O(1) relative to number of subjects.

        $allLessons = Lesson::on('app_mysql')
            ->whereIn('subject_id', $subjectIds)
            ->get();
        $allLessonIds = $allLessons->pluck('id');

        $allProgress = StudentLessonProgress::on('app_mysql')
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $allLessonIds)
            ->get()
            ->groupBy('lesson_id');

        $allAttempts = StudentExerciseAttempt::on('app_mysql')
            ->with(['exerciseSet', 'lesson'])
            ->where('student_id', $student->id)
            ->whereIn('lesson_id', $allLessonIds)
            ->orderBy('id', 'desc') // Use DB sorting for better performance
            ->get()
            ->groupBy('lesson_id');

        $lessonsBySubject = $allLessons->groupBy('subject_id');

        $performance = [];
        foreach($subjects as $sub) {
            $lessons = $lessonsBySubject->get($sub->id, collect());
            $lessonIds = $lessons->pluck('id');
            
            $subjectProgress = collect();
            $subjectAttempts = collect();

            foreach ($lessonIds as $lId) {
                if ($p = $allProgress->get($lId)) {
                    $subjectProgress = $subjectProgress->merge($p);
                }
                if ($a = $allAttempts->get($lId)) {
                    $subjectAttempts = $subjectAttempts->merge($a);
                }
            }
            
            // Re-sort attempts if needed, though they were already sorted by id desc
            $subjectAttempts = $subjectAttempts->sortByDesc('id');

            $completedCount = $subjectProgress->where('status', 'completed')->count();
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
                'total_study_time' => round($subjectProgress->sum('time_spent_seconds') / 60, 1),
                'attempts' => $subjectAttempts,
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
