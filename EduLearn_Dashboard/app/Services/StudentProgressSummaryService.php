<?php

namespace App\Services;

use App\Models\Student;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class StudentProgressSummaryService
{
    protected string $connection = 'app_mysql';

    protected float $lessonWeight = 0.45;
    protected float $exerciseCompletionWeight = 0.25;
    protected float $exerciseAccuracyWeight = 0.30;

    public function buildStudentOverview(Student $student): array
    {
        $classSectionId = (int) ($student->class_section_id ?? 0);

        if ($classSectionId <= 0) {
            return $this->emptyOverview($student, 'Student has no class_section_id.');
        }

        $subjectIds = $this->publishedSubjectIdsForClassSection($classSectionId);

        if ($subjectIds->isEmpty()) {
            return $this->emptyOverview($student, null);
        }

        $subjects = $subjectIds
            ->map(fn (int $subjectId) => $this->buildStudentSubjectProgress($student, $subjectId))
            ->values();

        $overallProgress = $this->averagePercent($subjects->pluck('overall_progress')->all());
        $lessonCompletionRate = $this->averagePercent($subjects->pluck('lessons.completion_rate')->all());
        $exerciseCompletionRate = $this->averagePercent($subjects->pluck('exercises.completion_rate')->all());
        $exerciseAccuracyRate = $this->averagePercent($subjects->pluck('exercises.accuracy_rate')->all());

        return [
            'student' => $this->studentPayload($student),
            'overall_progress' => $overallProgress,
            'lesson_completion_rate' => $lessonCompletionRate,
            'exercise_completion_rate' => $exerciseCompletionRate,
            'exercise_accuracy_rate' => $exerciseAccuracyRate,
            'total_study_time_seconds' => (int) $subjects->sum('total_study_time_seconds'),
            'subjects_count' => $subjects->count(),
            'subjects' => $subjects->all(),
        ];
    }

    public function buildStudentSubjectProgress(Student $student, int $subjectId): array
    {
        $classSectionId = (int) ($student->class_section_id ?? 0);

        if ($classSectionId <= 0) {
            return $this->emptySubjectResult($student, $subjectId, 'Student has no class_section_id.');
        }

        $lessons = $this->publishedLessonsForSubject($classSectionId, $subjectId);
        $lessonIds = $lessons->pluck('id')->map(fn ($id) => (int) $id)->values();

        $lessonSummary = $this->calculateLessonSummary((int) $student->id, $lessonIds);
        $exerciseSummary = $this->calculateExerciseSummary((int) $student->id, $lessonIds);

        $overallProgress = $this->calculateOverallProgress(
            lessonCompletionRate: $lessonSummary['completion_rate'],
            exerciseCompletionRate: $exerciseSummary['completion_rate'],
            exerciseAccuracyRate: $exerciseSummary['accuracy_rate'],
            hasLessons: $lessonSummary['total_lessons'] > 0,
            hasExercises: $exerciseSummary['total_exercise_sets'] > 0,
        );

        return [
            'student' => $this->studentPayload($student),
            'subject_id' => $subjectId,
            'class_section_id' => $classSectionId,
            'overall_progress' => $overallProgress,
            'total_study_time_seconds' => $lessonSummary['time_spent_seconds'] + $exerciseSummary['time_spent_seconds'],
            'lessons' => $lessonSummary,
            'exercises' => $exerciseSummary,
        ];
    }

    protected function publishedLessonsForSubject(int $classSectionId, int $subjectId): Collection
    {
        return DB::connection($this->connection)
            ->table('lessons')
            ->select(['id', 'title', 'subject_id', 'class_section_id', 'class_module_id', 'published_at'])
            ->where('class_section_id', $classSectionId)
            ->where('subject_id', $subjectId)
            ->where('status', 'published')
            ->orderBy('class_module_id')
            ->orderBy('published_at')
            ->orderBy('id')
            ->get();
    }

    protected function publishedSubjectIdsForClassSection(int $classSectionId): Collection
    {
        return DB::connection($this->connection)
            ->table('lessons')
            ->where('class_section_id', $classSectionId)
            ->where('status', 'published')
            ->whereNotNull('subject_id')
            ->distinct()
            ->orderBy('subject_id')
            ->pluck('subject_id')
            ->map(fn ($id) => (int) $id)
            ->values();
    }

    protected function calculateLessonSummary(int $studentId, Collection $lessonIds): array
    {
        $totalLessons = $lessonIds->count();

        if ($totalLessons === 0) {
            return [
                'total_lessons' => 0,
                'completed_lessons' => 0,
                'in_progress_lessons' => 0,
                'not_started_lessons' => 0,
                'completion_rate' => 0,
                'time_spent_seconds' => 0,
            ];
        }

        $progressRows = DB::connection($this->connection)
            ->table('student_lesson_progress')
            ->where('student_id', $studentId)
            ->whereIn('lesson_id', $lessonIds->all())
            ->get();

        $completedLessons = $progressRows
            ->where('status', 'completed')
            ->pluck('lesson_id')
            ->unique()
            ->count();

        $inProgressLessons = $progressRows
            ->where('status', 'draft')
            ->pluck('lesson_id')
            ->unique()
            ->count();

        $timeSpent = (int) $progressRows->sum(fn ($row) => (int) ($row->time_spent_seconds ?? 0));

        return [
            'total_lessons' => $totalLessons,
            'completed_lessons' => $completedLessons,
            'in_progress_lessons' => $inProgressLessons,
            'not_started_lessons' => max(0, $totalLessons - $completedLessons - $inProgressLessons),
            'completion_rate' => $this->percent($completedLessons, $totalLessons),
            'time_spent_seconds' => $timeSpent,
        ];
    }

    protected function calculateExerciseSummary(int $studentId, Collection $lessonIds): array
    {
        if ($lessonIds->isEmpty()) {
            return $this->emptyExerciseSummary();
        }

        $exerciseSets = DB::connection($this->connection)
            ->table('lesson_exercise_sets')
            ->select(['id', 'lesson_id'])
            ->whereIn('lesson_id', $lessonIds->all())
            ->where('status', 'published')
            ->get();

        $totalSets = $exerciseSets->count();

        if ($totalSets === 0) {
            return $this->emptyExerciseSummary();
        }

        $setIds = $exerciseSets->pluck('id')->map(fn ($id) => (int) $id)->values();

        $latestAttemptIds = DB::connection($this->connection)
            ->table('student_exercise_attempts')
            ->selectRaw('MAX(id) as id')
            ->where('student_id', $studentId)
            ->whereIn('exercise_set_id', $setIds->all())
            ->groupBy('exercise_set_id')
            ->pluck('id')
            ->filter()
            ->map(fn ($id) => (int) $id)
            ->values();

        $attempts = $latestAttemptIds->isEmpty()
            ? collect()
            : DB::connection($this->connection)
                ->table('student_exercise_attempts')
                ->whereIn('id', $latestAttemptIds->all())
                ->get();

        $completedAttempts = $attempts
            ->filter(fn ($row) => in_array((string) ($row->status ?? ''), ['submitted', 'graded'], true))
            ->count();

        $gradedAttempts = $attempts
            ->filter(fn ($row) => (string) ($row->status ?? '') === 'graded');

        $score = (float) $gradedAttempts->sum(fn ($row) => (float) ($row->score ?? 0));
        $totalPoints = (float) $gradedAttempts->sum(fn ($row) => (float) ($row->total_points ?? 0));

        $answeredCount = (int) $attempts->sum(fn ($row) => (int) ($row->answered_count ?? 0));
        $questionCount = (int) $attempts->sum(fn ($row) => (int) ($row->question_count ?? 0));
        $timeSpent = (int) $attempts->sum(fn ($row) => (int) ($row->time_spent_seconds ?? 0));

        return [
            'total_exercise_sets' => $totalSets,
            'completed_exercise_sets' => $completedAttempts,
            'in_progress_exercise_sets' => max(0, $attempts->count() - $completedAttempts),
            'not_started_exercise_sets' => max(0, $totalSets - $attempts->count()),
            'completion_rate' => $this->percent($completedAttempts, $totalSets),
            'accuracy_rate' => $totalPoints > 0 ? $this->percent($score, $totalPoints) : 0,
            'score' => round($score, 2),
            'total_points' => round($totalPoints, 2),
            'question_count' => $questionCount,
            'answered_count' => $answeredCount,
            'unanswered_count' => max(0, $questionCount - $answeredCount),
            'correct_count' => (int) $gradedAttempts->sum(fn ($row) => (int) ($row->correct_count ?? 0)),
            'wrong_count' => (int) $gradedAttempts->sum(fn ($row) => (int) ($row->wrong_count ?? 0)),
            'time_spent_seconds' => $timeSpent,
        ];
    }

    protected function calculateOverallProgress(
        int $lessonCompletionRate,
        int $exerciseCompletionRate,
        int $exerciseAccuracyRate,
        bool $hasLessons,
        bool $hasExercises,
    ): int {
        $weightedTotal = 0.0;
        $weightSum = 0.0;

        if ($hasLessons) {
            $weightedTotal += $lessonCompletionRate * $this->lessonWeight;
            $weightSum += $this->lessonWeight;
        }

        if ($hasExercises) {
            $weightedTotal += $exerciseCompletionRate * $this->exerciseCompletionWeight;
            $weightedTotal += $exerciseAccuracyRate * $this->exerciseAccuracyWeight;
            $weightSum += $this->exerciseCompletionWeight + $this->exerciseAccuracyWeight;
        }

        if ($weightSum <= 0) {
            return 0;
        }

        return (int) round($weightedTotal / $weightSum);
    }

    protected function emptyExerciseSummary(): array
    {
        return [
            'total_exercise_sets' => 0,
            'completed_exercise_sets' => 0,
            'in_progress_exercise_sets' => 0,
            'not_started_exercise_sets' => 0,
            'completion_rate' => 0,
            'accuracy_rate' => 0,
            'score' => 0,
            'total_points' => 0,
            'question_count' => 0,
            'answered_count' => 0,
            'unanswered_count' => 0,
            'correct_count' => 0,
            'wrong_count' => 0,
            'time_spent_seconds' => 0,
        ];
    }

    protected function emptySubjectResult(Student $student, int $subjectId, ?string $message): array
    {
        return [
            'student' => $this->studentPayload($student),
            'subject_id' => $subjectId,
            'class_section_id' => (int) ($student->class_section_id ?? 0),
            'overall_progress' => 0,
            'total_study_time_seconds' => 0,
            'message' => $message,
            'lessons' => [
                'total_lessons' => 0,
                'completed_lessons' => 0,
                'in_progress_lessons' => 0,
                'not_started_lessons' => 0,
                'completion_rate' => 0,
                'time_spent_seconds' => 0,
            ],
            'exercises' => $this->emptyExerciseSummary(),
        ];
    }

    protected function emptyOverview(Student $student, ?string $message): array
    {
        return [
            'student' => $this->studentPayload($student),
            'overall_progress' => 0,
            'lesson_completion_rate' => 0,
            'exercise_completion_rate' => 0,
            'exercise_accuracy_rate' => 0,
            'total_study_time_seconds' => 0,
            'subjects_count' => 0,
            'subjects' => [],
            'message' => $message,
        ];
    }

    protected function studentPayload(Student $student): array
    {
        return [
            'id' => (int) $student->id,
            'academic_id' => (string) $student->academic_id,
            'full_name' => (string) ($student->full_name ?? ''),
            'class_section_id' => $student->class_section_id ? (int) $student->class_section_id : null,
        ];
    }

    protected function percent(float|int $value, float|int $total): int
    {
        if ($total <= 0) return 0;
        return max(0, min(100, (int) round(($value / $total) * 100)));
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
