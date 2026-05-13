@extends('layouts.app')

@section('content')
<div class="reports-skin">
    <div class="page-header">
        <div>
            <h2 class="page-title">{{ __('Branch Management') }}</h2>
            <p class="subtitle">{{ __('Manage school branches, requests, and branch administrators') }}</p>
        </div>
        <div class="d-flex gap-2 mt-2 mt-sm-0">
            <a href="{{ route('settings.branches.requests') }}" class="btn btn-custom-ghost px-4 rounded-pill d-flex align-items-center gap-2">
                <i class="bi bi-send-check"></i> {{ __('Requests Status') }}
            </a>
            <button class="btn btn-primary px-4 shadow-sm rounded-pill d-flex align-items-center gap-2" id="openBranchFormBtn">
                <i class="bi bi-plus-lg"></i> {{ __('Request New Branch') }}
            </button>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm mb-4 d-flex align-items-center" style="border-radius: 16px; background: rgba(16, 185, 129, 0.1); color: #065f46;">
            <i class="bi bi-check-circle-fill me-3 fs-4"></i>
            <div class="fw-bold">{{ session('success') }}</div>
        </div>
    @endif

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm mb-4" style="border-radius: 16px; background: rgba(239, 68, 68, 0.1); color: #991b1b;">
            <div class="d-flex align-items-center mb-2">
                <i class="bi bi-exclamation-triangle-fill me-3 fs-4"></i>
                <div class="fw-bold">{{ __('Please correct the following errors:') }}</div>
            </div>
            <ul class="mb-0 ps-5">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div id="branchListView">
        <div class="table-shell">
            <table class="table">
                <thead>
                    <tr>
                        <th>{{ __('Branch Name') }}</th>
                        <th>{{ __('Admin') }}</th>
                        <th>{{ __('OTP') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th>{{ __('Created At') }}</th>
                        <th class="text-end">{{ __('Actions') }}</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($branches as $branch)
                        <tr>
                            <td>
                                <div class="fw-bold">{{ $branch->name }}</div>
                                <small class="text-muted">{{ $branch->city }}, {{ $branch->country }}</small>
                            </td>
                            <td>
                                <div>{{ $branch->admin_name }}</div>
                                <small class="text-muted">{{ $branch->email }}</small>
                            </td>
                            <td>
                                @if($branch->branchAdmin() && $branch->branchAdmin()->otp_plain)
                                    <code class="bg-light px-2 py-1 rounded border shadow-sm text-primary" style="font-size: 0.9rem;">
                                        {{ $branch->branchAdmin()->otp_plain }}
                                    </code>
                                @else
                                    <span class="text-muted small">---</span>
                                @endif
                            </td>
                            <td>
                                <span class="status-pill status-{{ $branch->status }}">
                                    @switch($branch->status)
                                        @case('pending') {{ __('Pending Approval') }} @break
                                        @case('active') {{ __('Active') }} @break
                                        @case('rejected') {{ __('Rejected') }} @break
                                        @default {{ $branch->status }}
                                    @endswitch
                                </span>
                            </td>
                            <td>{{ $branch->created_at->format('Y-m-d') }}</td>
                            <td class="text-end">
                                @if($branch->status === 'active')
                                    <a href="{{ route('settings.branches.permissions.edit', $branch) }}" class="btn btn-sm btn-soft-info">
                                        <i class="bi bi-shield-lock me-1"></i> {{ __('Permissions') }}
                                    </a>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-5">
                                <i class="bi bi-diagram-2 text-muted opacity-25 display-1 d-block mb-3"></i>
                                <p class="text-muted">{{ __('No branches found. Start by requesting your first branch!') }}</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- View 2: Form (Redesigned to match student form) -->
    <div id="branchFormView" class="card-panel" style="display:none;">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h5 class="fw-bold mb-1">{{ __('Request New Branch') }}</h5>
                <p class="text-muted small mb-0">{{ __('Fill the information below to request a new branch enrollment') }}</p>
            </div>
            <button class="btn btn-custom-ghost btn-sm px-3" id="backToBranchesBtn">
                <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'right' : 'left' }} me-1"></i> {{ __('Back to Branches') }}
            </button>
        </div>

        <form action="{{ route('settings.branches.store') }}" method="POST">
            @csrf
            
            <!-- Section 1: Branch Info -->
            <div class="row g-4 mb-4">
                <div class="col-12">
                    <h6 class="text-primary fw-bold mb-0"><i class="bi bi-building me-2"></i>{{ __('Branch Information') }}</h6>
                    <hr class="mt-2 mb-3 opacity-50">
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-bold small">{{ __('Branch Name') }}</label>
                    <input type="text" name="name" class="form-control" placeholder="{{ __('e.g. EduLearn - North Branch') }}" required>
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-bold small">{{ __('Official Branch Email') }}</label>
                    <input type="email" name="email" class="form-control" placeholder="{{ __('branch@school.edu') }}" required>
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-bold small">{{ __('Phone Number') }}</label>
                    <input type="text" name="phone" class="form-control" placeholder="{{ __('+123...') }}">
                </div>
                <div class="col-md-12">
                    <label class="form-label fw-bold small">{{ __('Address') }}</label>
                    <input type="text" name="address" class="form-control" placeholder="{{ __('Full address') }}">
                </div>
            </div>

            <!-- Section 2: Admin Info -->
            <div class="row g-4 mb-4">
                <div class="col-12">
                    <div class="d-flex align-items-center justify-content-between">
                        <h6 class="text-primary fw-bold mb-0"><i class="bi bi-person-badge me-2"></i>{{ __('Branch Administrator') }}</h6>
                    </div>
                    <hr class="mt-2 mb-3 opacity-50">
                </div>
                
                <div class="col-12">
                    <div class="alert alert-info border-0 shadow-sm d-flex align-items-center py-2 px-3 mb-3" style="border-radius: 12px;">
                        <i class="bi bi-info-circle-fill me-3 fs-5"></i>
                        <div class="small">
                            {{ __('A temporary password will be generated for this user. They will be forced to change it upon their first login.') }}
                        </div>
                    </div>
                </div>

                <div class="col-md-4">
                    <label class="form-label fw-bold small">{{ __('Admin Full Name') }}</label>
                    <input type="text" name="admin_name" class="form-control" placeholder="{{ __('Full Name') }}" required>
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-bold small">{{ __('Admin Login Email') }}</label>
                    <input type="email" name="admin_email" class="form-control" placeholder="{{ __('admin@branch.com') }}" required>
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-bold small">{{ __('One-Time Password (OTP)') }}</label>
                    <div class="input-group">
                        <input type="text" name="admin_password" id="admin_password" class="form-control" placeholder="{{ __('Set a temporary password') }}" required>
                        <button class="btn btn-outline-secondary" type="button" id="generatePasswordBtn">
                            <i class="bi bi-magic"></i>
                        </button>
                    </div>
                    <small class="text-muted">{{ __('Branch admin must change this on first login.') }}</small>
                </div>
            </div>

            <div class="mt-4 pt-4 border-top text-end">
                <button type="button" class="btn btn-light px-4 me-2" id="cancelBranchBtn">{{ __('Cancel') }}</button>
                <button type="submit" class="btn btn-primary px-5 fw-bold">
                    <i class="bi bi-send-fill me-2"></i> {{ __('Submit Request') }}
                </button>
            </div>
        </form>
    </div>
</div>

<style>
    /* Reset table styles to prevent inheritance from reports-skin */
    .reports-skin .table-shell {
        background: var(--card) !important;
        border: 1px solid var(--border) !important;
        border-radius: 18px !important;
        box-shadow: var(--shadow-sm) !important;
        padding: 1rem 1rem .5rem !important;
    }

    .reports-skin .table thead th {
        background: transparent !important;
        color: #94a3b8 !important;
        font-size: .7rem !important;
        text-transform: uppercase !important;
        letter-spacing: .04em !important;
        border-bottom: none !important;
        padding: 0.75rem !important;
    }

    .reports-skin .table tbody td {
        border-bottom: 1px solid var(--border) !important;
        padding: 1rem 0.75rem !important;
        background: transparent !important;
    }

    /* Custom Ghost Button Style */
    .btn-custom-ghost {
        background: rgba(255, 255, 255, 0.05) !important;
        color: var(--title) !important;
        border: 0 !important;
        transition: all 0.3s ease;
    }

    .btn-custom-ghost:hover {
        background: rgba(255, 255, 255, 0.05) !important;
        color: var(--title) !important;
    }
</style>

@push('scripts')
<script src="{{ asset('js/branches.js') }}"></script>
@endpush
@endsection
