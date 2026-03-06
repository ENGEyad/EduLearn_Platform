<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonModule extends Model
{
    protected $connection = 'app_mysql';

    protected $fillable = [
        'lesson_id',
        'title',
        'position',
    ];

    public function lesson()
    {
        return $this->belongsTo(Lesson::class);
    }

    public function topics()
    {
        return $this->hasMany(LessonTopic::class, 'module_id')->orderBy('position');
    }
}
