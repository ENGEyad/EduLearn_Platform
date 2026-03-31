<?php

namespace App\Services;

use App\Models\LessonExerciseDraftItem;
use App\Models\LessonExerciseSet;
use App\Models\LessonExerciseVersion;
use App\Models\LessonExerciseVersionItem;
use App\Models\LessonExerciseVersionOption;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class LessonExercisePublishService
{
    public function __construct(
        protected LessonExerciseDiffService $diffService
    ) {
    }

    protected string $connection = 'app_mysql';

    public function publish(LessonExerciseSet $set, int $teacherId): LessonExerciseVersion
    {
        return DB::connection($this->connection)->transaction(function () use ($set, $teacherId) {
            $set->load([
                'draftItems.options' => function ($query) {
                    $query->where('is_deleted', false)->orderBy('position');
                },
                'activeVersion.items.options',
            ]);

            $previousVersion = $set->activeVersion;

            $draftItems = $set->draftItems()
                ->with(['options' => function ($query) {
                    $query->where('is_deleted', false)->orderBy('position');
                }])
                ->orderBy('position')
                ->get();

            $this->validateDraftBeforePublish($draftItems);

            $diffMap = $this->diffService->buildDiff($previousVersion, $draftItems);

            LessonExerciseVersion::query()
                ->where('exercise_set_id', $set->id)
                ->where('is_active', true)
                ->update(['is_active' => false]);

            $nextVersionNo = ((int) LessonExerciseVersion::query()
                ->where('exercise_set_id', $set->id)
                ->max('version_no')) + 1;

            $newVersion = LessonExerciseVersion::query()->create([
                'exercise_set_id' => $set->id,
                'version_no' => $nextVersionNo,
                'previous_version_id' => $previousVersion?->id,
                'published_by_teacher_id' => $teacherId,
                'published_at' => now(),
                'content_hash' => $this->makeContentHash($draftItems),
                'is_active' => true,
                'change_summary_json' => $this->buildChangeSummary($diffMap),
                'meta' => null,
            ]);

            foreach ($draftItems as $draftItem) {
                /** @var LessonExerciseDraftItem $draftItem */
                $changeStatus = $diffMap[$draftItem->stable_question_key] ?? 'unchanged';

                $versionItem = LessonExerciseVersionItem::query()->create([
                    'version_id' => $newVersion->id,
                    'stable_question_key' => $draftItem->stable_question_key,
                    'origin' => $draftItem->origin,
                    'type' => $draftItem->type,
                    'question_text' => $draftItem->question_text,
                    'correct_text_answer' => $draftItem->correct_text_answer,
                    'explanation' => $draftItem->explanation,
                    'points' => $draftItem->points,
                    'position' => $draftItem->position,
                    'is_active' => !$draftItem->is_deleted && !$draftItem->is_archived,
                    'change_status_from_previous' => $changeStatus,
                    'meta' => $draftItem->meta,
                ]);

                foreach ($draftItem->options as $draftOption) {
                    LessonExerciseVersionOption::query()->create([
                        'version_item_id' => $versionItem->id,
                        'stable_option_key' => $draftOption->stable_option_key,
                        'option_text' => $draftOption->option_text,
                        'is_correct' => $draftOption->is_correct,
                        'position' => $draftOption->position,
                    ]);
                }
            }

            $set->current_published_version_id = $newVersion->id;
            $set->published_at = now();
            $set->archived_at = null;
            $set->needs_review = false;
            $set->status = 'published';
            $set->save();

            return $newVersion->fresh(['items.options', 'exerciseSet']);
        });
    }

    protected function validateDraftBeforePublish($draftItems): void
    {
        if ($draftItems->isEmpty()) {
            throw new InvalidArgumentException('Cannot publish an empty exercise draft.');
        }

        $activePublishableItems = $draftItems->filter(function ($item) {
            return !$item->is_deleted && !$item->is_archived;
        });

        if ($activePublishableItems->isEmpty()) {
            throw new InvalidArgumentException('Cannot publish because all questions are deleted or archived.');
        }

        foreach ($draftItems as $draftItem) {
            /** @var LessonExerciseDraftItem $draftItem */
            if ($draftItem->is_deleted || $draftItem->is_archived) {
                continue;
            }

            if (trim((string) $draftItem->question_text) === '') {
                throw new InvalidArgumentException("Question text is required for question {$draftItem->stable_question_key}.");
            }

            if ((float) $draftItem->points < 0) {
                throw new InvalidArgumentException("Points cannot be negative for question {$draftItem->stable_question_key}.");
            }

            $options = $draftItem->options->where('is_deleted', false)->sortBy('position')->values();

            if ($draftItem->type === 'short_answer') {
                if (trim((string) $draftItem->correct_text_answer) === '') {
                    throw new InvalidArgumentException("Short answer question {$draftItem->stable_question_key} must have a correct text answer.");
                }
            }

            if (in_array($draftItem->type, ['multiple_choice', 'true_false'], true)) {
                if ($options->count() < 2) {
                    throw new InvalidArgumentException("Question {$draftItem->stable_question_key} must have at least two options.");
                }

                $correctCount = $options->where('is_correct', true)->count();

                if ($correctCount !== 1) {
                    throw new InvalidArgumentException("Question {$draftItem->stable_question_key} must have exactly one correct option.");
                }

                foreach ($options as $option) {
                    if (trim((string) $option->option_text) === '') {
                        throw new InvalidArgumentException("Question {$draftItem->stable_question_key} has an empty option text.");
                    }
                }

                if ($draftItem->type === 'true_false' && $options->count() !== 2) {
                    throw new InvalidArgumentException("True/False question {$draftItem->stable_question_key} must have exactly two options.");
                }
            }
        }
    }

    protected function makeContentHash($draftItems): string
    {
        $payload = $draftItems->map(function ($item) {
            return [
                'stable_question_key' => $item->stable_question_key,
                'type' => $item->type,
                'question_text' => $item->question_text,
                'correct_text_answer' => $item->correct_text_answer,
                'explanation' => $item->explanation,
                'points' => $item->points,
                'position' => $item->position,
                'is_deleted' => $item->is_deleted,
                'is_archived' => $item->is_archived,
                'options' => $item->options->map(function ($option) {
                    return [
                        'stable_option_key' => $option->stable_option_key,
                        'option_text' => $option->option_text,
                        'is_correct' => $option->is_correct,
                        'position' => $option->position,
                    ];
                })->values()->toArray(),
            ];
        })->values()->toArray();

        return sha1(json_encode($payload, JSON_UNESCAPED_UNICODE));
    }

    protected function buildChangeSummary(array $diffMap): array
    {
        $counts = [
            'new' => 0,
            'updated' => 0,
            'deleted' => 0,
            'restored' => 0,
            'unchanged' => 0,
        ];

        foreach ($diffMap as $status) {
            if (array_key_exists($status, $counts)) {
                $counts[$status]++;
            }
        }

        return $counts;
    }
}