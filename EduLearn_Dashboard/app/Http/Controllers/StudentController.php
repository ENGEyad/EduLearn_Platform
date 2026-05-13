<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\ClassSection;
use App\Traits\HandlesImageUploads;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;

class StudentController extends Controller
{
    use HandlesImageUploads;
    /**
     * عرض صفحة الطلاب (الواجهة)
     */
    public function index()
    {
        $schoolId = auth()->user()->school_id;
        $grades = \App\Models\ClassSection::where('school_id', $schoolId)->select('grade')->distinct()->pluck('grade');
        $allSections = \App\Models\ClassSection::where('school_id', $schoolId)->orderBy('grade')->orderBy('section')->get();
        
        return view('students', [
            'title'        => 'Students – EduLearn',
            'pageTitle'    => __('Student Management'),
            'pageSubtitle' => __('Manage school students, status and profiles'),
            'grades'       => $grades,
            'allSections'  => $allSections,
        ]);
    }

    /**
     * إرجاع قائمة الطلاب JSON للـ JS (مفلترة حسب المدرسة)
     */
    public function list()
    {
        // نختار كل الأعمدة ما عدا photo_data لأن حجمها كبير جداً وتعطل المتصفح في القائمة
        return Student::where('school_id', auth()->user()->school_id)
            ->select('id', 'school_id', 'full_name', 'academic_id', 'gender', 'birthdate', 'email', 'status', 'grade', 'class_section', 'class_section_id', 'address_governorate', 'address_city', 'address_street', 'guardian_name', 'guardian_relation', 'guardian_relation_other', 'guardian_phone', 'performance_avg', 'attendance_rate', 'photo_path', 'photo_mime', 'notes', 'created_at', 'updated_at')
            ->orderBy('id', 'desc')
            ->get();
    }

    /**
     * توليد رقم أكاديمي فريد بنمط مؤسسي: [Prefix][SchoolID]-S-[Year]-[Grade]-[Section]-[Seq]
     */
    protected function generateAcademicId(?string $gradeRaw = null, ?string $classSection = null): string
    {
        $school = auth()->user()->school;
        $prefix = strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $school->name), 0, 3));
        $prefix = (empty($prefix) ? "EDU" : $prefix) . $school->id;
        $year   = now()->year;
        
        $gradeCode = $gradeRaw ? 'G' . preg_replace('/[^0-9]/', '', $gradeRaw) : 'GX';
        $sectionCode = $classSection ? strtoupper($classSection) : 'X';

        // للبحث عن آخر رقم تسلسلي لهذا النمط (المدرسة + السنة + الصف + الشعبة)
        $pattern = "$prefix-S-$year-$gradeCode-$sectionCode-%";
        $lastId = Student::where('academic_id', 'like', $pattern)
            ->orderBy('id', 'desc')
            ->value('academic_id');
            
        if ($lastId) {
            $parts = explode('-', $lastId);
            $currentCount = (int)end($parts) + 1;
        } else {
            $currentCount = 1;
        }
        
        return sprintf("%s-S-%d-%s-%s-%04d", $prefix, $year, $gradeCode, $sectionCode, $currentCount);
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
            'gender'                  => 'required|string|max:20',
            'birthdate'               => 'required|date|before_or_equal:' . now()->subYears(3)->format('Y-m-d') . '|after_or_equal:' . now()->subYears(22)->format('Y-m-d'),
            'status'                  => 'nullable|string|max:50',
            'email'                   => 'nullable|email|max:255',
            'grade'                   => 'required|string|max:100',
            'class_section'           => 'required|string|max:50',
            'address_governorate'     => 'nullable|string|max:100',
            'address_city'            => 'nullable|string|max:100',
            'address_street'          => 'nullable|string|max:150',
            'guardian_name'           => 'required|string|max:255',
            'guardian_relation'       => 'nullable|string|max:100',
            'guardian_relation_other' => 'nullable|string|max:100',
            'guardian_phone'          => 'required|string|max:50',
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
        $student->academic_id = $this->generateAcademicId($grade, $classSection);
        $student->school_id   = auth()->user()->school_id;

        // حفظ الصورة في قاعدة البيانات بشكل محسّن (WebP)
        if ($request->hasFile('photo')) {
            $optimized = $this->optimizeToBinary($request->file('photo'), 400, 75);
            $student->photo_data = $optimized['data'];
            $student->photo_mime = $optimized['mime'];
            $student->photo_path = null; // نلغي المسار القديم لأنه أصبح مخزناً في الداتا
        }

        $student->save();

        return response()->json($student, 201);
    }

    /**
     * تحديث طالب موجود
     */
    public function update(Request $request, Student $student)
    {
        if ($student->school_id !== auth()->user()->school_id) {
            abort(403, __('Unauthorized access to student record'));
        }

        $validated = $request->validate([
            'full_name'               => 'required|string|max:255',
            'gender'                  => 'required|string|max:20',
            'birthdate'               => 'required|date|before_or_equal:' . now()->subYears(3)->format('Y-m-d') . '|after_or_equal:' . now()->subYears(22)->format('Y-m-d'),
            'status'                  => 'nullable|string|max:50',
            'email'                   => 'nullable|email|max:255',
            'grade'                   => 'required|string|max:100',
            'class_section'           => 'required|string|max:50',
            'address_governorate'     => 'nullable|string|max:100',
            'address_city'            => 'nullable|string|max:100',
            'address_street'          => 'nullable|string|max:150',
            'guardian_name'           => 'required|string|max:255',
            'guardian_relation'       => 'nullable|string|max:100',
            'guardian_relation_other' => 'nullable|string|max:100',
            'guardian_phone'          => 'required|string|max:50',
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

        // لو فيه صورة جديدة → نحسنها ونحفظها في قاعدة البيانات وننظف المسار القديم
        if ($request->hasFile('photo')) {
            // حذف الصورة القديمة من الاستورج لو كانت موجودة لتقليل المساحة
            if ($student->photo_path) {
                $this->deletePreviousImage($student->photo_path);
            }

            $optimized = $this->optimizeToBinary($request->file('photo'), 400, 75);
            $student->photo_data = $optimized['data'];
            $student->photo_mime = $optimized['mime'];
            $student->photo_path = null;
        }

        $student->save();

        return response()->json($student);
    }

    /**
     * حذف طالب
     */
    public function destroy(Student $student)
    {
        if ($student->school_id !== auth()->user()->school_id) {
            abort(403, __('Unauthorized access to student record'));
        }

        $student->delete();

        return response()->json([
            'message' => __('Student deleted successfully'),
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

            return response()->json(['message' => __('Unsupported file type')], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'message' => __('Import failed'),
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

        // إزالة BOM من أول عمود لو فيه
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
                    $this->createStudentFromImportedRow($data);
                    $successCount++;
                } catch (\Exception $e) {
                    $failedCount++;
                }
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            fclose($handle);
            throw $e;
        }

        fclose($handle);

        return response()->json([
            'message' => __("Successfully imported :success records, failed :failed.", ['success' => $successCount, 'failed' => $failedCount]),
            'success' => $successCount,
            'failed'  => $failedCount,
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

        $rows = $sheets[0]; // أول شيت

        // أول صف = الهيدر
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
                    $this->createStudentFromImportedRow($data);
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
     * دالة مشتركة لإنشاء الطالب من سطر مستورد (CSV/Excel)
     */
    protected function createStudentFromImportedRow(array $data): void
    {
        $student = new Student();
        $student->school_id = auth()->user()->school_id;

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

        // academic_id: نتجاهل أي قيمة في الملف ونولّد رقم جديد دائماً لضمان توحيد القاعدة
        $student->academic_id = $this->generateAcademicId($grade, $classSection);

        // الاستيراد الآن لا يتعامل مع الصور (photo_path)
        $student->save();
    }

    /**
     * عرض صورة الطالب مباشرة من قاعدة البيانات
     */
    public function showPhoto(Student $student)
    {
        if ($student->school_id !== auth()->user()->school_id) {
            abort(403);
        }

        if (!$student->photo_data) {
            // لو مفيش داتا في الـ blob، نشوف لو لسه فيه مسار قديم (للتوافق مع البيانات القديمة)
            if ($student->photo_path) {
                return redirect(asset('storage/' . $student->photo_path));
            }
            abort(404);
        }

        return response($student->photo_data)
            ->header('Content-Type', $student->photo_mime ?: 'image/jpeg')
            ->header('Cache-Control', 'public, max-age=86400');
    }
}
