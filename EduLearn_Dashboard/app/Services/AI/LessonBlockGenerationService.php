<?php

namespace App\Services\AI;

use App\Models\LessonAiRun;
use App\Models\LessonAiSource;
use Illuminate\Support\Str;

class LessonBlockGenerationService
{
    public function __construct(
        protected OpenAiLessonClient $openAiClient,
    ) {
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public function generateBlocks(LessonAiSource $source, LessonAiRun $run, string $instructionKey, string $instructionText): array
    {
        $generated = $this->openAiClient->generateTextBlocks(
            $source->extracted_text,
            $instructionText
        );

        $blocks = [];
        foreach ($generated as $block) {
            $body = trim((string) ($block['body'] ?? ''));
            if ($body === '') {
                continue;
            }

            $blocks[] = [
                'stable_key' => (string) Str::uuid(),
                'type' => 'text',
                'body' => $body,
                'caption' => null,
                'media_path' => null,
                'media_mime' => null,
                'media_size' => null,
                'media_duration' => null,
                'created_origin' => 'ai',
                'last_edit_origin' => 'ai',
                'ai_source_id' => $source->id,
                'ai_last_run_id' => $run->id,
                'meta' => [
                    'font_size' => isset($block['font_size']) ? (float) $block['font_size'] : 18,
                    'is_bold' => (bool) ($block['is_bold'] ?? false),
                    'is_italic' => (bool) ($block['is_italic'] ?? false),
                    'ai_instruction_key' => $instructionKey,
                ],
            ];
        }

        return $blocks;
    }
}
