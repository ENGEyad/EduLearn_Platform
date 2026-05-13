<?php

namespace App\Services\AI;

use App\Models\Lesson;
use App\Models\LessonAiRun;
use App\Models\LessonAiSource;
use App\Models\Teacher;
use Illuminate\Http\UploadedFile;
use RuntimeException;

class AiOrchestratorService
{
    public function __construct(
        protected LessonAiSourceService $sourceService,
        protected LessonBlockGenerationService $generationService,
        protected LessonBlockRewriteService $rewriteService,
    ) {
    }

    /**
     * @return array{source: LessonAiSource, run: LessonAiRun, blocks: array<int, array<string, mixed>>}
     */
    public function generateBlocks(
        Lesson $lesson,
        Teacher $teacher,
        string $instructionKey,
        string $instructionText,
        ?string $sourceText = null,
        ?UploadedFile $pdfFile = null,
        bool $replaceSource = false
    ): array {
        $source = $this->sourceService->getActiveSourceForLesson($lesson);

        if ($replaceSource || !$source) {
            $source = $this->sourceService->createOrReplaceActiveSource(
                $lesson,
                $teacher,
                $sourceText,
                $pdfFile
            );
        }

        if (!$source) {
            throw new RuntimeException('No AI source is available for this lesson.');
        }

        $run = $this->createRun(
            lesson: $lesson,
            teacher: $teacher,
            source: $source,
            actionType: 'generate_append_blocks',
            instructionKey: $instructionKey,
            instructionText: $instructionText,
            targetStableKey: null,
            inputSnapshot: [
                'instruction_key' => $instructionKey,
                'source_id' => $source->id,
                'source_type' => $source->source_type,
                'source_reused' => !$replaceSource && !$pdfFile && trim((string) $sourceText) === '',
            ],
        );

        try {
            $blocks = $this->generationService->generateBlocks($source, $run, $instructionKey, $instructionText);

            $run->status = 'completed';
            $run->output_snapshot = ['blocks' => $blocks];
            $run->save();

            return [
                'source' => $source,
                'run' => $run,
                'blocks' => $blocks,
            ];
        } catch (\Throwable $e) {
            $run->status = 'failed';
            $run->error_message = $e->getMessage();
            $run->save();
            throw $e;
        }
    }

    /**
     * @return array{run: LessonAiRun, rewrite: array<string, mixed>}
     */
    public function rewriteBlock(
        Lesson $lesson,
        Teacher $teacher,
        string $stableKey,
        string $currentBody,
        string $instructionKey,
        string $instructionText
    ): array {
        $source = $this->sourceService->getActiveSourceForLesson($lesson);

        $run = $this->createRun(
            lesson: $lesson,
            teacher: $teacher,
            source: $source,
            actionType: $this->mapRewriteActionType($instructionKey),
            instructionKey: $instructionKey,
            instructionText: $instructionText,
            targetStableKey: $stableKey,
            inputSnapshot: [
                'stable_key' => $stableKey,
                'current_body' => $currentBody,
                'instruction_key' => $instructionKey,
                'source_id' => $source?->id,
            ],
        );

        try {
            $rewrite = $this->rewriteService->rewriteBlock(
                currentBody: $currentBody,
                run: $run,
                instructionKey: $instructionKey,
                instructionText: $instructionText,
                source: $source,
            );

            $run->status = 'completed';
            $run->output_snapshot = $rewrite;
            $run->save();

            return [
                'run' => $run,
                'rewrite' => $rewrite,
            ];
        } catch (\Throwable $e) {
            $run->status = 'failed';
            $run->error_message = $e->getMessage();
            $run->save();
            throw $e;
        }
    }

    protected function createRun(
        Lesson $lesson,
        Teacher $teacher,
        ?LessonAiSource $source,
        string $actionType,
        ?string $instructionKey,
        ?string $instructionText,
        ?string $targetStableKey,
        ?array $inputSnapshot
    ): LessonAiRun {
        $run = new LessonAiRun();
        $run->setConnection('app_mysql');
        $run->lesson_id = $lesson->id;
        $run->teacher_id = $teacher->id;
        $run->ai_source_id = $source?->id;
        $run->action_type = $actionType;
        $run->target_stable_key = $targetStableKey;
        $run->instruction_key = $instructionKey;
        $run->instruction_text = $instructionText;
        $run->status = 'processing';
        $run->input_snapshot = $inputSnapshot;
        $run->output_snapshot = null;
        $run->error_message = null;
        $run->save();

        return $run;
    }

    protected function mapRewriteActionType(string $instructionKey): string
    {
        return match ($instructionKey) {
            'simplify' => 'simplify_block',
            'shorten' => 'shorten_block',
            'expand' => 'expand_block',
            'clarify' => 'clarify_block',
            default => 'rewrite_block',
        };
    }
}
