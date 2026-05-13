<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckBranchPermission
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = auth()->user();

        if (!$user) {
            return redirect()->route('login');
        }

        // Super Admin and School Admin have full access
        if ($user->role === 'super_admin' || $user->role === 'school_admin') {
            return $next($request);
        }

        // Branch Admin needs specific permission
        if ($user->role === 'branch_admin') {
            // If they have the permission granted
            if (\App\Models\BranchPermission::userHas($user->id, $user->branch_id, $permission)) {
                return $next($request);
            }
        }

        if ($request->ajax() || $request->wantsJson()) {
            return response()->json(['error' => 'Forbidden', 'message' => __('Unauthorized access.')], 403);
        }

        abort(403, __('You do not have permission to access this module. Please contact your school administrator.'));
    }
}
