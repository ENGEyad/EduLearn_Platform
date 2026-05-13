<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use App\Traits\HandlesImageUploads;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;

class TeacherController extends Controller
{
    use HandlesImageUploads;
    public function index()
    {
        $schoolId = auth()->user()->school_id;
        $allSections = \App\Models\ClassSection::where('school_id', $schoolId)->orderBy('grade')->orderBy('section')->get();

        return view('teachers', [
            'pageTitle' => __('Teachers'),
            'pageSubtitle' => __('Add, edit and monitor teachers'),
            'allSections' => $allSections,
            'TEACHERS_ROUTES' => [
                'list'    => route('teachers.list'),
                'store'   => route('teachers.store'),
                'update'  => route('teachers.update', ['teacher' => '__ID__']),
                'destroy' => route('teachers.destroy', ['teacher' => '__ID__']),
                'import'  => route('teachers.import'),
            ],
            'CLASSES_API' => route('classes.list'),
            'CLASS_SUBJECTS_API' => route('class-subjects.list'),
        ]);
    }

    public function list()
    {
        $teachers = Teacher::where('school_id', auth()->user()->school_id)
            ->with([
                'assignments.subject', 
                'assignments.classSection' => function($q) {
                    $q->withCount('students');
                }
            ])
            ->orderBy('id', 'desc')
            ->get();

        $teachers->each(fn($t) => $t->append(['assigned_subjects', 'assigned_class_sections', 'total_assigned_students']));
        return response()->json($teachers);
    }

    public function store(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:255',
            'gender'    => 'required|string|max:20',
            'birthdate' => 'required|date|before_or_equal:' . now()->subYears(18)->format('Y-m-d') . '|after_or_equal:' . now()->subYears(70)->format('Y-m-d'),
            'shift'     => 'required|string|max:50',
            'photo'     => 'nullable|image|max:2048',
        ]);

        $data = $this->sanitize($request);

        if (empty($data['teacher_code'])) {
            $data['teacher_code'] = $this->generateTeacherCode();
        }

        // حفظ صورة الأستاذ
        if ($request->hasFile('photo')) {
            $data['photo_path'] = $this->uploadAndOptimize($request->file('photo'), 'teachers');
        }

        $data['school_id'] = auth()->user()->school_id;

        $teacher = Teacher::create($data);

        // Handle Assignments
        $assignmentsJson = $request->input('assignments_json', '[]');
        $assignments = json_decode($assignmentsJson, true);
        if (is_array($assignments)) {
            foreach ($assignments as $assignment) {
                if (!empty($assignment['class_section_id']) && !empty($assignment['subject_id'])) {
                    \App\Models\TeacherClassSubject::create([
                        'teacher_id' => $teacher->id,
                        'class_section_id' => $assignment['class_section_id'],
                        'subject_id' => $assignment['subject_id'],
                        'is_active' => true,
                    ]);
                }
            }
        }

        $teacher->load(['assignments.subject', 'assignments.classSection']);
        $teacher->append(['assigned_subjects', 'assigned_class_sections', 'total_assigned_students']);
        return response()->json($teacher, 201);
    }

    public function update(Request $request, Teacher $teacher)
    {
        if ($teacher->school_id !== auth()->user()->school_id) {
            abort(403, __('Unauthorized access to teacher record'));
        }

        $request->validate([
            'full_name' => 'required|string|max:255',
            'gender'    => 'required|string|max:20',
            'birthdate' => 'required|date|before_or_equal:' . now()->subYears(18)->format('Y-m-d') . '|after_or_equal:' . now()->subYears(70)->format('Y-m-d'),
            'shift'     => 'required|string|max:50',
            'photo'     => 'nullable|image|max:2048',
        ]);

        $data = $this->sanitize($request);

        if ($request->hasFile('photo')) {
            $this->deletePreviousImage($teacher->photo_path);
            $data['photo_path'] = $this->uploadAndOptimize($request->file('photo'), 'teachers');
        }

        $teacher->update($data);

        // Handle Assignments
        $assignmentsJson = $request->input('assignments_json', '[]');
        if ($request->has('assignments_json')) {
            $assignments = json_decode($assignmentsJson, true);
            if (is_array($assignments)) {
                // Remove old assignments and create new ones
                \App\Models\TeacherClassSubject::where('teacher_id', $teacher->id)->delete();
                foreach ($assignments as $assignment) {
                    if (!empty($assignment['class_section_id']) && !empty($assignment['subject_id'])) {
                        \App\Models\TeacherClassSubject::create([
                            'teacher_id' => $teacher->id,
                            'class_section_id' => $assignment['class_section_id'],
                            'subject_id' => $assignment['subject_id'],
                            'is_active' => true,
                        ]);
                    }
                }
            }
        }

        $teacher->refresh();
        $teacher->load(['assignments.subject', 'assignments.classSection']);
        $teacher->append(['assigned_subjects', 'assigned_class_sections', 'total_assigned_students']);
        return response()->json($teacher);
    }

    public function destroy(Teacher $teacher)
    {
        if ($teacher->school_id !== auth()->user()->school_id) {
            abort(403, __('Unauthorized access to teacher record'));
        }

        $teacher->delete();
        return response()->json(['deleted' => true]);
    }

    /**
     * استيراد أساتذة من CSV/Excel بنفس منطق الطلاب
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt,xls,xlsx',
        ]);

        $file = $request->file('file');
        $ext  = strtolower($file->getClientOriginalExtension());

        try {
            if (in_array($ext, ['csv', 'txt'])) {
                return $this->importFromCsv($file->getRealPath());
            }

            if (in_array($ext, ['xls', 'xlsx'])) {
                return $this->importFromExcel($file);
            }

            return response()->json(['message' => __('Unsupported file type')], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'message' => __('Import failed'),
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /** تنظيف البيانات القادمة من الـ JS */
    private function sanitize(Request $request): array
    {
        $data = $request->all();

        if (empty($data['full_name'])) {
            abort(422, __('Full name is required'));
        }

        $nullable = [
            'email','phone','gender','birth_governorate','birthdate','qualification','qualification_date',
            'current_school','join_date','current_role','shift','national_id','marital_status',
            'district','neighborhood','street','stage','experience_place','status'
        ];
        foreach ($nullable as $key) {
            if (array_key_exists($key, $data) && $data[$key] === '') {
                $data[$key] = null;
            }
        }

        $ints = ['age','weekly_load','salary','children','students_count','experience_years'];
        foreach ($ints as $key) {
            if (array_key_exists($key, $data)) {
                $data[$key] = ($data[$key] === '' || $data[$key] === null) ? null : (int) $data[$key];
            }
        }

        $floats = ['avg_student_score','attendance_rate'];
        foreach ($floats as $key) {
            if (array_key_exists($key, $data)) {
                $data[$key] = ($data[$key] === '' || $data[$key] === null) ? null : (float) $data[$key];
            }
        }

        $data['subjects'] = $request->input('subjects', []);
        $data['grades']   = $request->input('grades', []);

        // Remove fields that should not be mass-assigned
        unset($data['assignments_json'], $data['_method']);

        return $data;
    }

    /**
     * توليد كود الأستاذ بنمط مؤسسي: [Prefix][SchoolID]-T-[Year]-[Seq]
     */
    protected function generateTeacherCode(): string
    {
        static $currentCount = null;
        static $prefix = null;
        static $year = null;

        if ($currentCount === null) {
            $school = auth()->user()->school;
            $prefix = strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $school->name), 0, 3));
            $prefix = (empty($prefix) ? "EDU" : $prefix) . $school->id;
            $year   = now()->year;
            
            // ضمان التفرد على مستوى المنصة
            $lastCode = Teacher::where('teacher_code', 'like', "$prefix-T-$year-%")
                ->orderBy('teacher_code', 'desc')
                ->value('teacher_code');
                
            if ($lastCode) {
                $parts = explode('-', $lastCode);
                $currentCount = (int)end($parts) + 1;
            } else {
                $currentCount = 1;
            }
        }
        
        return sprintf("%s-T-%d-%04d", $prefix, $year, $currentCount++);
    }

    /**
     * استيراد من CSV
     */
    protected function importFromCsv(string $path)
    {
        if (!is_readable($path)) {
            return response()->json(['message' => __('Cannot read uploaded file')], 422);
        }

        $handle = fopen($path, 'r');
        if (!$handle) {
            return response()->json(['message' => __('Cannot open file')], 422);
        }

        $headers = fgetcsv($handle, 0, ',');
        if (!$headers) {
            fclose($handle);
            return response()->json(['message' => __('Empty file')], 422);
        }

        if (isset($headers[0])) {
            $headers[0] = preg_replace('/^\xEF\xBB\xBF/', '', $headers[0]);
        }

        $headers = array_map(function ($h) {
            return strtolower(trim($h));
        }, $headers);

        $successCount = 0;
        $failedCount = 0;
        
        DB::beginTransaction();
        try {
            while (($row = fgetcsv($handle, 0, ',')) !== false) {
                if (count(array_filter($row, fn($v) => $v !== null && $v !== '')) === 0) {
                    continue;
                }

                $headerCount = count($headers);
                $rowCount    = count($row);

                if ($rowCount < $headerCount) {
                    $row = array_pad($row, $headerCount, null);
                } elseif ($rowCount > $headerCount) {
                    $row = array_slice($row, 0, $headerCount);
                }

                try {
                    $data = array_combine($headers, $row);
                } catch (\Throwable $e) {
                    $failedCount++;
                    continue;
                }

                if (!$data || empty(trim($data['full_name'] ?? ''))) {
                    $failedCount++;
                    continue;
                }

                try {
                    $this->createTeacherFromImportedRow($data);
                    $successCount++;
                } catch (\Exception $e) {
                    $failedCount++;
                }
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            if (isset($handle) && is_resource($handle)) {
                fclose($handle);
            }
            throw $e;
        }

        if (isset($handle) && is_resource($handle)) {
            fclose($handle);
        }

        \App\Models\DashboardNotification::logEvent(
            'teacher_event',
            'Teachers Import',
            'notifications.teachers_imported',
            'System',
            'bi-file-earmark-arrow-up',
            auth()->user()->school_id
        );

        return response()->json([
            'message' => __("Successfully imported :success records, failed :failed.", ['success' => $successCount, 'failed' => $failedCount]),
        ]);
    }

    /**
     * استيراد من Excel (XLS/XLSX)
     */
    protected function importFromExcel($file)
    {
        $sheets = Excel::toArray([], $file);
        if (empty($sheets) || empty($sheets[0])) {
            return response()->json(['message' => __('Empty Excel file')], 422);
        }

        $rows = $sheets[0];

        $headers = $rows[0];
        if (isset($headers[0])) {
            $headers[0] = preg_replace('/^\xEF\xBB\xBF/', '', $headers[0]);
        }

        $headers = array_map(function ($h) {
            return strtolower(trim($h));
        }, $headers);

        $successCount = 0;
        $failedCount = 0;
        
        DB::beginTransaction();
        try {
            for ($i = 1; $i < count($rows); $i++) {
                $row = $rows[$i];

                if (!is_array($row) || count(array_filter($row, fn($v) => $v !== null && $v !== '')) === 0) {
                    continue;
                }

                $headerCount = count($headers);
                $rowCount    = count($row);

                if ($rowCount < $headerCount) {
                    $row = array_pad($row, $headerCount, null);
                } elseif ($rowCount > $headerCount) {
                    $row = array_slice($row, 0, $headerCount);
                }

                try {
                    $data = array_combine($headers, $row);
                } catch (\Throwable $e) {
                    $failedCount++;
                    continue;
                }

                if (!$data || empty(trim($data['full_name'] ?? ''))) {
                    $failedCount++;
                    continue;
                }

                try {
                    $this->createTeacherFromImportedRow($data);
                    $successCount++;
                } catch (\Exception $e) {
                    $failedCount++;
                }
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return response()->json([
            'message' => __("Successfully imported :success records, failed :failed.", ['success' => $successCount, 'failed' => $failedCount]),
            'success' => $successCount,
            'failed'  => $failedCount,
        ]);
    }

    /**
     * إنشاء أستاذ من صف مستورد
     */
    protected function createTeacherFromImportedRow(array $data): void
    {
        if (empty($data['full_name'])) {
            return;
        }

        $teacher = new Teacher();
        $teacher->school_id = auth()->user()->school_id;

        $teacher->full_name    = $data['full_name'] ?? '';
        // نتجاهل أي كود من الملف ونولّد كود جديد لضمان توحيد القاعدة
        $teacher->teacher_code = $this->generateTeacherCode();
        $teacher->email        = $data['email'] ?? null;
        $teacher->phone        = $data['phone'] ?? null;
        $teacher->status       = $data['status'] ?? 'Active';

        $teacher->birthdate    = $data['birthdate'] ?? null;
        $teacher->district     = $data['district'] ?? null;
        $teacher->neighborhood = $data['neighborhood'] ?? null;
        $teacher->street       = $data['street'] ?? null;

        $teacher->avg_student_score = (isset($data['avg_student_score']) && $data['avg_student_score'] !== '')
            ? (float)$data['avg_student_score']
            : null;

        $teacher->attendance_rate = (isset($data['attendance_rate']) && $data['attendance_rate'] !== '')
            ? (float)$data['attendance_rate']
            : null;

        if (!empty($data['subjects'])) {
            $teacher->subjects = array_map('trim', explode(',', $data['subjects']));
        }

        if (!empty($data['grades'])) {
            $teacher->grades = array_map('trim', explode(',', $data['grades']));
        }

        $teacher->save();

        // التزامن التلقائي للتعيينات بناءً على المواد والصفوف المدخلة كـ Tags
        $this->syncTeacherAssignmentsFromTags($teacher);
    }

    /**
     * تزامن التعيينات من النصوص (Tags) إلى سجلات رسمية
     */
    protected function syncTeacherAssignmentsFromTags(Teacher $teacher): void
    {
        $tSubjs = is_array($teacher->subjects) ? $teacher->subjects : [];
        $tGrds  = is_array($teacher->grades) ? $teacher->grades : [];

        if (empty($tSubjs) || empty($tGrds)) return;

        $allSubjects = \App\Models\Subject::all();
        $schoolClasses = \App\Models\ClassSection::where('school_id', $teacher->school_id)->get();

        foreach ($tSubjs as $sVal) {
            $sMatch = $allSubjects->first(fn($s) => 
                strcasecmp($s->name_ar, $sVal) === 0 || 
                strcasecmp($s->name_en, $sVal) === 0 || 
                mb_stripos($s->name_ar, $sVal) !== false
            );
            if (!$sMatch) continue;

            foreach ($tGrds as $gVal) {
                $gNum = preg_replace('/[^0-9]/', '', $gVal);
                $targetClasses = $schoolClasses->filter(fn($c) => (string)$c->grade === (string)$gNum);
                
                foreach ($targetClasses as $cl) {
                    \App\Models\TeacherClassSubject::updateOrCreate(
                        [
                            'teacher_id' => $teacher->id, 
                            'class_section_id' => $cl->id, 
                            'subject_id' => $sMatch->id
                        ],
                        [
                            'weekly_load' => 4, 
                            'is_active' => true
                        ]
                    );
                }
            }
        }
    }
}
