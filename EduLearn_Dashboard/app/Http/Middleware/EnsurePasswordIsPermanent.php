<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsurePasswordIsPermanent
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (Auth::check() && Auth::user()->is_temp_password) {
            // Avoid infinite redirection loop
            if (!$request->is('auth/force-password-change*') && !$request->is('logout')) {
                return redirect()->route('auth.force-password-change.show')
                    ->with('warning', 'يرجى تغيير كلمة المرور المؤقتة للمتابعة / Please change your temporary password to continue.');
            }
        }

        return $next($request);
    }
}
