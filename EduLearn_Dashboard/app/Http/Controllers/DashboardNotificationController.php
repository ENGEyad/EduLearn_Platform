<?php

namespace App\Http\Controllers;

use App\Models\DashboardNotification;
use Illuminate\Http\Request;

class DashboardNotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = auth()->user();
        $schoolId = $user->school_id;
        
        // 1. School Specific Notifications (Activities)
        $notifications = DashboardNotification::where('school_id', $schoolId)->latest()->paginate(15);

        // 2. System Wide Notifications (Inbox)
        $systemNotifications = \App\Models\SystemNotification::where(function($q) use ($user) {
            $q->where('target_role', 'all')
              ->orWhere('target_role', $user->role);
        })
        ->where(function($q) {
            $q->whereNull('scheduled_at')
              ->orWhere('scheduled_at', '<=', now());
        })
        ->withExists(['reads as is_read' => function($q) use ($user) {
            $q->where('user_id', $user->id);
        }])
        ->latest()
        ->get();

        if ($request->ajax()) {
            return view('notifications.partials.list', compact('notifications'))->render();
        }

        return view('notifications.index', [
            'notifications' => $notifications,
            'systemNotifications' => $systemNotifications,
            'pageTitle' => __('Notifications Center'),
            'pageSubtitle' => __('Manage alerts and system messages')
        ]);
    }

    public function markAsRead($id)
    {
        $schoolId = auth()->user()->school_id;
        $notification = DashboardNotification::where('school_id', $schoolId)->findOrFail($id);
        $notification->update(['is_read' => true]);

        return back()->with('success', __('Notification marked as read'));
    }

    public function markAllAsRead()
    {
        $schoolId = auth()->user()->school_id;
        DashboardNotification::where('school_id', $schoolId)->where('is_read', false)->update(['is_read' => true]);

        return back()->with('success', __('All notifications marked as read'));
    }

    public function clear()
    {
        $schoolId = auth()->user()->school_id;
        DashboardNotification::where('school_id', $schoolId)->delete();

        return back()->with('success', __('Notification history cleared'));
    }

    public function broadcast(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'target' => 'required|in:teachers,students,both',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('broadcasts', 'public');
        }

        \App\Models\SchoolBroadcast::create([
            'school_id' => auth()->user()->school_id,
            'title' => $request->title,
            'message' => $request->message,
            'target' => $request->target,
            'image' => $imagePath,
        ]);

        return back()->with('success', __('Broadcast sent successfully!'));
    }
}
