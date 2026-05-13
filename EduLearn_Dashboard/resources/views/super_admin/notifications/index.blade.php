@extends('super_admin.layout')
@section('title', __('Notifications Center'))

@push('styles')
<style>
    /* Dark Mode Visibility Fixes */
    .sa-header h1 { color: #fff !important; }
    .sa-header p.text-muted { color: rgba(255, 255, 255, 0.7) !important; }
    .sa-card h5, .sa-card h4 { color: #fff !important; }
    .text-muted { color: rgba(255, 255, 255, 0.6) !important; }
    .text-white-50 { color: rgba(255, 255, 255, 0.8) !important; }

    /* User Requested Styles */
    .sa-header { 
        display: flex; 
        justify-content: space-between; 
        align-items: center; 
        margin-bottom: 2rem; 
        padding-bottom: 1.5rem; 
        border-bottom: 1px solid rgba(255, 255, 255, 0.08); 
    }
    
    .sa-btn-primary { 
        background: linear-gradient(135deg, #FF6600, #e65c00) !important;
        color: #fff !important; 
        padding: 0.5rem 1.25rem !important;
        border-radius: 999px !important; 
        font-size: 0.85rem !important; 
        font-weight: 600 !important; 
        border: none !important;
        box-shadow: 0 4px 15px rgba(255, 102, 0, 0.3) !important;
        transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1) !important;
    }

    .sa-btn-primary:hover { 
        transform: translateY(-2px) !important; 
        box-shadow: 0 8px 25px rgba(255, 102, 0, 0.4) !important; 
    }

    [dir="rtl"] .me-2 {
        margin-left: 0.5rem !important;
        margin-right: 0 !important;
    }

    /* Page Specific Styles */
    .notif-item {
        padding: 1.25rem; border-radius: 20px; margin-bottom: 1.5rem;
        background: var(--navy-card); border: 1px solid rgba(255,255,255,0.05);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative; overflow: hidden;
    }
    .priority-indicator { position: absolute; top: 0; left: 0; bottom: 0; width: 5px; }
    .priority-normal { background: #3b82f6; }
    .priority-high { background: #f59e0b; }
    .priority-urgent { background: #ef4444; }

    .stats-tray {
        margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid rgba(255,255,255,0.05);
        display: grid; grid-template-columns: 1fr 1fr 1.2fr; gap: 1rem;
    }
    .stats-box {
        background: rgba(0,0,0,0.2); border-radius: 12px; padding: 1rem;
        max-height: 200px; overflow-y: auto;
    }
    .user-pill {
        display: flex; justify-content: space-between; align-items: center;
        padding: 6px 10px; border-radius: 8px; background: rgba(255,255,255,0.03);
        margin-bottom: 5px; font-size: 0.75rem;
    }
    .target-badge {
        font-size: 0.65rem; text-transform: uppercase; padding: 4px 10px; border-radius: 6px; 
        font-weight: 700; background: rgba(255,255,255,0.05); color: #94a3b8;
    }
</style>
@endpush

@section('content')
<div class="sa-header d-flex justify-content-between align-items-center mb-4">
    <div>
        <h1 class="fw-bold mb-1"><i class="bi bi-bell-fill me-2" style="color: var(--orange);"></i>{{ __('Notification Center') }}</h1>
        <p class="text-muted mb-0">{{ __('Track detailed engagement for every broadcast alert.') }}</p>
    </div>
    <button type="button" class="sa-btn sa-btn-primary px-4 rounded-pill" onclick="openNotifModal()">
        <i class="bi bi-send-fill me-2"></i> {{ __('Send New Alert') }}
    </button>
</div>

<div class="row g-4 mb-4 text-center">
    <div class="col-md-3">
        <div class="sa-card py-3">
            <h4 class="fw-bold text-primary mb-0">{{ $notifications->sum('unique_reads') }}</h4>
            <small class="text-muted">{{ __('Total Views') }}</small>
        </div>
    </div>
    <div class="col-md-3">
        <div class="sa-card py-3">
            <h4 class="fw-bold text-success mb-0">{{ $notifications->count() }}</h4>
            <small class="text-muted">{{ __('Total Sent') }}</small>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-lg-12">
        <div class="sa-card">
            <h5 class="fw-bold mb-4">{{ __('Detailed Engagement Log') }}</h5>

            @forelse($notifications as $notif)
                <div class="notif-item anim-fade-up">
                    <div class="priority-indicator priority-{{ $notif->priority }}"></div>
                    <div class="row">
                        <div class="col-md-6">
                            <div class="d-flex align-items-center gap-2 mb-2">
                                <span class="target-badge">{{ __($notif->target_role) }}</span>
                                <span class="small text-muted">{{ $notif->created_at->format('Y-m-d H:i') }}</span>
                            </div>
                            <h6 class="fw-bold text-white mb-2">{{ $notif->title }}</h6>
                            <p class="small text-muted mb-0">{{ $notif->message }}</p>
                            
                            <div class="mt-3">
                                <button type="button" class="sa-btn sa-btn-primary py-1 px-3" style="font-size: 0.75rem;" onclick="openFollowUpModal({{ json_encode($notif) }})">
                                    <i class="bi bi-reply-fill me-1"></i> {{ __('Follow-up / Response') }}
                                </button>
                                <form action="{{ route('super-admin.notifications.destroy', $notif) }}" method="POST" class="d-inline ms-2">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn btn-link p-0 text-danger small text-decoration-none" onclick="return confirm('{{ __('Are you sure?') }}')">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </form>
                            </div>
                        </div>
                        
                        <!-- Real-time Stats Grid -->
                        <div class="col-md-6">
                            <div class="stats-tray">
                                <!-- Seen Column -->
                                <div class="stats-box">
                                    <label class="small fw-bold text-info mb-2"><i class="bi bi-eye-fill me-1"></i> {{ __('Viewed By') }} ({{ count($notif->reads) }})</label>
                                    @foreach($notif->reads as $read)
                                        <div class="user-pill">
                                            <span class="text-white">{{ $read->user->name ?? 'User' }}</span>
                                            <span class="text-muted" style="font-size: 0.6rem;">{{ \Carbon\Carbon::parse($read->read_at)->diffForHumans() }}</span>
                                        </div>
                                    @endforeach
                                    @if(count($notif->reads) == 0) <p class="text-center small text-muted mt-3">No views yet</p> @endif
                                </div>

                                <!-- Pending Column -->
                                <div class="stats-box">
                                    @php
                                        $readUserIds = $notif->reads->pluck('user_id');
                                        $targetUsers = \App\Models\User::query();
                                        if($notif->target_role !== 'all') $targetUsers->where('role', $notif->target_role);
                                        $pending = $targetUsers->whereNotIn('id', $readUserIds)->get();
                                    @endphp
                                    <label class="small fw-bold text-warning mb-2"><i class="bi bi-clock-history me-1"></i> {{ __('Pending') }} ({{ $pending->count() }})</label>
                                    @foreach($pending as $user)
                                        <div class="user-pill">
                                            <span class="text-white-50">{{ $user->name }}</span>
                                            <i class="bi bi-dot text-warning"></i>
                                        </div>
                                    @endforeach
                                    @if($pending->count() == 0) <p class="text-center small text-muted mt-3">All reached</p> @endif
                                </div>

                                <!-- Responses Column -->
                                <div class="stats-box" style="background: rgba(255, 102, 0, 0.05);">
                                    <label class="small fw-bold text-orange mb-2"><i class="bi bi-chat-right-text-fill me-1"></i> {{ __('Responses') }} ({{ $notif->responses->count() }})</label>
                                    @foreach($notif->responses as $ticket)
                                        <div class="user-pill mb-2 p-2" style="background: rgba(255,255,255,0.05); cursor: pointer;" onclick="window.location='{{ route('super-admin.support.show', $ticket) }}'">
                                            <div class="w-100">
                                                <div class="d-flex justify-content-between align-items-center mb-1">
                                                    <span class="text-orange fw-bold" style="font-size: 0.7rem;">{{ $ticket->school->name ?? 'School' }}</span>
                                                    <span class="text-muted" style="font-size: 0.6rem;">{{ $ticket->created_at->diffForHumans() }}</span>
                                                </div>
                                                <p class="text-white small mb-0 lh-sm opacity-75" style="font-size: 0.65rem;">
                                                    {{ Str::limit($ticket->messages->first()->message ?? 'No message', 60) }}
                                                </p>
                                            </div>
                                        </div>
                                    @endforeach
                                    @if($notif->responses->count() == 0) 
                                        <p class="text-center small text-muted mt-3">{{ __('No responses yet') }}</p> 
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            @empty
                <div class="text-center py-5 opacity-50">
                    <i class="bi bi-bell-slash fs-1 d-block mb-3"></i>
                    <p>{{ __('No notifications record.') }}</p>
                </div>
            @endforelse
        </div>
    </div>
</div>

@push('scripts')
<!-- Create Modal -->
<div class="modal fade" id="sendNotificationModal" tabindex="-1" style="z-index: 9999;">
    <div class="modal-dialog modal-dialog-centered">
        <form action="{{ route('super-admin.notifications.store') }}" method="POST">
            @csrf
            <div class="modal-content border-0 bg-navy shadow-lg" style="border-radius: 24px;">
                <div class="modal-header border-0 px-4 pt-4 pb-0">
                    <h5 class="modal-title fw-bold text-white">{{ __('New Broadcast') }}</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body p-4">
                    <!-- AI Tool -->
                    <div class="mb-4 p-3 rounded-4 bg-primary bg-opacity-10 border border-primary border-opacity-10">
                        <label class="form-label small text-primary fw-bold mb-2">✨ AI Write Assistant</label>
                        <div class="input-group">
                            <input type="text" id="ai-topic" class="form-control bg-dark border-0 text-white small shadow-none" placeholder="Enter topic...">
                            <button type="button" class="btn btn-primary" onclick="generateAiContent(this)">
                                <span class="spinner-border spinner-border-sm d-none"></span> <i class="bi bi-magic"></i>
                            </button>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small text-white fw-bold">{{ __('Title') }}</label>
                        <input type="text" name="title" id="notif-title" class="form-control bg-dark border-0 text-white p-3" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small text-white fw-bold">{{ __('Message') }}</label>
                        <textarea name="message" id="notif-message" class="form-control bg-dark border-0 text-white p-3" rows="3" required></textarea>
                    </div>
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label small text-white fw-bold">{{ __('Target Audience') }}</label>
                            <select name="target_role" class="form-select bg-dark border-0 text-white p-3 shadow-none">
                                <option value="all">{{ __('Everyone') }}</option>
                                <option value="school_admin">{{ __('School Admins') }}</option>
                                <option value="teacher">{{ __('Teachers') }}</option>
                                <option value="student">{{ __('Students') }}</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small text-white fw-bold">{{ __('Priority') }}</label>
                            <select name="priority" class="form-select bg-dark border-0 text-white p-3 shadow-none">
                                <option value="normal">{{ __('Normal') }}</option>
                                <option value="high">{{ __('High') }}</option>
                                <option value="urgent">{{ __('Urgent') }}</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0 p-4 pt-0">
                    <button type="submit" class="sa-btn sa-btn-primary w-100 rounded-pill">{{ __('Shoot Broadcast') }}</button>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
    function openNotifModal() { new bootstrap.Modal(document.getElementById('sendNotificationModal')).show(); }

    function openFollowUpModal(notif) {
        if(typeof notif === 'string') notif = JSON.parse(notif);
        document.getElementById('notif-title').value = `Follow-up: ${notif.title}`;
        document.getElementById('notif-message').value = '';
        document.querySelector('select[name="target_role"]').value = notif.target_role;
        openNotifModal();
    }
    
    async function generateAiContent(btn) {
        const topic = document.getElementById('ai-topic').value;
        if(!topic) return;
        btn.disabled = true;
        try {
            const response = await fetch('/api/ai/generate-notification', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': '{{ csrf_token() }}' },
                body: JSON.stringify({ topic: topic })
            });
            const data = await response.json();
            if(data.success) {
                document.getElementById('notif-title').value = data.title;
                document.getElementById('notif-message').value = data.message;
            }
        } finally { btn.disabled = false; }
    }
</script>
@endpush

<style>
    .bg-navy { background: #0f172a !important; }
    .bg-dark { background: rgba(0,0,0,0.2) !important; }
</style>
@endsection
