<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonExerciseOption extends Model
{
    protected $connection = 'app_mysql';
    protected $guarded = ['id'];

    protected $casts = [
        'is_correct' => 'boolean',
    ];

    public function question()
    {
        return $this->belongsTo(LessonExerciseQuestion::class, 'question_id');
    }
}
