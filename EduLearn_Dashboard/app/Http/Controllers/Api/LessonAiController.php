<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\LessonAiSource;
use App\Models\Teacher;
use App\Services\AI\AiOrchestratorService;
use App\Services\AI\LessonAiSourceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LessonAiController extends Controller
{
    public function __construct(
        protected AiOrchestratorService $aiOrchestrator,
        protected LessonAiSourceService $sourceService,
    ) {
    }

    /**
     * GET /api/teacher/lessons/ai/source/{lesson}
     */
    public function getActiveSource(Request $request, $lesson): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher || !($teacher instanceof Teacher)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated or not a teacher',
            ], 401);
        }

        $lessonRow = $this->resolveOwnedLesson((int) $lesson, $teacher->id);
        if (!$lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        $source = $this->sourceService->getActiveSourceForLesson($lessonRow);

        return response()->json([
            'success' => true,
            'has_active_source' => $source !== null,
            'source' => $source ? $this->transformSource($source) : null,
        ]);
    }

    /**
     * POST /api/teacher/lessons/ai/source/{lesson}/replace
     */
    public function replaceSource(Request $request, $lesson): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher || !($teacher instanceof Teacher)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated or not a teacher',
            ], 401);
        }

        $validated = $request->validate([
            'source_text' => 'nullable|string',
            'file' => 'nullable|file|mimes:pdf|max:51200',
        ]);

        $lessonRow = $this->resolveOwnedLesson((int) $lesson, $teacher->id);
        if (!$lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        $sourceText = isset($validated['source_text'])
            ? trim((string) $validated['source_text'])
            : '';
        $pdfFile = $request->file('file');
        $hasText = $sourceText !== '';
        $hasFile = $pdfFile !== null;

        if (($hasText && $hasFile) || (!$hasText && !$hasFile)) {
            return response()->json([
                'success' => false,
                'message' => 'Provide either source_text or one PDF file.',
            ], 422);
        }

        try {
            $source = $this->sourceService->createOrReplaceActiveSource(
                lesson: $lessonRow,
                teacher: $teacher,
                sourceText: $hasText ? $sourceText : null,
                pdfFile: $hasFile ? $pdfFile : null,
            );

            return response()->json([
                'success' => true,
                'message' => 'AI source saved successfully.',
                'source' => $this->transformSource($source),
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to save AI source.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/teacher/lessons/ai/generate-blocks
     */
    public function generateBlocks(Request $request): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher || !($teacher instanceof Teacher)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated or not a teacher',
            ], 401);
        }

        $validated = $request->validate([
            'lesson_id' => 'required|integer',
            'instruction_key' => 'required|string|max:100',
            'source_mode' => 'required|in:existing,new_or_replace',
            'source_text' => 'nullable|string',
            'file' => 'nullable|file|mimes:pdf|max:51200',
        ]);

        $lessonRow = $this->resolveOwnedLesson((int) $validated['lesson_id'], $teacher->id);
        if (!$lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        $instructionKey = (string) $validated['instruction_key'];
        $instructionText = $this->resolveInstructionText($instructionKey);
        if ($instructionText === null) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid AI instruction key.',
            ], 422);
        }

        $sourceMode = (string) $validated['source_mode'];
        $sourceText = isset($validated['source_text'])
            ? trim((string) $validated['source_text'])
            : '';
        $pdfFile = $request->file('file');

        if ($sourceMode === 'existing') {
            if ($sourceText !== '' || $pdfFile !== null) {
                return response()->json([
                    'success' => false,
                    'message' => 'Do not send source_text or file when source_mode is existing.',
                ], 422);
            }

            if (!$this->sourceService->getActiveSourceForLesson($lessonRow)) {
                return response()->json([
                    'success' => false,
                    'message' => 'No active AI source found for this lesson.',
                ], 422);
            }
        } else {
            $hasText = $sourceText !== '';
            $hasFile = $pdfFile !== null;

            if (($hasText && $hasFile) || (!$hasText && !$hasFile)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Provide either source_text or one PDF file.',
                ], 422);
            }
        }

        try {
            $result = $this->aiOrchestrator->generateBlocks(
                lesson: $lessonRow,
                teacher: $teacher,
                instructionKey: $instructionKey,
                instructionText: $instructionText,
                sourceText: $sourceMode === 'new_or_replace' && $sourceText !== '' ? $sourceText : null,
                pdfFile: $sourceMode === 'new_or_replace' ? $pdfFile : null,
                replaceSource: $sourceMode === 'new_or_replace',
            );

            return response()->json([
                'success' => true,
                'message' => 'AI blocks generated successfully.',
                'ai_source_id' => $result['source']->id,
                'ai_run_id' => $result['run']->id,
                'blocks' => $result['blocks'],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate AI blocks.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/teacher/lessons/ai/rewrite-block
     */
    public function rewriteBlock(Request $request): JsonResponse
    {
        $teacher = $request->user();
        if (!$teacher || !($teacher instanceof Teacher)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated or not a teacher',
            ], 401);
        }

        $validated = $request->validate([
            'lesson_id' => 'required|integer',
            'stable_key' => 'required|string|max:100',
            'current_body' => 'required|string',
            'instruction_key' => 'required|string|max:100',
        ]);

        $lessonRow = $this->resolveOwnedLesson((int) $validated['lesson_id'], $teacher->id);
        if (!$lessonRow) {
            return response()->json([
                'success' => false,
                'message' => 'Lesson not found',
            ], 404);
        }

        $instructionKey = (string) $validated['instruction_key'];
        $instructionText = $this->resolveInstructionText($instructionKey);
        if ($instructionText === null) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid AI instruction key.',
            ], 422);
        }

        try {
            $result = $this->aiOrchestrator->rewriteBlock(
                lesson: $lessonRow,
                teacher: $teacher,
                stableKey: (string) $validated['stable_key'],
                currentBody: (string) $validated['current_body'],
                instructionKey: $instructionKey,
                instructionText: $instructionText,
            );

            return response()->json([
                'success' => true,
                'message' => 'AI block rewrite completed successfully.',
                'ai_run_id' => $result['run']->id,
                'stable_key' => (string) $validated['stable_key'],
                'body' => $result['rewrite']['body'],
                'last_edit_origin' => $result['rewrite']['last_edit_origin'],
                'ai_source_id' => $result['rewrite']['ai_source_id'],
                'ai_last_run_id' => $result['rewrite']['ai_last_run_id'],
                'meta_patch' => $result['rewrite']['meta_patch'] ?? [],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to rewrite AI block.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Helper: التحقق من ملكية الدرس للمعلم.
     */
    private function resolveOwnedLesson(int $lessonId, int $teacherId): ?Lesson
    {
        return Lesson::on('app_mysql')
            ->where('id', $lessonId)
            ->where('teacher_id', $teacherId)
            ->first();
    }

    private function resolveInstructionText(string $instructionKey): ?string
    {
        $instructions = config('lesson_ai.instructions', []);
        $instruction = $instructions[$instructionKey] ?? null;

        return is_string($instruction) && trim($instruction) !== ''
            ? trim($instruction)
            : null;
    }

    private function transformSource(LessonAiSource $source): array
    {
        $fileUrl = null;

        if (is_string($source->source_file_path) && trim($source->source_file_path) !== '') {
            $fileUrl = asset('storage/' . ltrim($source->source_file_path, '/'));
        }

        return [
            'id' => $source->id,
            'lesson_id' => $source->lesson_id,
            'teacher_id' => $source->teacher_id,
            'source_type' => $source->source_type,
            'source_file_name' => $source->source_file_name,
            'source_file_path' => $source->source_file_path,
            'source_file_url' => $fileUrl,
            'source_text' => $source->source_text,
            'extracted_text' => $source->extracted_text,
            'is_active' => (bool) $source->is_active,
            'created_at' => $source->created_at,
            'updated_at' => $source->updated_at,
        ];
    }
}
