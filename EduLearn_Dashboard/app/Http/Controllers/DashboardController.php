<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Teacher;
use App\Models\Student;
use App\Models\ClassSection;
use App\Models\Subject;
use Illuminate\Support\Facades\Http;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $period = $request->get('period', 'week');
        $periodMap = [
            'today' => 'اليوم',
            'week' => 'هذا الأسبوع',
            'month' => 'هذا الشهر',
            'year' => 'هذا العام'
        ];
        $periodLabel = $periodMap[$period] ?? 'هذا الأسبوع';

        // Cache statistics for 5 minutes
        $cacheKey = "dashboard_stats_school_" . (auth()->user()->school_id ?? 'global');
        $stats = \Illuminate\Support\Facades\Cache::remember($cacheKey, now()->addMinutes(5), function () {
            return [
                'teachers' => Teacher::count(),
                'students' => Student::count(),
                'classes' => ClassSection::count(),
                'subjects' => Subject::count(),
                'attendance' => round(Student::avg('attendance_rate') ?? 0),
                'performance' => round(Student::avg('performance_avg') ?? 0),
                'danglingStudents' => Student::whereNull('class_section_id')->count(),
            ];
        });

        return view('dashboard', [
            'pageTitle' => __('Dashboard'),
            'pageSubtitle' => __('Welcome, :name', ['name' => auth()->user()->name]),
            'period' => $period,
            'periodLabel' => $periodLabel,
            'stats' => $stats,
            'aiInsight' => null // Will be loaded via AJAX
        ]);
    }

    /**
     * Get AI-generated insight for the dashboard.
     * ⚡ Bolt: Implemented 1-hour caching for AI responses to improve performance and reduce API costs.
     */
    public function getAiInsight(Request $request)
    {
        $periodLabel = $request->get('period_label', 'هذا الأسبوع');
        $period = $request->get('period', 'week');

        // Fetch stats for AI
        $teachersCount = Teacher::count();
        $studentsCount = Student::count();
        $classesCount = ClassSection::count();
        $subjectsCount = Subject::count();
        $avgAttendance = Student::avg('attendance_rate') ?? 0;
        $avgPerformance = Student::avg('performance_avg') ?? 0;

        $statsSummary = "إحصائيات المدرسة لـ ($periodLabel): 
        - عدد المعلمين: $teachersCount
        - عدد الطلاب: $studentsCount
        - عدد الفصول: $classesCount
        - عدد المواد: $subjectsCount
        - متوسط الحضور: " . number_format($avgAttendance, 1) . "%
        - متوسط الأداء الأكاديمي: " . number_format($avgPerformance, 1) . " / 100";

        // Cache for 1 hour, key includes stats hash to refresh if data changes
        $cacheKey = "ai_insight_" . $period . "_" . md5($statsSummary);

        try {
            $aiInsight = \Illuminate\Support\Facades\Cache::remember($cacheKey, now()->addHour(), function () use ($statsSummary, $periodLabel) {
                $response = Http::timeout(15)->post('http://127.0.0.1:8001/chat/', [
                    'message' => "بصفتك محلل بيانات تعليمي، قم بتحليل إحصائيات فترة ($periodLabel) وتقديم تقرير (3 نقاط) باللغة العربية حول حالة المدرسة وتوصية واحدة: $statsSummary"
                ]);

                if ($response->successful()) {
                    return $response->json('reply') ?? "تعذر الحصول على تحليل دقيق حالياً.";
                }

                return null;
            });

            if ($aiInsight) {
                return response()->json([
                    'success' => true,
                    'aiInsight' => $aiInsight
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => "فشل الاتصال بخدمة الذكاء الاصطناعي"
            ], 500);
        }

        return response()->json(['success' => false, 'error' => 'Unknown error'], 500);
    }
}
