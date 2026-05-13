@extends('super_admin.layout')
@section('title', __('Platform Analytics'))

@push('head')
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
@endpush

@section('content')
<div class="sa-header">
    <div>
        <h1><i class="bi bi-bar-chart-fill me-2" style="color: var(--orange);"></i>{{ __('Platform Analytics') }}</h1>
        <p>{{ __('Comprehensive overview of platform growth and user engagement') }}</p>
    </div>
</div>

<!-- Stats -->
<div class="row g-4 mb-4">
    <div class="col-md-3">
        <div class="sa-card sa-stat">
            <div class="label">{{ __('Total Schools') }}</div>
            <div class="value">{{ $stats['total_schools'] }}</div>
            <i class="bi bi-buildings sa-stat-icon"></i>
        </div>
    </div>
    <div class="col-md-3">
        <div class="sa-card sa-stat">
            <div class="label">{{ __('Total Students') }}</div>
            <div class="value" style="color: #10b981;">{{ $stats['total_students'] }}</div>
            <i class="bi bi-people sa-stat-icon"></i>
        </div>
    </div>
    <div class="col-md-3">
        <div class="sa-card sa-stat">
            <div class="label">{{ __('Total Teachers') }}</div>
            <div class="value" style="color: #4da6ff;">{{ $stats['total_teachers'] }}</div>
            <i class="bi bi-person-badge sa-stat-icon"></i>
        </div>
    </div>
    <div class="col-md-3">
        <div class="sa-card sa-stat">
            <div class="label">{{ __('Total Subjects') }}</div>
            <div class="value" style="color: var(--orange);">{{ $stats['total_subjects'] }}</div>
            <i class="bi bi-journal-text sa-stat-icon"></i>
        </div>
    </div>
</div>

<!-- Charts -->
<div class="row g-4">
    <div class="col-md-8">
        <div class="sa-card">
            <h5><i class="bi bi-graph-up me-2"></i>{{ __('School Growth (Last 6 Months)') }}</h5>
            <div style="height: 300px;"><canvas id="growthChart"></canvas></div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="sa-card">
            <h5><i class="bi bi-pie-chart me-2"></i>{{ __('School Distribution') }}</h5>
            <div style="height: 300px;"><canvas id="schoolStatusChart"></canvas></div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    Chart.defaults.color = '#94a3b8';

    new Chart(document.getElementById('growthChart'), {
        type: 'line',
        data: {
            labels: {!! json_encode($growth->pluck('month')) !!},
            datasets: [{
                label: '{{ __("New Schools") }}',
                data: {!! json_encode($growth->pluck('count')) !!},
                borderColor: '#FF6600',
                backgroundColor: 'rgba(255,102,0,0.08)',
                fill: true, tension: 0.4, borderWidth: 2.5,
                pointRadius: 4, pointBackgroundColor: '#FF6600'
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { color: 'rgba(255,255,255,0.04)' } },
                y: { grid: { color: 'rgba(255,255,255,0.04)' }, beginAtZero: true, ticks: { stepSize: 1 } }
            }
        }
    });

    new Chart(document.getElementById('schoolStatusChart'), {
        type: 'doughnut',
        data: {
            labels: ['{{ __("Active") }}', '{{ __("Other") }}'],
            datasets: [{
                data: [{{ $stats['active_schools'] }}, {{ $stats['total_schools'] - $stats['active_schools'] }}],
                backgroundColor: ['#10b981', '#003366'],
                borderWidth: 0, hoverOffset: 12
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false, cutout: '65%',
            plugins: { legend: { position: 'bottom', labels: { padding: 16, usePointStyle: true, color: '#94a3b8' } } }
        }
    });
</script>
@endpush
