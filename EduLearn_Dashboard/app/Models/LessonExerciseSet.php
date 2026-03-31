<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LessonExerciseSet extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'lesson_exercise_sets';

    protected $fillable = [
        'lesson_id',
        'teacher_id',
        'title',
        'status',
        'generation_source',
        'current_draft_no',
        'current_published_version_id',
        'needs_review',
        'published_at',
        'archived_at',
        'meta',
    ];

    protected $casts = [
        'needs_review' => 'boolean',
        'published_at' => 'datetime',
        'archived_at' => 'datetime',
        'meta' => 'array',
    ];

    public function versions()
    {
        return $this->hasMany(LessonExerciseVersion::class, 'exercise_set_id');
    }

    public function activeVersion()
    {
        return $this->belongsTo(LessonExerciseVersion::class, 'current_published_version_id');
    }

    public function draftItems()
    {
        return $this->hasMany(LessonExerciseDraftItem::class, 'exercise_set_id')
            ->orderBy('position');
    }

    public function activeDraftItems()
    {
        return $this->hasMany(LessonExerciseDraftItem::class, 'exercise_set_id')
            ->where('is_deleted', false)
            ->where('is_archived', false)
            ->orderBy('position');
    }

    public function attempts()
    {
        return $this->hasMany(StudentExerciseAttempt::class, 'exercise_set_id');
    }

    public function lesson()
    {
        return $this->belongsTo(Lesson::class, 'lesson_id');
    }
}