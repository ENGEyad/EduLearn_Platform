<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LessonExerciseDraftOption extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'lesson_exercise_draft_options';

    protected $fillable = [
        'draft_item_id',
        'stable_option_key',
        'option_text',
        'is_correct',
        'position',
        'is_deleted',
        'deleted_at',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
        'is_deleted' => 'boolean',
        'deleted_at' => 'datetime',
    ];

    public function draftItem()
    {
        return $this->belongsTo(LessonExerciseDraftItem::class, 'draft_item_id');
    }
}