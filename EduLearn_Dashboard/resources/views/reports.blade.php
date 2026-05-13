@extends('layouts.app')

@section('content')

<div class="reports-skin"><!-- سكوب التصميم الخاص بالتقارير -->
  <!-- الهيدر الخاص بالطباعة فقط -->
  <div id="globalPrintHeader" class="d-none">
    <div class="d-flex align-items-center justify-content-between p-4 mb-4 border-bottom border-3 border-orange">
        <div class="d-flex align-items-center gap-3">
            <img src="{{ auth()->user()->school->logo_url ?? asset('images/logo-placeholder.png') }}" alt="Logo" style="width: 100px; height: 100px; object-fit: contain;">
            <div>
                <h3 class="mb-0 fw-bold text-navy">{{ auth()->user()->school->name }}</h3>
                <p class="text-muted small mb-0">{{ __('Official Academic Report') }}</p>
                <div class="text-navy small">{{ __('Academic Year') }}: {{ auth()->user()->school->academic_year ?? '2023-2024' }}</div>
            </div>
        </div>
        <div class="text-end">
            <h1 id="printReportTitle" class="text-navy fw-800 mb-1" style="font-size: 2.5rem;">{{ __('REPORT') }}</h1>
            <p class="text-muted small mb-0">{{ __('Date') }}: {{ date('Y/m/d') }}</p>
        </div>
    </div>
  </div>

  {{-- ===== View 1: Class Reports List ===== --}}
  <div id="reportsListView">
    <div class="content-wrap">
      <div class="page-header flex-column flex-md-row align-items-start align-items-md-center gap-3 mb-4">
        <div>
          <h2 class="page-title">{{ __('Class & Student Reports') }}</h2>
          <div class="text-muted small">{{ __('Analyze performance data and generate official academic reports.') }}</div>
        </div>
        <div class="d-flex flex-wrap gap-2 w-100 w-md-auto justify-content-start justify-content-md-end">
          <button class="btn btn-outline-secondary js-refresh-list" title="{{ __('Refresh') }}">
            <i class="bi bi-arrow-clockwise"></i>
          </button>
          <button class="btn btn-ai-strategic js-generate-ai shadow-sm px-4 flex-grow-1 flex-md-grow-0">
            <i class="bi bi-cpu-fill me-2 text-orange"></i> {{ __('Strategic AI Report') }}
          </button>
          <button class="btn btn-primary js-generate shadow-sm px-4 flex-grow-1 flex-md-grow-0">
            <i class="bi bi-file-bar-graph-fill me-2"></i> {{ __('Generate Report') }}
          </button>
        </div>
      </div>

      <!-- Quick Stats Overview -->
      <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
          <div class="cardy p-3 h-100 d-flex flex-column justify-content-between" style="border-left: 4px solid var(--primary) !important;">
            <div class="text-muted small mb-2 fw-bold text-uppercase">{{ __('Total Students') }}</div>
            <div class="d-flex align-items-center justify-content-between">
              <h3 class="mb-0 fw-800" id="topStatStudents">0</h3>
              <div class="rounded-pill px-2 py-1 bg-primary-soft text-primary small"><i class="bi bi-people"></i></div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="cardy p-3 h-100 d-flex flex-column justify-content-between" style="border-left: 4px solid #10b981 !important;">
            <div class="text-muted small mb-2 fw-bold text-uppercase">{{ __('Avg. Score') }}</div>
            <div class="d-flex align-items-center justify-content-between">
              <h3 class="mb-0 fw-800" id="topStatAvg">0%</h3>
              <div class="rounded-pill px-2 py-1 bg-success-soft text-success small"><i class="bi bi-graph-up"></i></div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="cardy p-3 h-100 d-flex flex-column justify-content-between" style="border-left: 4px solid #f59e0b !important;">
            <div class="text-muted small mb-2 fw-bold text-uppercase">{{ __('Attendance') }}</div>
            <div class="d-flex align-items-center justify-content-between">
              <h3 class="mb-0 fw-800" id="topStatAtt">0%</h3>
              <div class="rounded-pill px-2 py-1 bg-warning-soft text-warning small"><i class="bi bi-calendar-check"></i></div>
            </div>
          </div>
        </div>
        <div class="col-6 col-md-3">
          <div class="cardy p-3 h-100 d-flex flex-column justify-content-between" style="border-left: 4px solid #ef4444 !important;">
            <div class="text-muted small mb-2 fw-bold text-uppercase">{{ __('Lessons Done') }}</div>
            <div class="d-flex align-items-center justify-content-between">
              <h3 class="mb-0 fw-800" id="topStatLessons">0</h3>
              <div class="rounded-pill px-2 py-1 bg-danger-soft text-danger small"><i class="bi bi-book"></i></div>
            </div>
          </div>
        </div>
      </div>

      {{-- AI Report Archive --}}
      @if(isset($aiReports) && $aiReports->count() > 0)
      <div class="cardy mb-4 border-0 shadow-sm overflow-hidden" style="background: linear-gradient(135deg, #001A33 0%, #003366 100%); border-radius: 24px;">
          <div class="p-4">
              <div class="d-flex align-items-center justify-content-between mb-4">
                  <div>
                      <h5 class="text-white mb-1 fw-bold"><i class="bi bi-archive me-2 text-orange"></i> {{ __('Strategic Report Archive') }}</h5>
                      <p class="text-white-50 small mb-0">{{ __('Revisit your past AI-powered analytical insights.') }}</p>
                  </div>
                  <div class="d-flex align-items-center gap-3">
                      <a href="#" class="text-white-50 text-decoration-none small hover-white js-view-all-reports">
                          {{ __('View History') }} <i class="bi bi-arrow-right ms-1"></i>
                      </a>
                      <span class="badge rounded-pill bg-orange px-3 py-2 fw-bold">{{ $aiReports->count() }} {{ __('Reports Available') }}</span>
                  </div>
              </div>
              <div class="row g-3">
                  @foreach($aiReports->take(3) as $report)
                  <div class="col-md-4">
                      <div class="bg-white bg-opacity-10 rounded-4 p-4 border border-white border-opacity-10 h-100 transition-all hover-translate-y card-hover-glow">
                          <div class="d-flex justify-content-between align-items-start mb-3">
                              <div class="text-white fw-bold">{{ $report->title }}</div>
                              <div class="badge bg-white bg-opacity-20 text-white x-small">{{ $report->created_at->format('M d, Y') }}</div>
                          </div>
                          <div class="text-white-50 x-small mb-4 line-clamp-3" style="min-height: 3.5em;">
                              {{ Str::limit(strip_tags($report->dashboard_summary ?? $report->content), 120) }}
                          </div>
                          <button class="btn btn-orange btn-sm w-100 rounded-pill py-2 fw-bold js-view-archived-report" data-id="{{ $report->id }}">
                              <i class="bi bi-eye me-1"></i> {{ __('View Strategic Insights') }}
                          </button>
                      </div>
                  </div>
                  @endforeach
              </div>
          </div>
      </div>
      @endif

      <div class="filters flex-column flex-md-row mb-3 gap-3">
        <div class="input-group w-100" style="max-width:320px">
          <span class="input-group-text border-end-0"><i class="bi bi-search"></i></span>
          <input id="filterSearch" type="text" class="form-control border-start-0" placeholder="{{ __('Search by student, teacher, class') }}">
        </div>

        <div class="d-flex flex-column flex-sm-row gap-2 w-100 w-md-auto">
          <select id="filterClass" class="form-select flex-grow-1" style="max-width:220px">
            <option value="">{{ __('All Classes') }}</option>
            @foreach($classes_dropdown as $cls)
                <option value="{{ $cls->grade }} - {{ $cls->class_section }}">{{ $cls->grade }} - {{ $cls->class_section }}</option>
            @endforeach
          </select>

          <select id="filterSubject" class="form-select flex-grow-1" style="max-width:240px">
            <option value="">{{ __('All Subjects') }}</option>
            @foreach($subjects_dropdown as $sub)
                <option value="{{ $sub->id }}">{{ $sub->name }}</option>
            @endforeach
          </select>
          
          <button id="applyFiltersBtn" class="btn btn-primary px-4 w-100 w-sm-auto"><i class="bi bi-funnel me-1"></i> {{ __('Apply') }}</button>
        </div>
      </div>

      <div class="table-shell">
        <div style="max-height: 500px; overflow-y: auto; border: 1px solid var(--border); border-radius: 10px;">
          <table class="table align-middle mb-0" id="classesTable">
            <thead style="position: sticky; top: 0; background: var(--card); z-index: 5; border-bottom: 2px solid var(--border);">
              <tr>
                <th style="width:70%">{{ __('Student / Class Name') }}</th>
                <th class="text-end">{{ __('Actions') }}</th>
              </tr>
            </thead>
            <tbody><!-- filled dynamically --></tbody>
          </table>
        </div>

        <div class="d-flex justify-content-between align-items-center px-2 py-2">
          <div class="small text-muted" id="resultsInfo"></div>
          <nav class="pagination-wrap" aria-label="pagination">
            <ul class="pagination pagination-sm mb-0" id="pager"></ul>
          </nav>
        </div>
      </div>
    </div>
  </div>

  {{-- ===== View 2: Class Report ===== --}}
  <div id="classReportView" style="display:none;">
    <div class="page">
      <div class="d-flex flex-column flex-md-row align-items-start align-items-md-center justify-content-between gap-3 mb-3">
        <div class="crumbs">
          {{ __('Classes') }} <span class="sep">/</span> <span class="js-class-title">--</span> <span class="sep">/</span> <strong>{{ __('Class Performance') }}</strong>
        </div>
        <div class="no-print d-flex flex-wrap gap-2 w-100 w-md-auto">
          <button class="btn btn-outline-secondary js-refresh-class" title="{{ __('Refresh') }}"><i class="bi bi-arrow-clockwise"></i></button>
          <button class="btn btn-outline-secondary js-print" onclick="window.print()"><i class="bi bi-printer me-1"></i> {{ __('Print') }}</button>
          <button class="btn btn-info text-white js-view-cards"><i class="bi bi-person-badge me-1"></i> {{ __('Student Cards') }}</button>
          <button class="btn btn-soft btn-sm js-export"><i class="bi bi-file-earmark-pdf me-1"></i> {{ __('Export PDF') }}</button>
          <button class="btn btn-cta js-back-to-list"><i class="bi bi-arrow-left me-1"></i> {{ __('Back to List') }}</button>
        </div>
      </div>

      <div class="cardy panel mb-4" style="border: none !important; background: transparent !important;">
        <div class="d-flex align-items-center gap-4" style="padding: 20px; background: var(--card); border: 1px solid var(--border); border-radius: 12px;">
          <div class="rounded-circle bg-primary-soft d-flex align-items-center justify-content-center" style="width: 70px; height: 70px; font-size: 2rem; color: var(--primary);">
            <i class="bi bi-door-open"></i>
          </div>
          <div>
            <h3 class="js-class-title mb-1">--</h3>
            <div class="text-muted small">
              <span class="me-3"><i class="bi bi-people me-1"></i> <span class="js-students-count">--</span> {{ __('Students') }}</span>
              <span><i class="bi bi-calendar3 me-1"></i> {{ __('Academic Year') }}: 2023/2024</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="row row-cols-2 row-cols-md-4 g-3 mb-4">
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Avg Score') }}</h6><div class="val js-avg-score">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Pass Rate') }}</h6><div class="val js-pass-rate">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Attendance %') }}</h6><div class="val js-attendance">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Total Study Time') }}</h6><div class="val js-study-time">--</div></div></div>
      </div>

      <div class="cardy panel mt-4">
        <h6>{{ __('Grade Distribution') }}</h6>
        <div class="chart-wrap" style="height: 350px; padding: 20px;"><canvas id="gradeChart"></canvas></div>
      </div>

      <div class="cardy table-shell mt-4">
        <div class="section-title">{{ __('Students in this Class') }}</div>
        <div style="padding: 0px 15px 15px 15px;">
            <table class="table align-middle mb-0" id="studentsTable">
              <thead>
                <tr style="background: var(--card);">
                  <th style="background: #001A33; color:#fff">{{ __('Student Name') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('ID') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Section') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Score') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Attendance') }}</th>
                  <th style="background: #001A33; color:#fff" class="text-end">{{ __('Actions') }}</th>
                </tr>
              </thead>
              <tbody></tbody>
            </table>
        </div>
      </div>
    </div>
  </div>

  {{-- ===== View 3: Student Report ===== --}}
  <div id="studentReportView" style="display:none;">
    <div class="page">
      <div class="d-flex flex-column flex-md-row align-items-start align-items-md-center justify-content-between gap-3 mb-3">
        <div class="crumbs">
          {{ __('Students') }} <span class="sep">/</span> <span class="js-student-name">--</span> <span class="sep">/</span> <strong>{{ __('Performance Report') }}</strong>
        </div>
        <div class="no-print d-flex flex-wrap gap-2 w-100 w-md-auto">
          <button class="btn btn-outline-secondary js-refresh-student" title="{{ __('Refresh') }}"><i class="bi bi-arrow-clockwise"></i></button>
          <button class="btn btn-outline-secondary js-print" onclick="window.print()"><i class="bi bi-printer me-1"></i> {{ __('Print') }}</button>
          <button class="btn btn-soft btn-sm js-export"><i class="bi bi-file-earmark-pdf me-1"></i> {{ __('Export PDF') }}</button>
          <button class="btn btn-cta js-back-to-list"><i class="bi bi-arrow-left me-1"></i> {{ __('Back to List') }}</button>
        </div>
      </div>

      <div class="cardy panel mb-4" style="border: none !important; background: transparent !important;">
        <div class="d-flex align-items-center gap-4" style="padding: 20px; background: var(--card); border: 1px solid var(--border); border-radius: 12px;">
          <img class="js-student-avatar" src="" style="width: 80px; height: 80px; border-radius: 50%; object-fit: cover; border: 3px solid var(--primary);">
          <div>
            <h3 class="js-student-name mb-1">--</h3>
            <div class="text-muted small">
              <span class="me-3"><i class="bi bi-door-open me-1"></i> <span class="js-student-class">--</span></span>
              <span><i class="bi bi-person-badge me-1"></i> {{ __('Supervising Teacher') }}: <span class="js-student-teacher">--</span></span>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="row row-cols-2 row-cols-md-4 g-3 mb-4">
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Avg Score') }}</h6><div class="val js-s-avg">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Pass Rate') }}</h6><div class="val js-s-pass">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Attendance %') }}</h6><div class="val js-s-att">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Total Study Time') }}</h6><div class="val js-s-time">--</div></div></div>
      </div>

      <div class="row">
        <div class="col-md-7">
          <div class="cardy panel">
            <h6>{{ __('Grade Progression') }}</h6>
            <div class="chart-wrap" style="height:300px; padding: 20px;"><canvas id="progressChart"></canvas></div>
          </div>
        </div>
        <div class="col-md-5">
           <div class="cardy panel">
            <h6>{{ __('Study Time by Subject') }}</h6>
            <div class="chart-wrap" style="height:300px; padding: 20px;"><canvas id="timeChart"></canvas></div>
          </div>
        </div>
      </div>

      <div class="cardy table-shell mt-4">
        <div class="section-title">{{ __('Subject Performance Breakdown') }}</div>
        <div style="padding: 0px 15px 15px 15px;">
            <table class="table align-middle mb-0 js-subjects-table">
              <thead>
                <tr style="background: var(--card);">
                  <th style="background: #001A33; color:#fff">{{ __('Subject') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Score') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Rank') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Time Spent') }}</th>
                  <th style="background: #001A33; color:#fff" class="text-end">{{ __('Action') }}</th>
                </tr>
              </thead>
              <tbody></tbody>
            </table>
        </div>
      </div>
  {{-- ===== View 4: Subject Report ===== --}}
  <div id="subjectReportView" style="display:none;">
    <div class="page">
      <div class="d-flex flex-column flex-md-row align-items-start align-items-md-center justify-content-between gap-3 mb-3">
        <div class="crumbs">
          {{ __('Students') }} <span class="sep">/</span> <span class="js-sr-student">--</span> <span class="sep">/</span> {{ __('Reports') }} <span class="sep">/</span>
          <strong class="js-sr-subject">{{ __('Subject') }}</strong>
        </div>
        <div class="no-print d-flex flex-wrap gap-2 w-100 w-md-auto">
          <button class="btn btn-outline-secondary js-refresh-subject" title="{{ __('Refresh') }}"><i class="bi bi-arrow-clockwise"></i></button>
          <button class="btn btn-outline-secondary js-print" onclick="window.print()"><i class="bi bi-printer me-1"></i> {{ __('Print') }}</button>
          <button class="btn btn-cta js-back-to-student"><i class="bi bi-arrow-left me-1"></i> {{ __('Back to Student') }}</button>
        </div>
      </div>

      <div class="cardy panel mb-4" style="border: none !important; background: transparent !important;">
        <div class="d-flex align-items-center gap-4" style="padding: 20px; background: var(--card); border: 1px solid var(--border); border-radius: 12px;">
          <div class="rounded-circle bg-primary-soft d-flex align-items-center justify-content-center" style="width: 70px; height: 70px; font-size: 2rem; color: var(--primary);">
            <i class="bi bi-journal-text"></i>
          </div>
          <div>
            <h3 class="js-sr-title mb-1">--</h3>
            <div class="text-muted small">
              <span class="me-3"><i class="bi bi-person me-1"></i> <span class="js-sr-student">--</span></span>
              <span><i class="bi bi-info-circle me-1"></i> <span class="js-sr-subtitle">--</span></span>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="row row-cols-2 g-3 mb-4">
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Average Score') }}</h6><div class="val js-sr-avg">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Learning Time') }}</h6><div class="val js-sr-time">--</div></div></div>
      </div>

      <div class="row">
        <div class="col-md-6">
          <div class="cardy panel">
            <h6>{{ __('Subject Completion') }}</h6>
            <div class="chart-wrap" style="height:250px; padding: 20px;"><canvas id="completionChart"></canvas></div>
            <div class="text-center pb-3">
              <p class="muted mb-1 js-sr-completion-note small">{{ __('Keep going to reach 100%.') }}</p>
            </div>
          </div>
        </div>
        <div class="col-md-6">
           <div class="cardy panel">
            <div class="d-flex align-items-center justify-content-between p-2 px-3">
              <h6 class="mb-0" style="background:transparent; color:#fff; border:none; padding:0">{{ __('Recent Test Scores') }}</h6>
              <div class="trend-note small" style="color:#fff">
                 <span class="js-sr-trend">--</span> <i class="bi bi-arrow-up-right"></i>
              </div>
            </div>
            <div class="chart-wrap" style="height:250px; padding: 20px;"><canvas id="testsChart"></canvas></div>
          </div>
        </div>
      </div>

      <div class="cardy panel mt-4">
        <div class="section-title">{{ __('Latest Achievements') }}</div>
        <div class="ach-grid p-3">
          <div class="ach-card d-flex align-items-center gap-3 p-3" style="background: var(--card); border: 1px solid var(--border); border-radius: 12px;">
            <div class="ach-icn star text-warning fs-3"><i class="bi bi-star-fill"></i></div>
            <div>
              <div class="ach-title js-sr-ach1 fw-bold">—</div>
              <div class="ach-sub js-sr-ach1-sub text-muted small">—</div>
            </div>
          </div>
          <div class="ach-card d-flex align-items-center gap-3 p-3 mt-2" style="background: var(--card); border: 1px solid var(--border); border-radius: 12px;">
            <div class="ach-icn book text-primary fs-3"><i class="bi bi-journal-bookmark-fill"></i></div>
            <div>
              <div class="ach-title js-sr-ach2 fw-bold">—</div>
              <div class="ach-sub js-sr-ach2-sub text-muted small">—</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
 </div>

    </div>
  </div>

  {{-- ===== View 5: Teacher Report ===== --}}
  <div id="teacherReportView" style="display:none;">
    <div class="page">
      <div class="d-flex align-items-center justify-content-between mb-3">
        <div class="crumbs">
          {{ __('Teachers') }} <span class="sep">/</span> <span class="js-tr-name">--</span> <span class="sep">/</span> <strong>{{ __('Performance Report') }}</strong>
        </div>
        <div class="no-print d-flex gap-2">
          <button class="btn btn-outline-secondary js-refresh-teacher" title="{{ __('Refresh') }}"><i class="bi bi-arrow-clockwise"></i></button>
          <button class="btn btn-outline-secondary js-print" onclick="window.print()"><i class="bi bi-printer me-1"></i> {{ __('Print') }}</button>
          <button class="btn btn-soft btn-sm js-export"><i class="bi bi-file-earmark-pdf me-1"></i> {{ __('Export PDF') }}</button>
          <button class="btn btn-soft btn-sm js-export-excel"><i class="bi bi-file-earmark-spreadsheet me-1"></i> {{ __('Export Excel') }}</button>
          <button class="btn btn-cta js-back-to-list"><i class="bi bi-arrow-left me-1"></i> {{ __('Back to List') }}</button>
        </div>
      </div>

      <div class="cardy panel mb-4" style="border: none !important; background: transparent !important;">
        <div class="d-flex align-items-center gap-4" style="padding: 20px; background: var(--card); border: 1px solid var(--border); border-radius: 12px;">
          <img class="js-tr-avatar" src="" style="width: 80px; height: 80px; border-radius: 50%; object-fit: cover; border: 3px solid var(--primary);">
          <div>
            <h3 class="js-tr-name mb-1">--</h3>
            <div class="text-muted small">
              <span class="me-3"><i class="bi bi-person-badge me-1"></i> <span class="js-tr-code">--</span></span>
              <span><i class="bi bi-envelope me-1"></i> <span class="js-tr-email">--</span></span>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="row row-cols-2 row-cols-md-3 row-cols-lg-5 g-3 mb-4">
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Total Lessons') }}</h6><div class="val js-tr-lessons">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Total Exercises') }}</h6><div class="val js-tr-exercises">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Students Impacted') }}</h6><div class="val js-tr-students">--</div></div></div>
        <div class="col"><div class="cardy stat h-100 mb-0"><h6>{{ __('Avg. Student Score') }}</h6><div class="val js-tr-score">--</div></div></div>
        <div class="col">
            <div class="cardy stat h-100 mb-0">
                <h6>{{ __('School comparison') }}</h6>
                <div class="val js-tr-comparison">--</div>
                <div class="text-muted x-small" style="font-size: 10px;">{{ __('vs School Average') }}</div>
            </div>
        </div>
      </div>

      <div class="row">
        <div class="col-md-7">
          <div class="cardy panel">
            <h6>{{ __('Activity Timeline (Last 8 Weeks)') }}</h6>
            <div class="chart-wrap" style="height:300px; padding: 20px;"><canvas id="teacherActivityChart"></canvas></div>
          </div>
        </div>
        <div class="col-md-5">
           <div class="cardy panel">
            <h6>{{ __('Score by Class (%)') }}</h6>
            <div class="chart-wrap" style="height:300px; padding: 20px;"><canvas id="teacherClassChart"></canvas></div>
          </div>
        </div>
      </div>

      <div class="cardy table-shell mt-4">
        <div class="section-title">{{ __('Class-wise Performance') }}</div>
        <div style="padding: 0px 15px 15px 15px;">
            <table class="table align-middle mb-0 js-tr-classes-table">
              <thead>
                <tr style="background: var(--card);">
                  <th style="background: #001A33; color:#fff">{{ __('Class / Section') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Subject') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Lessons') }}</th>
                  <th style="background: #001A33; color:#fff">{{ __('Avg Score') }}</th>
                </tr>
              </thead>
              <tbody></tbody>
            </table>
        </div>
      </div>
    </div>
  </div>

  {{-- ===== View 6: Student Cards Report ===== --}}
  <div id="classCardsView" style="display:none;">
    <div class="page">
        <div class="d-flex flex-column flex-md-row align-items-start align-items-md-center justify-content-between gap-3 mb-4">
            <div>
                <div class="title">{{ __('Student ID Cards') }}: <span class="js-cards-class-title">---</span></div>
                <div class="subtitle">{{ __('Official student identification cards for the selected class.') }}</div>
            </div>
            <div class="d-flex flex-wrap align-items-center gap-2 no-print w-100 w-md-auto">
                <div class="form-check mb-0 me-2">
                    <input class="form-check-input js-select-all-cards" type="checkbox" id="selectAllCards">
                    <label class="form-check-label text-muted small" for="selectAllCards">{{ __('Select All') }}</label>
                </div>
                <button class="btn btn-outline-secondary js-back-to-class-report flex-grow-1 flex-md-grow-0"><i class="bi bi-arrow-left me-1"></i>{{ __('Back') }}</button>
                <button class="btn btn-soft-info js-print-selected-cards flex-grow-1 flex-md-grow-0"><i class="bi bi-check2-square me-1"></i>{{ __('Selected') }}</button>
                <button class="btn btn-primary js-print-cards flex-grow-1 flex-md-grow-0"><i class="bi bi-printer me-1"></i>{{ __('Print All') }}</button>
            </div>
        </div>

        <div class="cards-print-title" style="display: none;">
            {{ __('Student ID Cards') }} — <span class="js-cards-print-class-title"></span>
        </div>

        <div class="row g-4" id="studentCardsContainer">
            <!-- Cards will be injected here -->
        </div>
    </div>
  </div>

  {{-- ##### NEW: View 6: At-Risk Students Report (Printable) ##### --}}
  <div id="atRiskReportView" style="display: none;">
    <div class="content-wrap">
      <div class="page-header flex-column flex-md-row align-items-start align-items-md-center justify-content-between gap-3 d-print-none mb-4">
        <div>
          <h2 class="page-title text-danger"><i class="bi bi-exclamation-triangle-fill"></i> {{ __('At-Risk Students Report') }}</h2>
          <div class="text-muted small">{{ __('List of students whose performance or attendance is below threshold.') }}</div>
        </div>
        <div class="d-flex flex-wrap gap-2 w-100 w-md-auto">
            <button class="btn btn-soft-info js-view-cards no-print flex-grow-1 flex-md-grow-0">
                <i class="bi bi-person-badge me-1"></i> {{ __('Cards') }}
            </button>
            <button class="btn btn-soft-danger js-print no-print flex-grow-1 flex-md-grow-0">
                <i class="bi bi-file-earmark-pdf me-1"></i> {{ __('PDF') }}
            </button>
            <button class="btn btn-soft-success js-export-excel no-print flex-grow-1 flex-md-grow-0">
                <i class="bi bi-file-earmark-spreadsheet me-1"></i> {{ __('Excel') }}
            </button>
            <button class="btn btn-outline-secondary js-back-to-list no-print flex-grow-1 flex-md-grow-0">
                <i class="bi bi-arrow-left me-1"></i> {{ __('Back') }}
            </button>
        </div>
      </div>
      </div>

      <div class="cardy">
        <div class="p-4">
          <div class="table-responsive">
            <table class="table table-hover align-middle" id="atRiskTable">
              <thead class="bg-light">
                <tr>
                  <th>{{ __('Student Name') }}</th>
                  <th>{{ __('Class') }}</th>
                  <th>{{ __('Avg Score') }}</th>
                  <th>{{ __('Attendance') }}</th>
                  <th>{{ __('Reason / Risk') }}</th>
                  <th class="text-end">{{ __('Action') }}</th>
                </tr>
              </thead>
              <tbody>
                <!-- Populated via JS -->
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- ##### NEW: Generate Report Modal ##### --}}
  <div class="modal fade" id="generateReportModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content border-0 shadow-lg" style="border-radius: 20px; overflow: hidden;">
        <div class="modal-header bg-primary text-white p-4 border-0">
          <h5 class="modal-title d-flex align-items-center gap-2">
            <i class="bi bi-file-earmark-bar-graph-fill fs-4"></i>
            {{ __('Generate Performance Report') }}
          </h5>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body p-4">
          <div class="mb-4">
            <label class="form-label fw-bold small text-uppercase tracking-wider text-muted mb-2">{{ __('Report Type') }}</label>
            <div class="row g-2">
              <div class="col-6">
                <input type="radio" class="btn-check" name="report_type" id="rt_summary" value="summary" checked>
                <label class="btn btn-outline-soft w-100 py-3 d-flex flex-column align-items-center gap-2" for="rt_summary">
                  <i class="bi bi-pie-chart fs-3"></i>
                  <span class="small fw-bold">{{ __('Summary') }}</span>
                </label>
              </div>
              <div class="col-6">
                <input type="radio" class="btn-check" name="report_type" id="rt_students" value="students">
                <label class="btn btn-outline-soft w-100 py-3 d-flex flex-column align-items-center gap-2" for="rt_students">
                  <i class="bi bi-people fs-3"></i>
                  <span class="small fw-bold">{{ __('Students List') }}</span>
                </label>
              </div>
              <div class="col-6">
                <input type="radio" class="btn-check" name="report_type" id="rt_performance" value="performance">
                <label class="btn btn-outline-soft w-100 py-3 d-flex flex-column align-items-center gap-2" for="rt_performance">
                  <i class="bi bi-graph-up-arrow fs-3"></i>
                  <span class="small fw-bold">{{ __('Performance') }}</span>
                </label>
              </div>
              <div class="col-6">
                <input type="radio" class="btn-check" name="report_type" id="rt_risk" value="at_risk">
                <label class="btn btn-outline-soft w-100 py-3 d-flex flex-column align-items-center gap-2" for="rt_risk">
                  <i class="bi bi-exclamation-triangle fs-3 text-warning"></i>
                  <span class="small fw-bold">{{ __('At-Risk') }}</span>
                </label>
              </div>
            </div>
          </div>

          <div class="alert alert-soft-primary border-0 small d-flex align-items-start gap-2 mb-0">
            <i class="bi bi-info-circle-fill mt-1"></i>
            <span>{{ __('The report will be generated and displayed on screen based on your filters.') }}</span>
          </div>
        </div>
        <div class="modal-footer bg-light p-3 border-0">
          <button type="button" class="btn btn-link text-muted fw-bold text-decoration-none" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
          <button id="confirmGenerateBtn" type="button" class="btn btn-primary px-4 py-2 rounded-pill shadow-sm d-flex align-items-center gap-2">
            {{ __('View Report') }}
            <i class="bi bi-arrow-right"></i>
          </button>
        </div>
  
  {{-- ##### NEW: AI Analytics Report Modal ##### --}}
  <div class="modal fade" id="aiAnalyticsReportModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
      <div class="modal-content border-0 shadow-lg" style="border-radius: 20px; background: #f8fafc;">
        <div class="modal-header bg-navy text-white p-4 border-0">
          <div class="d-flex align-items-center gap-3">
            <div class="rounded-circle bg-orange d-flex align-items-center justify-content-center" style="width: 48px; height: 48px;">
                <i class="bi bi-robot fs-4 text-white"></i>
            </div>
            <div>
                <h5 class="modal-title mb-0 fw-bold">{{ __('Strategic Academic AI Insights') }}</h5>
                <div class="text-white-50 x-small">{{ __('Powered by EduLearn AI Analytics Engine') }}</div>
            </div>
          </div>
          <div class="d-flex align-items-center gap-2">
              <button class="btn btn-outline-light btn-sm js-print-ai-report" onclick="window.print()">
                  <i class="bi bi-printer me-1"></i> {{ __('Print') }}
              </button>
              <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
        </div>
        <div class="modal-body p-5">
          {{-- Loading State --}}
          <div id="aiReportLoading" class="text-center py-5">
            <div class="spinner-grow text-primary mb-3" style="width: 3rem; height: 3rem;" role="status"></div>
            <h4 class="fw-bold text-navy">{{ __('Analyzing School Data...') }}</h4>
            <p class="text-muted">{{ __('Gemini is processing thousands of data points to generate your strategic report.') }}</p>
            
            <div class="progress mt-4 mx-auto" style="height: 6px; max-width: 400px;">
              <div class="progress-bar progress-bar-striped progress-bar-animated bg-orange" style="width: 100%"></div>
            </div>
          </div>

          {{-- Report Content --}}
          <div id="aiReportContent" style="display:none;">
            <div id="aiReportMarkdown" class="markdown-body p-4 bg-white rounded-4 shadow-sm border">
                <!-- AI content will be rendered here -->
            </div>
            
            <div class="mt-4 d-flex justify-content-center gap-3 no-print">
                <button class="btn btn-outline-secondary px-4 py-2 rounded-pill" onclick="window.print()">
                    <i class="bi bi-printer me-2"></i> {{ __('Print Full Report') }}
                </button>
                <button id="copyAiInsight" class="btn btn-navy px-4 py-2 rounded-pill" onclick="copyAiText()" style="display:none;">
                    <i class="bi bi-clipboard me-2"></i> {{ __('Copy Text') }}
                </button>
            </div>
          </div>
        </div>
        <div class="modal-footer bg-light p-3 border-0">
          <button type="button" class="btn btn-secondary px-4 rounded-pill" data-bs-dismiss="modal">{{ __('Close') }}</button>
        </div>
      </div>
    </div>
  </div>

  {{-- ##### NEW: AI Reports Archive Modal (Full List) ##### --}}
  <div class="modal fade" id="aiReportsArchiveModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content border-0 shadow-lg" style="border-radius: 20px;">
        <div class="modal-header bg-light p-4 border-0">
          <h5 class="modal-title fw-bold text-navy"><i class="bi bi-archive me-2 text-orange"></i> {{ __('Report History') }}</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body p-4">
          <div class="table-responsive">
            <table class="table table-hover align-middle">
              <thead class="table-light">
                <tr>
                  <th>{{ __('Date') }}</th>
                  <th>{{ __('Report Title') }}</th>
                  <th class="text-end">{{ __('Action') }}</th>
                </tr>
              </thead>
              <tbody>
                @if(isset($aiReports))
                @foreach($aiReports as $report)
                <tr>
                  <td class="small text-muted">{{ $report->created_at->format('Y-m-d H:i') }}</td>
                  <td class="fw-bold text-navy">{{ $report->title }}</td>
                  <td class="text-end">
                    <button class="btn btn-sm btn-soft-primary js-view-archived-report" data-id="{{ $report->id }}" data-bs-dismiss="modal">
                      <i class="bi bi-eye"></i>
                    </button>
                  </td>
                </tr>
                @endforeach
                @endif
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>

 </div>

<style>
/* AI Strategic Button Premium Styling */
.btn-ai-strategic {
    background: linear-gradient(135deg, #001A33 0%, #003366 100%);
    border: 1px solid rgba(255, 102, 0, 0.3);
    color: #ffffff !important;
    font-weight: 600;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.btn-ai-strategic:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 20px rgba(255, 102, 0, 0.2);
    border-color: var(--accent);
    filter: brightness(1.1);
}

body.dark-mode .btn-ai-strategic {
    background: linear-gradient(135deg, #001020 0%, #001A33 100%);
    border-color: rgba(255, 102, 0, 0.5);
}

body.dark-mode .btn-ai-strategic:hover {
    box-shadow: 0 5px 20px rgba(255, 102, 0, 0.3);
}

/* =============== NEW STUDENT ID CARD STYLING =============== */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=Libre+Barcode+39&family=Manrope:wght@400;600;800&family=Noto+Sans+Arabic:wght@400;600;800&display=swap');

.card-scale-wrapper {
    zoom: 0.45; /* scale for viewing nicely on dashboard */
    margin: 0 auto;
}

.student-id-card-new {
    font-family: 'Inter', sans-serif;
    overflow: hidden;
    position: relative;
    background-color: #f8fafc;
    width: 800px;
    height: 480px;
    border-radius: 12px;
    box-shadow: 0 10px 25px rgba(0,0,0,0.15);
    margin: 0 auto;
    break-inside: avoid;
    text-align: left;
    direction: ltr;
}

.bg-accent-navy {
    position: absolute; bottom: 0; left: 0; width: 40%; height: 35%;
    background-color: #001A33;
    clip-path: polygon(0 0, 80% 0, 100% 100%, 0% 100%);
    z-index: 1;
    -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;
}

.bg-accent-orange {
    position: absolute; bottom: 0; left: 20%; width: 30%; height: 25%;
    background-color: #FF6600;
    clip-path: polygon(20% 0%, 100% 0%, 100% 100%, 0% 100%);
    z-index: 2;
    -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;
}

.ribbon-banner {
    position: absolute; top: 0; right: 40px; width: 140px; height: 200px;
    background-color: #001A33;
    clip-path: polygon(0 0, 100% 0, 100% 100%, 50% 85%, 0 100%);
    z-index: 3;
    display: flex; flex-direction: column; align-items: center; padding-top: 20px;
    color: white;
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;
}

.ribbon-banner .school-logo-c {
    width: 64px; height: 64px; margin-bottom: 8px; border: 2px solid white; border-radius: 50%;
    display: flex; align-items: center; justify-content: center; background: white; overflow: hidden;
}
.ribbon-banner .school-logo-c img, .ribbon-banner .school-logo-c svg { width: 100%; height: 100%; object-fit: cover; }
.ribbon-banner span { font-size: 12px; font-weight: bold; text-align: center; text-transform: uppercase; letter-spacing: 0.05em; padding: 0 8px; }

.profile-img-container {
    position: relative; z-index: 10; border: 8px solid #FF6600; border-radius: 50%;
    width: 240px; height: 240px; overflow: hidden;
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
    background: #e2e8f0;
}

.profile-img-container img { width: 100%; height: 100%; object-fit: cover; }

.card-decorative-circles {
    position: absolute; right: 40px; bottom: 160px; width: 80px; height: 80px;
    border: 2px solid #FF6600; border-radius: 50%; opacity: 0.3;
}

.card-decorative-circles::after {
    content: ''; position: absolute; top: 0; left: 20px; width: 80px; height: 80px;
    border: 2px solid #a7f3d0; border-radius: 50%;
}

.barcode-font { font-family: 'Libre Barcode 39', cursive; font-size: 64px; color: black; line-height: 1; }

.id-content { position: relative; z-index: 10; padding: 48px; height: 100%; display: flex; flex-direction: column; justify-content: space-between; }
.id-title { font-size: 48px; font-weight: 800; color: #001A33; letter-spacing: -0.025em; margin-bottom: 32px; text-transform: uppercase; line-height:1; }


.id-flex-row { display: flex; align-items: flex-start; gap: 48px; }
.id-details { flex-grow: 1; display: flex; flex-direction: column; gap: 16px; color: #0c4a6e; margin-top: 10px; }
.id-label { font-size: 14px; font-weight: bold; text-transform: uppercase; letter-spacing: 0.1em; color: #FF6600; margin: 0; }
.id-value { font-size: 24px; font-weight: 600; border-bottom: 2px solid #ff660066; padding-bottom: 4px; margin: 0; text-transform: uppercase; }


.id-footer { display: flex; align-items: flex-end; justify-content: space-between; margin-top: auto; }
.id-valid p { margin: 0; color: #0c4a6e; }
.id-valid .v-label { font-size: 10px; font-weight: bold; text-transform: uppercase; }
.id-valid .v-val { font-size: 12px; font-weight: 800; text-transform: uppercase; }

.barcode-area { display: flex; flex-direction: column; align-items: center; margin-left: 96px; }
.barcode-text { font-size: 10px; letter-spacing: 0.5em; font-family: monospace; margin-top: -5px; color: black; }

/* RTL Support for Student ID Card */
[dir="rtl"] .student-id-card-new {
    direction: rtl;
    text-align: right;
    font-family: 'Manrope', 'Noto Sans Arabic', 'Inter', sans-serif;
}
[dir="rtl"] .bg-accent-navy {
    left: auto; right: 0;
    clip-path: polygon(20% 0, 100% 0, 100% 100%, 0% 100%);
}
[dir="rtl"] .bg-accent-orange {
    left: auto; right: 20%;
    clip-path: polygon(0 0, 80% 0, 100% 100%, 0% 100%);
}
[dir="rtl"] .ribbon-banner {
    right: auto; left: 40px;
}
[dir="rtl"] .card-decorative-circles {
    right: auto; left: 40px;
}
[dir="rtl"] .card-decorative-circles::after {
    left: auto; right: 20px;
}
[dir="rtl"] .barcode-area {
    margin-left: 0; margin-right: 96px;
}
[dir="rtl"] .barcode-text, [dir="rtl"] .id-value.academic-id-text {
    direction: ltr; /* Ensure ID codes stay LTR */
    text-align: left;
}

@media print {
    /* Main Control: Hide everything then selectively show the current view */
    body { background: #fff !important; color: #000 !important; overflow: visible !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
    .sidebar, .topbar, .no-print, .btn, .crumbs, .mobile-nav, .modal-backdrop, .modal, .floating-actions, .input-group, .pagination-wrap, .page-header, .no-print-area { 
        display: none !important; 
    }
    .main-wrapper, .content-area { padding: 0 !important; margin: 0 !important; width: 100% !important; display: block !important; }
    
    /* Institutional Head */
    #globalPrintHeader { display: block !important; visibility: visible !important; }
    
    /* Isolation Logic for Report Views */
    #reportsListView, #classReportView, #studentReportView, #subjectReportView, #teacherReportView, #classCardsView, #atRiskReportView {
        display: none !important;
    }
    
    /* Reveal only the current active onscreen view */
    #reportsListView:not([style*="display: none"]),
    #classReportView:not([style*="display: none"]),
    #studentReportView:not([style*="display: none"]),
    #subjectReportView:not([style*="display: none"]),
    #teacherReportView:not([style*="display: none"]),
    #classCardsView:not([style*="display: none"]),
    #atRiskReportView:not([style*="display: none"]) {
        display: block !important;
    }
    
    /* Specific overrides for ID cards */
    body.printing-id-cards #globalPrintHeader { display: none !important; }
    body.printing-id-cards #classCardsView { display: block !important; }

    /* Professional Styling for Printed Elements */
    .reports-skin .cardy, .reports-skin .panel, .reports-skin .table-shell, .reports-skin .stat {
        border: 2px solid #cbd5e1 !important;
        border-radius: 8px !important;
        background: #fff !important;
        margin-bottom: 30px !important;
        page-break-inside: avoid !important;
        box-shadow: none !important;
    }

    .reports-skin h6, .reports-skin .section-title {
        background: #001A33 !important;
        color: #fff !important;
        padding: 12px 20px !important;
        border-bottom: 4px solid #FF6600 !important;
        font-size: 18px !important;
        font-weight: 800 !important;
        text-transform: uppercase !important;
        display: block !important;
    }

    .reports-skin table { width: 100% !important; border-collapse: collapse !important; margin: 0 !important; }
    .reports-skin th { background-color: #f8fafc !important; color: #001A33 !important; border: 1px solid #94a3b8 !important; padding: 12px !important; font-weight: bold !important; text-align: center !important; }
    .reports-skin td { border: 1px solid #cbd5e1 !important; padding: 10px !important; text-align: center !important; }

    .chart-wrap { height: 350px !important; width: 100% !important; margin-bottom: 20px !important; background: #fff !important; border: 1px solid #f1f5f9; }
    .val { font-size: 32px !important; font-weight: 800 !important; color: #001A33 !important; }

    @page { margin: 1.5cm; size: A4 portrait; }
}


/* Custom scrollbar styling from students page */
div[style*="overflow-y: auto"]::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}
div[style*="overflow-y: auto"]::-webkit-scrollbar-track {
  background: rgba(0,0,0,0.03);
  border-radius: 4px;
}
div[style*="overflow-y: auto"]::-webkit-scrollbar-thumb {
  background: rgba(0,0,0,0.1);
  border-radius: 4px;
}
div[style*="overflow-y: auto"]::-webkit-scrollbar-thumb:hover {
  background: rgba(0,0,0,0.2);
}
body.dark-mode div[style*="overflow-y: auto"]::-webkit-scrollbar-track {
  background: rgba(255,255,255,0.02);
}
body.dark-mode div[style*="overflow-y: auto"]::-webkit-scrollbar-thumb {
  background: rgba(255,255,255,0.1);
}

/* Dark Mode for Generate Report Modal */
body.dark-mode #generateReportModal .modal-content {
    background-color: #1e293b;
    color: #f1f5f9;
}
body.dark-mode #generateReportModal .modal-header {
    background-color: #0f172a !important;
}
body.dark-mode #generateReportModal .modal-body {
    background-color: #1e293b;
}
body.dark-mode #generateReportModal .modal-footer {
    background-color: #0f172a !important;
}
body.dark-mode #generateReportModal .btn-outline-soft {
    border-color: #475569; /* Brighter border */
    color: #cbd5e1;        /* Brighter text */
    background-color: rgba(255, 255, 255, 0.03); /* Subtle backdrop */
}
body.dark-mode #generateReportModal .btn-outline-soft:hover {
    border-color: #64748b;
    background-color: rgba(255, 255, 255, 0.05);
}
body.dark-mode #generateReportModal .btn-check:checked + .btn-outline-soft {
    background-color: rgba(56, 189, 248, 0.15);
    border-color: #38bdf8;
    color: #38bdf8;
    box-shadow: 0 0 15px rgba(56, 189, 248, 0.1);
}
body.dark-mode #generateReportModal .alert-soft-primary {
    background-color: rgba(56, 189, 248, 0.05);
    color: #7dd3fc;
}
body.dark-mode #generateReportModal .text-muted {
    color: #94a3b8 !important;
}

/* Specific button contrast for Excel & PDF in Dark Mode */
body.dark-mode #generateReportModal .btn-soft-success {
    border: 1px solid rgba(16, 185, 129, 0.3);
    color: #10b981 !important; /* Emerald Green */
    background-color: rgba(16, 185, 129, 0.05);
}
body.dark-mode #generateReportModal .btn-check:checked + .btn-soft-success {
    background-color: #10b981 !important;
    color: #fff !important;
    border-color: #10b981 !important;
}

body.dark-mode #generateReportModal .btn-soft-danger {
    border: 1px solid rgba(239, 68, 68, 0.3);
    color: #ef4444 !important; /* Rose Red */
    background-color: rgba(239, 68, 68, 0.05);
}
body.dark-mode #generateReportModal .btn-check:checked + .btn-soft-danger {
    background-color: #ef4444 !important;
    color: #fff !important;
    border-color: #ef4444 !important;
}
/* AI Report Styles */
#aiAnalyticsReportModal .bg-navy { background-color: #001A33 !important; }
#aiAnalyticsReportModal .text-orange { color: #FF6600 !important; }
#aiAnalyticsReportModal .bg-orange { background-color: #FF6600 !important; }

.ai-report-paper {
    font-family: 'Inter', system-ui, -apple-system, sans-serif;
    line-height: 1.7;
    color: #1e293b;
}

.markdown-body h1 { border-bottom: 2px solid #e2e8f0; padding-bottom: 0.5rem; margin-bottom: 1.5rem; color: #0f172a; font-weight: 800; }
.markdown-body h2 { margin-top: 2rem; margin-bottom: 1rem; color: #0f172a; font-weight: 700; display: flex; align-items: center; gap: 10px; }
.markdown-body h2::before { content: ''; display: inline-block; width: 4px; height: 1.2em; background: #FF6600; border-radius: 2px; }
.markdown-body h3 { margin-top: 1.5rem; color: #334155; font-weight: 600; }
.markdown-body ul { padding-left: 1.5rem; margin-bottom: 1rem; }
.markdown-body li { margin-bottom: 0.5rem; }
.markdown-body strong { color: #0f172a; }
.markdown-body blockquote { border-left: 4px solid #cbd5e1; padding-left: 1rem; color: #64748b; font-style: italic; margin: 1.5rem 0; }
.markdown-body table { width: 100%; border-collapse: collapse; margin-bottom: 1.5rem; }
.markdown-body th, .markdown-body td { border: 1px solid #e2e8f0; padding: 0.75rem; text-align: left; }
.markdown-body th { background: #f8fafc; font-weight: 600; }

body.dark-mode .ai-report-paper { background-color: #1e293b !important; color: #cbd5e1 !important; border-color: #334155 !important; }
body.dark-mode .markdown-body h1, 
body.dark-mode .markdown-body h2, 
body.dark-mode .markdown-body h3 { color: #f1f5f9; }
body.dark-mode .markdown-body th { background: #334155; }
body.dark-mode .markdown-body td { border-color: #334155; }

@media print {
    .modal-header, .modal-footer, .no-print { display: none !important; }
    #aiAnalyticsReportModal .modal-content { border: none !important; box-shadow: none !important; }
    .ai-report-paper { box-shadow: none !important; border: none !important; padding: 0 !important; }
}
</style>

@endsection

@push('scripts')
  <script>
    window.REPORTS_ROUTES = @json($REPORTS_ROUTES ?? []);
    window.SCHOOL_INFO = @json(auth()->user()?->school ?? null);
    Object.assign(window.I18N, {
      noMatchingResults: "{{ __('No matching results') }}",
      showingResults: "{{ __('Showing :count of :total result(s) (page :page)') }}",
      viewStudentReport: "{{ __('View Student Report') }}",
      students: "{{ __('students') }}",
      viewClassReport: "{{ __('View Class Report') }}",
      previous: "{{ __('Previous') }}",
      next: "{{ __('Next') }}",
      section: "{{ __('Section') }}",
      hrs: "{{ __('hrs') }}",
      viewReport: "{{ __('View report') }}",
      excellentCompleted: "{{ __('Excellent! Subject completed.') }}",
      keepGoing: "{{ __('Great job! Keep up the momentum to reach 100%.') }}",
      completed: "{{ __('Completed') }}",
      remaining: "{{ __('Remaining') }}",
      grade: "{{ __('Grade') }}",
      stage: "{{ __('Stage') }}",
      elementary: "{{ __('Elementary') }}",
      academicYear: "{{ __('Academic Year') }}",
      classReport: "{{ __('Class Report') }}",
      studentReport: "{{ __('Student Report') }}",
      subjectReport: "{{ __('Subject Report') }}",
      studentIdCards: "{{ __('Student ID Cards') }}",
      studentIdCardTitle: "{{ __('STUDENT ID CARD') }}",
      nameLabel: "{{ __('Name:') }}",
      studentIdLabel: "{{ __('Student ID:') }}",
      programLabel: "{{ __('Program:') }}",
      yearLabel: "{{ __('Year:') }}",
      validUntilLabel: "{{ __('Valid Until:') }}",
      selectAtLeastOne: "{{ __('Please select at least one card to print.') }}",
      lessons: "{{ __('Lessons') }}",
      exercises: "{{ __('Exercises') }}",
      generatingReport: "{{ __('Generating report...') }}",
      reportReady: "{{ __('Report is ready!') }}",
      preparingData: "{{ __('Preparing data...') }}",
      downloading: "{{ __('Downloading...') }}",
      noAtRiskFound: "{{ __('No students currently meet the At-Risk criteria.') }}",
      refresh: "{{ __('Refresh Page') }}",
      generatingReport: "{{ __('Generating Report') }}",
      backgroundGenerationNote: "{{ __('The AI is analyzing school data in the background. You can continue using the site.') }}",
      generatingStrategicReport: "{{ __('Generating Strategic Report...') }}",
      canCloseModalNote: "{{ __('You can close this window; the report will continue generating in the background.') }}",
      aiReportReady: "{{ __('AI Report Ready!') }}",
      strategicAnalysisComplete: "{{ __('Strategic analysis has been completed.') }}",
      viewReport: "{{ __('View Report') }}",
      close: "{{ __('Close') }}"
    });
    window.DEFAULT_AVATAR = "{{ asset('images/default-avatar.png') }}";
  </script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
  <script src="{{ asset('js/reports.js') }}"></script>
@endpush
