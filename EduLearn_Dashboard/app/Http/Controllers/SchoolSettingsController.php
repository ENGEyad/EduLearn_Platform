<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Traits\HandlesImageUploads;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class SchoolSettingsController extends Controller
{
    use HandlesImageUploads;
    public function index()
    {
        $school = auth()->user()->school;
        return view('settings.school', [
            'school' => $school,
            'pageTitle' => __('School Settings'),
            'pageSubtitle' => __('Manage your school profile and preferences')
        ]);
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
}
