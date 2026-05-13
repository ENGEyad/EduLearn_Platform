<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LearningActivity extends Model
{
    protected $connection = 'app_mysql';

    protected $table = 'learning_activities';

    protected $fillable = [
        'actor_type',
        'actor_id',
        'actor_code',
        'actor_name',
        'target_type',
        'target_id',
        'target_code',
        'class_section_id',
        'subject_id',
        'lesson_id',
        'exercise_set_id',
        'exercise_attempt_id',
        'event_type',
        'title',
        'body',
        'meta',
        'read_at',
    ];

    protected $casts = [
        'actor_id' => 'integer',
        'target_id' => 'integer',
        'class_section_id' => 'integer',
        'subject_id' => 'integer',
        'lesson_id' => 'integer',
        'exercise_set_id' => 'integer',
        'exercise_attempt_id' => 'integer',
        'meta' => 'array',
        'read_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public const ACTOR_STUDENT = 'student';
    public const ACTOR_TEACHER = 'teacher';
    public const ACTOR_SYSTEM = 'system';

    public const TARGET_STUDENT = 'student';
    public const TARGET_TEACHER = 'teacher';
    public const TARGET_CLASS_SECTION = 'class_section';

    public const EVENT_TEACHER_PUBLISHED_LESSON = 'teacher_published_lesson';
    public const EVENT_TEACHER_UPDATED_LESSON = 'teacher_updated_lesson';
    public const EVENT_TEACHER_PUBLISHED_EXERCISE = 'teacher_published_exercise';
    public const EVENT_TEACHER_UPDATED_EXERCISE = 'teacher_updated_exercise';
    public const EVENT_STUDENT_COMPLETED_LESSON = 'student_completed_lesson';
    public const EVENT_STUDENT_SUBMITTED_EXERCISE = 'student_submitted_exercise';
    public const EVENT_STUDENT_GRADED_EXERCISE = 'student_graded_exercise';

    /**
     * نطاق جلب الأنشطة المستهدفة لطالب معين (باستخدام ID أو academic_id)
     */
    public function scopeForStudent($query, int $studentId, ?string $academicId = null)
    {
        return $query->where('target_type', self::TARGET_STUDENT)
            ->where(function ($q) use ($studentId, $academicId) {
                $q->where('target_id', $studentId);

                if ($academicId !== null && trim($academicId) !== '') {
                    $q->orWhere('target_code', trim($academicId));
                }
            });
    }

    /**
     * نطاق جلب الأنشطة المستهدفة لمعلم معين (باستخدام teacher_code أو teacher_id)
     */
    public function scopeForTeacher($query, string $teacherCode, ?int $teacherId = null)
    {
        return $query->where('target_type', self::TARGET_TEACHER)
            ->where(function ($q) use ($teacherCode, $teacherId) {
                $teacherCode = trim($teacherCode);

                if ($teacherCode !== '') {
                    $q->where('target_code', $teacherCode);
                }

                if ($teacherId !== null) {
                    $q->orWhere('target_id', $teacherId);
                }
            });
    }

    /**
     * نطاق جلب الأنشطة المستهدفة لمعلم باستخدام ID فقط (للاستخدام مع التوكن)
     */
    public function scopeForTeacherById($query, int $teacherId)
    {
        return $query->where('target_type', self::TARGET_TEACHER)
            ->where('target_id', $teacherId);
    }
}
