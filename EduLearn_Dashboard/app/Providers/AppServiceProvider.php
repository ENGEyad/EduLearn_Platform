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
            if (\App\Models\DashboardNotification::class) {
                $latestNotifications = \App\Models\DashboardNotification::latest()->take(5)->get();
                $unreadCount = \App\Models\DashboardNotification::where('is_read', false)->count();
                $view->with('headerNotifications', $latestNotifications);
                $view->with('unreadNotificationsCount', $unreadCount);
            }
        });
    }
}
