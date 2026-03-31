<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SetUserPreferences
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (auth()->check()) {
            $user = auth()->user();
            // Sync from DB if session is empty or out of sync
            if (!session()->has('theme_mode')) {
                session(['theme_mode' => $user->theme_mode]);
            }
            if (!session()->has('language')) {
                session(['language' => $user->language]);
                app()->setLocale($user->language);
            }
        }

        // Apply from session (for both guests and auth users)
        $lang = session('language', 'ar');
        app()->setLocale($lang);
        
        // Share with all views
        view()->share('themeMode', session('theme_mode', 'light'));
        view()->share('currentLocale', $lang);

        return $next($request);
    }
}
