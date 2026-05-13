<?php

namespace App\Http\Controllers;

use App\Models\ClassSection;
use Illuminate\Http\Request;

class ClassSectionController extends Controller
{
    public function index()
    {
        return view('classes', [
            'pageTitle'         => __('Classes'),
            'pageSubtitle'      => __('Manage classes data'),
            'CLASSES_ROUTES'    => [
                'list'    => route('classes.list'),
                'store'   => route('classes.store'),
                'update'  => route('classes.update', ['class_section' => '__ID__']),
                'destroy' => route('classes.destroy', ['class_section' => '__ID__']),
            ],
        ]);
    }

    public function list()
    {
        return response()->json(
            ClassSection::where('school_id', auth()->user()->school_id)
                ->orderBy('grade')
                ->orderBy('section')
                ->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'grade'      => 'required|string|max:20',
            'section'    => [
                'required',
                'string',
                'max:20',
                function ($attribute, $value, $fail) {
                    if (!$this->isValidSection($value)) {
                        $fail(__('The section must follow the standard sequence (A, B, C... or أبجد، هوز، حطي...)'));
                    }
                },
            ],
            'name'       => 'nullable|string|max:255',
            'name_en'    => 'required|string|max:255',
            'name_ar'    => 'required|string|max:255',
            'stage'      => 'nullable|string|max:100',
            'is_active'  => 'nullable|boolean',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);
        $data['school_id'] = auth()->user()->school_id;
        if (empty($data['name'])) {
            $data['name'] = $data['name_en'];
        }

        $class = ClassSection::create($data);

        return response()->json([
            'message' => __('Class section created successfully'),
            'class'   => $class,
        ]);
    }

    public function update(Request $request, ClassSection $class_section)
    {
        if ($class_section->school_id !== auth()->user()->school_id) {
            abort(403, __('Unauthorized access to class section'));
        }

        $data = $request->validate([
            'grade'      => 'required|string|max:20',
            'section'    => [
                'required',
                'string',
                'max:20',
                function ($attribute, $value, $fail) {
                    if (!$this->isValidSection($value)) {
                        $fail(__('The section must follow the standard sequence (A, B, C... or أبجد، هوز، حطي...)'));
                    }
                },
            ],
            'name'       => 'nullable|string|max:255',
            'name_en'    => 'required|string|max:255',
            'name_ar'    => 'required|string|max:255',
            'stage'      => 'nullable|string|max:100',
            'is_active'  => 'nullable|boolean',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);
        if (empty($data['name'])) {
            $data['name'] = $data['name_en'];
        }

        $class_section->update($data);

        return response()->json([
            'message' => __('Class section updated successfully'),
            'class'   => $class_section,
        ]);
    }

    public function destroy(ClassSection $class_section)
    {
        if ($class_section->school_id !== auth()->user()->school_id) {
            abort(403, __('Unauthorized access to class section'));
        }

        $class_section->delete();

        return response()->json([
            'message' => __('Class section deleted successfully'),
        ]);
    }

    public function import(Request $request)
    {
        $request->validate([
            'csv_file' => 'required|file|mimes:csv,txt'
        ]);

        $file = $request->file('csv_file');
        $handle = fopen($file->getPathname(), 'r');
        $header = fgetcsv($handle); // Read headers

        $successCount = 0;
        $failedCount = 0;
        $schoolId = auth()->user()->school_id;

        \Illuminate\Support\Facades\DB::beginTransaction();

        try {
            while (($row = fgetcsv($handle)) !== false) {
                // headers: grade, section, name_en, name_ar, stage
                if (count($row) < 5) {
                    $failedCount++;
                    continue;
                }

                $grade   = trim($row[0]);
                $section = trim($row[1]);
                $name_en = trim($row[2]);
                $name_ar = trim($row[3]);
                $stage   = trim($row[4]);

                // Validate section logic
                if (!$this->isValidSection($section)) {
                    $failedCount++;
                    continue;
                }

                try {
                    ClassSection::updateOrCreate(
                        [
                            'school_id' => $schoolId,
                            'grade'     => $grade,
                            'section'   => $section
                        ],
                        [
                            'name'      => $name_en, 
                            'name_en'   => $name_en,
                            'name_ar'   => $name_ar,
                            'stage'     => $stage,
                            'is_active' => true
                        ]
                    );
                    $successCount++;
                } catch (\Exception $e) {
                    $failedCount++;
                }
            }
            \Illuminate\Support\Facades\DB::commit();
            fclose($handle);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            fclose($handle);
            return response()->json(['error' => $e->getMessage()], 422);
        }

        \App\Models\DashboardNotification::logEvent(
            'class_event',
            __('Classes Imported'),
            'notifications.classes_imported',
            'System',
            'bi-cloud-upload',
            $schoolId,
            ['count' => $successCount]
        );

        return response()->json([
            'message' => __("Successfully imported :success records, failed :failed.", ['success' => $successCount, 'failed' => $failedCount]),
            'success' => $successCount,
            'failed'  => $failedCount,
        ]);
    }

    /**
     * التحقق من كون الشعبة تتبع التسلسل المعتمد
     */
    private function isValidSection(string $section): bool
    {
        $allowedEn = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
        $allowedAr = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح', 'ط', 'ي', 'ك', 'ل', 'م', 'ن', 'س', 'ع', 'ف', 'ص', 'ق', 'ر', 'ش', 'ت', 'ث', 'خ', 'ذ', 'ض', 'ظ', 'غ'];
        
        // تنظيف النص
        $section = trim($section);
        
        return in_array(strtoupper($section), $allowedEn) || in_array($section, $allowedAr);
    }
}
