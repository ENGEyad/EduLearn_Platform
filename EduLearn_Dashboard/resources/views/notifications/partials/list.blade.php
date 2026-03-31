@if($notifications->isEmpty())
    <div class="text-center py-5">
        <div class="text-muted mb-3">
            <i class="bi bi-bell-slash display-4"></i>
        </div>
        <h6>{{ __('No notifications currently') }}</h6>
        <p class="text-muted small">{{ __('Any new activity will be listed here as it happens') }}</p>
    </div>
@else
    <div class="notification-list">
        @foreach($notifications as $notification)
            <div class="notification-item p-3 mb-3 rounded border {{ $notification->is_read ? 'notif-item-read' : 'notif-item-unread shadow-sm' }}" style="position: relative; transition: 0.2s;">
                <div class="d-flex align-items-start gap-3">
                    <div class="icon-wrap {{ $notification->is_read ? 'notif-icon-read' : 'notif-icon-unread' }} rounded-circle d-flex align-items-center justify-content-center" style="width: 45px; height: 45px; flex-shrink: 0;">
                        <i class="bi {{ $notification->icon ?? 'bi-info-circle' }} {{ $notification->is_read ? 'text-secondary' : 'text-primary' }} fs-5"></i>
                    </div>
                    <div class="flex-grow-1">
                        <div class="d-flex justify-content-between align-items-start">
                            <h6 class="mb-1 {{ $notification->is_read ? 'fw-normal' : 'fw-bold' }}">{{ __($notification->title, $notification->data ?? []) }}</h6>
                            <span class="text-muted" style="font-size: 0.75rem;">{{ $notification->created_at->diffForHumans() }}</span>
                        </div>
                        <p class="mb-2 small">{{ __($notification->message, $notification->data ?? []) }}</p>
                        <div class="d-flex justify-content-between align-items-center">
                            @php
                                $badgeClass = match($notification->type) {
                                    'teacher_event'    => 'bg-success-subtle text-success',
                                    'student_event'    => 'bg-primary-subtle text-primary',
                                    'subject_event'    => 'bg-warning-subtle text-warning',
                                    'assignment_event' => 'bg-info-subtle text-info',
                                    default            => 'bg-secondary-subtle text-secondary'
                                };
                            @endphp
                            <span class="badge {{ $badgeClass }} rounded-pill px-3" style="font-size: 0.7rem;">
                                {{ $notification->actor_name ?? __('System') }}
                            </span>
                            @if(!$notification->is_read)
                                <form action="{{ route('notifications.markRead', $notification->id) }}" method="POST" class="ms-auto">
                                    @csrf
                                    <button type="submit" class="btn btn-link btn-sm p-0 text-decoration-none" style="font-size: 0.8rem;">
                                        {{ __('Mark as Read') }}
                                    </button>
                                </form>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        @endforeach
    </div>

    <div class="mt-4">
        {{ $notifications->links() }}
    </div>
@endif
