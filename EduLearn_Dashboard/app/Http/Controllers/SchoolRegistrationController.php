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
        return view('auth.register_school');
    }

    public function register(Request $request)
    {
        $request->validate([
            'school_name' => 'required|string|max:255',
            'email' => 'required|email|unique:schools,email|unique:users,email',
            'phone' => 'required|string|max:20',
            'password' => 'required|string|min:8|confirmed',
            'admin_name' => 'required|string|max:255',
        ]);

        $school = School::create([
            'name' => $request->school_name,
            'slug' => Str::slug($request->school_name),
            'email' => $request->email,
            'phone' => $request->phone,
            'status' => 'pending', // Waiting for super admin approval
        ]);

        $user = User::create([
            'name' => $request->admin_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'school_id' => $school->id,
            'role' => 'school_admin',
        ]);

        // Set a long-lived cookie to remember this device has registered a school
        $cookie = cookie('school_setup_completed', 'true', 60 * 24 * 365 * 5); // 5 years

        return redirect()->route('login')
            ->with('success', 'Your school registration is pending approval by our support team.')
            ->withCookie($cookie);
    }
}
