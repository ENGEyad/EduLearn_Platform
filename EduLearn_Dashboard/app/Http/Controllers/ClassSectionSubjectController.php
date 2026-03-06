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
            'pageTitle'  => 'Class Subjects',
            'pageSubtitle' => 'Activate subjects per class & section',
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

        $classSection = ClassSection::with('classSubjects')
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

        $classSectionId = $data['class_section_id'];
        $subjectIds     = $data['subject_ids'] ?? [];

        // نشتغل في ترانزاكشن للتأمين
        \DB::transaction(function () use ($classSectionId, $subjectIds) {
            // نحذف كل الربط القديم لهذا الصف/الشعبة
            ClassSectionSubject::where('class_section_id', $classSectionId)->delete();

            // ننشئ الربط الجديد للمواد المختارة
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

            if (!empty($insertData)) {
                ClassSectionSubject::insert($insertData);
            }
        });

        return response()->json([
            'message' => 'Class subjects updated successfully',
        ]);
    }
}
