<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class EnsureSchoolIsActive
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::user();

        // If user is super admin, always allow
        if ($user && $user->role === 'super_admin') {
            return $next($request);
        }

        // If user is school admin, check school status
        if ($user && $user->school_id) {
            $school = $user->school;
            
            if ($school->status === 'pending') {
                return response()->view('auth.waiting_approval', [], 403);
            }
            
            if ($school->status === 'suspended') {
                return response()->view('auth.suspended', [], 403);
            }
        }

        return $next($request);
    }
}
