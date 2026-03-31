<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LessonExerciseVersion extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'lesson_exercise_versions';

    protected $fillable = [
        'exercise_set_id',
        'version_no',
        'previous_version_id',
        'published_by_teacher_id',
        'published_at',
        'content_hash',
        'is_active',
        'change_summary_json',
        'meta',
    ];

    protected $casts = [
        'published_at' => 'datetime',
        'is_active' => 'boolean',
        'change_summary_json' => 'array',
        'meta' => 'array',
    ];

    public function exerciseSet()
    {
        return $this->belongsTo(LessonExerciseSet::class, 'exercise_set_id');
    }

    public function previousVersion()
    {
        return $this->belongsTo(LessonExerciseVersion::class, 'previous_version_id');
    }

    public function nextVersions()
    {
        return $this->hasMany(LessonExerciseVersion::class, 'previous_version_id');
    }

    public function items()
    {
        return $this->hasMany(LessonExerciseVersionItem::class, 'version_id')
            ->orderBy('position');
    }

    public function activeItems()
    {
        return $this->hasMany(LessonExerciseVersionItem::class, 'version_id')
            ->where('is_active', true)
            ->orderBy('position');
    }

    public function attempts()
    {
        return $this->hasMany(StudentExerciseAttempt::class, 'exercise_version_id');
    }
}