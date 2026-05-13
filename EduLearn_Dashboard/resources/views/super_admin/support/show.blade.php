@extends('super_admin.layout')
@section('title', __('Ticket Details'))

@push('styles')
<style>
    .chat-bubble { max-width: 80%; padding: 1.25rem 1.5rem; border-radius: 20px; position: relative; margin-bottom: 20px; backdrop-filter: blur(12px); box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
    .bubble-admin { background: rgba(255,102,0,0.1); color: var(--orange); border: 1px solid rgba(255,102,0,0.2); margin-inline-end: auto; border-bottom-left-radius: 4px; }
    [dir="rtl"] .bubble-admin { border-bottom-left-radius: 20px; border-bottom-right-radius: 4px; }
    .bubble-school { background: var(--navy-card); color: var(--text); border: 1px solid var(--border); margin-inline-start: auto; border-bottom-right-radius: 4px; }
    [dir="rtl"] .bubble-school { border-bottom-right-radius: 20px; border-bottom-left-radius: 4px; }
    .x-small { font-size: 0.75rem; }
</style>
@endpush

@section('content')
<div class="sa-header">
    <div class="d-flex align-items-center gap-3">
        <a href="{{ route('super-admin.support.index') }}" class="sa-btn sa-btn-outline p-2 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; border-radius: 50%;">
            <i class="bi bi-arrow-right"></i>
        </a>
        <div>
            <h1>{{ $ticket->subject }}</h1>
            <p>{{ __('Ticket from') }}: <strong>{{ $ticket->school->name }}</strong> | {{ __('Status') }}: <strong>{{ $ticket->status }}</strong></p>
        </div>
    </div>
</div>

<div class="mb-5">
    @foreach($ticket->messages as $msg)
        <div class="chat-bubble {{ $msg->is_admin_reply ? 'bubble-admin' : 'bubble-school' }}">
            <div class="fw-bold small mb-2" style="opacity: 0.8;">{{ $msg->is_admin_reply ? __('You (Platform Admin)') : $ticket->school->name }}</div>
            <div class="mb-2">{{ $msg->message }}</div>
            <div class="text-muted x-small text-end" style="opacity: 0.6;">{{ $msg->created_at->format('H:i - Y/m/d') }}</div>
        </div>
    @endforeach
</div>

@if($ticket->status !== 'closed')
    <div class="sa-card">
        <form action="{{ route('super-admin.support.reply', $ticket) }}" method="POST">
            @csrf
            <h5 class="mb-3"><i class="bi bi-reply-fill me-2"></i>{{ __('Reply to Ticket') }}</h5>
            <textarea name="message" class="form-control mb-4" rows="4" placeholder="{{ __('Write your reply here...') }}" required></textarea>
            <div class="d-flex justify-content-between">
                <button type="submit" class="sa-btn sa-btn-primary px-5">{{ __('Send Reply') }}</button>
                <form action="{{ route('super-admin.support.close', $ticket) }}" method="POST" class="d-inline">
                    @csrf
                    <button type="submit" class="sa-btn sa-btn-outline px-4 text-danger" style="border-color: rgba(239, 68, 68, 0.3);" onclick="return confirm('{{ __('Are you sure you want to close this ticket?') }}')">
                        <i class="bi bi-x-lg me-1"></i> {{ __('Close Ticket') }}
                    </button>
                </form>
            </div>
        </form>
    </div>
@else
    <div class="sa-alert sa-alert-info text-center py-4 justify-content-center">
        <i class="bi bi-lock-fill"></i>
        {{ __('This ticket is closed. You can reopen it if needed.') }}
    </div>
@endif
@endsection
