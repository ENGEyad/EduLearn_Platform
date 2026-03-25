<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonExercise extends Model
{
    protected $connection = 'app_mysql';
    protected $guarded = ['id'];

    public function questions()
    {
        return $this->hasMany(LessonExerciseQuestion::class, 'exercise_id')->orderBy('position');
    }

    public function lesson()
    {
        return $this->belongsTo(Lesson::class, 'lesson_id');
    }
}
