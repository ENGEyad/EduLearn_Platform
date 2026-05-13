<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LessonExerciseVersionItem extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'lesson_exercise_version_items';

    protected $fillable = [
        'version_id',
        'stable_question_key',
        'origin',
        'type',
        'question_text',
        'correct_text_answer',
        'explanation',
        'points',
        'position',
        'is_active',
        'change_status_from_previous',
        'meta',
    ];

    protected $casts = [
        'points' => 'decimal:2',
        'is_active' => 'boolean',
        'meta' => 'array',
    ];

    public function version()
    {
        return $this->belongsTo(LessonExerciseVersion::class, 'version_id');
    }

    public function options()
    {
        return $this->hasMany(LessonExerciseVersionOption::class, 'version_item_id')
            ->orderBy('position');
    }

    public function answers()
    {
        return $this->hasMany(StudentExerciseAnswer::class, 'version_item_id');
    }
}