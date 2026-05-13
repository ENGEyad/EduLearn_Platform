<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LessonExerciseDraftItem extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'lesson_exercise_draft_items';

    protected $fillable = [
        'exercise_set_id',
        'stable_question_key',
        'origin',
        'type',
        'question_text',
        'correct_text_answer',
        'explanation',
        'points',
        'position',
        'is_active',
        'is_deleted',
        'deleted_at',
        'is_archived',
        'archived_at',
        'last_change_type',
        'meta',
    ];

    protected $casts = [
        'points' => 'decimal:2',
        'is_active' => 'boolean',
        'is_deleted' => 'boolean',
        'is_archived' => 'boolean',
        'deleted_at' => 'datetime',
        'archived_at' => 'datetime',
        'meta' => 'array',
    ];

    public function exerciseSet()
    {
        return $this->belongsTo(LessonExerciseSet::class, 'exercise_set_id');
    }

    public function options()
    {
        return $this->hasMany(LessonExerciseDraftOption::class, 'draft_item_id')
            ->orderBy('position');
    }

    public function activeOptions()
    {
        return $this->hasMany(LessonExerciseDraftOption::class, 'draft_item_id')
            ->where('is_deleted', false)
            ->orderBy('position');
    }
}