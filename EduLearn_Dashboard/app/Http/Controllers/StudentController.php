<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\ClassSection;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;

class StudentController extends Controller
{
    /**
     * عرض صفحة الطلاب (الواجهة)
     */
    public function index()
    {
        return view('students', [
            'title'        => 'Students – EduLearn',
            'pageTitle'    => 'Student Management',
            'pageSubtitle' => 'Manage school students, status and profiles',
        ]);
    }

    /**
     * إرجاع قائمة الطلاب JSON للـ JS
     */
    public function list()
    {
        return Student::orderBy('id', 'desc')->get();
    }

    /**
     * توليد رقم أكاديمي فريد
     */
    protected function generateAcademicId(): string
    {
        do {
            $id = 'S-' . now()->year . '-' . strtoupper(Str::random(4));
        } while (Student::where('academic_id', $id)->exists());

        return $id;
    }

    /**
     * Normalize grade + class_section مثل: "5/ب" → grade = "Grade 5", class_section = "ب"
     */
    protected function normalizeGradeAndSection(?string $gradeRaw, ?string $classSectionRaw = null): array
    {
        $grade = null;
        $classSection = $classSectionRaw;

        if ($gradeRaw) {
            $gradeRaw = trim($gradeRaw);

            // لو class_section فاضي وفي grade فيها "/" مثل 5/أ أو 5/A
            if ((empty($classSectionRaw) || $classSectionRaw === null) && str_contains($gradeRaw, '/')) {
                [$g, $sec] = array_pad(explode('/', $gradeRaw, 2), 2, null);
                $gradeRaw = trim($g);
                $classSection = $sec ? trim($sec) : null;
            }

            // نحول الأرقام العربية لأرقام إنجليزية
            $gradeDigits = strtr($gradeRaw, [
                '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
                '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
            ]);

            // نزيل أي كلمة Grade أو صف لو كانت موجودة
            $gradeDigits = preg_replace('/[^0-9]/', '', $gradeDigits);

            if ($gradeDigits !== '') {
                $grade = 'Grade ' . (int)$gradeDigits;
            }
        }

        return [$grade, $classSection];
    }

    /**
     * محاولة إيجاد class_section_id من grade + class_section النصية
     * مثال: grade = "Grade 5", classSection = "A"
     */
    protected function resolveClassSectionId(?string $grade, ?string $classSection): ?int
    {
        if (!$grade || !$classSection) {
            return null;
        }

        // استخراج رقم الصف من النص "Grade 5"
        $gradeDigits = preg_replace('/[^0-9]/', '', $grade);
        if ($gradeDigits === '') {
            return null;
        }

        return ClassSection::where('grade', $gradeDigits)
            ->where('section', $classSection)
            ->value('id');
    }

    /**
     * تخزين طالب جديد
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'full_name'               => 'required|string|max:255',
            'gender'                  => 'nullable|string|max:20',
            'birthdate'               => 'nullable|date',
            'status'                  => 'nullable|string|max:50',
            'email'                   => 'nullable|email|max:255',
            'grade'                   => 'nullable|string|max:100',
            'class_section'           => 'nullable|string|max:50',
            'address_governorate'     => 'nullable|string|max:100',
            'address_city'            => 'nullable|string|max:100',
            'address_street'          => 'nullable|string|max:150',
            'guardian_name'           => 'nullable|string|max:255',
            'guardian_relation'       => 'nullable|string|max:100',
            'guardian_relation_other' => 'nullable|string|max:100',
            'guardian_phone'          => 'nullable|string|max:50',
            'notes'                   => 'nullable|string|max:500',
            'photo'                   => 'nullable|image|max:2048', // صورة الطالب
        ]);

        // نطبّق نفس منطق Grade 1 / A
        [$grade, $classSection] = $this->normalizeGradeAndSection(
            $validated['grade'] ?? null,
            $validated['class_section'] ?? null
        );

        // نحاول ربط الطالب بالصف/الشعبة الحقيقي من جدول class_sections
        $classSectionId = $this->resolveClassSectionId($grade, $classSection);

        $student = new Student();
        $student->full_name               = $validated['full_name'];
        $student->gender                  = $validated['gender'] ?? null;
        $student->birthdate               = $validated['birthdate'] ?? null;
        $student->status                  = $validated['status'] ?? 'Active';
        $student->email                   = $validated['email'] ?? null;
        $student->grade                   = $grade;
        $student->class_section           = $classSection;
        $student->class_section_id        = $classSectionId;
        $student->address_governorate     = $validated['address_governorate'] ?? null;
        $student->address_city            = $validated['address_city'] ?? null;
        $student->address_street          = $validated['address_street'] ?? null;
        $student->guardian_name           = $validated['guardian_name'] ?? null;
        $student->guardian_relation       = $validated['guardian_relation'] ?? null;
        $student->guardian_relation_other = $validated['guardian_relation_other'] ?? null;
        $student->guardian_phone          = $validated['guardian_phone'] ?? null;
        $student->notes                   = $validated['notes'] ?? null;

        // توليد رقم أكاديمي
        $student->academic_id = $this->generateAcademicId();

        // حفظ الصورة إن وُجدت
        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('students', 'public');
            $student->photo_path = $path;
        }

        $student->save();

        return response()->json($student, 201);
    }

    /**
     * تحديث طالب موجود
     */
    public function update(Request $request, Student $student)
    {
        $validated = $request->validate([
            'full_name'               => 'required|string|max:255',
            'gender'                  => 'nullable|string|max:20',
            'birthdate'               => 'nullable|date',
            'status'                  => 'nullable|string|max:50',
            'email'                   => 'nullable|email|max:255',
            'grade'                   => 'nullable|string|max:100',
            'class_section'           => 'nullable|string|max:50',
            'address_governorate'     => 'nullable|string|max:100',
            'address_city'            => 'nullable|string|max:100',
            'address_street'          => 'nullable|string|max:150',
            'guardian_name'           => 'nullable|string|max:255',
            'guardian_relation'       => 'nullable|string|max:100',
            'guardian_relation_other' => 'nullable|string|max:100',
            'guardian_phone'          => 'nullable|string|max:50',
            'notes'                   => 'nullable|string|max:500',
            'photo'                   => 'nullable|image|max:2048',
        ]);

        [$grade, $classSection] = $this->normalizeGradeAndSection(
            $validated['grade'] ?? null,
            $validated['class_section'] ?? null
        );

        $classSectionId = $this->resolveClassSectionId($grade, $classSection);

        $student->full_name               = $validated['full_name'];
        $student->gender                  = $validated['gender'] ?? null;
        $student->birthdate               = $validated['birthdate'] ?? null;
        $student->status                  = $validated['status'] ?? 'Active';
        $student->email                   = $validated['email'] ?? null;
        $student->grade                   = $grade;
        $student->class_section           = $classSection;
        $student->class_section_id        = $classSectionId;
        $student->address_governorate     = $validated['address_governorate'] ?? null;
        $student->address_city            = $validated['address_city'] ?? null;
        $student->address_street          = $validated['address_street'] ?? null;
        $student->guardian_name           = $validated['guardian_name'] ?? null;
        $student->guardian_relation       = $validated['guardian_relation'] ?? null;
        $student->guardian_relation_other = $validated['guardian_relation_other'] ?? null;
        $student->guardian_phone          = $validated['guardian_phone'] ?? null;
        $student->notes                   = $validated['notes'] ?? null;

        // لو فيه صورة جديدة نحدّث المسار فقط (ما نحذف القديمة الآن)
        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('students', 'public');
            $student->photo_path = $path;
        }

        $student->save();

        return response()->json($student);
    }

    /**
     * حذف طالب
     */
    public function destroy(Student $student)
    {
        $student->delete();

        return response()->json([
            'message' => 'Student deleted successfully',
        ]);
    }

    /**
     * استيراد طلاب من ملف (CSV أو Excel)
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

        // إزالة BOM من أول عمود لو فيه
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

                $this->createStudentFromImportedRow($data);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            fclose($handle);
            throw $e;
        }

        fclose($handle);

        return response()->json([
            'message' => 'Students imported successfully',
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

        $rows = $sheets[0]; // أول شيت

        // أول صف = الهيدر
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

                $this->createStudentFromImportedRow($data);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return response()->json([
            'message' => 'Students imported successfully',
        ]);
    }

    /**
     * دالة مشتركة لإنشاء الطالب من سطر مستورد (CSV/Excel)
     */
    protected function createStudentFromImportedRow(array $data): void
    {
        $student = new Student();

        $student->full_name = $data['full_name'] ?? '';
        $student->gender    = $data['gender'] ?? null;
        $student->birthdate = $data['birthdate'] ?? null;

        $statusFromFile = $data['status'] ?? 'Active';
        if ($statusFromFile) {
            $statusFromFile = ucfirst(strtolower(trim($statusFromFile)));
        }
        $student->status = $statusFromFile ?: 'Active';

        // grade + class_section
        $gradeRaw        = $data['grade'] ?? null;
        $classSectionRaw = $data['class_section'] ?? null;
        [$grade, $classSection] = $this->normalizeGradeAndSection($gradeRaw, $classSectionRaw);

        $classSectionId = $this->resolveClassSectionId($grade, $classSection);

        $student->email               = $data['email'] ?? null;
        $student->grade               = $grade;
        $student->class_section       = $classSection;
        $student->class_section_id    = $classSectionId;
        $student->address_governorate = $data['address_governorate'] ?? null;
        $student->address_city        = $data['address_city'] ?? null;
        $student->address_street      = $data['address_street'] ?? null;
        $student->guardian_name       = $data['guardian_name'] ?? null;
        $student->guardian_relation   = $data['guardian_relation'] ?? null;
        $student->guardian_relation_other = $data['guardian_relation_other'] ?? null;
        $student->guardian_phone      = $data['guardian_phone'] ?? null;

        // performance/attendance لو موجودين في الملف
        $student->performance_avg = (isset($data['performance_avg']) && $data['performance_avg'] !== '')
            ? (float)$data['performance_avg']
            : null;

        $student->attendance_rate = (isset($data['attendance_rate']) && $data['attendance_rate'] !== '')
            ? (float)$data['attendance_rate']
            : null;

        $student->notes = $data['notes'] ?? null;

        // academic_id: لو موجود نستخدمه، غير كذا نولّد
        if (!empty($data['academic_id'])) {
            $student->academic_id = $data['academic_id'];
        } else {
            $student->academic_id = $this->generateAcademicId();
        }

        // الاستيراد الآن لا يتعامل مع الصور (photo_path)
        $student->save();
    }
}
