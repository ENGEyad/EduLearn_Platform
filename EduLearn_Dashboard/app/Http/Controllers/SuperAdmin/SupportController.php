<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use App\Models\SupportMessage;
use Illuminate\Http\Request;

class SupportController extends Controller
{
    public function index()
    {
        $tickets = SupportTicket::with('school')->orderBy('created_at', 'desc')->get();
        return view('super_admin.support.index', compact('tickets'));
    }

    public function show(SupportTicket $ticket)
    {
        $ticket->load(['school', 'messages.user']);
        return view('super_admin.support.show', compact('ticket'));
    }

    public function reply(Request $request, SupportTicket $ticket)
    {
        $request->validate(['message' => 'required|string']);

        SupportMessage::create([
            'ticket_id' => $ticket->id,
            'user_id' => auth()->id(),
            'message' => $request->message,
            'is_admin_reply' => true,
        ]);

        $ticket->update(['status' => 'pending']); // Waiting for user to see the reply

        return redirect()->back()->with('success', 'تم إرسال الرد بنجاح');
    }

    public function close(SupportTicket $ticket)
    {
        $ticket->update(['status' => 'closed']);
        return redirect()->back()->with('success', 'تم إغلاق التذكرة');
    }
}
