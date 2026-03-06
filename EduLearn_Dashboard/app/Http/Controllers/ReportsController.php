<?php

namespace App\Http\Controllers;

use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportsController extends Controller
{
    public function index()
    {
        return view('reports', [
            'pageTitle'      => 'Reports',
            'pageSubtitle'   => 'Generate system reports',
            'REPORTS_ROUTES' => [
                'list'    => route('reports.list'),
                'class'   => route('reports.class', ['grade' => '__GRADE__', 'section' => '__SECTION__']),
                'student' => route('reports.student', ['student' => '__ID__']),
            ],
        ]);
    }

    // جلب قائمة الصفوف/الشعب مميّزة من جدول الطلاب مع عدّ الطلاب
    public function list(Request $request)
    {
        $search = trim($request->get('search', ''));

        $query = Student::query()
            ->select(['grade','class_section', DB::raw('COUNT(*) as students_count')])
            ->when($search !== '', function ($q) use ($search) {
                $s = "%{$search}%";
                $q->where(function ($qq) use ($s) {
                    $qq->where('grade', 'like', $s)
                       ->orWhere('class_section', 'like', $s)
                       ->orWhere(DB::raw("CONCAT(COALESCE(grade,''),' - ',COALESCE(class_section,''))"), 'like', $s);
                });
            })
            ->groupBy('grade', 'class_section')
            ->orderBy('grade')->orderBy('class_section');

        $items = $query->get()->map(fn($row) => [
            'grade'          => $row->grade,
            'class_section'  => $row->class_section,
            'students_count' => (int) $row->students_count,
        ])->values();

        return response()->json([
            'data' => $items,
            'meta' => ['total' => $items->count()],
        ]);
    }

    // تقرير صف: الطلاب + أرقام Placeholder + توزيع درجات
    public function class(Request $request, $grade, $section)
    {
        $grade   = urldecode($grade);
        $section = urldecode($section);

        $students = Student::query()
            ->where('grade', $grade)
            ->where('class_section', $section)
            ->orderBy('id', 'asc')
            ->get(['id','full_name','academic_id','class_section']);

        $studentsTable = $students->map(fn($s) => [
            'id'          => $s->id,
            'name'        => $s->full_name,
            'academic_id' => $s->academic_id,
            'section'     => $s->class_section,
            'score'       => null,
            'attendance'  => null,
        ]);

        $stats = [
            'students'   => $students->count().' / '.$students->count(),
            'avg_score'  => 88.2,
            'pass_rate'  => 0.94,
            'attendance' => 0.98,
            'study_time' => 5.2,
        ];

        $gradeDist = [
            ['label'=>'Grade A','value'=>15],
            ['label'=>'Grade B','value'=>12],
            ['label'=>'Grade C','value'=>7],
            ['label'=>'Grade D','value'=>2],
            ['label'=>'Grade F','value'=>1],
        ];

        return response()->json([
            'grade'              => $grade,
            'section'            => $section,
            'stats'              => $stats,
            'grade_distribution' => $gradeDist,
            'students'           => $studentsTable,
        ]);
    }

    // تقرير طالب: الهوية من DB + Placeholder للباقي
    public function student(Student $student)
    {
        return response()->json([
            'student' => [
                'id'          => $student->id,
                'name'        => $student->full_name,
                'class'       => $student->grade,
                'section'     => $student->class_section,
                'academic_id' => $student->academic_id,
                'photo_url'   => $student->photo_path ? asset($student->photo_path) : null,
                'status'      => 'ON TRACK',
            ],
            'stats' => [
                'avg_score'  => 0.88,
                'pass_rate'  => 0.95,
                'attendance' => 0.98,
                'study_time' => 120,
            ],
            'charts' => [
                'progress' => [
                    'labels' => ['Sep','Oct','Nov','Dec','Jan','Feb','Mar','Apr','May'],
                    'values' => [72,75,78,80,82,84,86,87,88],
                ],
                'study_time_by_subject' => [
                    'labels' => ['Math','Science','History','English','Art'],
                    'values' => [40,35,25,20,10],
                ],
            ],
            'subjects' => [
                ['name'=>'Mathematics','score'=>0.92,'rank'=>'3rd','time'=>'40 hrs','status'=>'Pass'],
                ['name'=>'Science','score'=>0.85,'rank'=>'5th','time'=>'35 hrs','status'=>'Pass'],
                ['name'=>'History','score'=>0.88,'rank'=>'4th','time'=>'25 hrs','status'=>'Pass'],
                ['name'=>'English Literature','score'=>0.78,'rank'=>'12th','time'=>'20 hrs','status'=>'Pass'],
                ['name'=>'Art','score'=>0.45,'rank'=>'25th','time'=>'10 hrs','status'=>'Fail'],
            ],
        ]);
    }
}
