<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;

class TeacherController extends Controller
{
    public function index()
    {
        return view('teachers', [
            'pageTitle' => 'Teachers',
            'pageSubtitle' => 'Add, edit and monitor teachers',
            'TEACHERS_ROUTES' => [
                'list'    => route('teachers.list'),
                'store'   => route('teachers.store'),
                'update'  => route('teachers.update', ['teacher' => '__ID__']),
                'destroy' => route('teachers.destroy', ['teacher' => '__ID__']),
                'import'  => route('teachers.import'),
            ],
        ]);
    }

    public function list()
    {
        $teachers = Teacher::with(['assignments.subject', 'assignments.classSection'])
            ->orderBy('id', 'desc')
            ->get();

        return response()->json($teachers);
    }

    public function store(Request $request)
    {
        $request->validate([
            'photo' => 'nullable|image|max:2048',
        ]);

        $data = $this->sanitize($request);

        if (empty($data['teacher_code'])) {
            $data['teacher_code'] = $this->generateTeacherCode();
        }

        // حفظ صورة الأستاذ
        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('teachers', 'public');
            $data['photo_path'] = $path;
        }

        $teacher = Teacher::create($data);
        $teacher->load(['assignments.subject', 'assignments.classSection']);

        return response()->json($teacher, 201);
    }

    public function update(Request $request, Teacher $teacher)
    {
        $request->validate([
            'photo' => 'nullable|image|max:2048',
        ]);

        $data = $this->sanitize($request);

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('teachers', 'public');
            $data['photo_path'] = $path;
        }

        $teacher->update($data);
        $teacher->refresh();
        $teacher->load(['assignments.subject', 'assignments.classSection']);

        return response()->json($teacher);
    }

    public function destroy(Teacher $teacher)
    {
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

            return response()->json(['message' => 'Unsupported file type'], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'Import failed',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /** تنظيف البيانات القادمة من الـ JS */
    private function sanitize(Request $request): array
    {
        $data = $request->all();

        if (empty($data['full_name'])) {
            abort(422, 'full_name is required');
        }

        $nullable = [
            'email','phone','birth_governorate','birthdate','qualification','qualification_date',
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

        return $data;
    }

    protected function generateTeacherCode(): string
    {
        $year = now()->year;
        $rand = rand(100, 999);
        return "T-{$year}-{$rand}";
    }

    /**
     * استيراد من CSV
     */
    protected function importFromCsv(string $path)
    {
        if (!is_readable($path)) {
            return response()->json(['message' => 'Cannot read uploaded file'], 422);
        }

        $handle = fopen($path, 'r');
        if (!$handle) {
            return response()->json(['message' => 'Cannot open file'], 422);
        }

        $headers = fgetcsv($handle, 0, ',');
        if (!$headers) {
            fclose($handle);
            return response()->json(['message' => 'Empty file'], 422);
        }

        if (isset($headers[0])) {
            $headers[0] = preg_replace('/^\xEF\xBB\xBF/', '', $headers[0]);
        }

        $headers = array_map(function ($h) {
            return strtolower(trim($h));
        }, $headers);

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
                    continue;
                }

                if (!$data || empty($data['full_name'])) {
                    continue;
                }

                $this->createTeacherFromImportedRow($data);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            fclose($handle);
            throw $e;
        }

        fclose($handle);

        return response()->json([
            'message' => 'Teachers imported successfully',
        ]);
    }

    /**
     * استيراد من Excel (XLS/XLSX)
     */
    protected function importFromExcel($file)
    {
        $sheets = Excel::toArray([], $file);
        if (empty($sheets) || empty($sheets[0])) {
            return response()->json(['message' => 'Empty Excel file'], 422);
        }

        $rows = $sheets[0];

        $headers = $rows[0];
        if (isset($headers[0])) {
            $headers[0] = preg_replace('/^\xEF\xBB\xBF/', '', $headers[0]);
        }

        $headers = array_map(function ($h) {
            return strtolower(trim($h));
        }, $headers);

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
                    continue;
                }

                if (!$data || empty($data['full_name'])) {
                    continue;
                }

                $this->createTeacherFromImportedRow($data);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return response()->json([
            'message' => 'Teachers imported successfully',
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

        $teacher->full_name    = $data['full_name'] ?? '';
        $teacher->teacher_code = $data['teacher_code'] ?? $this->generateTeacherCode();
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
    }
}
