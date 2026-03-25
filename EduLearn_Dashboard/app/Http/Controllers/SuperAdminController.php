<?php

namespace App\Http\Controllers;

use App\Models\School;
use Illuminate\Http\Request;

class SuperAdminController extends Controller
{
    public function index()
    {
        $schools = School::orderBy('created_at', 'desc')->get();
        return view('super_admin.dashboard', compact('schools'));
    }

    public function activate(School $school)
    {
        $school->update(['status' => 'active']);
        return back()->with('success', "School '{$school->name}' has been activated successfully.");
    }

    public function suspend(School $school)
    {
        $newStatus = $school->status === 'suspended' ? 'active' : 'suspended';
        $school->update(['status' => $newStatus]);
        
        $msg = $newStatus === 'suspended' ? 'suspended' : 're-activated';
        return back()->with('success', "School '{$school->name}' has been $msg.");
    }

    public function notify(Request $request, School $school)
    {
        $request->validate(['message' => 'required|string']);
        
        // Simulating sending notification (could be email or DB notification)
        return back()->with('success', "Notification sent to '{$school->name}'.");
    }
}
