@extends('layouts.app')

@section('content')
<div class="container-fluid py-4">
    <div class="row g-4 mb-4">
        <!-- School Stats Cards -->
        <div class="col-6 col-xl-3">
            <div class="card-panel shadow-sm border-0 h-100 transition-all hover-translate-y" style="border-radius: 20px;">
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div class="icon-box bg-soft-primary text-primary shadow-sm" style="width: 50px; height: 50px; border-radius: 15px; display: flex; align-items: center; justify-content: center; background: rgba(0, 123, 255, 0.1);">
                        <i class="bi bi-people-fill fs-4"></i>
                    </div>
                    <div class="badge rounded-pill bg-soft-success text-success px-3 py-2" style="background: rgba(40, 167, 69, 0.1);">
                        <i class="bi bi-graph-up me-1"></i> +4.5%
                    </div>
                </div>
                <h6 class="text-muted small fw-bold text-uppercase mb-1" style="letter-spacing: 0.05em;">{{ __('Total Students') }}</h6>
                <h3 class="fw-bold text-title mb-0">{{ number_format($stats['students']) }}</h3>
                <div class="mt-3 d-flex flex-column flex-sm-row align-items-sm-center gap-2">
                    <div class="progress flex-grow-1" style="height: 4px; background: rgba(0,0,0,0.05);">
                        <div class="progress-bar bg-primary" style="width: 70%"></div>
                    </div>
                    <span class="x-small text-muted" style="font-size: 10px;">{{ __('Target') }}: 5k</span>
                </div>
            </div>
        </div>

        <div class="col-6 col-xl-3">
            <div class="card-panel shadow-sm border-0 h-100 transition-all hover-translate-y" style="border-radius: 20px;">
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div class="icon-box bg-soft-orange text-orange shadow-sm" style="width: 50px; height: 50px; border-radius: 15px; display: flex; align-items: center; justify-content: center; background: rgba(255, 152, 0, 0.1); color: #FF9800;">
                        <i class="bi bi-mortarboard-fill fs-4"></i>
                    </div>
                    <div class="badge rounded-pill bg-soft-info text-info px-3 py-2" style="background: rgba(0, 188, 212, 0.1);">
                        {{ __('Active') }}
                    </div>
                </div>
                <h6 class="text-muted small fw-bold text-uppercase mb-1" style="letter-spacing: 0.05em;">{{ __('Teachers') }}</h6>
                <h3 class="fw-bold text-title mb-0">{{ number_format($stats['teachers']) }}</h3>
                <div class="mt-3 d-flex align-items-center gap-2">
                    <div class="avatar-group d-flex">
                        <div class="avatar-sm rounded-circle border border-2 border-white" style="width: 24px; height: 24px; background: #eee; margin-left: -8px;"></div>
                        <div class="avatar-sm rounded-circle border border-2 border-white" style="width: 24px; height: 24px; background: #ddd; margin-left: -8px;"></div>
                        <div class="avatar-sm rounded-circle border border-2 border-white bg-primary text-white d-flex align-items-center justify-content-center" style="width: 24px; height: 24px; margin-left: -8px; font-size: 10px;">+5</div>
                    </div>
                    <span class="small text-muted">{{ __('On duty') }}</span>
                </div>
            </div>
        </div>

        <div class="col-6 col-xl-3">
            <div class="card-panel shadow-sm border-0 h-100 transition-all hover-translate-y" style="border-radius: 20px;">
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div class="icon-box bg-soft-success text-success shadow-sm" style="width: 50px; height: 50px; border-radius: 15px; display: flex; align-items: center; justify-content: center; background: rgba(40, 167, 69, 0.1);">
                        <i class="bi bi-check-circle-fill fs-4"></i>
                    </div>
                    <div class="badge rounded-pill bg-soft-warning text-warning px-3 py-2" style="background: rgba(255, 193, 7, 0.1);">
                        92%
                    </div>
                </div>
                <h6 class="text-muted small fw-bold text-uppercase mb-1" style="letter-spacing: 0.05em;">{{ __('Average Score') }}</h6>
                <h3 class="fw-bold text-title mb-0">{{ $stats['performance'] }}%</h3>
                <div class="mt-3 text-success small fw-semibold">
                    <i class="bi bi-caret-up-fill me-1"></i> {{ __('Improving trend') }}
                </div>
            </div>
        </div>

        <div class="col-6 col-xl-3">
            <div class="card-panel shadow-sm border-0 h-100 transition-all hover-translate-y" style="border-radius: 20px;">
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div class="icon-box bg-soft-danger text-danger shadow-sm" style="width: 50px; height: 50px; border-radius: 15px; display: flex; align-items: center; justify-content: center; background: rgba(220, 53, 69, 0.1);">
                        <i class="bi bi-exclamation-triangle-fill fs-4"></i>
                    </div>
                    <div class="badge rounded-pill bg-soft-danger text-danger px-3 py-2" style="background: rgba(220, 53, 69, 0.1);">
                        {{ __('Critical') }}
                    </div>
                </div>
                <h6 class="text-muted small fw-bold text-uppercase mb-1" style="letter-spacing: 0.05em;">{{ __('Dangling Students') }}</h6>
                <h3 class="fw-bold text-title mb-0">{{ number_format($stats['danglingStudents']) }}</h3>
                <div class="mt-3 text-muted small">
                    {{ __('Needs branch assignment') }}
                </div>
            </div>
        </div>
    </div>

    <div class="row g-4 mb-4">
        <!-- Main Dashboard Content -->
        <div class="col-lg-4">
            <div class="card-panel border-0 shadow-sm h-100 p-4 quick-actions-card" style="border-radius: 20px;">
                <div class="d-flex justify-content-between align-items-start mb-4">
                    <div>
                        <h5 class="fw-bold mb-1 text-title">{{ __('Quick Actions') }}</h5>
                        <p class="text-subtitle small mb-0">{{ __('Streamline your tasks') }}</p>
                    </div>
                    <div class="icon-circle rounded-circle p-2 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                        <i class="bi bi-lightning-charge text-orange fs-5"></i>
                    </div>
                </div>
                <div class="row g-3">
                    <div class="col-6">
                        <a href="{{ route('students.index') }}" class="action-btn text-decoration-none d-flex flex-column align-items-center p-3 rounded-4 transition-all">
                            <i class="bi bi-person-plus fs-4 text-orange mb-2"></i>
                            <span class="small fw-semibold text-title">{{ __('Add Student') }}</span>
                        </a>
                    </div>
                    <div class="col-6">
                        <a href="{{ route('teachers.index') }}" class="action-btn text-decoration-none d-flex flex-column align-items-center p-3 rounded-4 transition-all">
                            <i class="bi bi-person-badge fs-4 text-info mb-2"></i>
                            <span class="small fw-semibold text-title">{{ __('Staff') }}</span>
                        </a>
                    </div>
                    <div class="col-6">
                        <a href="{{ route('reports.index') }}" class="action-btn text-decoration-none d-flex flex-column align-items-center p-3 rounded-4 transition-all">
                            <i class="bi bi-bar-chart-line fs-4 text-danger mb-2"></i>
                            <span class="small fw-semibold text-title">{{ __('Reports') }}</span>
                        </a>
                    </div>
                    <div class="col-12 mt-2">
                        <a href="{{ route('settings.index') }}" class="action-btn text-decoration-none d-flex align-items-center justify-content-center gap-2 p-2 rounded-4 transition-all">
                            <i class="bi bi-gear fs-5 text-secondary"></i>
                            <span class="small fw-semibold text-title">{{ __('System Settings') }}</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- AI Analytics Report -->
        <div class="col-lg-8">
            <div class="card-panel h-100 shadow-sm overflow-hidden position-relative" style="border-left: 5px solid #001A33 !important;">
                <div class="d-flex flex-column flex-md-row justify-content-between align-items-start gap-3 mb-3">
                    <div>
                        <h5 class="fw-bold mb-0 d-flex align-items-center text-title">
                            <i class="bi bi-stars text-primary me-2"></i>
                            {{ __('AI Data Analysis Report') }}
                        </h5>
                        <p class="text-muted small mb-0">{{ app()->getLocale() === 'ar' ? 'رؤية أداء على مستوى النظام' : 'System-wide performance insight' }}</p>
                    </div>
                    <div class="d-flex flex-wrap gap-2">
                        <button class="btn btn-outline-secondary btn-sm rounded-pill px-3 no-print" id="copyAiInsight" onclick="copyAiText()" style="display:none;">
                            <i class="bi bi-clipboard me-1"></i> {{ __('Copy') }}
                        </button>
                        <span class="badge rounded-pill px-3 py-2" style="background: linear-gradient(135deg, #001A33, #003366); font-size: 10px;">{{ __('Powered by Gemini') }}</span>
                    </div>
                </div>
                <div class="ai-report-content h-100" id="aiInsightContainer">
                    @if($aiInsight)
                        <div class="space-y-3 p-1" id="aiInsightText">
                            {!! $aiInsight !!}
                        </div>
                        <div id="styledAiReport"></div>
                    @else
                        <div class="d-flex flex-column align-items-center justify-content-center py-5 text-center" id="aiLoadingState">
                            <div class="icon-box mb-3" style="width: 50px; height: 50px; border-radius: 15px; background: rgba(0, 26, 51, 0.05);">
                                <i class="bi bi-robot fs-3 text-navy"></i>
                            </div>
                            <h6 class="fw-bold text-navy mb-1 small">{{ __('No Strategic Analysis') }}</h6>
                            <p class="text-muted small px-3 mb-3">{{ __('Generate a report in the Reports section to see AI-styled insights here.') }}</p>
                            <a href="{{ route('reports.index') }}" class="btn btn-navy btn-sm rounded-pill px-4 mt-1">
                                {{ __('Generate Now') }}
                            </a>
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>

    <div class="row g-4">
        <!-- Chart: Student Distribution -->
        <div class="col-lg-5">
            <div class="card-panel border-0 shadow-sm h-100">
                <h5 class="fw-bold mb-4">{{ __('Student Distribution by Section') }}</h5>
                <div style="position: relative; height: 300px;">
                    <canvas id="sectionChart"></canvas>
                </div>
            </div>
        </div>

        <div class="col-lg-7">
            <div class="card-panel border-0 shadow-sm h-100">
                <h5 class="fw-bold mb-4 text-title">{{ __('School Health Checks') }}</h5>
                <div class="table-responsive">
                    <table class="table table-hover table-borderless align-middle mb-0">
                        <thead class="border-bottom">
                            <tr class="text-muted small text-uppercase" style="letter-spacing: 0.05em;">
                                <th class="pb-3 fw-bold ps-0 text-title">{{ __('Indicator') }}</th>
                                <th class="pb-3 fw-bold text-title d-none d-sm-table-cell">{{ __('Status') }}</th>
                                <th class="pb-3 fw-bold w-25 pe-0 text-title">{{ __('Progress') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr style="border-bottom: 1px solid var(--border);">
                                <td class="py-3 ps-0">
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="icon-box shadow-sm" style="width: 40px; height: 40px; border-radius: 10px; background: rgba(16, 185, 129, 0.1); color: #10b981;">
                                            <i class="bi bi-people-fill fs-5"></i>
                                        </div>
                                        <div>
                                            <div class="fw-bold text-title mb-1">{{ __('Staff Availability') }}</div>
                                            <small class="text-muted" id="staffCountText">{{ $stats['teachers'] }} {{ __('Active Personnel') }}</small>
                                        </div>
                                    </div>
                                </td>
                                <td class="py-3">
                                    <span class="badge rounded-pill px-3 py-2 fw-semibold d-none d-sm-inline-block" id="staffStatusBadge" style="background: rgba(16, 185, 129, 0.1); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.2);">{{ __('Optimal') }}</span>
                                </td>
                                <td class="py-3 pe-0">
                                    <div class="progress" style="height: 6px; border-radius: 10px; background-color: rgba(16, 185, 129, 0.1);">
                                        <div class="progress-bar rounded-pill" id="staffProgressBar" style="width: 100%; background-color: #10b981;"></div>
                                    </div>
                                </td>
                            </tr>
                            <tr style="border-bottom: 1px solid var(--border);">
                                <td class="py-3 ps-0">
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="icon-box shadow-sm" style="width: 40px; height: 40px; border-radius: 10px; background: rgba(239, 68, 68, 0.1); color: #ef4444;">
                                            <i class="bi bi-person-x-fill fs-5"></i>
                                        </div>
                                        <div>
                                            <div class="fw-bold text-title mb-1">{{ __('Unassigned Students') }}</div>
                                            <small class="text-muted" id="unassignedCountText" style="color: #ef4444 !important;">{{ $stats['danglingStudents'] }} {{ __('Requires Action') }}</small>
                                        </div>
                                    </div>
                                </td>
                                <td class="py-3">
                                    <span class="badge rounded-pill px-3 py-2 fw-semibold d-none d-sm-inline-block" id="unassignedStatusBadge" style="background: rgba(239, 68, 68, 0.1); color: #ef4444; border: 1px solid rgba(239, 68, 68, 0.2);">{{ __('Critical') }}</span>
                                </td>
                                <td class="py-3 pe-0">
                                    <div class="progress" style="height: 6px; border-radius: 10px; background-color: rgba(239, 68, 68, 0.1);">
                                        <div class="progress-bar rounded-pill" id="unassignedProgressBar" style="width: 25%; background-color: #ef4444;"></div>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td class="py-3 ps-0">
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="icon-box shadow-sm" style="width: 40px; height: 40px; border-radius: 10px; background: rgba(6, 182, 212, 0.1); color: #06b6d4;">
                                            <i class="bi bi-graph-up-arrow fs-5"></i>
                                        </div>
                                        <div>
                                            <div class="fw-bold text-title mb-1">{{ __('Academic Progress') }}</div>
                                            <small class="text-muted" id="progressCountText">{{ __('Median Score') }}: {{ $stats['performance'] }}%</small>
                                        </div>
                                    </div>
                                </td>
                                <td class="py-3">
                                    <span class="badge rounded-pill px-3 py-2 fw-semibold d-none d-sm-inline-block" id="progressStatusBadge" style="background: rgba(6, 182, 212, 0.1); color: #06b6d4; border: 1px solid rgba(6, 182, 212, 0.2);">{{ __('Stable') }}</span>
                                </td>
                                <td class="py-3 pe-0">
                                    <div class="progress" style="height: 6px; border-radius: 10px; background-color: rgba(6, 182, 212, 0.1);">
                                        <div class="progress-bar rounded-pill" id="academicProgressBar" style="width: {{ $stats['performance'] }}%; background-color: #06b6d4;"></div>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

@push('styles')
<style>
    .quick-actions-card { 
        background: #001A33; 
        color: white; 
    }
    body:not(.dark-mode) .quick-actions-card { 
        background: white; 
        color: var(--title); 
        border: 1px solid var(--border) !important;
    }
    
    .text-subtitle { color: rgba(255,255,255,0.7); }
    body:not(.dark-mode) .text-subtitle { color: var(--muted); }
    
    .icon-circle { background: rgba(255,255,255,0.1); }
    body:not(.dark-mode) .icon-circle { background: rgba(0,26,51,0.05); }

    .action-btn { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); color: white; }
    body:not(.dark-mode) .action-btn { 
        background: #f8fafc; 
        border: 1px solid #e2e8f0; 
        color: var(--title); 
    }
    
    .action-btn:hover { background: rgba(255,255,255,0.15); transform: translateY(-3px); color: #FF9800; }
    body:not(.dark-mode) .action-btn:hover { 
        background: #f1f5f9; 
        border-color: #cbd5e1; 
        color: #FF9800;
    }

    .text-orange { color: #FF9800 !important; }
    .text-navy { color: #001A33 !important; }

    .hover-translate-y:hover { transform: translateY(-5px); }
    .icon-box { display: flex; align-items: center; justify-content: center; }
    .avatar-group .avatar-sm:first-child { margin-left: 0; }
    .card-panel { background: white; border-radius: 20px; padding: 1.5rem; }
    
    /* Markdown Styles for AI Report */
    .markdown-body h1, .markdown-body h2, .markdown-body h3 { color: var(--navy); margin-top: 1.5rem; margin-bottom: 1rem; font-weight: 700; }
    .markdown-body p { margin-bottom: 1rem; color: #475569; }
    .markdown-body ul, .markdown-body ol { margin-bottom: 1rem; padding-left: 1.5rem; }
    .markdown-body li { margin-bottom: 0.5rem; color: #475569; }
    .markdown-body table { width: 100%; margin-bottom: 1rem; border-collapse: collapse; }
    .markdown-body th, .markdown-body td { padding: 0.75rem; border: 1px solid #e2e8f0; }
    .markdown-body th { background-color: #f8fafc; font-weight: 600; }
</style>
@endpush

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Chart: Section Distribution
        let sectionChartInstance = null;
        const ctx = document.getElementById('sectionChart');
        if (ctx) {
            sectionChartInstance = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: {!! json_encode($stats['chartData']['labels']) !!},
                    datasets: [{
                        data: {!! json_encode($stats['chartData']['data']) !!},
                        backgroundColor: ['#001A33', '#FF9800', '#00ACC1', '#43A047', '#E53935'],
                        borderWidth: 0,
                        hoverOffset: 15
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { usePointStyle: true, padding: 20, font: { family: 'Inter', size: 12 } } }
                    },
                    cutout: '75%'
                }
            });
        }

        // Render AI Insight if exists
        const aiTextEl = document.getElementById('aiInsightText');
        const styledReportEl = document.getElementById('styledAiReport');
        
        if (aiTextEl && aiTextEl.innerHTML.trim() !== '' && styledReportEl) {
            try {
                const rawContent = aiTextEl.innerText || aiTextEl.textContent;
                
                // --- Extract Data Block ---
                const dataMatch = rawContent.match(/<data>([\s\S]*?)<\/data>/);
                if (dataMatch && dataMatch[1]) {
                    try {
                        const aiData = JSON.parse(dataMatch[1].trim());
                        updateDashboardWithAiData(aiData);
                    } catch (e) {
                        console.error("AI Data Parsing Error:", e);
                    }
                }

                // --- Clean content for display (remove data tag) ---
                const displayContent = rawContent.replace(/<data>[\s\S]*?<\/data>/, '').trim();
                
                // --- Premium Tailwind Styler ---
                const lines = displayContent.split('\n').filter(l => l.trim() !== '');
                let html = '';
                let currentSection = null;

                const sections = {
                    summary: { title: '{{ __("Executive Summary") }}', icon: 'lightning-fill', color: 'orange', items: [] },
                    strengths: { title: '{{ __("Core Strengths") }}', icon: 'check-circle-fill', color: 'success', items: [] },
                    risks: { title: '{{ __("Critical Risks") }}', icon: 'exclamation-triangle-fill', color: 'danger', items: [] },
                    recommendations: { title: '{{ __("Next Steps") }}', icon: 'arrow-right-circle-fill', color: 'primary', items: [] }
                };

                lines.forEach(line => {
                    const l = line.trim();
                    if (l.toLowerCase().includes('summary')) currentSection = 'summary';
                    else if (l.toLowerCase().includes('strength')) currentSection = 'strengths';
                    else if (l.toLowerCase().includes('risk')) currentSection = 'risks';
                    else if (l.toLowerCase().includes('recommendation')) currentSection = 'recommendations';
                    else if (l.startsWith('*') || l.startsWith('-')) {
                        const content = l.replace(/^[\*\-]\s*/, '');
                        if (currentSection) sections[currentSection].items.push(content);
                    }
                });

                Object.values(sections).forEach(sec => {
                    if (sec.items.length > 0) {
                        html += `
                            <div class="mb-3 p-3 rounded-4 bg-white shadow-sm border-start border-4 border-${sec.color === 'orange' ? 'navy' : sec.color}" style="${sec.color === 'orange' ? 'border-left-color: #FF9800 !important' : ''}">
                                <div class="d-flex align-items-center gap-2 mb-2">
                                    <i class="bi bi-${sec.icon} text-${sec.color}"></i>
                                    <span class="fw-bold small text-navy uppercase tracking-wider">${sec.title}</span>
                                </div>
                                <ul class="list-unstyled mb-0">
                                    ${sec.items.slice(0, 3).map(item => `
                                        <li class="d-flex align-items-start gap-2 mb-2">
                                            <i class="bi bi-dot fs-4 text-muted mt-n1"></i>
                                            <span class="small text-muted" style="line-height: 1.4;">${item}</span>
                                        </li>
                                    `).join('')}
                                </ul>
                            </div>
                        `;
                    }
                });

                styledReportEl.innerHTML = html || marked.parse(displayContent);
                aiTextEl.style.display = 'none'; // Hide the raw text
                document.getElementById('copyAiInsight').style.display = 'block';
            } catch(e) {
                console.error("Dashboard AI render error:", e);
                styledReportEl.innerHTML = marked.parse(aiTextEl.innerText);
            }
        }

        function updateDashboardWithAiData(data) {
            // Update Health Table
            if (data.health) {
                const mappings = {
                    'Staff Availability': { badge: 'staffStatusBadge', bar: 'staffProgressBar' },
                    'Unassigned Students': { badge: 'unassignedStatusBadge', bar: 'unassignedProgressBar' },
                    'Academic Progress': { badge: 'progressStatusBadge', bar: 'academicProgressBar' }
                };

                const statusThemes = {
                    'Optimal': { bg: 'rgba(16, 185, 129, 0.1)', text: '#10b981', border: 'rgba(16, 185, 129, 0.2)', bar: '#10b981' },
                    'Stable': { bg: 'rgba(6, 182, 212, 0.1)', text: '#06b6d4', border: 'rgba(6, 182, 212, 0.2)', bar: '#06b6d4' },
                    'Warning': { bg: 'rgba(245, 158, 11, 0.1)', text: '#f59e0b', border: 'rgba(245, 158, 11, 0.2)', bar: '#f59e0b' },
                    'Critical': { bg: 'rgba(239, 68, 68, 0.1)', text: '#ef4444', border: 'rgba(239, 68, 68, 0.2)', bar: '#ef4444' }
                };

                data.health.forEach(item => {
                    const map = mappings[item.indicator];
                    if (map) {
                        const badge = document.getElementById(map.badge);
                        const bar = document.getElementById(map.bar);
                        const theme = statusThemes[item.status] || statusThemes['Stable'];

                        if (badge) {
                            badge.textContent = item.status;
                            badge.style.backgroundColor = theme.bg;
                            badge.style.color = theme.text;
                            badge.style.borderColor = theme.border;
                        }
                        if (bar) {
                            bar.style.width = item.progress + '%';
                            bar.style.backgroundColor = theme.bar;
                            bar.parentElement.style.backgroundColor = theme.bg;
                        }
                    }
                });
            }

            // Update Chart
            if (data.distribution && sectionChartInstance) {
                sectionChartInstance.data.labels = data.distribution.labels;
                sectionChartInstance.data.datasets[0].data = data.distribution.values;
                sectionChartInstance.update();
            }
        }
    });

    function copyAiText() {
        const text = document.getElementById('aiInsightText').innerText;
        navigator.clipboard.writeText(text).then(() => {
            const btn = document.getElementById('copyAiInsight');
            const original = btn.innerHTML;
            btn.innerHTML = '<i class="bi bi-check2"></i> {{ __("Copied") }}';
            setTimeout(() => btn.innerHTML = original, 2000);
        });
    }
</script>
@endpush
@endsection
