<?php

namespace App\Services;

use App\Models\LessonExerciseDraftItem;
use App\Models\LessonExerciseVersion;
use Illuminate\Support\Collection;

class LessonExerciseDiffService
{
    public function buildDiff(?LessonExerciseVersion $previousVersion, Collection $draftItems): array
    {
        $draftItems = $draftItems->values();

        if (!$previousVersion) {
            return $this->buildFirstPublishDiff($draftItems);
        }

        $previousItems = $previousVersion->items()
            ->with('options')
            ->get()
            ->keyBy('stable_question_key');

        $diffMap = [];

        foreach ($draftItems as $draftItem) {
            /** @var LessonExerciseDraftItem $draftItem */
            $key = $draftItem->stable_question_key;
            $previousItem = $previousItems->get($key);

            if ($draftItem->is_deleted) {
                $diffMap[$key] = 'deleted';
                continue;
            }

            if (!$previousItem) {
                $diffMap[$key] = 'new';
                continue;
            }

            $wasDeletedPreviously = $previousItem->change_status_from_previous === 'deleted';

            if ($wasDeletedPreviously) {
                $diffMap[$key] = 'restored';
                continue;
            }

            $isChanged = $this->isQuestionChanged($previousItem->toArray(), $draftItem->toArray(), $previousItem->options->toArray(), $draftItem->options()->where('is_deleted', false)->orderBy('position')->get()->toArray());

            $diffMap[$key] = $isChanged ? 'updated' : 'unchanged';
        }

        foreach ($previousItems as $previousKey => $previousItem) {
            $existsInDraft = $draftItems->firstWhere('stable_question_key', $previousKey);

            if (!$existsInDraft) {
                $diffMap[$previousKey] = 'deleted';
            }
        }

        return $diffMap;
    }

    protected function buildFirstPublishDiff(Collection $draftItems): array
    {
        $diffMap = [];

        foreach ($draftItems as $draftItem) {
            $diffMap[$draftItem->stable_question_key] = $draftItem->is_deleted ? 'deleted' : 'new';
        }

        return $diffMap;
    }

    protected function isQuestionChanged(array $previousItem, array $draftItem, array $previousOptions, array $draftOptions): bool
    {
        $normalizeText = static fn ($value) => trim((string) ($value ?? ''));

        $sameCore =
            ($previousItem['type'] ?? null) === ($draftItem['type'] ?? null) &&
            $normalizeText($previousItem['question_text'] ?? null) === $normalizeText($draftItem['question_text'] ?? null) &&
            $normalizeText($previousItem['correct_text_answer'] ?? null) === $normalizeText($draftItem['correct_text_answer'] ?? null) &&
            $normalizeText($previousItem['explanation'] ?? null) === $normalizeText($draftItem['explanation'] ?? null) &&
            (float) ($previousItem['points'] ?? 0) === (float) ($draftItem['points'] ?? 0) &&
            (bool) ($previousItem['is_active'] ?? false) === (bool) ($draftItem['is_active'] ?? false);

        if (!$sameCore) {
            return true;
        }

        $normalizeOptions = function (array $items): array {
            return collect($items)
                ->map(function ($option) {
                    return [
                        'stable_option_key' => $option['stable_option_key'] ?? null,
                        'option_text' => trim((string) ($option['option_text'] ?? '')),
                        'is_correct' => (bool) ($option['is_correct'] ?? false),
                        'position' => (int) ($option['position'] ?? 0),
                    ];
                })
                ->sortBy('position')
                ->values()
                ->toArray();
        };

        return $normalizeOptions($previousOptions) !== $normalizeOptions($draftOptions);
    }
}