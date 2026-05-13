<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class SchoolRegistrationController extends Controller
{
    public function showRegistrationForm()
    {
        return view('auth.login');
    }

    public function register(Request $request)
    {
        $request->validate([
            'school_name'   => 'required|string|max:255',
            'email'         => 'required|email|unique:schools,email|unique:users,email',
            'phone'         => 'required|string|max:20',
            'password'      => 'required|string|min:8|confirmed',
            'admin_name'    => 'required|string|max:255',
            'academic_year' => 'required|string|max:20',
            'school_type'   => 'required|string',
            'country'       => 'required|string|max:100',
            'city'          => 'required|string|max:100',
            'directorate'   => 'required|string|max:100',
            'address'       => 'required|string',
            'website'       => 'nullable|url|max:255',
            'logo'          => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        try {
            $logoPath = null;

            if ($request->hasFile('logo')) {
                $logoPath = $request->file('logo')->store('schools/logos', 'public');
            }

            $school = School::create([
                'name'          => $request->school_name,
                'slug'          => Str::slug($request->school_name),
                'email'         => $request->email,
                'phone'         => $request->phone,
                'status'        => 'pending',
                'academic_year' => $request->academic_year,
                'school_type'   => $request->school_type,
                'country'       => $request->country,
                'city'          => $request->city,
                'directorate'   => $request->directorate,
                'address'       => $request->address,
                'admin_name'    => $request->admin_name,
                'website'       => $request->website,
                'logo_path'     => $logoPath,
            ]);

            User::create([
                'name'      => $request->admin_name,
                'email'     => $request->email,
                'password'  => Hash::make($request->password),
                'school_id' => $school->id,
                'role'      => 'school_admin',
            ]);

            return redirect()->route('login')
                ->with('success', __('Your school registration is pending approval.'));

        } catch (\Exception $e) {
            return back()->withErrors(__('Something went wrong, please try again.'));
        }
    }
}
