<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SecurityHeaders
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        $reverbHost = trim((string) env('REVERB_HOST', ''));
        $reverbPort = trim((string) env('REVERB_PORT', '8080'));
        $connectSources = [
            "'self'",
            'ws:',
            'wss:',
            '*.pusherapp.com',
            '*.pusher.com',
            'cdn.jsdelivr.net',
        ];

        if ($reverbHost !== '') {
            $connectSources[] = $reverbHost . ':' . $reverbPort;
        }

        // --- Content Security Policy ---
        // Whitelists all known external sources used in the project.
        $csp = implode('; ', [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' cdn.jsdelivr.net js.pusher.com stats.pusher.com",
            "style-src 'self' 'unsafe-inline' cdn.jsdelivr.net fonts.googleapis.com",
            "font-src 'self' fonts.gstatic.com cdn.jsdelivr.net data:",
            "img-src 'self' data: blob: *.googleapis.com storage.googleapis.com",
            'connect-src ' . implode(' ', array_unique($connectSources)),
            "worker-src 'self' blob:",
            "frame-ancestors 'none'",
            "base-uri 'self'",
            "form-action 'self'",
        ]);

        $response->headers->set('Content-Security-Policy', $csp);

        // --- Clickjacking Protection ---
        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');

        // --- MIME Sniffing Protection ---
        $response->headers->set('X-Content-Type-Options', 'nosniff');

        // --- XSS Protection (legacy browsers) ---
        $response->headers->set('X-XSS-Protection', '1; mode=block');

        // --- Referrer Policy ---
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        // --- Permissions Policy ---
        $response->headers->set('Permissions-Policy', 'camera=(), microphone=(), geolocation=(), payment=()');

        // --- HSTS (only on HTTPS) ---
        if ($request->isSecure()) {
            $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        }

        return $response;
    }
}
