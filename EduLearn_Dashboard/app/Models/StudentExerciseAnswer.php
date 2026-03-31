<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudentExerciseAnswer extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'student_exercise_answers';

    protected $fillable = [
        'attempt_id',
        'version_item_id',
        'stable_question_key',
        'selected_option_id',
        'answer_text',
        'is_correct',
        'awarded_points',
        'checked_at',
        'feedback_snapshot',
        'answer_state',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
        'awarded_points' => 'decimal:2',
        'checked_at' => 'datetime',
        'feedback_snapshot' => 'array',
    ];

    public function attempt()
    {
        return $this->belongsTo(StudentExerciseAttempt::class, 'attempt_id');
    }

    public function versionItem()
    {
        return $this->belongsTo(LessonExerciseVersionItem::class, 'version_item_id');
    }

    public function selectedOption()
    {
        return $this->belongsTo(LessonExerciseVersionOption::class, 'selected_option_id');
    }
}