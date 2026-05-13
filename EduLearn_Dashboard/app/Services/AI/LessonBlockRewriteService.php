<?php

namespace App\Services\AI;

use App\Models\LessonAiRun;
use App\Models\LessonAiSource;

class LessonBlockRewriteService
{
    public function __construct(
        protected OpenAiLessonClient $openAiClient,
    ) {
    }

    public function rewriteBlock(
        string $currentBody,
        LessonAiRun $run,
        string $instructionKey,
        string $instructionText,
        ?LessonAiSource $source = null
    ): array {
        $rewritten = $this->openAiClient->rewriteTextBlock(
            $currentBody,
            $instructionText,
            $source?->extracted_text
        );

        return [
            'body' => $rewritten,
            'last_edit_origin' => 'ai',
            'ai_source_id' => $source?->id,
            'ai_last_run_id' => $run->id,
            'meta_patch' => [
                'ai_instruction_key' => $instructionKey,
            ],
        ];
    }
}
