@extends('super_admin.layout')
@section('title', __('Support Center'))

@section('content')
<div class="sa-header">
    <div>
        <h1><i class="bi bi-headset me-2" style="color: var(--orange);"></i>{{ __('Support Center') }}</h1>
        <p>{{ __('Manage responses and complaints from school administrators') }}</p>
    </div>
</div>

<div class="sa-card" style="padding: 0; overflow: hidden;">
    <div class="table-responsive">
        <table class="sa-table">
            <thead>
                <tr>
                    <th class="ps-4 py-3">{{ __('School') }}</th>
                    <th class="py-3">{{ __('Subject') }}</th>
                    <th class="py-3">{{ __('Status') }}</th>
                    <th class="py-3">{{ __('Priority') }}</th>
                    <th class="py-3">{{ __('Date') }}</th>
                    <th class="text-center py-3 pe-4">{{ __('Actions') }}</th>
                </tr>
            </thead>
            <tbody>
                @forelse($tickets as $ticket)
                <tr>
                    <td class="ps-4">
                        <div class="fw-bold">{{ $ticket->school->name }}</div>
                    </td>
                    <td>{{ $ticket->subject }}</td>
                    <td>
                        @if($ticket->status === 'open')
                            <span class="sa-badge sa-badge-pending">{{ __('Waiting') }}</span>
                        @elseif($ticket->status === 'pending')
                            <span class="sa-badge sa-badge-active" style="background: rgba(14, 165, 233, 0.15); color: #0ea5e9; border: 1px solid rgba(14, 165, 233, 0.3);">{{ __('Replied') }}</span>
                        @else
                            <span class="sa-badge sa-badge-active">{{ __('Closed') }}</span>
                        @endif
                    </td>
                    <td>
                        @if($ticket->priority === 'urgent')
                            <span class="text-danger fw-bold"><i class="bi bi-exclamation-triangle-fill me-1"></i> {{ __('Urgent') }}</span>
                        @else
                            <span class="text-muted">{{ $ticket->priority }}</span>
                        @endif
                    </td>
                    <td class="text-muted small">{{ $ticket->created_at->diffForHumans() }}</td>
                    <td class="text-center pe-4">
                        <a href="{{ route('super-admin.support.show', $ticket) }}" class="sa-btn sa-btn-primary py-1 px-3" style="font-size: 0.8rem;">
                            <i class="bi bi-chat-left-text me-1"></i> {{ __('Details & Reply') }}
                        </a>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="text-center py-5">
                        <div class="sa-empty">
                            <i class="bi bi-headset"></i>
                            <p>{{ __('No support tickets received yet') }}</p>
                        </div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
