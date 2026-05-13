<?php

namespace App\Http\Controllers;

use App\Models\SystemSetting;
use App\Models\SupportTicket;
use Illuminate\Http\Request;

class GeneralSupportController extends Controller
{
    public function index()
    {
        $settings = SystemSetting::whereIn('group', ['contact', 'social'])->get()->pluck('value', 'key');
        
        // If the user is a school admin, they might want to see their tickets
        $tickets = [];
        if (auth()->user()->school_id) {
            $tickets = SupportTicket::where('school_id', auth()->user()->school_id)
                ->orderBy('created_at', 'desc')
                ->take(5)
                ->get();
        }

        return view('support', compact('settings', 'tickets'));
    }

    public function storeTicket(Request $request)
    {
        $request->validate([
            'subject' => 'required|string|max:255',
            'message' => 'required|string',
            'priority' => 'required|in:low,normal,high,urgent',
        ]);

        $ticket = SupportTicket::create([
            'school_id' => auth()->user()->school_id,
            'subject' => $request->subject,
            'priority' => $request->priority,
            'status' => 'open',
        ]);

        $ticket->messages()->create([
            'user_id' => auth()->id(),
            'message' => $request->message,
            'is_admin_reply' => false,
        ]);

        return redirect()->back()->with('success', __('Support ticket created successfully. Our team will contact you soon.'));
    }
}
