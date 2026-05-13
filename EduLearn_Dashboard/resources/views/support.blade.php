@extends('layouts.app')

@section('content')
<!-- Page Header -->
<div class="d-flex justify-content-between align-items-center mb-4 anim-fade-up">
    <div>
        <h2 class="fw-bold text-title mb-1">{{ __('Help & Support Hub') }}</h2>
        <p class="text-muted small mb-0">{{ __('Need assistance? Connect with our global support team or browse resources.') }}</p>
    </div>
    <div class="d-flex gap-2">
        <button class="btn btn-soft-primary shadow-sm px-4 rounded-pill d-flex align-items-center gap-2" data-bs-toggle="modal" data-bs-target="#newTicketModal" style="color: #ffff;
    border: 1px solid #ffffff;">
            <i class="bi bi-plus-lg"></i> {{ __('Open New Ticket') }}
        </button>
    </div>
</div>

<div class="row g-4">
    <!-- Contact Channels -->
    <div class="col-lg-8 anim-fade-up anim-delay-1">
        <div class="row g-3">
            @php
                $channels = json_decode($settings['contact_channels'] ?? '[]', true);
            @endphp

            @forelse($channels as $channel)
                <div class="col-md-6">
                    <div class="card-panel h-100 p-4 d-flex flex-column align-items-center text-center">
                        @php
                            $iconColor = 'primary';
                            $icon = 'bi-link-45deg';
                            if($channel['type'] == 'email') { $icon = 'bi-envelope-paper-fill'; $iconColor = 'primary'; }
                            elseif($channel['type'] == 'whatsapp') { $icon = 'bi-whatsapp'; $iconColor = 'success'; }
                            elseif($channel['type'] == 'phone') { $icon = 'bi-telephone-fill'; $iconColor = 'info'; }
                            elseif($channel['type'] == 'telegram') { $icon = 'bi-telegram'; $iconColor = 'info'; }
                        @endphp
                        <div class="icon-circle bg-{{ $iconColor }} bg-opacity-10 text-{{ $iconColor }} mb-3" style="width: 60px; height: 60px; display: grid; place-items: center; border-radius: 50%; font-size: 1.5rem;">
                            <i class="bi {{ $icon }}"></i>
                        </div>
                        <h6 class="fw-bold mb-2">{{ $channel['label'] }}</h6>
                        <p class="text-muted small mb-3">
                            @if($channel['type'] == 'whatsapp') {{ __('Available for real-time chat and quick inquiries.') }}
                            @elseif($channel['type'] == 'email') {{ __('Best for inquiries and detailed technical reports.') }}
                            @else {{ __('Official communication channel for support.') }} @endif
                        </p>
                        
                        @php
                            $href = $channel['value'];
                            if($channel['type'] == 'email' && !str_starts_with($href, 'mailto:')) $href = 'mailto:'.$href;
                            if($channel['type'] == 'phone' && !str_starts_with($href, 'tel:')) $href = 'tel:'.$href;
                        @endphp

                        <a href="{{ $href }}" target="_blank" class="btn btn-soft-{{ $iconColor }} rounded-pill px-4 w-100">
                            <label class="mb-0" style="cursor: pointer; color: #fff; border: 1px solid #ffffff; opacity: 0.5;border-radius: 50px;">{{ $channel['value'] }}</label>
                        </a>
                    </div>
                </div>
            @empty
                <div class="col-12">
                    <div class="card-panel p-5 text-center">
                        <i class="bi bi-info-circle display-4 text-muted mb-3"></i>
                        <p>{{ __('No contact channels are currently configured. Please check back later.') }}</p>
                    </div>
                </div>
            @endforelse

            <!-- Help Center (Keep as a static featured resource if needed, or make it dynamic too) -->
            <div class="col-md-12">
                <div class="card-panel p-4 overflow-hidden position-relative">
                    <div class="position-absolute top-0 end-0 p-4 opacity-10" style="font-size: 5rem; transform: rotate(15deg);">
                        <i class="bi bi-journal-text"></i>
                    </div>
                    <div class="row align-items-center">
                        <div class="col-md-8">
                            <h5 class="fw-bold text-navy mb-2">{{ __('Comprehensive Help Center') }}</h5>
                            <p class="text-muted mb-4">{{ __('Detailed video tutorials, user manuals, and FAQs for managing your school and branches.') }}</p>
                            <a href="{{ $settings['help_center_url'] ?? '#' }}" target="_blank" class="btn btn-primary px-5 rounded-pill shadow-sm">
                                <i class="bi bi-arrow-right-circle me-2"></i> {{ __('Visit Knowledge Base') }}
                            </a>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Social Media -->
            <div class="col-md-12">
                <div class="card-panel p-3 d-flex justify-content-center gap-4 bg-light border-0">
                    <span class="text-muted small fw-bold text-uppercase pt-2">{{ __('Join our community:') }}</span>
                    <a href="{{ $settings['facebook_url'] ?? '#' }}" target="_blank" class="fs-4 text-primary"><i class="bi bi-facebook"></i></a>
                    <a href="{{ $settings['twitter_url'] ?? '#' }}" target="_blank" class="fs-4 text-dark"><i class="bi bi-twitter-x"></i></a>
                    @if(isset($settings['telegram_url']))
                    <a href="{{ $settings['telegram_url'] }}" target="_blank" class="fs-4 text-info"><i class="bi bi-telegram"></i></a>
                    @endif
                </div>
            </div>
        </div>
    </div>

    <!-- Recent Tickets -->
    <div class="col-lg-4 anim-fade-up anim-delay-2">
        <div class="card-panel h-100 p-4">
            <h6 class="fw-bold mb-4 d-flex align-items-center">
                <i class="bi bi-chat-dots-fill text-orange me-2"></i> {{ __('Your Recent Tickets') }}
            </h6>
            
            <div class="ticket-list d-flex flex-column gap-3">
                @forelse($tickets as $ticket)
                <div class="p-3 rounded-4 bg-light border border-white">
                    <div class="d-flex justify-content-between align-items-start mb-2">
                        <span class="small fw-bold text-navy text-truncate" style="max-width: 150px;">{{ $ticket->subject }}</span>
                        @if($ticket->status === 'open')
                            <span class="badge bg-soft-warning text-warning rounded-pill" style="font-size: 0.65rem;">{{ __('Waiting') }}</span>
                        @elseif($ticket->status === 'pending')
                            <span class="badge bg-soft-info text-info rounded-pill" style="font-size: 0.65rem;">{{ __('Replied') }}</span>
                        @else
                            <span class="badge bg-soft-success text-success rounded-pill" style="font-size: 0.65rem;">{{ __('Closed') }}</span>
                        @endif
                    </div>
                    <div class="d-flex justify-content-between align-items-center">
                        <small class="text-muted">{{ $ticket->created_at->format('M d, Y') }}</small>
                        <span class="small text-{{ $ticket->priority === 'urgent' ? 'danger' : 'muted' }} fw-bold capitalize">
                            <i class="bi bi-flag-fill me-1"></i> {{ __($ticket->priority) }}
                        </span>
                    </div>
                </div>
                @empty
                <div class="text-center py-5">
                    <i class="bi bi-inbox text-muted opacity-30 display-4 d-block mb-2"></i>
                    <p class="text-muted small">{{ __('No active tickets found.') }}</p>
                </div>
                @endforelse
            </div>

            <div class="mt-4 pt-4 border-top">
                <div class="p-3 rounded-4 bg-orange bg-opacity-10 text-orange small d-flex gap-3">
                    <i class="bi bi-lightbulb-fill fs-4"></i>
                    <div>
                        <strong>{{ __('Pro Tip:') }}</strong><br>
                        {{ __('Attaching screenshots helps us resolve technical issues 30% faster.') }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- New Ticket Modal -->
<div class="modal fade" id="newTicketModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
            <form action="{{ route('support.ticket.store') }}" method="POST">
                @csrf
                <div class="modal-header border-0 pb-0">
                    <h5 class="modal-title fw-bold text-navy">{{ __('Open Official Support Ticket') }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body py-4">
                    <div class="mb-3">
                        <label class="form-label fw-bold">{{ __('Subject') }}</label>
                        <input type="text" name="subject" class="form-control" required placeholder="{{ __('Briefly describe the issue') }}">
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-bold">{{ __('Priority') }}</label>
                        <select name="priority" class="form-select" required>
                            <option value="low">{{ __('Low - Feature suggestion / Question') }}</option>
                            <option value="normal" selected>{{ __('Normal - General issue') }}</option>
                            <option value="high">{{ __('High - Urgent operation failure') }}</option>
                            <option value="urgent">{{ __('Urgent - System down / Critical') }}</option>
                        </select>
                    </div>
                    <div class="mb-0">
                        <label class="form-label fw-bold">{{ __('Describe your issue') }}</label>
                        <textarea name="message" class="form-control" rows="5" required placeholder="{{ __('Please provide as much detail as possible...') }}"></textarea>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-light px-4 rounded-pill" data-bs-toggle="modal">{{ __('Cancel') }}</button>
                    <button type="submit" class="btn btn-primary px-5 rounded-pill shadow">{{ __('Submit Ticket') }}</button>
                </div>
            </form>
        </div>
    </div>
</div>

<style>
    .capitalize { text-transform: capitalize; }
    .icon-circle { transition: transform 0.3s ease; }
    .card-panel:hover .icon-circle { transform: scale(1.1) rotate(5deg); }

    /* Dark Mode Improvements for Soft Buttons */
    [data-bs-theme="dark"] .btn-soft-primary { background: rgba(13, 110, 253, 0.2) !important; color: #fff !important; border: 1px solid rgba(13, 110, 253, 0.3); }
    [data-bs-theme="dark"] .btn-soft-success { background: rgba(25, 135, 84, 0.2) !important; color: #fff !important; border: 1px solid rgba(25, 135, 84, 0.3); }
    [data-bs-theme="dark"] .btn-soft-info { background: rgba(13, 202, 240, 0.2) !important; color: #fff !important; border: 1px solid rgba(13, 202, 240, 0.3); }
    [data-bs-theme="dark"] .btn-soft-warning { background: rgba(255, 193, 7, 0.2) !important; color: #fff !important; border: 1px solid rgba(255, 193, 7, 0.3); }
    [data-bs-theme="dark"] .btn-soft-danger { background: rgba(220, 53, 69, 0.2) !important; color: #fff !important; border: 1px solid rgba(220, 53, 69, 0.3); }
</style>
@endsection
