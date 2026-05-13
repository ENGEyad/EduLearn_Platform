<?php

namespace App\Jobs;

use App\Models\AiReport;
use App\Services\AI\AcademicAnalyticsService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Exception;

class GenerateStrategicReportJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $timeout = 240; // 4 minutes

    /**
     * Create a new job instance.
     */
    public function __construct(
        protected AiReport $report
    ) {}

    /**
     * Execute the job.
     */
    public function handle(AcademicAnalyticsService $analyticsService): void
    {
        $this->report->update(['status' => 'processing']);

        try {
            // 1. Generate Full Strategic Report
            $content = $analyticsService->generateReport($this->report->school_id, [
                'filters' => $this->report->filters,
                'context' => ['title' => $this->report->title]
            ]);

            // 2. Generate Styled Dashboard Summary (Instant Load)
            $dashboardSummary = null;
            try {
                $promptPath = storage_path('app/ai/dashboard_prompt.txt');
                if (file_exists($promptPath)) {
                    $promptTemplate = file_get_contents($promptPath);
                    $fullPrompt = str_replace('[[REPORT_CONTENT]]', $content, $promptTemplate);

                    $response = \Illuminate\Support\Facades\Http::timeout(60)->post('http://127.0.0.1:8001/generate-report/', [
                        'prompt' => $fullPrompt
                    ]);

                    if ($response->successful()) {
                        $styledHtml = $response->json('report_markdown');
                        // Clean markdown blocks
                        $styledHtml = preg_replace('/^```html\s*/i', '', $styledHtml);
                        $styledHtml = preg_replace('/^```\s*/', '', $styledHtml);
                        $styledHtml = preg_replace('/```$/', '', $styledHtml);
                        $dashboardSummary = trim($styledHtml);
                    }
                }
            } catch (Exception $e) {
                \Log::warning("Failed to generate dashboard summary, but full report succeeded: " . $e->getMessage());
            }

            $this->report->update([
                'content' => $content,
                'dashboard_summary' => $dashboardSummary,
                'status' => 'completed'
            ]);
        } catch (Exception $e) {
            $this->report->update([
                'status' => 'failed',
                'error_message' => $e->getMessage()
            ]);
            \Log::error("Strategic Report Job Failed: " . $e->getMessage());
        }
    }
}
