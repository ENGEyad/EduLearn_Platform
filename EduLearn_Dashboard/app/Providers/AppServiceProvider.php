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
        \Illuminate\Support\Facades\View::composer('*', function ($view) {
            if (auth()->check()) {
                $schoolId = auth()->user()->school_id;
                $latestNotifications = \App\Models\DashboardNotification::where('school_id', $schoolId)->latest()->take(5)->get();
                $unreadCount = \App\Models\DashboardNotification::where('school_id', $schoolId)->where('is_read', false)->count();
                $view->with('headerNotifications', $latestNotifications);
                $view->with('unreadNotificationsCount', $unreadCount);
            } else {
                $view->with('headerNotifications', collect([]));
                $view->with('unreadNotificationsCount', 0);
            }
        });
        \Illuminate\Support\Facades\Blade::if('branchCan', function ($permission) {
            return auth()->check() && auth()->user()->hasBranchPermission($permission);
        });
    }
}
