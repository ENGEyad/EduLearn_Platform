<?php

return [
    'model' => env('GEMINI_LESSON_MODEL', 'gemini-2.5-pro'),

    'instructions' => [
        'structured_explanation' => 'Create clear, well-structured educational explanation blocks from the provided source.',
        'simplify_for_students' => 'Create student-friendly explanation blocks using simpler language while staying faithful to the source.',
        'short_explanation' => 'Create concise educational explanation blocks from the source without losing the essential meaning.',
        'clarify_and_organize' => 'Reorganize the source into clearer educational blocks with stronger logical flow.',
        'focus_key_points' => 'Generate explanation blocks that focus only on the key points and core ideas from the source.',
        'focus_definitions' => 'Generate explanation blocks that emphasize definitions and concept meanings from the source.',
        'focus_steps' => 'Generate explanation blocks that emphasize ordered steps and procedural explanation from the source.',
        'add_examples' => 'Generate explanation blocks that include source-grounded educational examples when supported by the source text.',
        'rewrite' => 'Rewrite the current block with better educational phrasing while preserving the meaning.',
        'simplify' => 'Rewrite the current block using easier language for students while preserving the meaning.',
        'shorten' => 'Rewrite the current block in a shorter form while preserving the essential meaning.',
        'expand' => 'Rewrite the current block with more explanation and detail, without adding unsupported facts.',
        'clarify' => 'Rewrite the current block to make it clearer and easier to understand without changing the meaning.',
    ],
];
