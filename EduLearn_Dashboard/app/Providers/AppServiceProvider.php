<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // ⚡ Bolt: Optimize view composer to avoid redundant DB queries on every partial render.
        // We target only 'layouts.app' instead of '*' as these variables are only used there.
        \Illuminate\Support\Facades\View::composer('layouts.app', function ($view) {
            static $cachedData = null;

            if ($cachedData === null) {
                if (auth()->check()) {
                    $schoolId = auth()->user()->school_id;
                    $cachedData = [
                        'latest' => \App\Models\DashboardNotification::where('school_id', $schoolId)->latest()->take(5)->get(),
                        'unread' => \App\Models\DashboardNotification::where('school_id', $schoolId)->where('is_read', false)->count(),
                    ];
                } else {
                    $cachedData = [
                        'latest' => collect([]),
                        'unread' => 0,
                    ];
                }
            }

            $view->with('headerNotifications', $cachedData['latest']);
            $view->with('unreadNotificationsCount', $cachedData['unread']);
        });
        \Illuminate\Support\Facades\Blade::if('branchCan', function ($permission) {
            return auth()->check() && auth()->user()->hasBranchPermission($permission);
        });
    }
}
