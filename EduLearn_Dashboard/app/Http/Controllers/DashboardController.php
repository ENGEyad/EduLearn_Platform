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

    public function getAiInsight(Request $request)
    {
        $periodLabel = $request->get('period_label', 'هذا الأسبوع');
        $period = $request->get('period', 'week');
        
        // Fetch fresh stats for AI (or use cached ones if preferred, but AI usually wants latest)
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

        // ⚡ Bolt Optimization: Cache AI response to avoid redundant external API calls.
        // Cache key is based on the period and a hash of the current stats.
        $statsHash = md5($statsSummary);
        $cacheKey = "ai_insight_{$period}_{$statsHash}";

        if ($cached = \Illuminate\Support\Facades\Cache::get($cacheKey)) {
            return response()->json([
                'success' => true,
                'aiInsight' => $cached,
                'cached' => true
            ]);
        }

        try {
            $response = Http::timeout(15)->post('http://127.0.0.1:8001/chat/', [
                'message' => "بصفتك محلل بيانات تعليمي، قم بتحليل إحصائيات فترة ($periodLabel) وتقديم تقرير (3 نقاط) باللغة العربية حول حالة المدرسة وتوصية واحدة: $statsSummary"
            ]);

            if ($response->successful()) {
                $reply = $response->json('reply') ?? "تعذر الحصول على تحليل دقيق حالياً.";

                // Cache the response for 1 hour (3600 seconds)
                \Illuminate\Support\Facades\Cache::put($cacheKey, $reply, 3600);

                return response()->json([
                    'success' => true,
                    'aiInsight' => $reply
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
