<?php

namespace App\Services\AI;

use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\ClassSection;
use App\Models\TeacherClassSubject;
use App\Models\StudentLessonProgress;
use App\Models\StudentExerciseAttempt;
use App\Models\LearningActivity;
use Illuminate\Support\Collection;

class AnalyticsPromptBuilder
{
    /**
     * Build the structured JSON payload for the AI Analytics Report.
     */
    public function build(
        School $school,
        Collection $students,
        Collection $teachers,
        Collection $classes,
        Collection $assignments,
        Collection $progress,
        Collection $attempts,
        Collection $activities,
        array $reportContext = [],
        array $filters = [],
        array $comparisonPeriod = ['enabled' => false]
    ): array {
        return [
            'report_type' => 'full_analytics_report',
            'report_context' => array_merge([
                'title' => 'School Analytics Report',
                'generated_at' => now()->toIso8601String(),
                'date_range' => [
                    'start' => now()->startOfMonth()->toDateString(),
                    'end' => now()->toDateString()
                ],
                'institution_scope' => 'single_school',
                'language' => 'en'
            ], $reportContext),
            'filters' => array_merge([
                'school_id' => $school->id,
                'grade' => null,
                'class_section_id' => null,
                'teacher_id' => null,
                'student_id' => null,
                'subject_id' => null
            ], $filters),
            'school' => [
                'id' => $school->id,
                'name' => $school->name,
                'academic_year' => $school->academic_year ?? '2023-2024',
                'school_type' => $school->school_type ?? 'Secondary',
                'section' => $school->section ?? 'Morning',
                'country' => $school->country ?? 'Iraq',
                'city' => $school->city ?? 'Unknown',
                'directorate' => $school->directorate ?? 'Unknown',
                'status' => $school->status ?? 'active',
                'admin_name' => $school->admin_name ?? 'School Admin',
                'num_students' => $school->num_students ?? $students->count(),
                'features' => ['analytics', 'lessons', 'exercises'],
                'subjects' => [],
                'branches' => []
            ],
            'students' => $students->map(fn($s) => [
                'id' => $s->id,
                'school_id' => $s->school_id,
                'full_name' => $s->full_name,
                'academic_id' => $s->academic_id,
                'gender' => $s->gender,
                'status' => $s->status,
                'grade' => $s->grade,
                'class_section' => $s->class_section,
                'class_section_id' => $s->class_section_id,
                'attendance_rate' => $s->attendance_rate,
                'performance_avg' => $s->performance_avg ?? 0,
                'total_study_time_seconds' => $s->total_study_time_seconds,
                'subjects' => $s->subjects ?? []
            ])->toArray(),
            'teachers' => $teachers->map(fn($t) => [
                'id' => $t->id,
                'full_name' => $t->full_name,
                'teacher_code' => $t->teacher_code,
                'status' => $t->status,
                'weekly_load' => $t->weekly_load ?? 0,
                'subjects' => $t->subjects ?? [],
                'grades' => $t->grades ?? [],
                'students_count' => $t->students_count ?? 0,
                'avg_student_score' => $t->avg_student_score ?? 0,
                'attendance_rate' => $t->attendance_rate ?? 100
            ])->toArray(),
            'classes' => $classes->map(fn($c) => [
                'id' => $c->id,
                'grade' => $c->grade,
                'section' => $c->section,
                'name' => $c->display_name ?? ($c->grade . ' - ' . $c->section),
                'stage' => $c->stage ?? 'Secondary',
                'is_active' => $c->is_active ?? true,
                'students_count' => $c->students_count ?? 0,
                'subjects' => $c->subjects ?? []
            ])->toArray(),
            'teacher_class_subject_assignments' => $assignments->map(fn($a) => [
                'teacher_id' => $a->teacher_id,
                'class_section_id' => $a->class_section_id,
                'subject_id' => $a->subject_id,
                'weekly_load' => $a->weekly_load,
                'is_active' => $a->is_active ?? true
            ])->toArray(),
            'student_lesson_progress' => $progress->map(fn($p) => [
                'student_id' => $p->student_id,
                'lesson_id' => $p->lesson_id,
                'status' => $p->status,
                'time_spent_seconds' => $p->time_spent_seconds,
                'last_opened_at' => $p->last_opened_at?->toIso8601String(),
                'completed_at' => $p->completed_at?->toIso8601String()
            ])->toArray(),
            'student_exercise_attempts' => $attempts->map(fn($e) => [
                'student_id' => $e->student_id,
                'lesson_id' => $e->lesson_id,
                'exercise_set_id' => $e->exercise_set_id,
                'status' => $e->status,
                'score' => $e->score,
                'total_points' => $e->total_points,
                'correct_count' => $e->correct_count,
                'wrong_count' => $e->wrong_count,
                'submitted_at' => $e->submitted_at?->toIso8601String(),
                'graded_at' => $e->graded_at?->toIso8601String()
            ])->toArray(),
            'learning_activities' => $activities->map(fn($l) => [
                'actor_type' => $l->actor_type,
                'actor_id' => $l->actor_id,
                'target_type' => $l->target_type,
                'target_id' => $l->target_id,
                'class_section_id' => $l->class_section_id,
                'subject_id' => $l->subject_id,
                'lesson_id' => $l->lesson_id,
                'event_type' => $l->event_type,
                'title' => $l->title ?? '',
                'created_at' => $l->created_at?->toIso8601String()
            ])->toArray(),
            'comparison_period' => $comparisonPeriod
        ];
    }

    /**
     * Get the system instruction prompt for the AI model.
     */
    public function getSystemInstruction(): string
    {
        return <<<PROMPT
You are a senior educational analytics expert, school performance analyst, and academic reporting specialist.

Your task is to generate a highly accurate, evidence-based analytics report for a school dashboard using ONLY the structured data provided to you.
Do not invent facts, do not assume missing values, and do not exaggerate conclusions.
If data is missing, incomplete, inconsistent, or too weak for a strong conclusion, explicitly say so.

Your reporting goals:
1. Produce a professional Analytics Report for school leadership.
2. Produce performance insights for students.
3. Produce performance insights for teachers.
4. Produce performance insights for classes/sections.
5. Produce school-level trends, risks, strengths, and recommendations.

Core rules:
- Base every insight on the provided data.
- Distinguish clearly between facts, patterns, risks, and recommendations.
- Where possible, quantify findings with percentages, averages, counts, rankings, and comparisons.
- Highlight both strengths and weak areas.
- Flag anomalies, missing data, and unreliable conclusions.
- Be concise but professional.
- Use an executive tone suitable for principals, school admins, and academic supervisors.
- Never mention that you are an AI model.
- If the report covers a selected date range, only analyze that period.
- If comparison data exists, compare current period vs previous period.
- If no comparison data exists, do not fabricate trends.

Interpretation guidance:
- Students:
  Analyze academic performance, attendance, engagement, study time, exercise results, lesson completion, subject-level strengths/weaknesses, consistency, and at-risk indicators.
- Teachers:
  Analyze teaching load, assigned students, attendance, average student outcomes, class coverage, subject coverage, and indicators of effectiveness based on student outcomes and activity patterns.
- Classes:
  Analyze class performance by grade/section, attendance, engagement, completion, score distribution, strongest/weakest subjects, and concentration of at-risk students.
- School:
  Analyze overall enrollment, active/inactive trends, academic performance, attendance, engagement, teacher allocation, class balance, subject coverage, and operational/academic risks.

Important analytic constraints:
- A low attendance rate must be treated as a risk factor.
- A low performance average must be treated as an academic risk factor.
- Low study time with low scores suggests low engagement risk.
- High study time with low scores suggests possible learning difficulty risk.
- High attendance with low performance suggests instruction, content difficulty, or assessment issues.
- Low attendance plus low completion plus low scores indicates high intervention priority.
- For teachers, do not claim teacher quality directly unless supported by multiple signals.
- For teachers, present findings as “performance indicators” or “instructional signals,” not absolute judgments.
- For classes, identify whether underperformance is broad or concentrated in specific students or subjects.
- For the school, separate academic insights from operational insights.

When generating the report, use this output structure:

# Analytics Report

## 1. Executive Summary
- Summarize the most important overall findings.
- Include 3 to 6 key takeaways.

## 2. School-Level Overview
- School identity and academic context
- Enrollment and structure
- Overall performance indicators
- Attendance and engagement indicators
- School strengths
- School risks
- Notable trends

## 3. Student Performance Analysis
- Overall student performance summary
- Top-performing students
- Students needing intervention
- Attendance-related risk students
- Engagement-related risk students
- Lesson completion insights
- Exercise/assessment insights
- Subject-level patterns if available

## 4. Teacher Performance Analysis
- Teacher workload and allocation
- Teacher coverage across classes and subjects
- Teachers with strong performance indicators
- Teachers/classes needing support
- Student outcome patterns linked to teacher assignments
- Attendance and engagement signals for teacher groups

## 5. Class Performance Analysis
- Best-performing classes
- Lowest-performing classes
- Attendance by class
- Engagement by class
- Completion and assessment results by class
- Subjects driving class success or weakness
- Priority classes for intervention

## 6. Risks and Alerts
- Academic risks
- Attendance risks
- Engagement risks
- Teacher allocation risks
- Class imbalance risks
- Data quality issues

## 7. Recommendations
Provide recommendations in 3 levels:
- Immediate actions (next 1 to 2 weeks)
- Short-term actions (this month)
- Strategic actions (this term/semester)

## 8. Data Gaps and Reliability Notes
- Mention missing fields, weak coverage, stale data, or any reasons confidence is limited.

Output quality requirements:
- Write in clear professional English.
- Use bullets where helpful.
- Use exact numbers from the data whenever possible.
- If ranking items, explain the metric used.
- If confidence is low, state that clearly.
- Do not hallucinate student names, teacher names, class names, or metrics.
- Keep the report actionable and realistic.

Small Upgrade For Better Accuracy:
Before writing the final report, internally compute and output a JSON block with these keys:
- school_summary
- student_risk_list
- teacher_indicator_list
- class_performance_list
- top_strengths
- top_risks
- data_gaps

Then use those computed results to write the final report.
PROMPT;
    }
}

