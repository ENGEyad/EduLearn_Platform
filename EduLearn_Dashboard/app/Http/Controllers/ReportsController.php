<?php

namespace App\Http\Controllers;

use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportsController extends Controller
{
    public function index()
    {
        $years = \App\Models\Student::select('grade')->distinct()->whereNotNull('grade')->pluck('grade');
        $teachers = \App\Models\Teacher::select('id', 'full_name')->get();
        // Get all unique classes/sections for filtering
        $classes = \App\Models\Student::select('grade', 'class_section')
            ->distinct()
            ->whereNotNull('grade')
            ->whereNotNull('class_section')
            ->orderBy('grade')
            ->orderBy('class_section')
            ->get();

        // Get all subject names
        $subjects = \App\Models\Subject::select('id', 'name_en as name')->orderBy('name_en')->get();

        return view('reports', [
            'pageTitle' => __('Reports'),
            'pageSubtitle' => __('A detailed overview of class performance and student data.'),
            'years' => $years,
            'teachers' => $teachers,
            'classes_dropdown' => $classes,
            'subjects_dropdown' => $subjects,
            'REPORTS_ROUTES' => [
                'list' => route('reports.list'),
                'class' => route('reports.class', ['grade' => '__GRADE__', 'section' => '__SECTION__']),
                'student' => route('reports.student', ['student' => '__ID__']),
                'subject' => route('reports.subject', ['student' => '__SID__', 'subject' => '__SUBID__']),
            ],
        ]);
    }

    // جلب قائمة الصفوف/الشعب مميّزة من جدول الطلاب مع عدّ الطلاب (Optimized to avoid N+1 queries)
    public function list(Request $request)
    {
        $search = trim($request->get('search', ''));
        $classFilter = trim($request->get('class', ''));
        $subjectFilter = trim($request->get('subject', ''));

        // Start with a base query of distinct classes with counts in ONE query
        $query = Student::query()
            ->select('grade', 'class_section')
            ->selectRaw('count(*) as students_count')
            ->whereNotNull('grade')
            ->whereNotNull('class_section')
            ->groupBy('grade', 'class_section');

        // If filtering by subject
        if ($subjectFilter !== '') {
            $query->whereHas('classSection.subjects', function ($q) use ($subjectFilter) {
                $q->where('subject_id', $subjectFilter);
            });
        }

        if ($classFilter !== '') {
            $parts = explode('-', $classFilter);
            if (count($parts) == 2) {
                $query->where('grade', trim($parts[0]))
                    ->where('class_section', trim($parts[1]));
            }
        }

        // Optimized search: Filter classes by name or by existence of matching students in ONE database call
        if ($search !== '') {
            $tableName = (new Student())->getTable();
            $driver = DB::connection()->getDriverName();
            $concatSql = ($driver === 'sqlite')
                ? "grade || ' - ' || class_section"
                : "CONCAT(grade, ' - ', class_section)";

            $query->where(function ($q) use ($search, $concatSql, $tableName) {
                $q->where(DB::raw($concatSql), 'like', "%{$search}%")
                  ->orWhereExists(function ($sub) use ($search, $tableName) {
                      $sub->select(DB::raw(1))
                          ->from($tableName . ' as s2')
                          ->whereColumn('s2.grade', $tableName . '.grade')
                          ->whereColumn('s2.class_section', $tableName . '.class_section')
                          ->where(function ($q2) use ($search) {
                              $q2->where('full_name', 'like', "%{$search}%")
                                 ->orWhere('academic_id', 'like', "%{$search}%");
                          });
                  });
            });
        }

        // Execute the optimized grouped query
        $items = $query->orderBy('grade')->orderBy('class_section')->get();

        // Convert counts to integers for API consistency and map to final structure
        $data = $items->map(function ($item) {
            return [
                'grade' => $item->grade,
                'class_section' => $item->class_section,
                'students_count' => (int) $item->students_count,
            ];
        });

        // If search matches students, grab them directly (2nd query max)
        $matchingStudents = collect();
        if ($search !== '') {
            $matchingStudentsQuery = Student::where(function ($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                    ->orWhere('academic_id', 'like', "%{$search}%");
            });

            if ($classFilter !== '') {
                $parts = explode('-', $classFilter);
                if (count($parts) == 2) {
                    $matchingStudentsQuery->where('grade', trim($parts[0]))
                        ->where('class_section', trim($parts[1]));
                }
            }

            $matchingStudents = $matchingStudentsQuery->get(['id', 'full_name', 'academic_id', 'grade', 'class_section', 'photo_path']);
        }

        return response()->json([
            'data' => $data->values(),
            'students' => $matchingStudents,
            'meta' => ['total' => $data->count() + $matchingStudents->count()],
        ]);
    }

    // تقرير صف: الطلاب + أرقام Placeholder + توزيع درجات
    public function class(Request $request, $grade, $section)
    {
        $grade = urldecode($grade);
        $section = urldecode($section);

        $students = Student::query()
            ->where('grade', $grade)
            ->where('class_section', $section)
            ->orderBy('id', 'asc')
            ->get(['id', 'full_name', 'academic_id', 'class_section', 'photo_path']);

        $studentsTable = $students->map(fn($s) => [
            'id' => $s->id,
            'name' => $s->full_name,
            'academic_id' => $s->academic_id,
            'section' => $s->class_section,
            'photo_url' => $s->photo_url,
            'score' => null,
            'attendance' => null,
            ]);

        $totalStudyTimeSec = Student::query()
            ->where('grade', $grade)
            ->where('class_section', $section)
            ->sum('total_study_time_seconds');
        $totalStudyTimeHrs = round($totalStudyTimeSec / 3600, 1);

        $stats = [
            'students' => $students->count() . ' / ' . $students->count(),
            'avg_score' => 88.2,
            'pass_rate' => 0.94,
            'attendance' => 0.98,
            'study_time' => $totalStudyTimeHrs,
        ];

        $gradeDist = [
            ['label' => 'Grade A', 'value' => 15],
            ['label' => 'Grade B', 'value' => 12],
            ['label' => 'Grade C', 'value' => 7],
            ['label' => 'Grade D', 'value' => 2],
            ['label' => 'Grade F', 'value' => 1],
        ];

        return response()->json([
            'grade' => $grade,
            'section' => $section,
            'stats' => $stats,
            'grade_distribution' => $gradeDist,
            'students' => $studentsTable,
        ]);
    }

    // تقرير طالب: الهوية من DB + Placeholder للباقي
    public function student(Student $student)
    {
        $studyTimeHrs = round(($student->total_study_time_seconds ?? 0) / 3600, 1);

        // Fetch subjects associated with the student's class section
        $classSectionId = $student->class_section_id;
        $subjectIds = \App\Models\ClassSectionSubject::where('class_section_id', $classSectionId)->pluck('subject_id');
        $subjects = \App\Models\Subject::whereIn('id', $subjectIds)->get();

        $subjectsData = $subjects->map(function ($sub) use ($student) {
            // Study time per subject
            $lessons = \App\Models\Lesson::on('app_mysql')->where('subject_id', $sub->id)->get();
            $progressRecords = \App\Models\StudentLessonProgress::on('app_mysql')
                ->where('student_id', $student->id)
                ->whereIn('lesson_id', $lessons->pluck('id'))
                ->get();

            $studyTimeSecSub = $progressRecords->sum('time_spent_seconds');
            $studyTimeHrsSubStr = round($studyTimeSecSub / 3600, 1) . ' hrs';

            // simple placeholders for score and rank right now
            $score = 0.85;
            $status = $score >= 0.5 ? 'Pass' : 'Fail';

            return [
            'id' => $sub->id,
            'name' => $sub->name_en,
            'score' => $score,
            'rank' => 'N/A',
            'time' => $studyTimeHrsSubStr, // e.g. "40 hrs"
            'numeric_time' => round($studyTimeSecSub / 3600, 1), // numeric for charting
            'status' => $status,
            ];
        })->values()->toArray();


        return response()->json([
            'student' => [
                'id' => $student->id,
                'name' => $student->full_name,
                'class' => $student->grade,
                'section' => $student->class_section,
                'academic_id' => $student->academic_id,
                'photo_url' => $student->photo_url,
                'status' => 'ON TRACK',
            ],
            'stats' => [
                'avg_score' => 0.88,
                'pass_rate' => 0.95,
                'attendance' => 0.98,
                'study_time' => $studyTimeHrs,
            ],
            'charts' => [
                'progress' => [
                    'labels' => ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'],
                    'values' => [72, 75, 78, 80, 82, 84, 86, 87, 88],
                ],
                'study_time_by_subject' => [
                    'labels' => collect($subjectsData)->pluck('name')->toArray(),
                    'values' => collect($subjectsData)->pluck('numeric_time')->toArray(),
                ],
            ],
            'subjects' => collect($subjectsData)->map(function ($s) {
            unset($s['numeric_time']); // Remove numeric time before sending array to frontend to match structure
            return $s;
        })->toArray(),
        ]);
    }
}
