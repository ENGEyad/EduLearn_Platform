<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Mail\SchoolApproved;
use App\Mail\SchoolRejected;
use App\Mail\ModificationRequested;
use App\Events\SchoolStatusUpdated;
use App\Services\SchoolInitializationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class SuperAdminController extends Controller
{
    protected $initService;

    public function __construct(SchoolInitializationService $initService)
    {
        $this->initService = $initService;
    }

    public function index()
    {
        $schools = School::orderBy('created_at', 'desc')->get();
        
        $stats = [
            'total'           => $schools->count(),
            'main_schools'    => $schools->whereNull('parent_school_id')->count(),
            'branches'        => $schools->whereNotNull('parent_school_id')->count(),
            'pending'         => $schools->where('status', 'pending')->count(),
            'active'          => $schools->where('status', 'active')->count(),
            'suspended'       => $schools->where('status', 'suspended')->count(),
            'rejected'        => $schools->where('status', 'rejected')->count(),
        ];

        return view('super_admin.dashboard', compact('schools', 'stats'));
    }

    public function approve(School $school)
    {
        $school->update([
            'status' => 'active',
            'rejection_reason' => null
        ]);

        Mail::to($school->email)->send(new SchoolApproved($school));
        
        event(new SchoolStatusUpdated($school, "Your school '{$school->name}' has been approved and activated!"));

        return back()->with('success', "School '{$school->name}' has been approved and activated.");
    }

    public function reject(Request $request, School $school)
    {
        $request->validate([
            'reason' => 'required|string|max:1000',
        ]);

        $school->update([
            'status' => 'rejected',
            'rejection_reason' => $request->reason
        ]);

        Mail::to($school->email)->send(new SchoolRejected($school, $request->reason));

        event(new SchoolStatusUpdated($school, "Your school registration has been rejected. Reason: {$request->reason}"));

        return back()->with('success', "School '{$school->name}' has been rejected.");
    }

    public function requestModification(Request $request, School $school)
    {
        $request->validate([
            'instructions' => 'required|string|max:1000',
        ]);

        // Keep as pending but store modification instructions in rejection_reason field
        $school->update([
            'status' => 'pending', 
            'rejection_reason' => $request->instructions
        ]);

        Mail::to($school->email)->send(new ModificationRequested($school, $request->instructions));

        event(new SchoolStatusUpdated($school, "Update Required: {$request->instructions}"));

        return back()->with('info', "Modification request sent to '{$school->name}'.");
    }

    public function activate(School $school)
    {
        $school->update(['status' => 'active']);
        
        return back()->with('success', "School '{$school->name}' has been activated.");
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
