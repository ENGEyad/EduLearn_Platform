<?php

namespace App\Http\Controllers;

use App\Models\DashboardNotification;
use Illuminate\Http\Request;

class DashboardNotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = DashboardNotification::latest()->paginate(15);

        if ($request->ajax()) {
            return view('notifications.partials.list', compact('notifications'))->render();
        }

        return view('notifications.index', [
            'notifications' => $notifications,
            'pageTitle' => __('System Alerts'),
            'pageSubtitle' => __('Latest events and activities from teachers and students')
        ]);
    }

    public function markAsRead($id)
    {
        $notification = DashboardNotification::findOrFail($id);
        $notification->update(['is_read' => true]);

        return back()->with('success', 'تم تحديد التنبيه كمقروء');
    }

    public function markAllAsRead()
    {
        DashboardNotification::where('is_read', false)->update(['is_read' => true]);

        return back()->with('success', 'تم تحديد جميع التنبيهات كمقروءة');
    }

    public function clear()
    {
        DashboardNotification::truncate();

        return back()->with('success', 'تم مسح سجل التنبيهات');
    }
}
