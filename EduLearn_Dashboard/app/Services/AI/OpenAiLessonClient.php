<?php

namespace App\Services\AI;

use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class OpenAiLessonClient
{
    protected string $apiKey;
    protected string $baseUrl;
    protected string $model;
    protected int $timeout;

    public function __construct()
    {
        $this->apiKey = (string) config('services.gemini.api_key', env('GEMINI_API_KEY', ''));
        $this->baseUrl = rtrim((string) config('services.gemini.base_url', env('GEMINI_API_BASE', 'https://generativelanguage.googleapis.com/v1beta')), '/');
        $this->model = (string) config('lesson_ai.model', env('GEMINI_LESSON_MODEL', 'gemini-3.1-flash-lite'));
        $this->timeout = (int) env('GEMINI_TIMEOUT', 90);
    }

    /**
     * Generate structured text blocks from the provided source text.
     *
     * @return array<int, array<string, mixed>>
     */
    public function generateTextBlocks(string $sourceText, string $instructionText): array
    {
        $schema = [
            'type' => 'object',
            'properties' => [
                'blocks' => [
                    'type' => 'array',
                    'items' => [
                        'type' => 'object',
                        'properties' => [
                            'body' => ['type' => 'string'],
                            'font_size' => ['type' => 'number'],
                            'is_bold' => ['type' => 'boolean'],
                            'is_italic' => ['type' => 'boolean'],
                        ],
                        'required' => ['body', 'font_size', 'is_bold', 'is_italic'],
                    ],
                ],
            ],
            'required' => ['blocks'],
        ];

        $payload = [
            'systemInstruction' => [
                'parts' => [
                    [
                        'text' => $this->generationSystemPrompt(),
                    ],
                ],
            ],
            'contents' => [
                [
                    'role' => 'user',
                    'parts' => [
                        [
                            'text' => "Instruction:\n{$instructionText}\n\nSource Text:\n{$sourceText}",
                        ],
                    ],
                ],
            ],
            'generationConfig' => [
                'responseMimeType' => 'application/json',
                'responseJsonSchema' => $schema,
                'temperature' => 0.2,
            ],
        ];

        $data = $this->postGenerateContent($payload);
        $json = $this->extractGeneratedText($data);
        $decoded = json_decode($json, true);

        if (!is_array($decoded) || !isset($decoded['blocks']) || !is_array($decoded['blocks'])) {
            throw new RuntimeException('Gemini returned an invalid blocks payload.');
        }

        return array_values(array_map(function (array $block): array {
            return [
                'body' => trim((string) ($block['body'] ?? '')),
                'font_size' => isset($block['font_size']) ? (float) $block['font_size'] : 18.0,
                'is_bold' => (bool) ($block['is_bold'] ?? false),
                'is_italic' => (bool) ($block['is_italic'] ?? false),
            ];
        }, $decoded['blocks']));
    }

    /**
     * Rewrite a single text block according to a guided instruction.
     */
    public function rewriteTextBlock(string $currentBody, string $instructionText, ?string $sourceText = null): string
    {
        $schema = [
            'type' => 'object',
            'properties' => [
                'body' => ['type' => 'string'],
            ],
            'required' => ['body'],
        ];

        $sourcePart = $sourceText && trim($sourceText) !== ''
            ? "\n\nLesson Source Reference:\n{$sourceText}"
            : '';

        $payload = [
            'systemInstruction' => [
                'parts' => [
                    [
                        'text' => $this->rewriteSystemPrompt(),
                    ],
                ],
            ],
            'contents' => [
                [
                    'role' => 'user',
                    'parts' => [
                        [
                            'text' => "Instruction:\n{$instructionText}\n\nCurrent Block Body:\n{$currentBody}{$sourcePart}",
                        ],
                    ],
                ],
            ],
            'generationConfig' => [
                'responseMimeType' => 'application/json',
                'responseJsonSchema' => $schema,
                'temperature' => 0.2,
            ],
        ];

        $data = $this->postGenerateContent($payload);
        $json = $this->extractGeneratedText($data);
        $decoded = json_decode($json, true);

        if (!is_array($decoded) || !isset($decoded['body'])) {
            throw new RuntimeException('Gemini returned an invalid rewrite payload.');
        }

        return trim((string) $decoded['body']);
    }

    /**
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    protected function postGenerateContent(array $payload): array
    {
        if ($this->apiKey === '') {
            throw new RuntimeException('GEMINI_API_KEY is not configured.');
        }

        $url = $this->baseUrl . '/models/' . $this->model . ':generateContent';

        $response = Http::timeout($this->timeout)
            ->acceptJson()
            ->withHeaders([
                'x-goog-api-key' => $this->apiKey,
                'Content-Type' => 'application/json',
            ])
            ->post($url, $payload);

        if ($response->failed()) {
            throw new RuntimeException(
                'Gemini request failed: ' . $response->status() . ' ' . $response->body()
            );
        }

        $data = $response->json();
        if (!is_array($data)) {
            throw new RuntimeException('Invalid Gemini response format.');
        }

        return $data;
    }

    /**
     * Extract generated text from Gemini generateContent response.
     *
     * @param array<string, mixed> $data
     */
    protected function extractGeneratedText(array $data): string
    {
        $text = Arr::get($data, 'candidates.0.content.parts.0.text');

        if (is_string($text) && trim($text) !== '') {
            return $text;
        }

        throw new RuntimeException('Could not extract generated text from Gemini response.');
    }

    protected function generationSystemPrompt(): string
    {
        return implode("\n", [
            'You are an educational lesson-block generator.',
            'Return only structured JSON that matches the supplied schema.',
            'Use only the supplied source text.',
            'Do not invent facts or add information from outside the source.',
            'Do not add headings, titles, bullet lists, numbering, or labels.',
            'Each generated block must be ready to be stored directly as the body of a single text block.',
            'Split content into clear logical educational paragraphs.',
            'Do not decide a fixed number of blocks in advance; split by natural educational structure only.',
            'Keep the language clear and suitable for students.',
            'Default formatting should be font_size 18, is_bold false, is_italic false unless the source strongly requires emphasis.',
        ]);
    }

    protected function rewriteSystemPrompt(): string
    {
        return implode("\n", [
            'You are an educational text rewriting assistant for a single lesson block.',
            'Return only structured JSON that matches the supplied schema.',
            'Rewrite only the current block body according to the instruction.',
            'Do not add headings, numbering, titles, or labels.',
            'Do not create multiple blocks.',
            'Do not add unsupported facts.',
            'Keep the result suitable for direct replacement of the current block body.',
        ]);
    }
}