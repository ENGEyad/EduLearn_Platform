@extends('layouts.app')

@section('content')
<div class="reports-skin">
    <div class="page-header d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="page-title">{{ __('Branch Requests Status') }}</h2>
            <p class="subtitle">{{ __('Track the status of your requests sent to the Super Admin') }}</p>
        </div>
        <div class="d-flex gap-2">
            <button onclick="window.location.reload()" class="btn btn-light rounded-pill px-3 border shadow-sm">
                <i class="bi bi-arrow-clockwise"></i>
            </button>
            <a href="{{ route('settings.branches.index') }}" class="btn btn-outline-secondary rounded-pill px-3">
                <i class="bi bi-arrow-left me-1"></i> {{ __('Back') }}
            </a>
            <a href="{{ route('settings.branches.index') }}" class="btn btn-primary rounded-pill px-3 shadow-sm">
                <i class="bi bi-plus-lg me-1"></i> {{ __('New Request') }}
            </a>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm mb-4 d-flex align-items-center rounded-4">
            <i class="bi bi-check-circle-fill me-3 fs-4"></i>
            <div>{{ session('success') }}</div>
        </div>
    @endif

    <div class="table-shell table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="bg-light text-title small text-uppercase">
                <tr>
                    <th class="ps-4">{{ __('Branch Details') }}</th>
                    <th>{{ __('Admin Assigned') }}</th>
                    <th>{{ __('Status') }}</th>
                    <th>{{ __('Request Date') }}</th>
                    <th>{{ __('Note / Feedback') }}</th>
                    <th class="text-end pe-4">{{ __('Actions') }}</th>
                </tr>
            </thead>

            <tbody>
                @forelse($branches as $branch)
                <tr>
                    <td class="ps-4">
                        <div class="fw-bold text-title">{{ $branch->name }}</div>
                        <div class="text-secondary small">{{ $branch->email }}</div>
                    </td>
                    <td>
                        <div class="fw-medium">{{ $branch->admin_name }}</div>
                        <div class="text-secondary small">{{ $branch->branchAdmin() ? $branch->branchAdmin()->email : __('N/A') }}</div>
                    </td>
                    <td>
                        <span class="status-badge status-{{ $branch->status }}">
                            @switch($branch->status)
                                @case('pending') {{ __('Pending Approval') }} @break
                                @case('active') {{ __('Approved & Active') }} @break
                                @case('rejected') {{ __('Rejected') }} @break
                                @case('suspended') {{ __('Suspended') }} @break
                                @default {{ $branch->status }}
                            @endswitch
                        </span>
                    </td>
                    <td>
                        <div class="small">{{ $branch->created_at->format('Y/m/d') }}</div>
                        <div class="text-secondary extra-small">{{ $branch->created_at->diffForHumans() }}</div>
                    </td>
                    <td>
                        @if($branch->rejection_reason)
                            <span class="text-muted small italic" title="{{ $branch->rejection_reason }}">
                                <i class="bi bi-info-circle me-1"></i> {{ Str::limit($branch->rejection_reason, 30) }}
                            </span>
                        @else
                            <span class="text-secondary small">--</span>
                        @endif
                    </td>
                    <td class="text-end pe-4">
                        @if($branch->status === 'pending')
                        <div class="d-flex justify-content-end gap-2">
                            <a href="{{ route('settings.branches.requests.edit', $branch) }}" class="btn btn-sm btn-outline-secondary rounded-pill px-3" title="{{ __('Edit') }}">
                                <i class="bi bi-pencil me-1"></i> {{ __('Edit') }}
                            </a>
                            
                            <form action="{{ route('settings.branches.requests.destroy', $branch) }}" method="POST" onsubmit="return confirm('{{ __('Are you sure you want to delete this request?') }}')">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill px-3">
                                    <i class="bi bi-trash me-1"></i> {{ __('Delete') }}
                                </button>
                            </form>
                        </div>
                        @else
                        <span class="text-muted small">{{ __('Processed') }}</span>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" class="text-center py-5">
                        <div class="text-muted">
                            <i class="bi bi-inbox fs-2 mb-3 d-block"></i>
                            {{ __('No requests found.') }}
                        </div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<style>
/* Glassmorphism Design System */
.reports-skin {
    background: transparent;
    padding: 20px;
}

.page-header {
    margin-bottom: 2rem;
}

.table-shell {
    background: rgba(255, 255, 255, 0.7);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 30px;
    box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.07);
    overflow: hidden;
    transition: all 0.4s ease;
}

body.dark-mode .table-shell {
    background: rgba(30, 41, 59, 0.6);
    border: 1px solid rgba(255, 255, 255, 0.05);
    box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.2);
}

.table {
    margin-bottom: 0;
    border-collapse: separate;
    border-spacing: 0 8px;
    background: transparent !important;
}

.table thead th {
    background: rgba(248, 250, 252, 0.4);
    border: none;
    padding: 1.25rem 1rem;
    color: var(--title);
    font-weight: 700;
    font-size: 0.75rem;
    letter-spacing: 1px;
}

body.dark-mode .table thead th {
    background: rgba(255, 255, 255, 0.8) !important;
    color: #000000 !important;
}

body.dark-mode .text-title, 
body.dark-mode .small,
body.dark-mode .text-secondary { 
    color: #ffffff !important; 
}
body.dark-mode .extra-small {
    color: rgba(255, 255, 255, 0.7) !important;
}

.table tbody tr {
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    border-radius: 15px;
}

.table tbody tr td {
    padding: 1.5rem 1rem;
    background: transparent;
    border-bottom: 1px solid rgba(0,0,0,0.03);
}

body.dark-mode .table tbody tr td {
    border-bottom: 1px solid rgba(255,255,255,0.03);
}

.table tbody tr:hover {
    background: rgba(255,255,255,0.4) !important;
    transform: scale(1.002);
}

body.dark-mode .table tbody tr:hover {
    background: rgba(255,255,255,0.03) !important;
}

/* Status Badges - Glass Style */
.status-badge {
    padding: 8px 16px;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 700;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.status-pending { 
    background: rgba(245, 158, 11, 0.15); 
    color: #d97706; 
    border: 1px solid rgba(245, 158, 11, 0.1); 
}
.status-active { 
    background: rgba(16, 185, 129, 0.15); 
    color: #059669; 
    border: 1px solid rgba(16, 185, 129, 0.1); 
}
.status-rejected { 
    background: rgba(239, 68, 68, 0.15); 
    color: #dc2626; 
    border: 1px solid rgba(239, 68, 68, 0.1); 
}

.text-title { color: var(--title); font-weight: 600; }
.extra-small { font-size: 0.7rem; opacity: 0.7; }

/* Custom Scrollbar for Glassy Look */
.table-responsive::-webkit-scrollbar {
    height: 6px;
}
.table-responsive::-webkit-scrollbar-track {
    background: rgba(0,0,0,0.02);
}
.table-responsive::-webkit-scrollbar-thumb {
    background: rgba(0,0,0,0.1);
    border-radius: 10px;
}
</style>
@endsection
