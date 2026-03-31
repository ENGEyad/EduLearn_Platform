<?php

namespace App\Services;

use App\Models\Lesson;
use App\Models\LessonExerciseDraftItem;
use App\Models\LessonExerciseDraftOption;
use App\Models\LessonExerciseSet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class LessonExerciseDraftService
{
    protected string $connection = 'app_mysql';

    public function getOrCreateSet(Lesson $lesson, int $teacherId): LessonExerciseSet
    {
        return LessonExerciseSet::query()->firstOrCreate(
            ['lesson_id' => $lesson->id],
            [
                'teacher_id' => $teacherId,
                'title' => $lesson->title ? ('تمارين: ' . $lesson->title) : 'تمارين الدرس',
                'status' => 'draft',
                'generation_source' => 'manual',
                'current_draft_no' => 1,
                'needs_review' => false,
            ]
        );
    }

    public function getDraftForLesson(Lesson $lesson, int $teacherId): LessonExerciseSet
    {
        $set = $this->getOrCreateSet($lesson, $teacherId);

        $set->load([
            'draftItems.options' => function ($query) {
                $query->orderBy('position');
            },
            'activeVersion',
        ]);

        return $set;
    }

    public function saveDraft(Lesson $lesson, int $teacherId, array $payload): LessonExerciseSet
    {
        return DB::connection($this->connection)->transaction(function () use ($lesson, $teacherId, $payload) {
            $set = $this->getOrCreateSet($lesson, $teacherId);

            if (isset($payload['title'])) {
                $set->title = $payload['title'] ?: $set->title;
            }

            if (!empty($payload['generation_source']) && in_array($payload['generation_source'], ['manual', 'ai', 'mixed'], true)) {
                $set->generation_source = $payload['generation_source'];
            }

            $incomingQuestions = collect($payload['questions'] ?? [])->values();

            $existingDraftItems = LessonExerciseDraftItem::query()
                ->where('exercise_set_id', $set->id)
                ->get()
                ->keyBy('stable_question_key');

            $seenQuestionKeys = [];

            foreach ($incomingQuestions as $index => $questionData) {
                $stableQuestionKey = $questionData['stable_question_key'] ?? (string) Str::uuid();
                $seenQuestionKeys[] = $stableQuestionKey;

                $draftItem = $existingDraftItems->get($stableQuestionKey);

                if (!$draftItem) {
                    $draftItem = new LessonExerciseDraftItem();
                    $draftItem->exercise_set_id = $set->id;
                    $draftItem->stable_question_key = $stableQuestionKey;
                    $draftItem->last_change_type = 'created';
                } else {
                    $draftItem->last_change_type = 'updated';
                }

                $type = $questionData['type'] ?? null;
                if (!in_array($type, ['true_false', 'multiple_choice', 'short_answer'], true)) {
                    throw new InvalidArgumentException("Invalid question type for question {$stableQuestionKey}");
                }

                $draftItem->origin = $questionData['origin'] ?? $draftItem->origin ?? 'manual';
                $draftItem->type = $type;
                $draftItem->question_text = trim((string) ($questionData['question_text'] ?? ''));
                $draftItem->correct_text_answer = $questionData['correct_text_answer'] ?? null;
                $draftItem->explanation = $questionData['explanation'] ?? null;
                $draftItem->points = $questionData['points'] ?? 1;
                $draftItem->position = $questionData['position'] ?? ($index + 1);
                $draftItem->is_active = array_key_exists('is_active', $questionData) ? (bool) $questionData['is_active'] : true;
                $draftItem->is_deleted = false;
                $draftItem->deleted_at = null;
                $draftItem->is_archived = array_key_exists('is_archived', $questionData) ? (bool) $questionData['is_archived'] : false;
                $draftItem->archived_at = $draftItem->is_archived ? now() : null;
                $draftItem->meta = $questionData['meta'] ?? null;

                $draftItem->save();

                $this->syncDraftOptions($draftItem, $questionData['options'] ?? []);
            }

            $itemsToSoftDelete = LessonExerciseDraftItem::query()
                ->where('exercise_set_id', $set->id)
                ->whereNotIn('stable_question_key', $seenQuestionKeys ?: ['__none__'])
                ->get();

            foreach ($itemsToSoftDelete as $item) {
                if (!$item->is_deleted) {
                    $item->is_deleted = true;
                    $item->deleted_at = now();
                    $item->last_change_type = 'deleted';
                    $item->save();
                }
            }

            $set->status = 'draft';
            $set->needs_review = false;
            $set->save();

            return $this->getDraftForLesson($lesson, $teacherId);
        });
    }

    protected function syncDraftOptions(LessonExerciseDraftItem $draftItem, array $options): void
    {
        $existingOptions = LessonExerciseDraftOption::query()
            ->where('draft_item_id', $draftItem->id)
            ->get()
            ->keyBy('stable_option_key');

        $seenOptionKeys = [];

        foreach (array_values($options) as $index => $optionData) {
            $stableOptionKey = $optionData['stable_option_key'] ?? (string) Str::uuid();
            $seenOptionKeys[] = $stableOptionKey;

            $option = $existingOptions->get($stableOptionKey);

            if (!$option) {
                $option = new LessonExerciseDraftOption();
                $option->draft_item_id = $draftItem->id;
                $option->stable_option_key = $stableOptionKey;
            }

            $option->option_text = trim((string) ($optionData['option_text'] ?? ''));
            $option->is_correct = (bool) ($optionData['is_correct'] ?? false);
            $option->position = $optionData['position'] ?? ($index + 1);
            $option->is_deleted = false;
            $option->deleted_at = null;

            $option->save();
        }

        $optionsToDelete = LessonExerciseDraftOption::query()
            ->where('draft_item_id', $draftItem->id)
            ->whereNotIn('stable_option_key', $seenOptionKeys ?: ['__none__'])
            ->get();

        foreach ($optionsToDelete as $option) {
            if (!$option->is_deleted) {
                $option->is_deleted = true;
                $option->deleted_at = now();
                $option->save();
            }
        }
    }

    public function softDeleteDraftQuestion(LessonExerciseSet $set, string $stableQuestionKey): ?LessonExerciseDraftItem
    {
        $item = LessonExerciseDraftItem::query()
            ->where('exercise_set_id', $set->id)
            ->where('stable_question_key', $stableQuestionKey)
            ->first();

        if (!$item) {
            return null;
        }

        $item->is_deleted = true;
        $item->deleted_at = now();
        $item->last_change_type = 'deleted';
        $item->save();

        $set->status = 'draft';
        $set->save();

        return $item;
    }

    public function restoreDraftQuestion(LessonExerciseSet $set, string $stableQuestionKey): ?LessonExerciseDraftItem
    {
        $item = LessonExerciseDraftItem::query()
            ->where('exercise_set_id', $set->id)
            ->where('stable_question_key', $stableQuestionKey)
            ->first();

        if (!$item) {
            return null;
        }

        $item->is_deleted = false;
        $item->deleted_at = null;
        $item->last_change_type = 'restored';
        $item->save();

        $set->status = 'draft';
        $set->save();

        return $item;
    }

    public function archiveDraftQuestion(LessonExerciseSet $set, string $stableQuestionKey): ?LessonExerciseDraftItem
    {
        $item = LessonExerciseDraftItem::query()
            ->where('exercise_set_id', $set->id)
            ->where('stable_question_key', $stableQuestionKey)
            ->first();

        if (!$item) {
            return null;
        }

        $item->is_archived = true;
        $item->archived_at = now();
        $item->last_change_type = 'archived';
        $item->save();

        $set->status = 'draft';
        $set->save();

        return $item;
    }

    public function unarchiveDraftQuestion(LessonExerciseSet $set, string $stableQuestionKey): ?LessonExerciseDraftItem
    {
        $item = LessonExerciseDraftItem::query()
            ->where('exercise_set_id', $set->id)
            ->where('stable_question_key', $stableQuestionKey)
            ->first();

        if (!$item) {
            return null;
        }

        $item->is_archived = false;
        $item->archived_at = null;
        $item->last_change_type = 'unarchived';
        $item->save();

        $set->status = 'draft';
        $set->save();

        return $item;
    }

    public function archiveSet(LessonExerciseSet $set): LessonExerciseSet
    {
        $set->status = 'archived';
        $set->archived_at = now();
        $set->save();

        return $set->fresh(['draftItems.options', 'activeVersion']);
    }

    public function unarchiveSet(LessonExerciseSet $set): LessonExerciseSet
    {
        $set->status = 'draft';
        $set->archived_at = null;
        $set->save();

        return $set->fresh(['draftItems.options', 'activeVersion']);
    }
}