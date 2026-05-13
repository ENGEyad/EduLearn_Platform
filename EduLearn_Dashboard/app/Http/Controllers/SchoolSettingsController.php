<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Traits\HandlesImageUploads;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class SchoolSettingsController extends Controller
{
    use HandlesImageUploads;

    protected $initService;

    public function __construct(\App\Services\SchoolInitializationService $initService)
    {
        $this->initService = $initService;
    }
    public function index()
    {
        $school = auth()->user()->school;

        if (auth()->user()->role === 'super_admin') {
            return redirect()->route('super-admin.dashboard');
        }

        if (!$school || !$school->is_initialized) {
            return redirect()->route('school-setup.wizard');
        }

        return view('settings.school', [
            'school' => $school,
            'pageTitle' => __('School Settings'),
            'pageSubtitle' => __('Manage your school profile and preferences')
        ]);
    }

    public function showWizard()
    {
        $user = auth()->user();
        $school = $user->school;
        
        if ($user->role === 'super_admin') {
            return redirect()->route('super-admin.dashboard');
        }

        // Allow re-entry to the wizard for configuration fixes
        // if ($school->is_initialized) { ... } // Removed redirect if needed


        // Use Subjects based on school type or all subjects
        $subjects = \App\Models\Subject::where('is_active', true)->get();
        
        return view('settings.wizard', [
            'school' => $school,
            'subjects' => $subjects,
            'pageTitle' => __('System Initialization'),
        ]);
    }

    public function initialize(Request $request)
    {
        $school = auth()->user()->school;

        $request->validate([
            'school_type' => 'required|string|in:Primary,Secondary,Primary/Secondary,Other',
            'section'     => 'nullable|string|in:Scientific,Literary,Scientific/Literary',
            'subject_ids' => 'required|array|min:1',
            'subject_ids.*' => 'exists:subjects,id',
        ]);

        \DB::transaction(function () use ($request, $school) {
            // Update school details
            $school->update([
                'school_type'    => $request->school_type,
                'section'        => $request->section,
                'is_initialized' => true,
            ]);

            // 1. Sync chosen subjects explicitly
            // Clear existing and sync fresh
            $school->subjects()->detach(); 
            $syncData = [];
            foreach ($request->subject_ids as $sid) {
                $syncData[$sid] = ['is_active' => true];
            }
            $school->subjects()->sync($syncData);

            // 2. Setup the academic structure (Classes/Grades) based on the NEW type
            $this->setupSchoolStructure($school, $request->school_type);
        });

        return redirect()->route('dashboard')->with('success', __('School system initialized successfully. Welcome to EduLearn!'));
    }

    protected function setupSchoolStructure(School $school, $type = null)
    {
        $type = $type ?? $school->school_type;
        $startGrade = 1;
        $endGrade = 12;

        if ($type === 'Primary') {
            $endGrade = 6;
        } elseif ($type === 'Secondary') {
            $startGrade = 7;
        }

        // Delete ALL existing sections for a clean start during initialization
        \App\Models\ClassSection::where('school_id', $school->id)->delete();

        // Setup the relevant Grades with Sections A and B
        $sectionMap = ['أ' => 'A', 'ب' => 'B', 'ج' => 'C', 'د' => 'D'];
        for ($gradeNum = $startGrade; $gradeNum <= $endGrade; $gradeNum++) {
            foreach (['أ', 'ب'] as $letter) {
                $engLetter = $sectionMap[$letter] ?? $letter;
                \App\Models\ClassSection::create(
                    [
                        'school_id' => $school->id,
                        'grade'     => $gradeNum,
                        'section'   => $letter,
                        'name'      => "Grade {$gradeNum} - {$engLetter}",
                        'name_en'   => "Grade {$gradeNum} - {$engLetter}",
                        'name_ar'   => "الصف {$gradeNum} - {$letter}",
                        'stage'     => ($gradeNum <= 6) ? 'Primary' : (($gradeNum <= 9) ? 'Middle' : 'Secondary'),
                        'is_active' => true
                    ]
                );
            }
        }
    }

    public function update(Request $request)
    {
        $school = auth()->user()->school;

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:schools,email,' . $school->id,
            'phone' => 'required|string|max:20',
            'academic_year' => 'required|string|max:20',
            'school_type' => 'required|string|max:100',
            'country' => 'required|string|max:100',
            'city' => 'required|string|max:100',
            'directorate' => 'required|string|max:100',
            'website' => 'required|url|max:255',
            'address' => 'required|string',
            'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        $data = $request->except('logo');

        if ($request->hasFile('logo')) {
            $this->deletePreviousImage($school->logo_path);
            $data['logo_path'] = $this->uploadAndOptimize(
                $request->file('logo'),
                'schools/logos',
                maxWidth: 400,
                quality: 85,
                thumbWidth: 80
            );
        }

        $school->update($data);

        return redirect()->back()->with('success', __('School information updated successfully.'));
    }

    public function updatePreferences(Request $request)
    {
        $request->validate([
            'theme_mode' => 'required|in:light,dark',
            'language' => 'required|in:ar,en',
        ]);

        $user = auth()->user();
        $user->update([
            'theme_mode' => $request->theme_mode,
            'language' => $request->language,
        ]);

        session([
            'theme_mode' => $request->theme_mode,
            'language' => $request->language,
        ]);

        return redirect()->back()->with('success', __('Preferences updated successfully.'));
    }

    public function updateSecurity(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'user_name' => 'required|string|max:255',
            'user_email' => 'required|email|unique:users,email,' . $user->id,
            'password' => 'nullable|string|min:8|confirmed',
        ]);

        $data = [
            'name' => $request->user_name,
            'email' => $request->user_email,
        ];

        if ($request->filled('password')) {
            $data['password'] = \Hash::make($request->password);
        }

        $user->update($data);

        return redirect()->back()->with('success', __('Account security settings updated successfully.'));
    }
}
