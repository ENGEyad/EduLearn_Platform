@extends('layouts.app')

@section('content')

<div class="reports-skin"><!-- سكوب التصميم الخاص بالتقارير -->

  {{-- ===== View 1: Class Reports List ===== --}}
  <div id="reportsListView">
    <div class="content-wrap">
      <div class="page-header">
        <div>
          <h2 class="page-title">Class Reports</h2>
          <div class="text-muted small">List classes and filter by name, year, and teacher.</div>
        </div>
        <button class="btn btn-primary js-generate">
          <i class="bi bi-file-bar-graph me-1"></i> Generate Report
        </button>
      </div>

      <div class="filters mb-3">
        <div class="input-group" style="max-width:320px">
          <span class="input-group-text border-end-0"><i class="bi bi-search"></i></span>
          <input id="filterSearch" type="text" class="form-control border-start-0" placeholder="Search by class name (e.g., Grade 4 - A)">
        </div>

        <select id="filterYear" class="form-select" style="max-width:220px">
          <option value="">All Years</option>
        </select>

        <select id="filterTeacher" class="form-select" style="max-width:240px">
          <option value="">All Teachers</option>
        </select>
      </div>

      <div class="table-shell">
        <table class="table align-middle" id="classesTable">
          <thead>
            <tr>
              <th style="width:70%">Class Name</th>
              <th class="text-end">Actions</th>
            </tr>
          </thead>
          <tbody><!-- filled dynamically --></tbody>
        </table>

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
      <!-- Header -->
      <div class="d-flex align-items-center justify-content-between">
        <div>
          <div class="title">Class Report: <span class="js-class-title">Grade 10 - Section B</span></div>
          <div class="subtitle">A detailed overview of class performance and student data.</div>
        </div>
        <div class="d-flex gap-2 no-print">
          <button class="btn-ghost js-print"><i class="bi bi-printer me-1"></i>Print</button>
          <button class="btn-cta js-export"><i class="bi bi-download me-1"></i>Export CSV / PDF</button>
        </div>
      </div>

      <!-- Stat cards -->
      <div class="stats">
        <div class="cardy stat"><div class="k">Students</div><div class="v js-students-count">--</div><div class="delta g d-none">+0%</div></div>
        <div class="cardy stat"><div class="k">Avg Score</div><div class="v js-avg-score">--</div><div class="delta g d-none">+0%</div></div>
        <div class="cardy stat"><div class="k">Pass Rate</div><div class="v js-pass-rate">--</div><div class="delta r d-none">0%</div></div>
        <div class="cardy stat"><div class="k">Attendance</div><div class="v js-attendance">--</div><div class="delta g d-none">0%</div></div>
        <div class="cardy stat"><div class="k">Study Time</div><div class="v js-study-time">--</div><div class="delta g d-none">0</div></div>
      </div>

      <!-- Grade Distribution -->
      <div class="cardy panel mt-3">
        <h6>Grade Distribution</h6>
        <div class="chart-wrap"><canvas id="gradeChart"></canvas></div>
      </div>

      <!-- Students by Section -->
      <div class="cardy table-shell mt-3">
        <h6 class="mb-2">Students by Section</h6>
        <div class="table-responsive">
          <table class="table align-middle" id="studentsTable">
            <thead>
              <tr>
                <th>STUDENT NAME</th>
                <th>ID</th>
                <th>SECTION</th>
                <th>SCORE</th>
                <th>ATTENDANCE</th>
                <th>ACTIONS</th>
              </tr>
            </thead>
            <tbody><!-- filled dynamically --></tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  {{-- ===== View 3: Student Report ===== --}}
  <div id="studentReportView" style="display:none;">
    <div class="page-wrap">
      <!-- Breadcrumb + Actions -->
      <div class="d-flex align-items-center justify-content-between">
        <div class="crumbs">
          Students <span class="sep">/</span> <span class="js-student-name-breadcrumb">--</span> <span class="sep">/</span> <strong>Report</strong>
        </div>
        <div class="no-print d-flex gap-2">
          <button class="btn btn-outline btn-sm js-print"><i class="bi bi-printer"></i> Print student report</button>
          <button class="btn btn-soft btn-sm js-export"><i class="bi bi-file-earmark-pdf"></i> Export PDF</button>
        </div>
      </div>

      <div class="page-head">
        <div class="page-title">Student Report</div>
      </div>

      <!-- Header -->
      <div class="cardy student-head d-flex align-items-center">
        <div class="kvs flex-grow-1">
          <div class="avatar">--</div>
          <div class="meta">
            <div class="name js-student-name">--</div>
            <div class="sub js-student-class">--</div>
            <div class="sub js-student-teacher">Supervising Teacher: --</div>
          </div>
          <span class="status-pill"><span class="status-dot"></span> On Track</span>
        </div>
      </div>

      <!-- Stats -->
      <div class="stats stats--student">
        <div class="cardy stat"><h6>Avg Score</h6><div class="val js-s-avg">--</div></div>
        <div class="cardy stat"><h6>Pass Rate</h6><div class="val js-s-pass">--</div></div>
        <div class="cardy stat"><h6>Attendance %</h6><div class="val js-s-att">--</div></div>
        <div class="cardy stat"><h6>Total Study Time</h6><div class="val js-s-time">--</div></div>
      </div>

      <!-- Charts -->
      <div class="row-charts">
        <div class="cardy panel">
          <h6>Grade Progression</h6>
          <div class="chart-wrap"><canvas id="progressChart"></canvas></div>
        </div>
        <div class="cardy panel">
          <h6>Study Time by Subject</h6>
          <div class="chart-wrap"><canvas id="timeChart"></canvas></div>
        </div>
      </div>

      <!-- Subjects table -->
      <div class="cardy table-shell mt-3">
        <div class="section-title">Subject Performance Breakdown</div>
        <div class="table-responsive">
          <table class="table align-middle js-subjects-table">
            <thead>
              <tr>
                <th>Subject</th>
                <th>Score</th>
                <th>Rank in Class</th>
                <th>Time Spent</th>
                <th>Status</th>
                <th class="text-end">Action</th>
              </tr>
            </thead>
            <tbody><!-- filled dynamically --></tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  {{-- ===== View 4: Subject Report ===== --}}
  <div id="subjectReportView" style="display:none;">
    <div class="page">
      <!-- Breadcrumbs & CTA -->
      <div class="d-flex align-items-center justify-content-between">
        <div class="crumbs">
          Students <span class="sep">/</span> <span class="js-sr-student">--</span> <span class="sep">/</span> Reports <span class="sep">/</span>
          <strong class="js-sr-subject">Subject</strong>
        </div>
        <div class="no-print d-flex gap-2">
          <button class="btn btn-outline-secondary js-print"><i class="bi bi-printer me-1"></i> Print</button>
          <button class="btn btn-cta js-back-to-student"><i class="bi bi-arrow-left me-1"></i> Back to Student</button>
        </div>
      </div>

      <!-- Header -->
      <div class="d-flex align-items-center justify-content-between topbar">
        <div>
          <div class="title js-sr-title">Subject Progress</div>
          <div class="subtitle js-sr-subtitle">--</div>
        </div>
      </div>

      <!-- Hero row -->
      <div class="grid-hero mt-2">
        <!-- Subject Completion -->
        <div class="cardy panel">
          <h6>Subject Completion</h6>
          <div class="row align-items-center">
            <div class="col-6">
              <div class="chart-wrap" style="height:180px"><canvas id="completionChart"></canvas></div>
            </div>
            <div class="col-6">
              <p class="muted mb-1 js-sr-completion-note">Keep going to reach 100%.</p>
            </div>
          </div>
        </div>
        <!-- Recent Tests -->
        <div class="cardy panel">
          <div class="d-flex align-items-center justify-content-between">
            <h6 class="mb-0">Recent Test Scores</h6>
            <div class="trend-note">
              <span class="muted">Last 5 tests trend</span> <span class="js-sr-trend">--</span> <i class="bi bi-arrow-up-right"></i>
            </div>
          </div>
          <div class="chart-wrap mt-2" style="height:180px"><canvas id="testsChart"></canvas></div>
        </div>
      </div>

      <!-- Mini stats -->
      <div class="mini-two mt-3">
        <div class="cardy stat-mini">
          <div class="icn-badge"><i class="bi bi-trophy"></i></div>
          <div>
            <div class="label">Average Score</div>
            <div class="val js-sr-avg">--</div>
          </div>
        </div>
        <div class="cardy stat-mini">
          <div class="icn-badge"><i class="bi bi-alarm"></i></div>
          <div>
            <div class="label">Learning Time</div>
            <div class="val js-sr-time">--</div>
          </div>
        </div>
      </div>

      <!-- Achievements -->
      <div class="cardy panel mt-3">
        <div class="section-title">Latest Achievements</div>
        <div class="ach-grid">
          <div class="ach-card">
            <div class="ach-icn star"><i class="bi bi-star-fill"></i></div>
            <div>
              <div class="ach-title js-sr-ach1">—</div>
              <div class="ach-sub js-sr-ach1-sub">—</div>
            </div>
          </div>
          <div class="ach-card">
            <div class="ach-icn book"><i class="bi bi-journal-bookmark-fill"></i></div>
            <div>
              <div class="ach-title js-sr-ach2">—</div>
              <div class="ach-sub js-sr-ach2-sub">—</div>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>

</div>
@endsection

@push('scripts')
  <script>window.REPORTS_ROUTES = @json($REPORTS_ROUTES ?? []);</script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
  <script src="{{ asset('js/reports.js') }}"></script>
@endpush
