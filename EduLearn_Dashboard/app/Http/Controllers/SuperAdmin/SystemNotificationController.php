<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\SystemNotification;
use App\Events\SystemAlertBroadcast;
use Illuminate\Http\Request;

class SystemNotificationController extends Controller
{
    public function index()
    {
        $notifications = SystemNotification::with(['reads.user.school'])
            ->withCount(['reads as unique_reads'])
            ->orderBy('created_at', 'desc')
            ->get();

        foreach ($notifications as $notif) {
            // Find support tickets that were created as responses to this notification
            $notif->responses = \App\Models\SupportTicket::where('subject', 'LIKE', "%{$notif->title}%")
                ->with(['school', 'messages'])
                ->get();
        }

        return view('super_admin.notifications.index', compact('notifications'));
    }

    public function trackRead(Request $request, $id)
    {
        \Illuminate\Support\Facades\Log::info("Tracking read for notification: " . $id);
        $notification = SystemNotification::findOrFail($id);
        $user = auth()->user();
        
        \App\Models\SystemNotificationRead::updateOrCreate(
            ['system_notification_id' => $notification->id, 'user_id' => $user->id],
            [
                'read_at' => now(),
                'interacted' => $request->has('interacted') ? $request->interacted : false,
            ]
        );

        return response()->json(['success' => true]);
    }

    public function getDetails(SystemNotification $notification)
    {
        // Fetch readers using the relationship
        $readers = $notification->reads()->with('user')->get()->map(function($read) {
            return [
                'name' => $read->user->name ?? 'Unknown',
                'email' => $read->user->email ?? '-',
                'read_at' => $read->read_at,
                'interacted' => $read->interacted
            ];
        });

        // Fetch targets who missed it
        $targetRole = $notification->target_role;
        $targetUsers = \App\Models\User::query();
        if ($targetRole !== 'all') $targetUsers->where('role', $targetRole);

        $readUserIds = $notification->reads->pluck('user_id');
        $nonReaders = $targetUsers->whereNotIn('id', $readUserIds)->select('name', 'email')->get();

        return response()->json([
            'success' => true,
            'readers' => $readers,
            'non_readers' => $nonReaders
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'target_role' => 'required|string', // all, school_admin, teacher, student
            'priority' => 'required|in:normal,high,urgent',
            'action_url' => 'nullable|url|max:255',
            'scheduled_at' => 'nullable|date|after_or_equal:now',
            'icon' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:7',
            'expires_at' => 'nullable|date',
        ]);

        $notification = SystemNotification::create($data);

        // Broadcast the notification in real-time
        broadcast(new SystemAlertBroadcast($notification))->toOthers();

        return redirect()->back()->with('success', 'تم إرسال ولث التنبيه اللحظي بنجاح');
    }

    public function destroy(SystemNotification $notification)
    {
        $notification->delete();
        return redirect()->back()->with('success', 'تم حذف التنبيه بنجاح');
    }
}
