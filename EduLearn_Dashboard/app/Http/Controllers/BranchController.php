<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\User;
use App\Models\BranchPermission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class BranchController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        
        if ($user->role === 'super_admin') {
            // Super Admin sees all branches in the system
            $branches = School::whereNotNull('parent_school_id')->get();
        } else {
            $school = $user->school;
            // School Admin sees only branches belonging to their school
            $branches = $school ? School::where('parent_school_id', $school->id)->get() : collect();
        }

        return view('settings.branches.index', compact('branches'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:schools,email',
            'phone' => 'nullable|string',
            'address' => 'nullable|string',
            'admin_name' => 'required|string|max:255',
            'admin_email' => 'required|email|unique:users,email',
            'admin_password' => 'required|string|min:6',
        ]);

        $user = Auth::user();
        $parentSchool = $user->school;
        $parentSchoolId = $parentSchool ? $parentSchool->id : null;
        $logoPath = $parentSchool ? $parentSchool->logo_path : null;

        // 1. Create the Branch School (Pending status)
        $slug = Str::slug($request->name);
        if (empty($slug)) {
            $slug = 'branch-' . Str::random(5);
        }
        $slug .= '-' . rand(100, 999);

        $branch = School::create([
            'name' => $request->name,
            'slug' => $slug,
            'email' => $request->email,
            'phone' => $request->phone,
            'address' => $request->address,
            'logo_path' => $logoPath, // Inherit logo from parent
            'status' => $user->role === 'super_admin' ? 'active' : 'pending',
            'parent_school_id' => $parentSchoolId,
            'admin_name' => $request->admin_name,
        ]);

        // 2. Create the Branch Admin User (Temp Password)
        $tempPassword = $request->admin_password;
        $user = User::create([
            'name' => $request->admin_name,
            'email' => $request->admin_email,
            'password' => Hash::make($tempPassword),
            'role' => 'branch_admin',
            'school_id' => $branch->id, // Important: belongs to the branch
            'branch_id' => $branch->id, // Specifically marks them as an admin of this branch
            'is_temp_password' => true,
            'otp_plain' => $tempPassword,
        ]);

        // In a real app, we would send $tempPassword to the user's email after Super Admin approves.
        // For now, we store it or show it in the response (not secure, but for demo).
        
        return back()->with('success', __('Branch request submitted successfully. Waiting for Super Admin approval.') . ' ' . __('Default password for admin: :password', ['password' => $tempPassword]));
    }

    public function editPermissions(School $branch)
    {
        // Check if this branch belongs to the authenticated school admin's school
        $user = Auth::user();
        $schoolId = $user->school_id;

        if ($user->role !== 'super_admin' && $branch->parent_school_id !== $schoolId) {
            abort(403);
        }

        $branchAdmin = $branch->branchAdmin();
        
        if (!$branchAdmin) {
            return back()->with('error', __('This branch does not have an assigned administrator.'));
        }

        $availablePermissions = BranchPermission::PERMISSIONS;
        $activePermissions = BranchPermission::where('user_id', $branchAdmin->id)
            ->where('granted', true)
            ->pluck('permission')
            ->toArray();

        return view('settings.branches.permissions', compact('branch', 'branchAdmin', 'availablePermissions', 'activePermissions'));
    }

    public function updatePermissions(Request $request, School $branch)
    {
        $user = Auth::user();
        if ($user->role !== 'super_admin' && $branch->parent_school_id !== $user->school_id) {
            abort(403);
        }

        $branchAdmin = $branch->branchAdmin();
        if (!$branchAdmin) {
            return back()->with('error', __('Cannot update permissions: No administrator assigned to this branch.'));
        }

        $permissions = $request->input('permissions', []);

        // Revoke all first or update efficiently
        BranchPermission::where('user_id', $branchAdmin->id)->update(['granted' => false]);

        foreach ($permissions as $permKey) {
            BranchPermission::updateOrCreate(
                ['user_id' => $branchAdmin->id, 'branch_id' => $branch->id, 'permission' => $permKey],
                ['granted' => true]
            );
        }

        return back()->with('success', __('Permissions updated successfully.'));
    }
    /**
     * Show the status of outgoing branch requests.
     */
    public function requests()
    {
        $user = Auth::user();
        if ($user->role === 'super_admin') {
            $branches = School::whereNotNull('parent_school_id')
                ->where('status', 'pending')
                ->orderBy('created_at', 'desc')
                ->get();
        } else {
            $schoolId = $user->school_id;
            $branches = $schoolId ? School::where('parent_school_id', $schoolId)
                ->orderBy('created_at', 'desc')
                ->get() : collect();
        }
            
        return view('settings.branches.requests', compact('branches'));
    }

    /**
     * Delete a pending branch request.
     */
    public function destroy(School $branch)
    {
        // Safety check: must be a branch of this school and still pending
        $user = Auth::user();
        if (($user->role !== 'super_admin' && $branch->parent_school_id !== $user->school_id) || $branch->status !== 'pending') {
            abort(403, 'Unauthorized or request already processed.');
        }

        // Delete the branch school and associated admin user (if any)
        $branch->users()->delete();
        $branch->delete();

        return back()->with('success', __('Branch request deleted successfully.'));
    }
    /**
     * Show the form for editing the specified branch request.
     */
    public function editRequest(School $branch)
    {
        $user = Auth::user();
        if (($user->role !== 'super_admin' && $branch->parent_school_id !== $user->school_id) || $branch->status !== 'pending') {
            abort(403);
        }
        $branchAdmin = $branch->branchAdmin();
        return view('settings.branches.edit_request', compact('branch', 'branchAdmin'));
    }

    /**
     * Update the specified branch request in storage.
     */
    public function updateRequest(Request $request, School $branch)
    {
        $user = Auth::user();
        if (($user->role !== 'super_admin' && $branch->parent_school_id !== $user->school_id) || $branch->status !== 'pending') {
            abort(403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:schools,email,' . $branch->id,
            'phone' => 'nullable|string',
            'address' => 'nullable|string',
            'admin_name' => 'required|string|max:255',
            'admin_password' => 'nullable|string|min:6',
        ]);

        $branch->update([
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'address' => $request->address,
            'admin_name' => $request->admin_name,
        ]);

        // Update branch admin name and password (if provided)
        $branchAdmin = $branch->branchAdmin();
        if ($branchAdmin) {
            $updateData = ['name' => $request->admin_name];
            if ($request->filled('admin_password')) {
                $updateData['password'] = Hash::make($request->admin_password);
                $updateData['is_temp_password'] = true;
                $updateData['otp_plain'] = $request->admin_password;
            }
            $branchAdmin->update($updateData);
        }

        return redirect()->route('settings.branches.requests')->with('success', __('Branch request updated successfully.'));
    }
}
