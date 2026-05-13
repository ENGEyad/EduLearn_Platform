<?php

namespace App\Services\AI;

use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use App\Models\StudentLessonProgress;
use App\Models\StudentExerciseAttempt;
use App\Models\LearningActivity;
use Illuminate\Support\Facades\Http;
use Exception;

class AcademicAnalyticsService
{
    public function __construct(
        protected AnalyticsPromptBuilder $promptBuilder
    ) {}

    /**
     * Orchestrate the data aggregation and AI call to generate a professional analytics report.
     *
     * @param int $schoolId
     * @param array $options
     * @return string
     * @throws Exception
     */
    public function generateReport(int $schoolId, array $options = []): string
    {
        $school = School::findOrFail($schoolId);
        $filters = $options['filters'] ?? [];
        
        // 1. Collect Core Data & Aggregates
        $studentQuery = Student::where('school_id', $schoolId);
        
        if (!empty($filters['grade'])) {
            $studentQuery->where('grade', $filters['grade']);
        }
        if (!empty($filters['class_section'])) {
            $studentQuery->where('class_section', $filters['class_section']);
        }
        
        $allStudents = $studentQuery->get();
        $totalStudents = $allStudents->count();
        
        // Sample students if the list is too large (Top 40, Bottom 40, and 20 random)
        if ($totalStudents > 100) {
            $sorted = $allStudents->sortByDesc('performance_avg');
            $students = $sorted->take(40)
                ->merge($sorted->take(-40))
                ->merge($allStudents->random(min($totalStudents, 20)))
                ->unique('id');
        } else {
            $students = $allStudents;
        }

        $teachers = Teacher::where('school_id', $schoolId)->get();
        $classes = ClassSection::where('school_id', $schoolId)->get();
        $classIds = $classes->pluck('id');
        
        // 2. Collect Relationship & Performance Data (Filtered by sampled students or scoped to school)
        $assignments = TeacherClassSubject::whereIn('class_section_id', $classIds)->get();
        
        $sampledStudentIds = $students->pluck('id');
        $progress = StudentLessonProgress::whereIn('student_id', $sampledStudentIds)->get();
        $attempts = StudentExerciseAttempt::whereIn('student_id', $sampledStudentIds)->get();
        
        // 3. Collect Recent Activities
        $activities = LearningActivity::whereIn('class_section_id', $classIds)
            ->latest()
            ->take(50)
            ->get();

        // 4. Build Aggregated Stats for Context
        $schoolStats = [
            'total_students_count' => $totalStudents,
            'global_avg_score' => round($allStudents->avg('performance_avg') ?? 0, 2),
            'global_attendance_rate' => round($allStudents->avg('attendance_rate') ?? 0, 2),
            'data_sampling_active' => $totalStudents > 100,
            'sample_size' => $students->count()
        ];

        // 5. Build Payload
        $dataPayload = $this->promptBuilder->build(
            $school,
            $students,
            $teachers,
            $classes,
            $assignments,
            $progress,
            $attempts,
            $activities,
            array_merge($options['context'] ?? [], ['school_stats' => $schoolStats]),
            $options['filters'] ?? [],
            $options['comparison'] ?? ['enabled' => false]
        );

        // 5. Prepare AI Request
        $systemPrompt = $this->promptBuilder->getSystemInstruction();
        
        // Assuming your AI service has an endpoint that takes a system prompt and a JSON data payload
        $aiServiceUrl = config('services.ai.url', 'http://127.0.0.1:8001') . '/api/v1/analytics/generate';
        
        try {
            $response = Http::timeout(120)->post($aiServiceUrl, [
                'system_prompt' => $systemPrompt,
                'data' => $dataPayload,
                'model' => $options['model'] ?? 'gemini-flash-latest',
            ]);
            
            if ($response->failed()) {
                throw new Exception("AI Analytics Service Error: " . ($response->json('detail') ?? $response->body()));
            }

            return $response->json('report_markdown') ?? 'No report content returned.';
        } catch (Exception $e) {
            \Log::error("Academic Analytics Generation Failed: " . $e->getMessage());
            throw new Exception("AI Analysis Failed: " . $e->getMessage());
        }
    }
}
