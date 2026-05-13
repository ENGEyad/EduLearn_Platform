@extends('layouts.app')

@push('styles')
<style>
    .nav-tabs-custom { border-bottom: 2px solid rgba(255,102,0,0.1); }
    .nav-tabs-custom .nav-link { 
        border: none; color: var(--muted); padding: 1rem 2rem; 
        font-weight: 600; transition: all 0.3s; position: relative;
    }
    .nav-tabs-custom .nav-link.active { 
        color: var(--orange); background: transparent; 
    }
    .nav-tabs-custom .nav-link.active::after {
        content: ''; position: absolute; bottom: -2px; left: 0; right: 0;
        height: 2px; background: var(--orange);
    }
    
    .inbox-item {
        padding: 1.5rem; border-radius: 20px; background: rgba(255,255,255,0.03);
        border: 1px solid rgba(255,255,255,0.05); margin-bottom: 1.25rem;
        transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative; overflow: hidden;
    }
    .inbox-item::before {
        content: ''; position: absolute; top: 0; left: 0; width: 4px; height: 100%;
        background: var(--border);
    }
    .inbox-item:hover { 
        transform: translateY(-4px) scale(1.01); 
        background: rgba(255,255,255,0.06);
        border-color: rgba(255,102,0,0.3);
        box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    }
    .inbox-item.priority-urgent::before { background: #ef4444; }
    .inbox-item.priority-high::before { background: #f59e0b; }
    .inbox-item.priority-normal::before { background: #3b82f6; }
    .inbox-item.is-read { opacity: 0.7; filter: grayscale(0.2); }
    .inbox-item.is-read::before { background: #64748b !important; }

    .inbox-badge {
        padding: 5px 14px; border-radius: 10px; font-size: 0.65rem; 
        font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em;
    }
    /* High Visibility Buttons */
    .btn-glass {
        background: var(--orange) !important;
        color: #fff !important;
        border: 1px solid var(--orange) !important;
        box-shadow: 0 4px 12px rgba(255, 102, 0, 0.3);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        font-size: 0.75rem; font-weight: 700;
        backdrop-filter: none; /* No need for blur if solid */
    }
    .btn-glass:hover { 
        background: #e65c00 !important; /* Slightly darker orange */
        transform: translateY(-2px);
        box-shadow: 0 6px 20px rgba(255, 102, 0, 0.4);
    }
    
    .btn-soft {
        background-color: var(--btn-soft-bg) !important;
        color: var(--btn-soft-text) !important;
        border: 1px solid var(--btn-soft-border) !important;
        backdrop-filter: blur(4px);
        -webkit-backdrop-filter: blur(4px);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        font-weight: 600;
    }
    .btn-soft:hover {
        background-color: var(--btn-soft-hover-bg) !important;
        color: var(--btn-soft-hover-text) !important;
        transform: translateY(-2px);
        box-shadow: 0 4px 15px rgba(0,0,0,0.15);
    }

    .btn-glass i { transition: transform 0.3s; }
    .btn-glass:hover i { transform: scale(1.1); }

    /* Modal Styling */
    .modal-glass {
        background: #0f172a !important; /* Solid dark background for modal */
        border: 1px solid rgba(255,255,255,0.1) !important;
        border-radius: 24px !important;
    }
    .modal-header-glass { border-bottom: 1px solid rgba(255,255,255,0.05); }
    .modal-footer-glass { border-top: 1px solid rgba(255,255,255,0.05); }

    /* Custom Adaptive Select Styling */
    .custom-adaptive-select {
        background-color: var(--bg) !important;
        color: var(--text) !important;
        cursor: pointer;
    }
    
    .custom-adaptive-select option {
        background-color: var(--card);
        color: var(--text);
        padding: 10px;
    }

    body.dark-mode .bg-light-subtle {
        background-color: rgba(255, 255, 255, 0.03) !important;
        border: 1px solid rgba(255, 255, 255, 0.05) !important;
    }

    body.dark-mode .broadcast-form-wrap .card-panel {
        background: linear-gradient(145deg, #001A33, #001020) !important;
        border: 1px solid rgba(255, 102, 0, 0.1) !important;
        box-shadow: 0 20px 40px rgba(0,0,0,0.4) !important;
    }

    body.dark-mode .broadcast-form-wrap .form-control,
    body.dark-mode .broadcast-form-wrap .custom-adaptive-select {
        background: rgba(0, 0, 0, 0.2) !important;
        border: 1px solid rgba(255, 255, 255, 0.05) !important;
        color: #e2e8f0 !important;
    }

    body.dark-mode .broadcast-form-wrap .form-control:focus,
    body.dark-mode .broadcast-form-wrap .custom-adaptive-select:focus {
        border-color: var(--orange) !important;
        box-shadow: 0 0 0 3px rgba(255, 102, 0, 0.15) !important;
        background: rgba(0, 0, 0, 0.3) !important;
    }
</style>
@endpush

@section('content')
<div class="row g-4">
    <div class="col-12">
        <div class="card-panel shadow-sm">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h5 class="section-title mb-0"><i class="bi bi-bell-fill me-2" style="color: var(--orange);"></i>{{ __('Notifications Center') }}</h5>
                    <p class="text-muted small mb-0">{{ __('Track system alerts and school activities') }}</p>
                </div>
                <div class="d-flex gap-2">
                    <form action="{{ route('notifications.markAllRead') }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-soft btn-sm px-3 rounded-pill">
                            <i class="bi bi-check2-all me-1"></i> {{ __('Mark All Read') }}
                        </button>
                    </form>
                    <form action="{{ route('notifications.clear') }}" method="POST" onsubmit="return confirm('{{ __('Are you sure you want to clear all history?') }}')">
                        @csrf @method('DELETE')
                        <button type="submit" class="btn btn-soft-danger btn-sm px-3 rounded-pill">
                            <i class="bi bi-trash me-1"></i> {{ __('Clear') }}
                        </button>
                    </form>
                </div>
            </div>

            <!-- Tabs Navigation -->
            <ul class="nav nav-tabs nav-tabs-custom mb-4" id="notifTabs" role="tablist">
                <li class="nav-item">
                    <a class="nav-link active" data-bs-toggle="tab" href="#activity" role="tab">
                        <i class="bi bi-activity me-2"></i>{{ __('School Activity') }}
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" data-bs-toggle="tab" href="#inbox" role="tab">
                        <i class="bi bi-inbox-fill me-2"></i>{{ __('System Inbox') }}
                        @if(count($systemNotifications) > 0)
                            <span class="ms-1 badge rounded-pill bg-danger" style="font-size: 0.6rem;">{{ count($systemNotifications) }}</span>
                        @endif
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" data-bs-toggle="tab" href="#broadcast" role="tab">
                        <i class="bi bi-megaphone-fill me-2"></i>{{ __('Broadcast Alert') }}
                    </a>
                </li>
            </ul>

            <div class="tab-content pt-2">
                <!-- Tab 1: Activity -->
                <div class="tab-pane fade show active" id="activity" role="tabpanel">
                    <div id="notifications-container">
                        @include('notifications.partials.list')
                    </div>
                </div>

                <!-- Tab 2: Inbox (System Alerts) -->
                <div class="tab-pane fade" id="inbox" role="tabpanel">
                    @forelse($systemNotifications as $notif)
                        <div class="inbox-item priority-{{ $notif->priority }} {{ $notif->is_read ? 'is-read' : '' }}" id="inbox-{{ $notif->id }}">
                            <div class="d-flex justify-content-between align-items-start">
                                <div class="flex-grow-1">
                                    <div class="d-flex align-items-center gap-2 mb-3">
                                        <span class="inbox-badge bg-{{ $notif->priority == 'urgent' ? 'danger' : ($notif->priority == 'high' ? 'warning' : 'primary') }} bg-opacity-20 text-{{ $notif->priority == 'urgent' ? 'danger' : ($notif->priority == 'high' ? 'warning' : 'primary') }}">
                                            <i class="bi bi-circle-fill me-1" style="font-size: 0.4rem;"></i> {{ __($notif->priority) }}
                                        </span>
                                        <span class="text-white-50 small"><i class="bi bi-clock me-1"></i>{{ $notif->created_at->diffForHumans() }}</span>
                                        @if($notif->is_read)
                                            <span class="badge bg-success bg-opacity-10 text-success small rounded-pill px-2" style="font-size: 0.6rem;">
                                                <i class="bi bi-check2-circle"></i> {{ __('Read') }}
                                            </span>
                                        @endif
                                    </div>
                                    <h6 class="fw-bold mb-2 text-white" style="font-size: 1.1rem;">{{ $notif->title }}</h6>
                                    <p class="text-white small mb-0 lh-base opacity-75" style="font-size: 0.95rem;">{{ $notif->message }}</p>
                                    
                                    <div class="d-flex gap-2 mt-4">
                                        <button onclick="viewSystemNotifDetails({{ json_encode($notif) }})" class="btn btn-soft px-3 rounded-pill">
                                            <i class="bi bi-eye-fill me-1"></i> {{ __('View Details') }}
                                        </button>

                                        @if(!$notif->is_read)
                                            <button onclick="markSystemNotifRead({{ $notif->id }}, this)" class="btn btn-soft px-3 rounded-pill">
                                                <i class="bi bi-check2 me-1"></i> {{ __('Mark as Read') }}
                                            </button>
                                        @endif
                                        
                                        <button onclick="openResponseModal({{ json_encode($notif) }})" class="btn btn-soft px-3 rounded-pill">
                                            <i class="bi bi-reply-fill me-1"></i> {{ __('Response') }}
                                        </button>
                                    </div>
                                </div>
                                @if($notif->priority == 'urgent' && !$notif->is_read)
                                    <div class="ms-3 text-danger fs-4 anim-pulse">
                                        <i class="bi bi-exclamation-octagon-fill"></i>
                                    </div>
                                @endif
                            </div>
                        </div>
                    @empty
                        <div class="text-center py-5 opacity-50">
                            <i class="bi bi-inbox fs-1 mb-3 d-block"></i>
                            <p>{{ __('Your system inbox is empty') }}</p>
                        </div>
                    @endforelse
                </div>

                <!-- Tab 3: Broadcast Alert -->
                <div class="tab-pane fade" id="broadcast" role="tabpanel">
                    <div class="row justify-content-center">
                        <div class="col-md-8">
                    <div class="card-panel border-0 shadow-sm p-4 broadcast-form-wrap">
                        <form action="{{ route('notifications.broadcast') }}" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="mb-3">
                                <label class="form-label text-title small fw-bold">{{ __('Broadcast Title') }}</label>
                                <input type="text" name="title" class="form-control bg-light-subtle border-0 rounded-3 p-3" placeholder="{{ __('Enter alert title') }}" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label text-title small fw-bold">{{ __('Message Subtitle') }}</label>
                                <textarea name="message" class="form-control bg-light-subtle border-0 rounded-3 p-3" rows="3" placeholder="{{ __('What do you want to announce?') }}" required></textarea>
                            </div>
                            <div class="row g-3 mb-4">
                                <div class="col-md-6">
                                    <label class="form-label text-title small fw-bold">{{ __('Target Audience') }}</label>
                                    <select name="target" class="form-select custom-adaptive-select border-0 rounded-3 p-3 shadow-none">
                                        <option value="both">{{ __('Both Apps (Teachers & Students)') }}</option>
                                        <option value="teachers">{{ __('Teachers App Only') }}</option>
                                        <option value="students">{{ __('Students App Only') }}</option>
                                    </select>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label text-title small fw-bold">{{ __('Optional Photo') }}</label>
                                    <input type="file" name="image" class="form-control bg-light-subtle border-0 rounded-3 p-3">
                                </div>
                            </div>
                            <div class="text-end">
                                <button type="submit" class="btn btn-soft px-5 py-3 rounded-pill">
                                    <i class="bi bi-send-fill me-2"></i> {{ __('Send Broadcast Now') }}
                                </button>
                            </div>
                        </form>
                    </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Response Modal -->
<div class="modal fade" id="responseModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content modal-glass text-white">
            <form action="{{ route('support.ticket.store') }}" method="POST">
                @csrf
                <input type="hidden" name="subject" id="resp-subject">
                <input type="hidden" name="priority" value="normal">
                <div class="modal-header modal-header-glass">
                    <h5 class="modal-title fw-bold">{{ __('Send Response') }}</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-4">
                    <p class="text-white-50 small mb-3">{{ __('Your response will be sent directly to the Super Admin as a priority ticket.') }}</p>
                    <div class="mb-3">
                        <label class="form-label text-white small fw-bold">{{ __('Your Message') }}</label>
                        <textarea name="message" class="form-control bg-dark border-0 text-white p-3" rows="4" placeholder="{{ __('Type your response here...') }}" required></textarea>
                    </div>
                </div>
                <div class="modal-footer modal-footer-glass">
                    <button type="button" class="btn btn-soft px-4 rounded-pill" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                    <button type="submit" class="btn btn-soft px-4 rounded-pill">{{ __('Send') }}</button>
                </div>
            </form>
        </div>
    </div>
</div>
<div class="modal fade" id="notifDetailsModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content modal-glass text-white">
            <div class="modal-header modal-header-glass">
                <h5 class="modal-title fw-bold" id="modal-notif-title"></h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-4">
                <div class="d-flex align-items-center gap-2 mb-3" id="modal-notif-meta">
                    <!-- Meta info like priority and time will go here -->
                </div>
                <p id="modal-notif-message" class="lh-base opacity-75" style="font-size: 1rem;"></p>
                
                <div id="modal-notif-actions" class="d-flex gap-2 mt-4">
                    <!-- Actions like Mark as Read and Response will go here -->
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    // View system notification details in modal
    function viewSystemNotifDetails(notif) {
        const modal = new bootstrap.Modal(document.getElementById('notifDetailsModal'));
        document.getElementById('modal-notif-title').innerText = notif.title;
        document.getElementById('modal-notif-message').innerText = notif.message;
        
        // Priority translations mapping
        const priorityLabels = {
            'urgent': '{{ __("urgent") }}',
            'high': '{{ __("high") }}',
            'normal': '{{ __("normal") }}'
        };
        
        // Meta info
        const metaArea = document.getElementById('modal-notif-meta');
        const priorityColor = notif.priority === 'urgent' ? 'danger' : (notif.priority === 'high' ? 'warning' : 'primary');
        metaArea.innerHTML = `
            <span class="inbox-badge bg-${priorityColor} bg-opacity-20 text-${priorityColor}">
                <i class="bi bi-circle-fill me-1" style="font-size: 0.4rem;"></i> ${priorityLabels[notif.priority] || notif.priority}
            </span>
            <span class="text-white-50 small"><i class="bi bi-clock me-1"></i> {{ __("Just now") }}</span>
        `;
        
        // Action buttons
        const actionArea = document.getElementById('modal-notif-actions');
        let actionsHtml = '';
        
        if (!notif.is_read) {
            actionsHtml += `
                <button onclick="markSystemNotifRead(${notif.id}, this)" class="btn btn-soft px-4 rounded-pill">
                    <i class="bi bi-check2 me-1"></i> {{ __('Mark as Read') }}
                </button>
            `;
        }
        
        actionsHtml += `
            <button onclick="openResponseModal(${JSON.stringify(notif)})" class="btn btn-soft px-4 rounded-pill">
                <i class="bi bi-reply-fill me-1"></i> {{ __('Response') }}
            </button>
        `;
        
        if (notif.action_url) {
            actionsHtml += `
                <a href="${notif.action_url}" target="_blank" class="btn btn-soft px-4 rounded-pill">
                    <i class="bi bi-box-arrow-up-right me-1"></i> {{ __('Visit Link') }}
                </a>
            `;
        }
        
        actionArea.innerHTML = actionsHtml;
        modal.show();
    }

    // Open the response modal with pre-filled subject
    function openResponseModal(notif) {
        if(typeof notif === 'string') notif = JSON.parse(notif);
        document.getElementById('resp-subject').value = `RE: ${notif.title}`;
        
        // Hide details modal if open
        const detailsModal = bootstrap.Modal.getInstance(document.getElementById('notifDetailsModal'));
        if(detailsModal) detailsModal.hide();
        
        new bootstrap.Modal(document.getElementById('responseModal')).show();
    }

    // Mark system notification as read
    async function markSystemNotifRead(id, btn) {
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>';
        
        try {
            const url = '{{ route("notifications.trackRead", ["id" => ":id"]) }}'.replace(':id', id);
            console.log('Marking system notif as read:', url);
            
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({ interacted: true })
            });
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.message || `Server error: ${response.status}`);
            }
            
            const data = await response.json();
            if(data.success) {
                const item = document.getElementById(`inbox-${id}`);
                if (item) item.classList.add('is-read');
                btn.remove();
                
                // Update badge if exists
                const badgeArea = item?.querySelector('.mb-3');
                if (badgeArea && !badgeArea.querySelector('.bg-success')) {
                    const badge = document.createElement('span');
                    badge.className = 'badge bg-success bg-opacity-10 text-success small rounded-pill px-2';
                    badge.style.fontSize = '0.6rem';
                    badge.innerHTML = '<i class="bi bi-check2-circle"></i> {{ __("Read") }}';
                    badgeArea.appendChild(badge);
                }
            }
        } catch (error) {
            console.error('Notification Error:', error);
            alert('Error: ' + error.message);
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-check2 me-1"></i> {{ __("Mark as Read") }}';
        }
    }

    // Keep internal activity list updated (Existing logic)
    setInterval(function() {
        if (document.querySelector('#activity').classList.contains('active')) {
            fetch('{{ route('notifications.index') }}', {
                headers: { 'X-Requested-With': 'XMLHttpRequest' }
            })
            .then(response => response.text())
            .then(html => {
                const container = document.getElementById('notifications-container');
                if (container) container.innerHTML = html;
            })
            .catch(error => console.error('Error fetching activity:', error));
        }
    }, 5000); 
</script>
@endsection
