@extends('layouts.app')

@section('content')
<div class="reports-skin">
    <div class="page-header mb-4">
        <div>
            <h2 class="page-title">{{ __('Branch Permissions') }}</h2>
            <p class="subtitle">{{ __('Manage granular access for :name administrator', ['name' => $branch->name]) }}</p>
        </div>
        <div>
            <a href="{{ route('settings.branches.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-right me-1"></i> {{ __('Back to Branches') }}
            </a>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm mb-4">
            {{ session('success') }}
        </div>
    @endif

    <div class="row">
        <div class="col-md-4">
            <div class="cardy panel mb-4">
                <div class="text-center py-4">
                    <div class="avatar-circle mx-auto mb-3" style="width: 80px; height: 80px; font-size: 2rem;">
                        {{ strtoupper(substr($branchAdmin->name, 0, 1)) }}
                    </div>
                    <h5 class="fw-bold mb-1">{{ $branchAdmin->name }}</h5>
                    <p class="text-muted small mb-3">{{ $branchAdmin->email }}</p>
                    <span class="badge bg-primary-subtle text-primary border border-primary-subtle px-3 py-2 rounded-pill">
                        {{ __('Branch Administrator') }}
                    </span>
                </div>
                <hr class="my-4 opacity-50">
                <div class="small">
                    <div class="d-flex justify-content-between mb-2">
                        <span class="text-muted">{{ __('Status') }}</span>
                        <span class="fw-bold text-success">{{ __('Active') }}</span>
                    </div>
                    <div class="d-flex justify-content-between mb-2">
                        <span class="text-muted">{{ __('Last Login') }}</span>
                        <span class="fw-bold">{{ $branchAdmin->last_login_at ? $branchAdmin->last_login_at->diffForHumans() : __('Never') }}</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-md-8">
            <div class="cardy panel">
                <h6 class="text-primary mb-4 border-bottom pb-2">
                    <i class="bi bi-shield-check me-2"></i> {{ __('Granted Permissions') }}
                </h6>
                
                <form action="{{ route('settings.branches.permissions.update', $branch) }}" method="POST">
                    @csrf
                    <div class="row g-4">
                        @foreach($availablePermissions as $key => $label)
                            <div class="col-md-6">
                                <div class="permission-item p-3 border rounded-3 transition-all hover-shadow-sm d-flex align-items-center gap-3">
                                    <div class="form-check form-switch m-0 fs-5">
                                        <input class="form-check-input" type="checkbox" name="permissions[]" value="{{ $key }}" 
                                               id="perm_{{ $key }}" {{ in_array($key, $activePermissions) ? 'checked' : '' }}>
                                    </div>
                                    <label class="form-check-label flex-grow-1" for="perm_{{ $key }}">
                                        <div class="fw-bold">{{ $label }}</div>
                                        <small class="text-muted d-block">{{ __('Allow branch admin to') }} {{ strtolower($label) }}</small>
                                    </label>
                                </div>
                            </div>
                        @endforeach
                    </div>

                    <div class="mt-5 pt-4 border-top text-end">
                        <button type="submit" class="btn btn-primary px-5 py-2 fw-bold">
                            <i class="bi bi-save me-1"></i> {{ __('Save Permissions') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<style>
    .permission-item {
        background: var(--card-bg);
        transition: all 0.2s ease;
    }
    .permission-item:hover {
        border-color: var(--link) !important;
        background: rgba(37, 99, 235, 0.02);
        transform: translateY(-2px);
    }
    .form-check-input:checked {
        background-color: var(--link);
        border-color: var(--link);
    }
</style>

@push('scripts')
<script src="{{ asset('js/branches.js') }}"></script>
@endpush
@endsection
