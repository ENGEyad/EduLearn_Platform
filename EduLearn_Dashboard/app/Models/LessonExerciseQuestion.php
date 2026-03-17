<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonExerciseQuestion extends Model
{
    protected $connection = 'app_mysql';
    protected $guarded = ['id'];

    public function options()
    {
        return $this->hasMany(LessonExerciseOption::class, 'question_id')->orderBy('position');
    }

    public function exercise()
    {
        return $this->belongsTo(LessonExercise::class, 'exercise_id');
    }
}
