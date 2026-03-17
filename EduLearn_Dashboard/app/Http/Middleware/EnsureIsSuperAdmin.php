<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class EnsureIsSuperAdmin
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!Auth::check()) {
            return redirect()->route('login')->with('error', 'يرجى تسجيل الدخول أولاً للوصول لهذه المنطقة.');
        }

        if (Auth::user()->role !== 'super_admin') {
            abort(403, 'Unauthorized action. Only super admins can access this area.');
        }

        return $next($request);
    }
}
