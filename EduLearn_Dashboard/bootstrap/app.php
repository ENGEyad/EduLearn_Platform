<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->web(append: [
            \App\Http\Middleware\SecurityHeaders::class,
            \App\Http\Middleware\SetUserPreferences::class,
            \App\Http\Middleware\SetLocale::class,
            \App\Http\Middleware\EnsurePasswordIsPermanent::class,
        ]);
        $middleware->alias([
            'school.active' => \App\Http\Middleware\EnsureSchoolIsActive::class,
            'super_admin' => \App\Http\Middleware\EnsureIsSuperAdmin::class,
            'image.cache' => \App\Http\Middleware\SetImageCacheHeaders::class,
            'branch.can' => \App\Http\Middleware\CheckBranchPermission::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
