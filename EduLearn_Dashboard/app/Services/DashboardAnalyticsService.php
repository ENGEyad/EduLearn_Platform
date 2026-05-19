<?php

namespace App\Services;

use App\Models\ClassSection;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\Subject;
use App\Models\Teacher;
use Carbon\Carbon;

class DashboardAnalyticsService
{
    public function __construct(
        protected DashboardInsightPayloadBuilder $payloadBuilder
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function buildOverview(int $schoolId, string $period, ?string $schoolName = null): array
    {
        $periodLabel = $this->periodLabel($period);
        [$currentStart, $currentEnd] = $this->periodRange($period);
        [$previousStart, $previousEnd] = $this->previousPeriodRange($period, $currentStart, $currentEnd);

        $studentIds = Student::where('school_id', $schoolId)->pluck('id');
        $sections = ClassSection::where('school_id', $schoolId)
            ->withCount('students')
            ->withAvg('students', 'attendance_rate')
            ->get();

        $performanceOverall = (float) (StudentExerciseAttempt::whereIn('student_id', $studentIds)->avg('score') ?? 0);
        $attendanceOverall = (float) (Student::where('school_id', $schoolId)->avg('attendance_rate') ?? 0);

        $stats = [
            'teachers' => Teacher::where('school_id', $schoolId)->count(),
            'students' => $studentIds->count(),
            'classes' => $sections->count(),
            'subjects' => Subject::whereHas('classSections', function ($query) use ($schoolId) {
                $query->where('school_id', $schoolId);
            })->count(),
            'attendance' => round($attendanceOverall, 1),
            'performance' => round($performanceOverall, 1),
            'danglingStudents' => Student::where('school_id', $schoolId)->whereNull('class_section_id')->count(),
            'chartData' => [
                'labels' => $sections->map(fn ($section) => $section->name ?: ($section->grade . ' / ' . $section->section))->values(),
                'data' => $sections->pluck('students_count')->values(),
            ],
        ];

        $currentPerformance = (float) (StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->whereBetween('created_at', [$currentStart, $currentEnd])
            ->avg('score') ?? 0);

        $previousPerformance = (float) (StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->whereBetween('created_at', [$previousStart, $previousEnd])
            ->avg('score') ?? 0);

        $performanceChangePoints = null;
        if ($currentPerformance > 0 && $previousPerformance > 0) {
            $performanceChangePoints = round($currentPerformance - $previousPerformance, 1);
        }

        $lowAttendanceStudents = Student::where('school_id', $schoolId)
            ->where('attendance_rate', '<', 85)
            ->count();

        $lowPerformanceStudents = StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->select('student_id')
            ->groupBy('student_id')
            ->havingRaw('AVG(score) < ?', [70])
            ->get()
            ->count();

        $lowAttendanceClasses = $sections
            ->filter(function ($section) {
                $avgAttendance = $section->students_avg_attendance_rate;
                return $avgAttendance !== null && (float) $avgAttendance < 85;
            })
            ->count();

        $risks = [];
        if ($stats['attendance'] < 85) {
            $risks[] = 'average attendance is below the 85% threshold';
        }
        if ($stats['performance'] < 70) {
            $risks[] = 'average academic performance is below the 70/100 threshold';
        }
        if ($stats['danglingStudents'] > 0) {
            $risks[] = 'some students are unassigned to class sections';
        }

        $anomalies = [];
        if ($stats['danglingStudents'] > 0) {
            $anomalies[] = $stats['danglingStudents'] . ' unassigned students';
        }
        if ($lowAttendanceStudents > 0) {
            $anomalies[] = $lowAttendanceStudents . ' students below the attendance threshold';
        }
        if ($lowPerformanceStudents > 0) {
            $anomalies[] = $lowPerformanceStudents . ' students with weak exercise performance averages';
        }
        if ($lowAttendanceClasses > 0) {
            $anomalies[] = $lowAttendanceClasses . ' classes below the attendance threshold';
        }

        $recommendedFocus = [];
        if ($stats['attendance'] < 85 || $lowAttendanceStudents > 0) {
            $recommendedFocus[] = 'attendance recovery plan for weak cohorts';
        }
        if ($stats['performance'] < 70 || $lowPerformanceStudents > 0) {
            $recommendedFocus[] = 'targeted academic intervention for low-performing students';
        }
        if ($stats['danglingStudents'] > 0) {
            $recommendedFocus[] = 'complete class assignment cleanup for all unassigned students';
        }
        if (empty($recommendedFocus)) {
            $recommendedFocus[] = 'maintain current performance with continuous monitoring';
        }

        $dataLimitations = [
            'attendance trend is unavailable because attendance is stored as a current aggregate field rather than a historical time series',
        ];
        if ($performanceChangePoints === null) {
            $dataLimitations[] = 'performance trend comparison is limited because one of the compared periods has insufficient attempt data';
        }

        $analytics = [
            'period' => $period,
            'period_label' => $periodLabel,
            'stats' => $stats,
            'performance_change_points' => $performanceChangePoints,
            'risks' => $risks,
            'anomalies' => $anomalies,
            'recommended_focus' => $recommendedFocus,
            'data_limitations' => $dataLimitations,
        ];

        $analytics['insight_payload'] = $this->payloadBuilder->build($analytics, $schoolName);

        return $analytics;
    }

    protected function periodLabel(string $period): string
    {
        return match ($period) {
            'today' => 'اليوم',
            'month' => 'هذا الشهر',
            'year' => 'هذا العام',
            default => 'هذا الأسبوع',
        };
    }

    /**
     * @return array{0: Carbon, 1: Carbon}
     */
    protected function periodRange(string $period): array
    {
        $now = now();

        return match ($period) {
            'today' => [$now->copy()->startOfDay(), $now->copy()->endOfDay()],
            'month' => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()],
            'year' => [$now->copy()->startOfYear(), $now->copy()->endOfYear()],
            default => [$now->copy()->startOfWeek(), $now->copy()->endOfWeek()],
        };
    }

    /**
     * @return array{0: Carbon, 1: Carbon}
     */
    protected function previousPeriodRange(string $period, Carbon $currentStart, Carbon $currentEnd): array
    {
        return match ($period) {
            'today' => [$currentStart->copy()->subDay()->startOfDay(), $currentEnd->copy()->subDay()->endOfDay()],
            'month' => [$currentStart->copy()->subMonthNoOverflow()->startOfMonth(), $currentStart->copy()->subMonthNoOverflow()->endOfMonth()],
            'year' => [$currentStart->copy()->subYear()->startOfYear(), $currentStart->copy()->subYear()->endOfYear()],
            default => [$currentStart->copy()->subWeek()->startOfWeek(), $currentEnd->copy()->subWeek()->endOfWeek()],
        };
    }
}
