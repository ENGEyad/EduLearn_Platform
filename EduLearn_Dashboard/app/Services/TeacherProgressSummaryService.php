<?php

namespace App\Services;

use App\Models\Student;
use App\Models\Teacher;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

class TeacherProgressSummaryService
{
    protected string $appConnection = 'app_mysql';

    public function __construct(
        protected StudentProgressSummaryService $studentProgressService,
    ) {
    }

    /**
     * بناء ملخص التقدم للمعلم.
     */
    public function buildTeacherSummary(int $teacherId): array
    {
        $assignments = $this->teacherAssignments($teacherId);

        if ($assignments->isEmpty()) {
            return [
                'teacher_id' => $teacherId,
                'assignments_count' => 0,
                'students_count' => 0,
                'average_overall_progress' => 0,
                'average_lesson_completion_rate' => 0,
                'average_exercise_completion_rate' => 0,
                'average_exercise_accuracy_rate' => 0,
                'total_study_time_seconds' => 0,
                'assignments' => [],
            ];
        }

        $assignmentSummaries = $assignments
            ->map(function ($assignment) use ($teacherId) {
                return $this->buildClassSubjectProgress(
                    teacherId: $teacherId,
                    classSectionId: (int) $assignment->class_section_id,
                    subjectId: (int) $assignment->subject_id,
                    skipAuthorization: true,
                );
            })
            ->values();

        return [
            'teacher_id' => $teacherId,
            'assignments_count' => $assignmentSummaries->count(),
            'students_count' => (int) $assignmentSummaries->sum('students_count'),
            'average_overall_progress' => $this->averagePercent($assignmentSummaries->pluck('average_overall_progress')->all()),
            'average_lesson_completion_rate' => $this->averagePercent($assignmentSummaries->pluck('average_lesson_completion_rate')->all()),
            'average_exercise_completion_rate' => $this->averagePercent($assignmentSummaries->pluck('average_exercise_completion_rate')->all()),
            'average_exercise_accuracy_rate' => $this->averagePercent($assignmentSummaries->pluck('average_exercise_accuracy_rate')->all()),
            'total_study_time_seconds' => (int) $assignmentSummaries->sum('total_study_time_seconds'),
            'assignments' => $assignmentSummaries->all(),
        ];
    }

    public function buildClassSubjectProgress(
        int $teacherId,
        int $classSectionId,
        int $subjectId,
        bool $skipAuthorization = false,
    ): array {
        if (!$skipAuthorization) {
            $this->assertTeacherCanAccessClassSubject($teacherId, $classSectionId, $subjectId);
        }

        $students = Student::query()
            ->where('class_section_id', $classSectionId)
            ->orderBy('full_name')
            ->get();

        $studentProgressRows = $students
            ->map(fn (Student $student) => $this->studentProgressService->buildStudentSubjectProgress($student, $subjectId))
            ->values();

        return [
            'class_section_id' => $classSectionId,
            'subject_id' => $subjectId,
            'students_count' => $studentProgressRows->count(),
            'average_overall_progress' => $this->averagePercent($studentProgressRows->pluck('overall_progress')->all()),
            'average_lesson_completion_rate' => $this->averagePercent($studentProgressRows->pluck('lessons.completion_rate')->all()),
            'average_exercise_completion_rate' => $this->averagePercent($studentProgressRows->pluck('exercises.completion_rate')->all()),
            'average_exercise_accuracy_rate' => $this->averagePercent($studentProgressRows->pluck('exercises.accuracy_rate')->all()),
            'total_study_time_seconds' => (int) $studentProgressRows->sum('total_study_time_seconds'),
            'students' => $studentProgressRows->map(fn (array $row) => [
                'student' => $row['student'] ?? null,
                'subject_id' => $row['subject_id'] ?? $subjectId,
                'class_section_id' => $row['class_section_id'] ?? $classSectionId,
                'overall_progress' => $row['overall_progress'] ?? 0,
                'total_study_time_seconds' => $row['total_study_time_seconds'] ?? 0,
                'lessons' => $row['lessons'] ?? [],
                'exercises' => $row['exercises'] ?? [],
            ])->all(),
        ];
    }

    public function buildStudentSubjectProgress(
        int $teacherId,
        int|string|null $studentId,
        ?string $academicId,
        int $subjectId,
    ): array {
        $student = $this->resolveStudent($studentId, $academicId);
        $classSectionId = (int) ($student->class_section_id ?? 0);

        if ($classSectionId <= 0) {
            throw new HttpException(422, 'Student has no class_section_id.');
        }

        $this->assertTeacherCanAccessClassSubject($teacherId, $classSectionId, $subjectId);

        return $this->studentProgressService->buildStudentSubjectProgress($student, $subjectId);
    }

    protected function teacherAssignments(int $teacherId): Collection
    {
        return DB::connection($this->appConnection)
            ->table('teacher_class_subjects')
            ->select(['id', 'teacher_id', 'class_section_id', 'subject_id', 'is_active'])
            ->where('teacher_id', $teacherId)
            ->where(function ($query) {
                $query->where('is_active', true)
                    ->orWhereNull('is_active');
            })
            ->orderBy('class_section_id')
            ->orderBy('subject_id')
            ->get();
    }

    protected function assertTeacherCanAccessClassSubject(int $teacherId, int $classSectionId, int $subjectId): void
    {
        $exists = DB::connection($this->appConnection)
            ->table('teacher_class_subjects')
            ->where('teacher_id', $teacherId)
            ->where('class_section_id', $classSectionId)
            ->where('subject_id', $subjectId)
            ->where(function ($query) {
                $query->where('is_active', true)
                    ->orWhereNull('is_active');
            })
            ->exists();

        if (!$exists) {
            throw new HttpException(403, 'This teacher is not allowed to access this class/subject progress.');
        }
    }

    protected function resolveStudent(int|string|null $studentId, ?string $academicId): Student
    {
        $query = Student::query();

        if ($studentId !== null && $studentId !== '' && $studentId !== 0) {
            $student = $query->where('id', (int) $studentId)->first();
        } elseif ($academicId !== null && trim($academicId) !== '') {
            $student = $query->where('academic_id', trim($academicId))->first();
        } else {
            throw new HttpException(422, 'student_id or academic_id is required.');
        }

        if (!$student) {
            throw new HttpException(404, 'Student not found.');
        }

        return $student;
    }

    protected function averagePercent(array $values): int
    {
        $numbers = collect($values)
            ->filter(fn ($value) => is_numeric($value))
            ->map(fn ($value) => (float) $value)
            ->values();

        if ($numbers->isEmpty()) return 0;

        return max(0, min(100, (int) round($numbers->avg())));
    }
}
