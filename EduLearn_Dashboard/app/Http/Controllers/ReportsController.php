<?php

namespace App\Http\Controllers;

use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Services\AI\AcademicAnalyticsService;
use App\Models\AiReport;
use App\Jobs\GenerateStrategicReportJob;

class ReportsController extends Controller
{
    public function index()
    {
        $schoolId = auth()->user()->school_id;
        $years = \App\Models\Student::select('grade')->distinct()->where('school_id', $schoolId)->whereNotNull('grade')->pluck('grade');
        $teachers = \App\Models\Teacher::select('id', 'full_name')->where('school_id', $schoolId)->get();
        // Get all unique classes/sections for filtering
        $classes = \App\Models\Student::select('grade', 'class_section')
            ->distinct()
            ->where('school_id', $schoolId)
            ->whereNotNull('grade')
            ->whereNotNull('class_section')
            ->orderBy('grade')
            ->orderBy('class_section')
            ->get();

        // Get all subject names
        $subjects = auth()->user()->school->subjects()->select('subjects.id', 'subjects.name_en as name')->orderBy('name_en')->get();

        // Get reports history
        $aiReports = AiReport::where('school_id', $schoolId)
            ->where('status', 'completed')
            ->latest()
            ->get();

        return view('reports', [
            'pageTitle' => __('Reports'),
            'pageSubtitle' => __('A detailed overview of class performance and student data.'),
            'years' => $years,
            'teachers' => $teachers,
            'classes_dropdown' => $classes,
            'subjects_dropdown' => $subjects,
            'aiReports' => $aiReports,
            'REPORTS_ROUTES' => [
                'list' => route('reports.list'),
                'class' => route('reports.class', ['grade' => '__GRADE__', 'section' => '__SECTION__']),
                'student' => route('reports.student', ['student' => '__ID__']),
                'subject' => route('reports.subject', ['student' => '__SID__', 'subject' => '__SUBID__']),
                'teacher' => route('reports.teacher', ['teacher' => '__ID__']),
                'atRisk' => route('reports.atRisk'),
                'aiAnalytics' => route('reports.aiAnalytics'),
                'aiReportStatus' => route('reports.aiReportStatus', ['report' => '__ID__']),
            ],
        ]);
    }

    // جلب قائمة الصفوف/الشعب مميّزة من جدول الطلاب مع عدّ الطلاب
    public function list(Request $request)
    {
        $schoolId = auth()->user()->school_id;
        $search = trim($request->get('search', ''));
        $classFilter = trim($request->get('class', ''));
        $subjectFilter = trim($request->get('subject', ''));

        // Start with a base query of distinct classes
        $query = Student::select('grade', 'class_section')->distinct()
            ->where('school_id', $schoolId)
            ->whereNotNull('grade')
            ->whereNotNull('class_section');

        // If filtering by subject, finding the class matching the subject Filter in memory or DB
        if ($subjectFilter !== '') {
            $query->whereHas('classSection', function ($q) use ($subjectFilter) {
                $q->whereHas('subjects', function ($q2) use ($subjectFilter) {
                        $q2->where('subject_id', $subjectFilter);
                    }
                    );
                });
        }

        if ($classFilter !== '') {
            $parts = explode('-', $classFilter);
            if (count($parts) == 2) {
                $query->where('grade', trim($parts[0]))
                    ->where('class_section', trim($parts[1]));
            }
        }

        // To handle the search string safely without breaking `group by`, we will fetch the grouped classes
        // then filter in memory if the search string is present.
        $baseClasses = $query->orderBy('grade')->orderBy('class_section')->get();

        $items = collect();
        foreach ($baseClasses as $row) {
            // Check student count
            $studentQuery = Student::where('school_id', $schoolId)->where('grade', $row->grade)->where('class_section', $row->class_section);

            // if we have a search term, we can check if it matches the class name or any student in the class
            $matchesSearch = true;
            if ($search !== '') {
                $s = strtolower($search);
                $className = strtolower($row->grade . ' - ' . $row->class_section);

                // If it doesn't match class name, check if any student matches
                if (strpos($className, $s) === false) {
                    $hasMatchingStudent = (clone $studentQuery)->where(function ($q) use ($search) {
                        $q->where('full_name', 'like', "%{$search}%")
                            ->orWhere('academic_id', 'like', "%{$search}%");
                    })->exists();
                    if (!$hasMatchingStudent) {
                        $matchesSearch = false; // Does not match class name or student name
                    }
                }
            }

            if ($matchesSearch) {
                $items->push([
                    'grade' => $row->grade,
                    'class_section' => $row->class_section,
                    'students_count' => $studentQuery->count(),
                ]);
            }
        }

        // If search matches students, grab them directly
        $matchingStudents = collect();
        if ($search !== '') {
            $matchingStudents = Student::where('school_id', $schoolId)->where(function ($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                    ->orWhere('academic_id', 'like', "%{$search}%");
            });

            if ($classFilter !== '') {
                $parts = explode('-', $classFilter);
                if (count($parts) == 2) {
                    $matchingStudents->where('grade', trim($parts[0]))
                        ->where('class_section', trim($parts[1]));
                }
            }

            $matchingStudents = $matchingStudents->get(['id', 'full_name', 'academic_id', 'grade', 'class_section', 'photo_path']);
        }

        return response()->json([
            'data' => $items->values(),
            'students' => $matchingStudents,
            'meta' => ['total' => $items->count() + $matchingStudents->count()],
        ]);
    }

    // تقرير صف: الطلاب + أرقام Placeholder + توزيع درجات
    public function class(Request $request, $grade, $section)
    {
        $schoolId = auth()->user()->school_id;

        $students = Student::query()
            ->where('school_id', $schoolId)
            ->where('grade', $grade)
            ->where('class_section', $section)
            ->orderBy('id', 'asc')
            ->get(['id', 'full_name', 'academic_id', 'class_section', 'photo_path', 'attendance_rate']);

        $studentIds = $students->pluck('id');

        $allAttempts = \App\Models\StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->select('student_id', \Illuminate\Support\Facades\DB::raw('avg(score) as avg_score'))
            ->groupBy('student_id')
            ->pluck('avg_score', 'student_id');

        $studentsTable = $students->map(function($s) use ($allAttempts) {
            $avgScore = $allAttempts[$s->id] ?? 0;
            $attendance = $s->attendance_rate ?? 100;
            return [
                'id' => $s->id,
                'name' => $s->full_name,
                'academic_id' => $s->academic_id,
                'section' => $s->class_section,
                'photo_url' => $s->photo_url,
                'score' => round($avgScore, 1) . '%',
                'attendance' => round($attendance, 1) . '%',
            ];
        });

        $totalStudyTimeSec = Student::query()
            ->where('school_id', $schoolId)
            ->where('grade', $grade)
            ->where('class_section', $section)
            ->sum('total_study_time_seconds');
        $totalStudyTimeHrs = round($totalStudyTimeSec / 3600, 1);

        $classSection = \App\Models\ClassSection::where('school_id', $schoolId)
            ->where('grade', $grade)
            ->where('section', $section)
            ->first();

        if ($classSection) {
            $avgScore = \App\Models\StudentExerciseAttempt::whereIn('student_id', $studentIds)->avg('score') ?? 0;
            $totalAttempts = \App\Models\StudentExerciseAttempt::whereIn('student_id', $studentIds)->count();
            $passRate = $totalAttempts > 0
                ? (\App\Models\StudentExerciseAttempt::whereIn('student_id', $studentIds)->where('score', '>=', 60)->count() / $totalAttempts)
                : 1.0;
            $attendance = $students->avg('attendance_rate') ?? 100;
            // scale to 0-1 if needed by front-end
            if ($attendance > 1) $attendance = $attendance / 100;
            $gradeDist = $this->gradeDistribution($studentIds);
        } else {
            $avgScore = 0; $passRate = 0; $attendance = 0; $gradeDist = [];
        }

        $stats = [
            'students' => $students->count() . ' / ' . $students->count(),
            'avg_score' => round($avgScore, 1),
            'pass_rate' => round($passRate, 2),
            'attendance' => round($attendance, 2),
            'study_time' => $totalStudyTimeHrs,
        ];

        return response()->json([
            'grade' => $grade,
            'section' => $section,
            'stats' => $stats,
            'grade_distribution' => $gradeDist,
            'students' => $studentsTable,
        ]);
    }

    // تقرير طالب: الهوية من DB + Placeholder للباقي
    public function student(Student $student)
    {
        if ($student->school_id !== auth()->user()->school_id) {
            abort(403, 'Unauthorized access to student report.');
        }

        $studyTimeHrs = round(($student->total_study_time_seconds ?? 0) / 3600, 1);

        // --- Real Subject Performance ---
        $classSectionId = $student->class_section_id;
        $subjectsData = \App\Models\Subject::whereHas('classSections', function($q) use ($classSectionId) {
            $q->where('class_section_id', $classSectionId);
        })->get()->map(function ($sub) use ($student) {
            // Real average score for THIS subject
            $avgScore = \App\Models\StudentExerciseAttempt::where('student_id', $student->id)
                ->whereHas('exerciseSet', function($q) use ($sub) {
                    $q->where('subject_id', $sub->id);
                })->avg('score') ?? 0;

            // Study time for this subject
            $lessons = \App\Models\Lesson::where('subject_id', $sub->id)->pluck('id');
            $timeSec = \App\Models\StudentLessonProgress::where('student_id', $student->id)
                ->whereIn('lesson_id', $lessons)
                ->sum('time_spent_seconds');

            return [
                'id' => $sub->id,
                'name' => $sub->name_en,
                'score' => round($avgScore / 100, 2), // Front-end expects 0-1
                'rank' => 'N/A', 
                'time' => round($timeSec / 3600, 1) . ' hrs',
                'numeric_time' => round($timeSec / 3600, 1),
                'status' => $avgScore >= 60 ? 'Pass' : 'Low',
            ];
        });

        // --- Real Progress Data (Last 6 Months) ---
        $progressLabels = []; $progressValues = [];
        for ($i = 5; $i >= 0; $i--) {
            $date = now()->subMonths($i);
            $progressLabels[] = $date->format('M');
            $progressValues[] = \App\Models\StudentExerciseAttempt::where('student_id', $student->id)
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->avg('score') ?? 0;
        }

        $overallAvg = \App\Models\StudentExerciseAttempt::where('student_id', $student->id)->avg('score') ?? 0;
        $attendance = ($student->attendance_rate ?? 100) / 100;

        return response()->json([
            'student' => [
                'id' => $student->id,
                'name' => $student->full_name,
                'class' => $student->grade,
                'section' => $student->class_section,
                'academic_id' => $student->academic_id,
                'photo_url' => $student->photo_url,
                'status' => $overallAvg >= 60 ? 'ON TRACK' : 'AT RISK',
            ],
            'stats' => [
                'avg_score' => round($overallAvg, 1),
                'pass_rate' => $overallAvg >= 60 ? 1.0 : 0.0, // simplified for now
                'attendance' => round($attendance, 2),
                'study_time' => $studyTimeHrs,
            ],
            'charts' => [
                'progress' => [
                    'labels' => $progressLabels,
                    'values' => $progressValues,
                ],
                'study_time_by_subject' => [
                    'labels' => $subjectsData->pluck('name')->toArray(),
                    'values' => $subjectsData->pluck('numeric_time')->toArray(),
                ],
            ],
            'subjects' => $subjectsData->toArray(),
        ]);
    }

    public function teacher(\App\Models\Teacher $teacher)
    {
        if ($teacher->school_id !== auth()->user()->school_id) {
            abort(403, 'Unauthorized access to teacher report.');
        }

        $schoolId = auth()->user()->school_id;

        // --- Active Assignments ---
        $assignments = \App\Models\TeacherClassSubject::where('teacher_id', $teacher->id)->with(['classSection', 'subject'])->get();
        $classSectionIds = $assignments->pluck('class_section_id')->unique();
        
        // --- Activity Stats ---
        $lessonsCount = \App\Models\Lesson::where('teacher_id', $teacher->id)->count();
        $exercisesCount = \App\Models\LessonExerciseSet::where('teacher_id', $teacher->id)->count();
        
        // --- Student Counts ---
        $totalStudents = \App\Models\Student::whereIn('class_section_id', $classSectionIds)->count();

        // --- Performance Results ---
        $studentIdsForTeacher = \App\Models\Student::whereIn('class_section_id', $classSectionIds)->pluck('id');
        
        $avgScore = \App\Models\StudentExerciseAttempt::whereIn('student_id', $studentIdsForTeacher)->avg('score') ?? 0;
        
        // Optional: Compete with school avg
        $schoolAvg = \App\Models\StudentExerciseAttempt::whereHas('student', function($q) use ($schoolId) {
            $q->where('school_id', $schoolId);
        })->avg('score') ?? 0;

        $contentStats = $assignments->map(function($a) use ($teacher) {
            $lessons = \App\Models\Lesson::where('teacher_id', $teacher->id)
                ->where('class_section_id', $a->class_section_id)
                ->where('subject_id', $a->subject_id)
                ->count();
            
            $classStudents = \App\Models\Student::where('class_section_id', $a->class_section_id)->pluck('id');
            $avgScoreClass = \App\Models\StudentExerciseAttempt::whereIn('student_id', $classStudents)->avg('score') ?? 0;
            
            return [
                'class' => $a->classSection->display_name ?? ($a->classSection->grade . ' - ' . $a->classSection->section),
                'subject' => $a->subject->name_en ?? 'N/A',
                'lessons' => $lessons,
                'avg_score' => round($avgScoreClass, 1)
            ];
        });

        // --- Efficient Timeline Fetch ---
        $weeks = []; $lessonCounts = []; $exerciseCounts = [];
        for ($i = 5; $i >= 0; $i--) {
            $start = now()->subWeeks($i)->startOfWeek();
            $end = (clone $start)->endOfWeek();
            
            $weeks[] = $start->format('d M'); // e.g., "14 Apr"
            
            $lessonCounts[] = \App\Models\Lesson::where('teacher_id', $teacher->id)
                ->whereBetween('created_at', [$start, $end])
                ->count();
                
            $exerciseCounts[] = \App\Models\LessonExerciseSet::where('teacher_id', $teacher->id)
                ->whereBetween('created_at', [$start, $end])
                ->count();
        }

        return response()->json([
            'teacher_info' => [
                'id' => $teacher->id,
                'name' => $teacher->full_name,
                'code' => $teacher->teacher_code ?? 'T-' . $teacher->id,
                'avatar' => $teacher->photo_url,
                'email' => $teacher->email,
            ],
            'overview' => [
                'total_lessons' => $lessonsCount,
                'total_exercises' => $exercisesCount,
                'total_students' => $totalStudents,
                'avg_student_score' => round($avgScore, 1),
                'school_avg_comparison' => round($schoolAvg, 1),
            ],
            'content_stats' => $contentStats,
            'activity_timeline' => [
                'labels' => $weeks,
                'lessons' => $lessonCounts,
                'exercises' => $exerciseCounts,
            ]
        ]);
    }

    public function subject(Student $student, $subjectId)
    {
        $attempts = \App\Models\StudentExerciseAttempt::where('student_id', $student->id)
            ->whereHas('exerciseSet', function($q) use ($subjectId) {
                $q->where('subject_id', $subjectId);
            })->latest()->take(10)->get();

        return response()->json([
            'student' => $student,
            'subject_id' => $subjectId,
            'performance' => $attempts->map(fn($a) => [
                'topic' => $a->exerciseSet->title ?? 'Exercise',
                'score' => round($a->score, 1),
                'status' => $a->score >= 60 ? 'good' : 'at_risk',
                'date' => $a->created_at->format('Y-m-d')
            ])
        ]);
    }

    /**
     * Helper for real data: grade distribution.
     */
    private function gradeDistribution($studentIds)
    {
        $scores = \App\Models\StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->pluck('score');

        $dist = ['A' => 0, 'B' => 0, 'C' => 0, 'D' => 0, 'F' => 0];
        foreach ($scores as $s) {
            if ($s >= 90) $dist['A']++;
            elseif ($s >= 80) $dist['B']++;
            elseif ($s >= 70) $dist['C']++;
            elseif ($s >= 60) $dist['D']++;
            else $dist['F']++;
        }

        return [
            ['label' => 'Excellent (A)', 'value' => $dist['A']],
            ['label' => 'Very Good (B)', 'value' => $dist['B']],
            ['label' => 'Good (C)', 'value' => $dist['C']],
            ['label' => 'Satisfactory (D)', 'value' => $dist['D']],
            ['label' => 'Failing (F)', 'value' => $dist['F']],
        ];
    }

    /**
     * Helper for real data: identify at-risk students.
     */
    private function getAtRiskStudentIds($schoolId, $classFilter = null)
    {
        $studentQuery = Student::where('school_id', $schoolId);
        
        if ($classFilter) {
            $parts = explode('-', $classFilter);
            if (count($parts) == 2) {
                $studentQuery->where('grade', trim($parts[0]))
                             ->where('class_section', trim($parts[1]));
            }
        }
        
        $targetIds = $studentQuery->pluck('id');
        if ($targetIds->isEmpty()) return collect();

        // Low score logic (avg < 60)
        $lowScores = \App\Models\StudentExerciseAttempt::whereIn('student_id', $targetIds)
            ->groupBy('student_id')
            ->havingRaw('AVG(score) < 60')
            ->pluck('student_id');

        // Low attendance logic (attendance < 75%)
        $lowAttendance = Student::whereIn('id', $targetIds)
            ->where('attendance_rate', '<', 75)
            ->pluck('id');

        return $lowScores->merge($lowAttendance)->unique();
    }

    /**
     * تقرير الطلاب المتعثرين (At-Risk Students)
     * معايير التعثر: درجة أقل من 60% أو حضور أقل من 85%
     */
    public function atRisk(Request $request)
    {
        $schoolId = auth()->user()->school_id;
        $classFilter = $request->get('class');
        $atRiskIds = $this->getAtRiskStudentIds($schoolId, $classFilter);

        $students = Student::whereIn('id', $atRiskIds)->get();

        $data = $students->map(function($s) {
            $avgScore = \App\Models\StudentExerciseAttempt::where('student_id', $s->id)->avg('score') ?? 0;
            $attendance = $s->attendance_rate ?? 100;

            return [
                'id' => $s->id,
                'name' => $s->full_name,
                'academic_id' => $s->academic_id,
                'class' => $s->grade . ' - ' . $s->class_section,
                'avg_score' => round($avgScore, 1) . '%',
                'attendance' => round($attendance, 1) . '%',
                'risk_level' => $avgScore < 60 ? 'High' : 'Medium',
                'reason' => $avgScore < 60 ? 'Low academic performance detected across core subjects.' : 'Low attendance rate below 75%.',
                'photo_url' => $s->photo_url,
            ];
        });

        return response()->json([
            'students' => $data,
        ]);
    }

    /**
     * Generate a professional AI-driven academic analytics report.
     */
    public function generateAiAnalytics(Request $request, AcademicAnalyticsService $analyticsService)
    {
        $schoolId = auth()->user()->school_id;
        $userId = auth()->id();
        
        $filters = [
            'grade' => $request->get('grade'),
            'class_section' => $request->get('class_section'),
        ];

        try {
            // Create a pending report record
            $report = AiReport::create([
                'user_id' => $userId,
                'school_id' => $schoolId,
                'title' => 'Strategic Academic Performance Report',
                'status' => 'pending',
                'filters' => $filters
            ]);

            // Dispatch background job
            GenerateStrategicReportJob::dispatch($report);

            return response()->json([
                'status' => 'success',
                'message' => 'Report generation started in background.',
                'report_id' => $report->id
            ]);
        } catch (\Exception $e) {
            \Log::error("Controller AI Analytics Start Failed: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Check the status of an AI report (for polling).
     */
    public function checkAiReportStatus(AiReport $report)
    {
        if ($report->user_id !== auth()->id()) {
            abort(403);
        }

        return response()->json([
            'status' => $report->status,
            'content' => $report->content,
            'error' => $report->error_message,
            'generated_at' => $report->updated_at->toIso8601String()
        ]);
    }
}
