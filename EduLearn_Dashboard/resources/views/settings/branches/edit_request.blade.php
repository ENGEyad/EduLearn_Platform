@extends('layouts.app')

@section('content')
<div class="reports-skin">
    <div class="page-header d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="page-title">{{ __('Edit Branch Request') }}</h2>
            <p class="subtitle">{{ __('Update the details for :name branch request', ['name' => $branch->name]) }}</p>
        </div>
        <a href="{{ route('settings.branches.requests') }}" class="btn btn-outline-secondary rounded-pill px-4">
            <i class="bi bi-arrow-left me-2"></i> {{ __('Back to Status') }}
        </a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm mb-4" style="border-radius: 16px; background: rgba(239, 68, 68, 0.1); color: #dc2626;">
            <ul class="mb-0">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="card border-0 shadow-lg rounded-4 overflow-hidden glass-card">
        <div class="card-body p-4 p-md-5">
            <form action="{{ route('settings.branches.requests.update', $branch) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row g-4">
                    <!-- Branch Info Section -->
                    <div class="col-12 border-bottom pb-3 mb-2 border-light border-opacity-10">
                        <h5 class="text-title mb-0 d-flex align-items-center gap-2">
                            <i class="bi bi-info-circle text-primary"></i> {{ __('Branch Details') }}
                        </h5>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">{{ __('Branch Name') }}</label>
                        <input type="text" name="name" class="form-control rounded-3 px-3 py-2" value="{{ old('name', $branch->name) }}" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">{{ __('Official Branch Email') }}</label>
                        <input type="email" name="email" class="form-control rounded-3 px-3 py-2" value="{{ old('email', $branch->email) }}" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">{{ __('Phone Number') }}</label>
                        <input type="text" name="phone" class="form-control rounded-3 px-3 py-2" value="{{ old('phone', $branch->phone) }}">
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">{{ __('Address') }}</label>
                        <input type="text" name="address" class="form-control rounded-3 px-3 py-2" value="{{ old('address', $branch->address) }}">
                    </div>

                    <!-- Admin Info Section -->
                    <div class="col-12 border-bottom pb-3 mb-2 mt-5 border-light border-opacity-10">
                        <h5 class="text-title mb-0 d-flex align-items-center gap-2">
                            <i class="bi bi-person-badge text-primary"></i> {{ __('Branch Administrator') }}
                        </h5>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">{{ __('Admin Full Name') }}</label>
                        <input type="text" name="admin_name" class="form-control rounded-3 px-3 py-2" value="{{ old('admin_name', $branch->admin_name) }}" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">{{ __('Admin Login Email') }}</label>
                        <input type="email" class="form-control rounded-3 px-3 py-2 bg-light opacity-75" value="{{ $branchAdmin->email }}" readonly disabled>
                        <div class="form-text text-muted small mt-1">
                            <i class="bi bi-shield-lock me-1"></i> {{ __('Login email cannot be changed for existing accounts.') }}
                        </div>
                    </div>

                    <div class="col-md-12">
                        <label class="form-label text-secondary small">{{ __('Reset Password (Optional)') }}</label>
                        <div class="input-group">
                            <input type="text" name="admin_password" id="admin_password" class="form-control rounded-3 px-3 py-2" placeholder="{{ __('Leave blank to keep current password') }}">
                            <button class="btn btn-outline-secondary" type="button" id="generatePasswordBtn">
                                <i class="bi bi-magic"></i>
                            </button>
                        </div>
                        <div class="form-text text-muted small mt-1">
                            {{ __('If you set a new password, the branch admin will be forced to change it on their next login.') }}
                        </div>
                    </div>

                    <div class="col-12 mt-5 d-flex justify-content-end gap-3">
                        <a href="{{ route('settings.branches.requests') }}" class="btn btn-outline-secondary rounded-pill px-5">
                            {{ __('Cancel') }}
                        </a>
                        <button type="submit" class="btn btn-primary rounded-pill px-5 shadow-sm">
                            <i class="bi bi-save me-2"></i> {{ __('Update Request') }}
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<style>
.glass-card {
    background: rgba(255, 255, 255, 0.7);
    backdrop-filter: blur(15px);
    -webkit-backdrop-filter: blur(15px);
    border: 1px solid rgba(255, 255, 255, 0.4) !important;
}

body.dark-mode .glass-card {
    background: rgba(30, 41, 59, 0.6);
    border: 1px solid rgba(255, 255, 255, 0.05) !important;
}

.text-title { color: var(--title); }
.text-secondary { color: var(--text-muted); }

.form-control:focus {
    border-color: var(--bs-primary) !important;
    box-shadow: 0 0 0 0.25rem rgba(var(--bs-primary-rgb), 0.1);
}

body.dark-mode .form-control {
    background-color: rgba(0, 0, 0, 0.2);
    border-color: rgba(255, 255, 255, 0.1);
    color: white;
}
</style>

@push('scripts')
<script src="{{ asset('js/branches.js') }}"></script>
@endpush
@endsection
