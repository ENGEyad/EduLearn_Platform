<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Teacher;
use App\Models\Student;
use App\Models\ClassSection;
use App\Models\Subject;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

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

        $teachersCount = Teacher::count();
        $studentsCount = Student::count();
        $classesCount = ClassSection::count();
        $subjectsCount = Subject::count();

        // Calculate averages (simulating historical data for the demo)
        $avgAttendance = Student::avg('attendance_rate') ?? 0;
        $avgPerformance = Student::avg('performance_avg') ?? 0;

        // Simulate some variance based on period
        if ($period === 'today') {
            $avgAttendance *= 0.98;
            $avgPerformance *= 1.05;
        }
        elseif ($period === 'month') {
            $avgAttendance *= 1.02;
        }

        // Prepare context for AI
        $statsSummary = "إحصائيات المدرسة لـ ($periodLabel): 
        - عدد المعلمين: $teachersCount
        - عدد الطلاب: $studentsCount
        - عدد الفصول: $classesCount
        - عدد المواد: $subjectsCount
        - متوسط الحضور: " . number_format($avgAttendance, 1) . "%
        - متوسط الأداء الأكاديمي: " . number_format($avgPerformance, 1) . " / 100";

        // ⚡ Bolt Optimization: Cache AI-generated insights to avoid blocking page loads
        // The AI service is slow; caching results based on the current stats & period
        // ensures a fast experience while still updating when data significantly changes.
        $cacheKey = 'dashboard_ai_insight_' . md5($statsSummary . $period);

        $aiInsight = Cache::remember($cacheKey, 3600, function() use ($periodLabel, $statsSummary) {
            try {
                // Call the AI service running on 8001
                $response = Http::timeout(10)->post('http://127.0.0.1:8001/chat/', [
                    'message' => "بصفتك محلل بيانات تعليمي، قم بتحليل إحصائيات فترة ($periodLabel) وتقديم تقرير (3 نقاط) باللغة العربية حول حالة المدرسة وتوصية واحدة: $statsSummary"
                ]);

                if ($response->successful()) {
                    return $response->json('reply') ?? "تعذر الحصول على تحليل دقيق حالياً.";
                }

                return "الذكاء الاصطناعي غير متاح حالياً للتحليل.";
            }
            catch (\Exception $e) {
                \Log::error("Dashboard AI analysis failed: " . $e->getMessage());
                return "فشل الاتصال بخدمة الذكاء الاصطناعي حالياً.";
            }
        });

        return view('dashboard', [
            'pageTitle' => 'Dashboard',
            'pageSubtitle' => 'Welcome, Admin!',
            'period' => $period,
            'periodLabel' => $periodLabel,
            'stats' => [
                'teachers' => $teachersCount,
                'students' => $studentsCount,
                'classes' => $classesCount,
                'subjects' => $subjectsCount,
                'attendance' => round($avgAttendance),
                'performance' => round($avgPerformance),
                'danglingStudents' => Student::whereNull('class_section_id')->count(),
            ],
            'aiInsight' => $aiInsight
        ]);
    }
}
