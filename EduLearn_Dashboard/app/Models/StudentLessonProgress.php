<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentLessonProgress extends Model
{
    protected $connection = 'app_mysql';

    protected $table = 'student_lesson_progress';

    protected $fillable = [
        'lesson_id',
        'student_id',
        'status',
        'last_opened_at',
        'completed_at',
    ];

    protected $casts = [
        'last_opened_at' => 'datetime',
        'completed_at'   => 'datetime',
    ];

    public function lesson()
    {
        return $this->belongsTo(Lesson::class);
    }
}
