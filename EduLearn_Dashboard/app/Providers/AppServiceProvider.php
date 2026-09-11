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
                // Memoize notification query results per request to avoid executing DB queries on every rendered Blade partial
                $data = once(function () use ($schoolId) {
                    return [
                        'latest' => \App\Models\DashboardNotification::where('school_id', $schoolId)->latest()->take(5)->get(),
                        'unread' => \App\Models\DashboardNotification::where('school_id', $schoolId)->where('is_read', false)->count(),
                    ];
                });
                $view->with('headerNotifications', $data['latest']);
                $view->with('unreadNotificationsCount', $data['unread']);
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
