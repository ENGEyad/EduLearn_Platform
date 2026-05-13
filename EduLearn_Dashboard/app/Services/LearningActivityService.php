<?php

namespace App\Services;

use App\Models\LearningActivity;
use App\Models\Student;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Arr;

class LearningActivityService
{
    public function record(array $payload): LearningActivity
    {
        $data = [
            'actor_type'          => $this->safeString($payload['actor_type'] ?? LearningActivity::ACTOR_SYSTEM, LearningActivity::ACTOR_SYSTEM),
            'actor_id'            => $this->nullableInt($payload['actor_id'] ?? null),
            'actor_code'          => $this->nullableString($payload['actor_code'] ?? null),
            'actor_name'          => $this->nullableString($payload['actor_name'] ?? null),
            'target_type'         => $this->safeString($payload['target_type'] ?? '', ''),
            'target_id'           => $this->nullableInt($payload['target_id'] ?? null),
            'target_code'         => $this->nullableString($payload['target_code'] ?? null),
            'class_section_id'    => $this->nullableInt($payload['class_section_id'] ?? null),
            'subject_id'          => $this->nullableInt($payload['subject_id'] ?? null),
            'lesson_id'           => $this->nullableInt($payload['lesson_id'] ?? null),
            'exercise_set_id'     => $this->nullableInt($payload['exercise_set_id'] ?? null),
            'exercise_attempt_id' => $this->nullableInt($payload['exercise_attempt_id'] ?? null),
            'event_type'          => $this->safeString($payload['event_type'] ?? '', ''),
            'title'               => $this->safeString($payload['title'] ?? '', 'Learning activity'),
            'body'                => $this->nullableString($payload['body'] ?? null),
            'meta'                => Arr::get($payload, 'meta', null),
        ];

        if ($data['target_type'] === '') {
            throw new \InvalidArgumentException('Activity target_type is required.');
        }
        if ($data['event_type'] === '') {
            throw new \InvalidArgumentException('Activity event_type is required.');
        }

        return LearningActivity::query()->create($data);
    }

    public function recordTeacherLessonActivityForStudent(array $payload): LearningActivity
    {
        return $this->record([
            'actor_type'       => LearningActivity::ACTOR_TEACHER,
            'actor_id'         => $payload['teacher_id'] ?? null,
            'actor_code'       => $payload['teacher_code'] ?? null,
            'actor_name'       => $payload['teacher_name'] ?? null,
            'target_type'      => LearningActivity::TARGET_STUDENT,
            'target_id'        => $payload['student_id'] ?? null,
            'target_code'      => $payload['academic_id'] ?? null,
            'class_section_id' => $payload['class_section_id'] ?? null,
            'subject_id'       => $payload['subject_id'] ?? null,
            'lesson_id'        => $payload['lesson_id'] ?? null,
            'event_type'       => $payload['event_type'] ?? LearningActivity::EVENT_TEACHER_PUBLISHED_LESSON,
            'title'            => $payload['title'] ?? 'New lesson available',
            'body'             => $payload['body'] ?? null,
            'meta'             => $payload['meta'] ?? null,
        ]);
    }

    public function recordTeacherExerciseActivityForStudent(array $payload): LearningActivity
    {
        return $this->record([
            'actor_type'       => LearningActivity::ACTOR_TEACHER,
            'actor_id'         => $payload['teacher_id'] ?? null,
            'actor_code'       => $payload['teacher_code'] ?? null,
            'actor_name'       => $payload['teacher_name'] ?? null,
            'target_type'      => LearningActivity::TARGET_STUDENT,
            'target_id'        => $payload['student_id'] ?? null,
            'target_code'      => $payload['academic_id'] ?? null,
            'class_section_id' => $payload['class_section_id'] ?? null,
            'subject_id'       => $payload['subject_id'] ?? null,
            'lesson_id'        => $payload['lesson_id'] ?? null,
            'exercise_set_id'  => $payload['exercise_set_id'] ?? null,
            'event_type'       => $payload['event_type'] ?? LearningActivity::EVENT_TEACHER_PUBLISHED_EXERCISE,
            'title'            => $payload['title'] ?? 'New exercises available',
            'body'             => $payload['body'] ?? null,
            'meta'             => $payload['meta'] ?? null,
        ]);
    }

    public function recordStudentLessonActivityForTeacher(array $payload): LearningActivity
    {
        return $this->record([
            'actor_type'       => LearningActivity::ACTOR_STUDENT,
            'actor_id'         => $payload['student_id'] ?? null,
            'actor_code'       => $payload['academic_id'] ?? null,
            'actor_name'       => $payload['student_name'] ?? null,
            'target_type'      => LearningActivity::TARGET_TEACHER,
            'target_id'        => $payload['teacher_id'] ?? null,
            'target_code'      => $payload['teacher_code'] ?? null,
            'class_section_id' => $payload['class_section_id'] ?? null,
            'subject_id'       => $payload['subject_id'] ?? null,
            'lesson_id'        => $payload['lesson_id'] ?? null,
            'event_type'       => $payload['event_type'] ?? LearningActivity::EVENT_STUDENT_COMPLETED_LESSON,
            'title'            => $payload['title'] ?? 'Student completed a lesson',
            'body'             => $payload['body'] ?? null,
            'meta'             => $payload['meta'] ?? null,
        ]);
    }

    public function recordStudentExerciseActivityForTeacher(array $payload): LearningActivity
    {
        return $this->record([
            'actor_type'          => LearningActivity::ACTOR_STUDENT,
            'actor_id'            => $payload['student_id'] ?? null,
            'actor_code'          => $payload['academic_id'] ?? null,
            'actor_name'          => $payload['student_name'] ?? null,
            'target_type'         => LearningActivity::TARGET_TEACHER,
            'target_id'           => $payload['teacher_id'] ?? null,
            'target_code'         => $payload['teacher_code'] ?? null,
            'class_section_id'    => $payload['class_section_id'] ?? null,
            'subject_id'          => $payload['subject_id'] ?? null,
            'lesson_id'           => $payload['lesson_id'] ?? null,
            'exercise_set_id'     => $payload['exercise_set_id'] ?? null,
            'exercise_attempt_id' => $payload['exercise_attempt_id'] ?? null,
            'event_type'          => $payload['event_type'] ?? LearningActivity::EVENT_STUDENT_SUBMITTED_EXERCISE,
            'title'               => $payload['title'] ?? 'Student submitted exercises',
            'body'                => $payload['body'] ?? null,
            'meta'                => $payload['meta'] ?? null,
        ]);
    }

    /**
     * آخر الأنشطة للطالب مع دعم المؤشر.
     */
    public function recentForStudent(Student $student, int $limit = 20, ?int $beforeId = null): Collection
    {
        $limit = max(1, min($limit, 50));

        $query = LearningActivity::query()
            ->forStudent((int) $student->id, (string) $student->academic_id)
            ->latest('id');

        if ($beforeId !== null) {
            $query->where('id', '<', $beforeId);
        }

        return $query->limit($limit)->get();
    }

    /**
     * آخر الأنشطة للمعلم باستخدام معرف المعلم (teacherId) بدلاً من teacher_code.
     */
    public function recentForTeacher(int $teacherId, int $limit = 20, ?int $beforeId = null): Collection
    {
        $limit = max(1, min($limit, 50));

        $query = LearningActivity::query()
            ->forTeacherById($teacherId)
            ->latest('id');

        if ($beforeId !== null) {
            $query->where('id', '<', $beforeId);
        }

        return $query->limit($limit)->get();
    }

    /**
     * @deprecated استخدم recentForTeacher بدلاً من هذه الدالة
     */
    public function recentForTeacherCode(string $teacherCode, int $limit = 20, ?int $beforeId = null): Collection
    {
        $limit = max(1, min($limit, 50));

        $query = LearningActivity::query()
            ->forTeacher($teacherCode)
            ->latest('id');

        if ($beforeId !== null) {
            $query->where('id', '<', $beforeId);
        }

        return $query->limit($limit)->get();
    }

    public function markTargetActivitiesAsRead(string $targetType, ?int $targetId, ?string $targetCode, array $activityIds): int
    {
        $activityIds = collect($activityIds)
            ->map(fn ($id) => (int) $id)
            ->filter(fn ($id) => $id > 0)
            ->unique()
            ->values()
            ->all();

        if (empty($activityIds)) {
            return 0;
        }

        $query = LearningActivity::query()
            ->where('target_type', $targetType)
            ->whereIn('id', $activityIds);

        $query->where(function ($q) use ($targetId, $targetCode) {
            if ($targetId !== null) {
                $q->where('target_id', $targetId);
            }
            if ($targetCode !== null && trim($targetCode) !== '') {
                if ($targetId !== null) {
                    $q->orWhere('target_code', trim($targetCode));
                } else {
                    $q->where('target_code', trim($targetCode));
                }
            }
        });

        return $query->update(['read_at' => now()]);
    }

    public function recordStudentLessonActivity(\App\Models\Student $student, \App\Models\Lesson $lesson, string $eventType = LearningActivity::EVENT_STUDENT_COMPLETED_LESSON): LearningActivity
    {
        $teacher = null;
        if (!empty($lesson->teacher_id)) {
            $teacher = \App\Models\Teacher::query()->find($lesson->teacher_id);
        }

        return $this->recordStudentLessonActivityForTeacher([
            'student_id'       => $student->id,
            'academic_id'      => $student->academic_id,
            'student_name'     => $student->full_name ?? null,
            'teacher_id'       => $teacher?->id,
            'teacher_code'     => $teacher?->teacher_code,
            'class_section_id' => $lesson->class_section_id,
            'subject_id'       => $lesson->subject_id,
            'lesson_id'        => $lesson->id,
            'event_type'       => $eventType,
            'title'            => 'أكمل طالب درسًا',
            'body'             => "أكمل الطالب {$student->full_name} دراسة الدرس \"{$lesson->title}\".",
        ]);
    }

    protected function nullableInt(mixed $value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }
        if (is_numeric($value)) {
            return (int) $value;
        }
        return null;
    }

    protected function nullableString(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $text = trim((string) $value);
        return $text === '' ? null : $text;
    }

    protected function safeString(mixed $value, string $fallback): string
    {
        $text = trim((string) ($value ?? ''));
        return $text === '' ? $fallback : $text;
    }
}
