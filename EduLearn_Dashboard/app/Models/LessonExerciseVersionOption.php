<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LessonExerciseVersionOption extends Model
{
    use HasFactory;

    protected $connection = 'app_mysql';

    protected $table = 'lesson_exercise_version_options';

    protected $fillable = [
        'version_item_id',
        'stable_option_key',
        'option_text',
        'is_correct',
        'position',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
    ];

    public function versionItem()
    {
        return $this->belongsTo(LessonExerciseVersionItem::class, 'version_item_id');
    }
}