<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Sets aggressive cache headers for static image assets served from storage.
 * Browser will cache images for 7 days, avoiding repeat downloads.
 */
class SetImageCacheHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Only apply to image content types
        $contentType = $response->headers->get('Content-Type', '');
        if (str_starts_with($contentType, 'image/')) {
            $response->headers->set('Cache-Control', 'public, max-age=604800, immutable');
        }

        return $response;
    }
}
