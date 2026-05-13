<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ForcePasswordChangeController extends Controller
{
    /**
     * Show the force password change form.
     */
    public function show()
    {
        return view('auth.force_password_change');
    }

    /**
     * Update the user's password and remove the temporary flag.
     */
    public function update(Request $request)
    {
        $user = Auth::user();

        $request->validate([
            'current_password' => ['required', 'current_password'],
            'password' => ['required', 'confirmed', 'min:8'],
        ]);

        $user->update([
            'password' => Hash::make($request->password),
            'is_temp_password' => false,
            'last_password_change' => now(),
            'otp_plain' => null,
        ]);

        return redirect()->intended('/dashboard')->with('success', __('Password updated successfully.'));
    }
}
