<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudentExerciseAttempt extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'student_exercise_attempts';

    protected $fillable = [
        'exercise_set_id',
        'exercise_version_id',
        'lesson_id',
        'student_id',
        'status',
        'score',
        'total_points',
        'correct_count',
        'wrong_count',
        'submitted_at',
        'graded_at',
        'last_synced_version_id',
        'has_pending_changes',
    ];

    protected $casts = [
        'score' => 'decimal:2',
        'total_points' => 'decimal:2',
        'correct_count' => 'integer',
        'wrong_count' => 'integer',
        'submitted_at' => 'datetime',
        'graded_at' => 'datetime',
        'has_pending_changes' => 'boolean',
    ];

    public function exerciseSet()
    {
        return $this->belongsTo(LessonExerciseSet::class, 'exercise_set_id');
    }

    public function version()
    {
        return $this->belongsTo(LessonExerciseVersion::class, 'exercise_version_id');
    }

    public function syncedVersion()
    {
        return $this->belongsTo(LessonExerciseVersion::class, 'last_synced_version_id');
    }

    public function answers()
    {
        return $this->hasMany(StudentExerciseAnswer::class, 'attempt_id');
    }

    public function lesson()
    {
        return $this->belongsTo(Lesson::class, 'lesson_id');
    }
}