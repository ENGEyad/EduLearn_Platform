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

        $stats = $this->getDashboardStats();

        return view('dashboard', [
            'pageTitle' => __('Dashboard'),
            'pageSubtitle' => __('Welcome, :name', ['name' => auth()->user()->name]),
            'period' => $period,
            'periodLabel' => $periodLabel,
            'stats' => $stats,
            'aiInsight' => null // Will be loaded via AJAX
        ]);
    }

    public function getAiInsight(Request $request)
    {
        $periodLabel = $request->get('period_label', 'هذا الأسبوع');

        // Use cached stats to avoid redundant database queries
        $stats = $this->getDashboardStats();

        $statsSummary = "إحصائيات المدرسة لـ ($periodLabel): 
        - عدد المعلمين: {$stats['teachers']}
        - عدد الطلاب: {$stats['students']}
        - عدد الفصول: {$stats['classes']}
        - عدد المواد: {$stats['subjects']}
        - متوسط الحضور: {$stats['attendance']}%
        - متوسط الأداء الأكاديمي: {$stats['performance']} / 100";

        try {
            $response = Http::timeout(15)->post('http://127.0.0.1:8001/chat/', [
                'message' => "بصفتك محلل بيانات تعليمي، قم بتحليل إحصائيات فترة ($periodLabel) وتقديم تقرير (3 نقاط) باللغة العربية حول حالة المدرسة وتوصية واحدة: $statsSummary"
            ]);

            if ($response->successful()) {
                return response()->json([
                    'success' => true,
                    'aiInsight' => $response->json('reply') ?? "تعذر الحصول على تحليل دقيق حالياً."
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

    /**
     * Get cached dashboard statistics.
     * Bolt Optimization: Consolidates redundant queries into a single cached result.
     */
    private function getDashboardStats()
    {
        $cacheKey = "dashboard_stats_school_" . (auth()->user()->school_id ?? 'global');
        return \Illuminate\Support\Facades\Cache::remember($cacheKey, now()->addMinutes(5), function () {
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
    }
}
