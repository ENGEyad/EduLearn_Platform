<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonTopic extends Model
{
    protected $connection = 'app_mysql';

    protected $fillable = [
        'lesson_id',
        'module_id',
        'title',
        'position',
    ];

    public function lesson()
    {
        return $this->belongsTo(Lesson::class);
    }

    public function module()
    {
        return $this->belongsTo(LessonModule::class, 'module_id');
    }

    // ❌ لا يوجد subtopics() هنا بعد إلغاء الفكرة
}
