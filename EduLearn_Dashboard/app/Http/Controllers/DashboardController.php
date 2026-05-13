<?php

namespace App\Http\Controllers;

use App\Services\DashboardAnalyticsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class DashboardController extends Controller
{
    public function index(Request $request, DashboardAnalyticsService $analyticsService)
    {
        $schoolId = $this->resolveSchoolId();
        if ($schoolId === null) {
            abort(400, 'No school is associated with the authenticated user.');
        }

        $period = $request->get('period', 'week');
        $schoolName = auth()->user()->school->name ?? 'EduLearn School';
        $cacheKey = 'dashboard_stats_school_v3_' . $schoolId . '_' . $period;

        $overview = Cache::remember($cacheKey, now()->addMinutes(5), function () use ($analyticsService, $schoolId, $period, $schoolName) {
            return $analyticsService->buildOverview($schoolId, $period, $schoolName);
        });

        $latestReport = \App\Models\AiReport::where('school_id', $schoolId)
            ->where('status', 'completed')
            ->latest()
            ->first();

        $latestReport = \App\Models\AiReport::where('school_id', $schoolId)
            ->where('status', 'completed')
            ->latest()
            ->first();

        return view('dashboard', [
            'pageTitle' => __('Dashboard'),
            'pageSubtitle' => __('Welcome, :name', ['name' => auth()->user()->name]),
            'period' => $period,
            'periodLabel' => $overview['period_label'],
            'stats' => $overview['stats'],
            'aiInsight' => $latestReport ? $latestReport->dashboard_summary : null,
        ]);
    }

    public function getAiInsight(Request $request, DashboardAnalyticsService $analyticsService)
    {
        $schoolId = $this->resolveSchoolId();
        if ($schoolId === null) {
            return response()->json([
                'success' => false,
                'error' => __('Analysis failed'),
            ], 400);
        }

        $period = $request->get('period', 'week');
        $schoolName = auth()->user()->school->name ?? 'EduLearn School';
        $overview = $analyticsService->buildOverview($schoolId, $period, $schoolName);

        try {
            $response = Http::timeout(25)->post('http://127.0.0.1:8001/dashboard-insight/', $overview['insight_payload']);

            if ($response->successful()) {
                return response()->json([
                    'success' => true,
                    'aiInsight' => $response->json('reply') ?? $this->defaultAiInsightFallback(),
                ]);
            }
        } catch (\Throwable $exception) {
            \Illuminate\Support\Facades\Log::error('AI Insight Error: ' . $exception->getMessage(), [
                'exception' => $exception,
                'school_id' => $schoolId,
            ]);
            return response()->json([
                'success' => false,
                'error' => __('Connection error'),
            ], 500);
        }

        return response()->json([
            'success' => false,
            'error' => __('Analysis failed'),
        ], 500);
    }

    protected function defaultAiInsightFallback(): string
    {
        return 'تعذر الحصول على تحليل دقيق حالياً.';
    }

    protected function resolveSchoolId(): ?int
    {
        $user = auth()->user();
        if (!$user) {
            return null;
        }

        if (!empty($user->school_id)) {
            return (int) $user->school_id;
        }

        if (isset($user->school) && !empty($user->school?->id)) {
            return (int) $user->school->id;
        }

        return null;
    }
}
