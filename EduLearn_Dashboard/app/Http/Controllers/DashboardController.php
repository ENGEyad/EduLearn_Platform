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

        // ⚡ Bolt: Cache the AI insight to avoid redundant slow HTTP calls to the AI service
        // Using a cache key based on period and a hash of the current stats to ensure accuracy.
        $cacheKey = "ai_insight_{$period}_" . md5($statsSummary);
        $aiInsight = Cache::get($cacheKey);

        if (!$aiInsight) {
            try {
                // Call the AI service running on 8001
                $response = Http::timeout(10)->post('http://127.0.0.1:8001/chat/', [
                    'message' => "بصفتك محلل بيانات تعليمي، قم بتحليل إحصائيات فترة ($periodLabel) وتقديم تقرير (3 نقاط) باللغة العربية حول حالة المدرسة وتوصية واحدة: $statsSummary"
                ]);

                if ($response->successful()) {
                    $aiInsight = $response->json('reply') ?? "تعذر الحصول على تحليل دقيق حالياً.";
                    // Cache successful response for 1 hour
                    Cache::put($cacheKey, $aiInsight, 3600);
                } else {
                    $aiInsight = "الذكاء الاصطناعي غير متاح حالياً للتحليل.";
                }
            } catch (\Exception $e) {
                $aiInsight = "فشل الاتصال بخدمة الذكاء الاصطناعي: " . $e->getMessage();
                // Note: Exceptions are not cached to allow retry on next refresh
            }
        }

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
