<?php

namespace App\Http\Controllers;

use App\Models\ClassSection;
use App\Models\Subject;
use App\Models\ClassSectionSubject;
use Illuminate\Http\Request;

class ClassSectionSubjectController extends Controller
{
    /**
     * صفحة إدارة مواد كل صف/شعبة
     */
    public function index()
    {
        return view('class_subjects', [
            'pageTitle'  => __('Class Subjects'),
            'pageSubtitle' => __('Activate subjects per class & section'),
            'CLASS_SUBJECT_ROUTES' => [
                'list' => route('class-subjects.list'),
                'save' => route('class-subjects.save'),
            ],
            // نعيد استخدام نفس APIs الموجودة في الصفحات الأخرى
            'CLASSES_API'  => route('classes.list'),
            'SUBJECTS_API' => route('subjects.list'),
        ]);
    }

    /**
     * إرجاع قائمة المواد لهذه الـ class_section_id
     * مع فلاغ is_assigned يحدد هل المادة مفعّلة لهذا الصف/الشعبة أم لا.
     *
     * GET /class-subjects/list?class_section_id=ID
     */
    public function list(Request $request)
    {
        $classSectionId = $request->query('class_section_id');

        if (!$classSectionId) {
            return response()->json([]);
        }

        $classSection = ClassSection::where('school_id', auth()->user()->school_id)
            ->with('classSubjects')
            ->findOrFail($classSectionId);

        // نعمل خريطة للمواد المربوطة بهذا الصف/الشعبة
        $assignedMap = $classSection->classSubjects
            ->keyBy('subject_id');

        // نجيب كل المواد (أو ممكن فقط is_active=true لو حبيت)
        $subjects = Subject::orderBy('name_en')
            ->orderBy('code')
            ->get()
            ->map(function (Subject $subject) use ($assignedMap) {
                $pivot = $assignedMap->get($subject->id);

                return [
                    'id'          => $subject->id,
                    'code'        => $subject->code,
                    'name_en'     => $subject->name_en,
                    'name_ar'     => $subject->name_ar,
                    'is_active'   => (bool) $subject->is_active,
                    'is_assigned' => $pivot ? (bool) $pivot->is_active : false,
                ];
            })
            ->values()
            ->all();

        return response()->json($subjects);
    }

    /**
     * حفظ المواد المفعّلة لصف/شعبة معيّن
     * نتوقع JSON مثل:
     * {
     *   "class_section_id": 3,
     *   "subject_ids": [1, 2, 5]
     * }
     */
    public function save(Request $request)
    {
        $data = $request->validate([
            'class_section_id' => 'required|exists:class_sections,id',
            'subject_ids'      => 'array',
            'subject_ids.*'    => 'integer|exists:subjects,id',
        ]);

        $classSection = ClassSection::where('school_id', auth()->user()->school_id)
            ->findOrFail($data['class_section_id']);

        $classSectionId = $classSection->id;
        $subjectIds     = $data['subject_ids'] ?? [];

        // نشتغل في ترانزاكشن للتأمين
        try {
            \DB::transaction(function () use ($classSection, $classSectionId, $subjectIds) {
                // 1. نحذف كل الربط القديم لهذا الصف/الشعبة في جدول class_section_subjects
                ClassSectionSubject::where('class_section_id', $classSectionId)->delete();

                if (!empty($subjectIds)) {
                    $insertData = [];
                    foreach ($subjectIds as $sid) {
                        $insertData[] = [
                            'class_section_id' => $classSectionId,
                            'subject_id'       => $sid,
                            'is_active'        => true,
                            'created_at'       => now(),
                            'updated_at'       => now(),
                        ];
                    }
                    ClassSectionSubject::insert($insertData);

                    // 2. تحديث جدول school_subjects: نضمن أن أي مادة تم إضافتها لصف موجودة أيضاً في قائمة مواد المدرسة
                    $school = $classSection->school;
                    if ($school) {
                        // نجلب المواد الموجودة حالياً لتجنب التكرار
                        $currentSchoolSubjects = $school->subjects()->pluck('subjects.id')->toArray();
                        $newToSchool = array_diff($subjectIds, $currentSchoolSubjects);

                        if (!empty($newToSchool)) {
                            $syncData = [];
                            foreach ($newToSchool as $sid) {
                                $syncData[$sid] = ['is_active' => true];
                            }
                            $school->subjects()->attach($syncData);
                        }
                    }
                }
            });

            return response()->json([
                'message' => __('Class subjects updated successfully'),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error saving class subjects: ' . $e->getMessage()
            ], 500);
        }
    }
}
