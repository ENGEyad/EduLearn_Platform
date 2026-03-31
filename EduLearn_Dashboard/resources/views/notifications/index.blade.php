@extends('layouts.app')

@section('content')
<div class="row">
    <div class="col-12">
        <div class="card-panel shadow-sm">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h5 class="section-title mb-0"><i class="bi bi-bell me-2 text-primary"></i>{{ __('Notifications Center') }}</h5>
                    <p class="text-muted small mb-0">{{ __('Track all important events on the platform') }}</p>
                </div>
                <div class="d-flex gap-2">
                    <form action="{{ route('notifications.markAllRead') }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-soft btn-sm">
                            <i class="bi bi-check2-all me-1"></i> {{ __('Mark All as Read') }}
                        </button>
                    </form>
                    <form action="{{ route('notifications.clear') }}" method="POST" onsubmit="return confirm('{{ __('Are you sure you want to clear all notifications?') }}')">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="btn btn-soft-danger btn-sm">
                            <i class="bi bi-trash me-1"></i> {{ __('Clear History') }}
                        </button>
                    </form>
                </div>
            </div>

            <div id="notifications-container">
                @include('notifications.partials.list')
            </div>
        </div>
    </div>
</div>

<script>
    setInterval(function() {
        fetch('{{ route('notifications.index') }}', {
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
        .then(response => response.text())
        .then(html => {
            document.getElementById('notifications-container').innerHTML = html;
        })
        .catch(error => console.error('Error fetching notifications:', error));
    }, 1000); // 1 second
</script>

<style>
.notification-item:hover {
    transform: translateX(-5px);
}
</style>
@endsection
