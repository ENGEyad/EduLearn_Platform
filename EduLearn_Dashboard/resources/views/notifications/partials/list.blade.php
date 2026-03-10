@if($notifications->isEmpty())
    <div class="text-center py-5">
        <div class="text-muted mb-3">
            <i class="bi bi-bell-slash display-4"></i>
        </div>
        <h6>لا توجد تنبيهات حالياً</h6>
        <p class="text-muted small">سيتم إدراج أي نشاط جديد هنا فور حدوثه</p>
    </div>
@else
    <div class="notification-list">
        @foreach($notifications as $notification)
            <div class="notification-item p-3 mb-3 rounded border {{ $notification->is_read ? 'bg-light text-muted' : 'bg-white border-primary-subtle shadow-sm' }}" style="position: relative; transition: 0.2s;">
                <div class="d-flex align-items-start gap-3">
                    <div class="icon-wrap {{ $notification->is_read ? 'bg-secondary-subtle' : 'bg-primary-subtle' }} rounded-circle d-flex align-items-center justify-content-center" style="width: 45px; height: 45px; flex-shrink: 0;">
                        <i class="bi {{ $notification->icon ?? 'bi-info-circle' }} {{ $notification->is_read ? 'text-secondary' : 'text-primary' }} fs-5"></i>
                    </div>
                    <div class="flex-grow-1">
                        <div class="d-flex justify-content-between align-items-start">
                            <h6 class="mb-1 {{ $notification->is_read ? 'fw-normal' : 'fw-bold' }}">{{ $notification->title }}</h6>
                            <span class="text-muted" style="font-size: 0.75rem;">{{ $notification->created_at->diffForHumans() }}</span>
                        </div>
                        <p class="mb-2 small">{{ $notification->message }}</p>
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
                                {{ $notification->actor_name ?? 'النظام' }}
                            </span>
                            @if(!$notification->is_read)
                                <form action="{{ route('notifications.markRead', $notification->id) }}" method="POST" class="ms-auto">
                                    @csrf
                                    <button type="submit" class="btn btn-link btn-sm p-0 text-decoration-none" style="font-size: 0.8rem;">
                                        تحديد كمقروء
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
