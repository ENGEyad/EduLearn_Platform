<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use App\Models\Lesson;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\LessonBlock;
use App\Models\Exercise;
use App\Models\StudentResponse;

class AiController extends Controller
{
    private $aiBaseUrl = 'http://127.0.0.1:8001';

    /**
     * قم بتوليد تمارين بناءً على محتوى الدرس
     */
    public function generateExercises(Request $request)
    {
        $validated = $request->validate([
            'lesson_id' => 'required|integer',
            'count' => 'nullable|integer|min:1|max:10',
            'difficulty' => 'nullable|string|in:easy,medium,hard',
        ]);

        $lesson = Lesson::on('app_mysql')->with('blocks')->findOrFail($validated['lesson_id']);

        // تجميع النصوص من الدرس
        $content = $lesson->blocks->where('type', 'text')->pluck('body')->join("\n\n");

        // التحقق من وجود ملفات PDF
        $pdfBlock = $lesson->blocks->where('type', 'file')->first();
        $filename = null;
        if ($pdfBlock && $pdfBlock->media_path) {
            $filename = basename($pdfBlock->media_path);
        }

        try {
            $response = Http::post("{$this->aiBaseUrl}/generate-exercises/", [
                'content' => $content ?: null,
                'filename' => $filename,
                'count' => $validated['count'] ?? 5,
                'difficulty' => $validated['difficulty'] ?? 'medium'
            ]);

            if ($response->successful()) {
                $exercisesData = json_decode($response->json('exercises'), true);

                if (!is_array($exercisesData)) {
                    return response()->json(['success' => false, 'message' => 'Invalid AI response format'], 500);
                }

                $savedExercises = [];
                foreach ($exercisesData as $item) {
                    $exercise = Exercise::create([
                        'lesson_id' => $lesson->id,
                        'question' => $item['question'],
                        'type' => $item['type'] ?? 'multiple_choice',
                        'options' => isset($item['options']) ? json_encode($item['options']) : null,
                        'correct_answer' => $item['answer'],
                        'explanation' => $item['explanation'] ?? null,
                        'difficulty' => $validated['difficulty'] ?? 'medium',
                    ]);
                    $savedExercises[] = $exercise->id;
                }

                return response()->json([
                    'success' => true,
                    'message' => count($savedExercises) . ' exercises generated and saved.',
                    'lesson_id' => $lesson->id
                ]);
            }

            return response()->json(['success' => false, 'message' => 'AI failed to generate exercises'], 500);
        }
        catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * يحفظ إجابة الطالب على تمرين معين
     */
    public function submitResponse(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|integer',
            'exercise_id' => 'required|integer',
            'answer' => 'required|string',
            'time_taken' => 'nullable|numeric',
        ]);

        $exercise = Exercise::find($validated['exercise_id']);
        if (!$exercise)
            return response()->json(['success' => false, 'message' => 'Exercise not found'], 404);

        $isCorrect = (trim(strtolower($validated['answer'])) === trim(strtolower($exercise->correct_answer)));

        StudentResponse::create([
            'student_id' => $validated['student_id'],
            'exercise_id' => $validated['exercise_id'],
            'student_answer' => $validated['answer'],
            'is_correct' => $isCorrect,
            'time_taken' => $validated['time_taken'],
        ]);

        // Log Notification
        $student = \App\Models\Student::find($validated['student_id']);
        $statusText = $isCorrect ? 'بشكل صحيح' : 'بشكل خاطئ';
        \App\Models\DashboardNotification::logEvent(
            'student_event',
            'حل تمرين ذكي',
            "قام الطالب {$student->full_name} بالإجابة على تمرين {$statusText}.",
            $student->full_name,
            $isCorrect ? 'bi-check-circle-fill text-success' : 'bi-x-circle-fill text-danger'
        );

        return response()->json([
            'success' => true,
            'is_correct' => $isCorrect,
            'explanation' => $exercise->explanation
        ]);
    }

    /**
     * جلب تمارين مخصصة لمستوى الطالب
     */
    public function getAdaptiveExercises(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|integer',
            'topic' => 'required|string',
        ]);

        // حساب مستوى الطالب في هذا الموضوع (Topic) بناءً على آخر 10 إجابات
        $responses = StudentResponse::where('student_id', $validated['student_id'])
            ->whereHas('exercise', function ($q) use ($validated) {
            $q->where('question', 'LIKE', "%{$validated['topic']}%");
        })
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        $correctCount = $responses->where('is_correct', true)->count();
        $proficiency = $responses->count() > 0 ? $correctCount / $responses->count() : 0.5;

        // تحديد الأخطاء السابقة
        $previousMistakes = $responses->where('is_correct', false)->pluck('question')->toArray();

        try {
            $response = Http::post("{$this->aiBaseUrl}/adaptive-content/", [
                'student_level' => $proficiency,
                'topic' => $validated['topic'],
                'previous_mistakes' => array_slice($previousMistakes, 0, 3)
            ]);

            return response()->json([
                'success' => true,
                'proficiency' => $proficiency,
                'tailored_quiz' => json_decode($response->json('tailored_quiz'), true)
            ]);
        }
        catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * توليد تقرير يومي للمعلم
     */
    public function generateDailyReport(Request $request)
    {
        $validated = $request->validate([
            'teacher_code' => 'required|string',
        ]);

        $teacher = Teacher::where('teacher_code', $validated['teacher_code'])->firstOrFail();

        // تجميع إحصائيات الفصول التابعة له
        $classStats = [
            'total_students' => Student::whereHas('classSection', function ($q) use ($teacher) {
            $q->whereHas('assignments', function ($sq) use ($teacher) {
                    $sq->where('teacher_id', $teacher->id);
                }
                );
            })->count(),
            'avg_attendance' => 92, // Placeholder for real data
            'avg_performance' => 78, // Placeholder
        ];

        // الطلاب الذين يحتاجون اهتمام (مثال)
        $studentIssues = [
            ['name' => 'Ahmed Ali', 'issue' => 'Dropped in performance by 15%'],
            ['name' => 'Sara Mahmoud', 'issue' => 'Missed 3 days this week'],
        ];

        try {
            $response = Http::post("{$this->aiBaseUrl}/teacher-daily-report/", [
                'teacher_name' => $teacher->full_name,
                'class_stats' => $classStats,
                'student_issues' => $studentIssues
            ]);

            return response()->json([
                'success' => true,
                'report' => $response->json('report')
            ]);
        }
        catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }
}
