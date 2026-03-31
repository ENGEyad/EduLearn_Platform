@extends('layouts.app')

@section('content')

<div class="reports-skin"><!-- سكوب التصميم الخاص بالتقارير -->

  {{-- ===== View 1: Class Reports List ===== --}}
  <div id="reportsListView">
    <div class="content-wrap">
      <div class="page-header">
        <div>
          <h2 class="page-title">{{ __('Class & Student Reports') }}</h2>
          <div class="text-muted small">{{ __('Search students by name or academic ID, or filter by class.') }}</div>
        </div>
        <div class="d-flex gap-2">
          <button class="btn btn-outline-secondary js-refresh-list" title="{{ __('Refresh') }}">
            <i class="bi bi-arrow-clockwise"></i>
          </button>
          <button class="btn btn-primary js-generate">
            <i class="bi bi-file-bar-graph me-1"></i> {{ __('Generate Report') }}
          </button>
        </div>
      </div>

      <div class="filters mb-3">
        <div class="input-group" style="max-width:320px">
          <span class="input-group-text border-end-0"><i class="bi bi-search"></i></span>
          <input id="filterSearch" type="text" class="form-control border-start-0" placeholder="{{ __('Search by student, teacher, class') }}">
        </div>

        <select id="filterClass" class="form-select" style="max-width:220px">
          <option value="">{{ __('All Classes') }}</option>
          @foreach($classes_dropdown as $cls)
              <option value="{{ $cls->grade }} - {{ $cls->class_section }}">{{ $cls->grade }} - {{ $cls->class_section }}</option>
          @endforeach
        </select>

        <select id="filterSubject" class="form-select" style="max-width:240px">
          <option value="">{{ __('All Subjects') }}</option>
          @foreach($subjects_dropdown as $sub)
              <option value="{{ $sub->id }}">{{ $sub->name }}</option>
          @endforeach
        </select>
        
        <button id="applyFiltersBtn" class="btn btn-primary px-4"><i class="bi bi-funnel me-1"></i> {{ __('Apply') }}</button>
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
      <!-- Header -->
      <div class="d-flex align-items-center justify-content-between">
        <div>
          <div class="title">{{ __('Class Report') }}: <span class="js-class-title">--</span></div>
          <div class="subtitle">{{ __('A detailed overview of class performance and student data.') }}</div>
        </div>
        <div class="d-flex gap-2 no-print">
          <button class="btn btn-outline-secondary js-refresh-class" title="{{ __('Refresh') }}"><i class="bi bi-arrow-clockwise"></i></button>
          <button class="btn btn-outline-secondary js-back-to-list"><i class="bi bi-arrow-left me-1"></i>{{ __('Back to List') }}</button>
          <button class="btn btn-info text-white js-view-cards"><i class="bi bi-person-badge me-1"></i>{{ __('Student Cards Report') }}</button>
          <button class="btn-ghost js-print"><i class="bi bi-printer me-1"></i>{{ __('Print') }}</button>
          <button class="btn-cta js-export"><i class="bi bi-download me-1"></i>{{ __('Export CSV / PDF') }}</button>
        </div>
      </div>

      <!-- Stat cards -->
      <div class="stats">
        <div class="cardy stat"><div class="k">{{ __('Students') }}</div><div class="v js-students-count">--</div><div class="delta g d-none">+0%</div></div>
        <div class="cardy stat"><div class="k">{{ __('Avg Score') }}</div><div class="v js-avg-score">--</div><div class="delta g d-none">+0%</div></div>
        <div class="cardy stat"><div class="k">{{ __('Pass Rate') }}</div><div class="v js-pass-rate">--</div><div class="delta r d-none">0%</div></div>
        <div class="cardy stat"><div class="k">{{ __('Attendance') }}</div><div class="v js-attendance">--</div><div class="delta g d-none">0%</div></div>
        <div class="cardy stat"><div class="k">{{ __('Study Time') }}</div><div class="v js-study-time">--</div><div class="delta g d-none">0</div></div>
      </div>

      <!-- Grade Distribution -->
      <div class="cardy panel mt-3">
        <h6>{{ __('Grade Distribution') }}</h6>
        <div class="chart-wrap"><canvas id="gradeChart"></canvas></div>
      </div>

      <!-- Students by Section -->
      <div class="cardy table-shell mt-3">
        <h6 class="mb-2">{{ __('Students by Section') }}</h6>
        <div style="max-height: 400px; overflow-y: auto; border: 1px solid var(--border); border-radius: 8px;">
          <table class="table align-middle mb-0" id="studentsTable">
            <thead style="position: sticky; top: 0; background: var(--card); z-index: 5; border-bottom: 2px solid var(--border);">
              <tr>
                <th>{{ __('STUDENT NAME') }}</th>
                <th>{{ __('ID') }}</th>
                <th>{{ __('SECTION') }}</th>
                <th>{{ __('SCORE') }}</th>
                <th>{{ __('ATTENDANCE') }}</th>
                <th>{{ __('ACTIONS') }}</th>
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
          {{ __('Students') }} <span class="sep">/</span> <span class="js-student-name-breadcrumb">--</span> <span class="sep">/</span> <strong>{{ __('Report') }}</strong>
        </div>
        <div class="no-print d-flex gap-2">
          <button class="btn btn-outline-secondary btn-sm js-refresh-student" title="{{ __('Refresh') }}"><i class="bi bi-arrow-clockwise"></i></button>
          <button class="btn btn-outline-secondary btn-sm js-back-to-class"><i class="bi bi-arrow-left"></i> {{ __('Back to Class') }}</button>
          <button class="btn btn-outline btn-sm js-print"><i class="bi bi-printer"></i> {{ __('Print student report') }}</button>
          <button class="btn btn-soft btn-sm js-export"><i class="bi bi-file-earmark-pdf"></i> {{ __('Export PDF') }}</button>
        </div>
      </div>

      <div class="page-head">
        <div class="page-title">{{ __('Student Report') }}</div>
      </div>

      <!-- Header -->
      <div class="cardy student-head d-flex align-items-center">
        <div class="kvs flex-grow-1">
          <div class="avatar">--</div>
          <div class="meta">
            <div class="name js-student-name">--</div>
            <div class="sub js-student-class">--</div>
            <div class="sub js-student-teacher">{{ __('Supervising Teacher') }}: --</div>
          </div>
          <span class="status-pill"><span class="status-dot"></span> {{ __('On Track') }}</span>
        </div>
      </div>

      <!-- Stats -->
      <div class="stats stats--student">
        <div class="cardy stat"><h6>{{ __('Avg Score') }}</h6><div class="val js-s-avg">--</div></div>
        <div class="cardy stat"><h6>{{ __('Pass Rate') }}</h6><div class="val js-s-pass">--</div></div>
        <div class="cardy stat"><h6>{{ __('Attendance %') }}</h6><div class="val js-s-att">--</div></div>
        <div class="cardy stat"><h6>{{ __('Total Study Time') }}</h6><div class="val js-s-time">--</div></div>
      </div>

      <!-- Charts -->
      <div class="row-charts">
        <div class="cardy panel">
          <h6>{{ __('Grade Progression') }}</h6>
          <div class="chart-wrap"><canvas id="progressChart"></canvas></div>
        </div>
        <div class="cardy panel">
          <h6>{{ __('Study Time by Subject') }}</h6>
          <div class="chart-wrap"><canvas id="timeChart"></canvas></div>
        </div>
      </div>

      <!-- Subjects table -->
      <div class="cardy table-shell mt-3">
        <div class="section-title">{{ __('Subject Performance Breakdown') }}</div>
        <div style="max-height: 400px; overflow-y: auto; border: 1px solid var(--border); border-radius: 8px;">
          <table class="table align-middle mb-0 js-subjects-table">
            <thead style="position: sticky; top: 0; background: var(--card); z-index: 5; border-bottom: 2px solid var(--border);">
              <tr>
                <th>{{ __('Subject') }}</th>
                <th>{{ __('Score') }}</th>
                <th>{{ __('Rank in Class') }}</th>
                <th>{{ __('Time Spent') }}</th>
                <th>{{ __('Status') }}</th>
                <th class="text-end">{{ __('Action') }}</th>
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
          {{ __('Students') }} <span class="sep">/</span> <span class="js-sr-student">--</span> <span class="sep">/</span> {{ __('Reports') }} <span class="sep">/</span>
          <strong class="js-sr-subject">{{ __('Subject') }}</strong>
        </div>
        <div class="no-print d-flex gap-2">
          <button class="btn btn-outline-secondary js-refresh-subject" title="{{ __('Refresh') }}"><i class="bi bi-arrow-clockwise"></i></button>
          <button class="btn btn-outline-secondary js-print"><i class="bi bi-printer me-1"></i> {{ __('Print') }}</button>
          <button class="btn btn-cta js-back-to-student"><i class="bi bi-arrow-left me-1"></i> {{ __('Back to Student') }}</button>
        </div>
      </div>

      <!-- Header -->
      <div class="d-flex align-items-center justify-content-between topbar">
        <div>
          <div class="title js-sr-title">{{ __('Subject Progress') }}</div>
          <div class="subtitle js-sr-subtitle">--</div>
        </div>
      </div>

      <!-- Hero row -->
      <div class="grid-hero mt-2">
        <!-- Subject Completion -->
        <div class="cardy panel">
          <h6>{{ __('Subject Completion') }}</h6>
          <div class="row align-items-center">
            <div class="col-6">
              <div class="chart-wrap" style="height:180px"><canvas id="completionChart"></canvas></div>
            </div>
            <div class="col-6">
              <p class="muted mb-1 js-sr-completion-note">{{ __('Keep going to reach 100%.') }}</p>
            </div>
          </div>
        </div>
        <!-- Recent Tests -->
        <div class="cardy panel">
          <div class="d-flex align-items-center justify-content-between">
            <h6 class="mb-0">{{ __('Recent Test Scores') }}</h6>
            <div class="trend-note">
              <span class="muted">{{ __('Last 5 tests trend') }}</span> <span class="js-sr-trend">--</span> <i class="bi bi-arrow-up-right"></i>
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
            <div class="label">{{ __('Average Score') }}</div>
            <div class="val js-sr-avg">--</div>
          </div>
        </div>
        <div class="cardy stat-mini">
          <div class="icn-badge"><i class="bi bi-alarm"></i></div>
          <div>
            <div class="label">{{ __('Learning Time') }}</div>
            <div class="val js-sr-time">--</div>
          </div>
        </div>
      </div>

      <!-- Achievements -->
      <div class="cardy panel mt-3">
        <div class="section-title">{{ __('Latest Achievements') }}</div>
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

  {{-- ===== View 5: Student Cards Report ===== --}}
  <div id="classCardsView" style="display:none;">
    <div class="page">
        <div class="d-flex align-items-center justify-content-between mb-4">
            <div>
                <div class="title">{{ __('Student ID Cards') }}: <span class="js-cards-class-title">---</span></div>
                <div class="subtitle">{{ __('Official student identification cards for the selected class.') }}</div>
            </div>
            <div class="d-flex align-items-center gap-3 no-print">
                <div class="form-check mb-0">
                    <input class="form-check-input js-select-all-cards" type="checkbox" id="selectAllCards">
                    <label class="form-check-label text-muted small" for="selectAllCards">{{ __('Select All') }}</label>
                </div>
                <button class="btn btn-outline-secondary js-back-to-class-report"><i class="bi bi-arrow-left me-1"></i>{{ __('Back to Report') }}</button>
                <button class="btn btn-soft-info js-print-selected-cards"><i class="bi bi-check2-square me-1"></i>{{ __('Print Selected') }}</button>
                <button class="btn btn-primary js-print-cards"><i class="bi bi-printer me-1"></i>{{ __('Print All Cards') }}</button>
            </div>
        </div>

        <div class="row g-4" id="studentCardsContainer">
            <!-- Cards will be injected here -->
        </div>
    </div>
  </div>

</div>

<style>
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

.bg-accent-teal {
    position: absolute; bottom: 0; left: 0; width: 40%; height: 35%;
    background-color: #a7f3d0;
    clip-path: polygon(0 0, 80% 0, 100% 100%, 0% 100%);
    z-index: 1;
    -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;
}

.bg-accent-blue {
    position: absolute; bottom: 0; left: 20%; width: 30%; height: 25%;
    background-color: #0ea5e9;
    clip-path: polygon(20% 0%, 100% 0%, 100% 100%, 0% 100%);
    z-index: 2;
    -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;
}

.ribbon-banner {
    position: absolute; top: 0; right: 40px; width: 140px; height: 200px;
    background-color: #0ea5e9;
    clip-path: polygon(0 0, 100% 0, 100% 100%, 50% 85%, 0 100%);
    z-index: 3;
    display: flex; flex-direction: column; align-items: center; padding-top: 20px;
    color: white;
    -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;
}
.ribbon-banner .school-logo-c {
    width: 64px; height: 64px; margin-bottom: 8px; border: 2px solid white; border-radius: 50%;
    display: flex; align-items: center; justify-content: center; background: white; overflow: hidden;
}
.ribbon-banner .school-logo-c img, .ribbon-banner .school-logo-c svg { width: 100%; height: 100%; object-fit: cover; }
.ribbon-banner span { font-size: 12px; font-weight: bold; text-align: center; text-transform: uppercase; letter-spacing: 0.05em; padding: 0 8px; }

.profile-img-container {
    position: relative; z-index: 10; border: 8px solid #0ea5e9; border-radius: 50%;
    width: 240px; height: 240px; overflow: hidden;
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
    background: #e2e8f0;
}
.profile-img-container img { width: 100%; height: 100%; object-fit: cover; }

.card-decorative-circles {
    position: absolute; right: 40px; bottom: 160px; width: 80px; height: 80px;
    border: 2px solid #a7f3d0; border-radius: 50%;
}
.card-decorative-circles::after {
    content: ''; position: absolute; top: 0; left: 20px; width: 80px; height: 80px;
    border: 2px solid #a7f3d0; border-radius: 50%;
}

.barcode-font { font-family: 'Libre Barcode 39', cursive; font-size: 64px; color: black; line-height: 1; }

.id-content { position: relative; z-index: 10; padding: 48px; height: 100%; display: flex; flex-direction: column; justify-content: space-between; }
.id-title { font-size: 48px; font-weight: 800; color: #0284c7; letter-spacing: -0.025em; margin-bottom: 32px; text-transform: uppercase; line-height:1; }

.id-flex-row { display: flex; align-items: flex-start; gap: 48px; }
.id-details { flex-grow: 1; display: flex; flex-direction: column; gap: 16px; color: #0c4a6e; margin-top: 10px; }
.id-label { font-size: 14px; font-weight: bold; text-transform: uppercase; letter-spacing: 0.1em; color: #0284c7; margin: 0; }
.id-value { font-size: 24px; font-weight: 600; border-bottom: 2px solid #d1d5db; padding-bottom: 4px; margin: 0; text-transform: uppercase; }

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
[dir="rtl"] .bg-accent-teal {
    left: auto; right: 0;
    clip-path: polygon(20% 0, 100% 0, 100% 100%, 0% 100%);
}
[dir="rtl"] .bg-accent-blue {
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
    .d-none-print { display: none !important; }
    .card-scale-wrapper { zoom: 1 !important; transform: none !important; margin-bottom: 20px !important; }
    .student-id-card-new { border: 1px solid #e2e8f0; box-shadow: none; }
    body { background: #fff !important; color: #000 !important; overflow: visible !important; height: auto !important; }
    .main-wrapper { 
        margin: 0 !important; 
        padding: 0 !important; 
        height: auto !important; 
        overflow: visible !important; 
        display: block !important;
    }
    .sidebar, .topbar { display: none !important; }
    .content-area { 
        padding: 0 !important; 
        margin: 0 !important;
        overflow: visible !important; 
        width: 100% !important;
    }
    .cardy, .table-shell, .panel, .stat, .stat-mini, .stat-card { 
        border: 1px solid #eaedf0 !important; 
        box-shadow: none !important; 
        margin-bottom: 1.5rem !important; 
        break-inside: avoid; 
        background: #fff !important;
    }
    .chart-wrap { height: 280px !important; margin-bottom: 1rem; }
    canvas { max-width: 100% !important; }
    
    /* Force background printing */
    * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
    
    /* Table Print Fixes */
    thead { display: table-header-group !important; position: static !important; }
    tr { break-inside: avoid; break-after: auto; }
    div[style*="overflow-y: auto"] { overflow: visible !important; max-height: none !important; border: none !important; }
    
    .reports-skin .content-wrap, .reports-skin .page, .reports-skin .page-wrap {
        max-width: 100% !important;
        padding: 0 !important;
        margin: 0 !important;
    }
    
    /* Photo-like Print Layout Overrides */
    
    /* Big Blue Header (Reversing flex to put image on right, title on left) */
    #globalPrintHeader {
        background-color: #2b3a8c !important;
        margin: -15px -15px 30px -15px !important;
        padding: 30px 40px !important;
        border: none !important;
        display: flex !important;
        flex-direction: row-reverse !important;
        align-items: center !important;
        justify-content: space-between !important;
    }
    #globalPrintHeader .text-end {
        text-align: left !important;
        flex-grow: 1 !important;
    }
    #globalPrintHeader h4#printReportTitle {
        font-size: 32px !important;
        font-weight: 800 !important;
        color: white !important;
        margin-bottom: 10px !important;
    }
    #globalPrintHeader h3, #globalPrintHeader p, #globalPrintHeader .text-muted, #globalPrintHeader .text-dark, #globalPrintHeader .text-primary {
        color: rgba(255,255,255,0.9) !important;
        text-align: left !important;
    }
    
    #globalPrintHeader .d-flex.align-items-center.gap-3 {
        flex-direction: column !important; /* Stack school name below logo */
    }
    #globalPrintHeader img {
        width: 130px !important;
        height: 130px !important;
        border-radius: 50% !important;
        border: 4px solid white !important;
        box-shadow: 0 0 10px rgba(0,0,0,0.2) !important;
        object-fit: cover !important;
    }

    /* Cards/Panels shape to match photo (Light blue top bars with rounded cutouts) */
    .reports-skin .cardy, .reports-skin .panel, .reports-skin .table-shell, .reports-skin .stat {
        border: 1px solid #dcdcdc !important;
        border-radius: 0 !important;
        padding: 0 !important;
        margin-bottom: 25px !important;
        overflow: visible !important;
        page-break-inside: avoid !important;
    }
    
    /* Headers inside panels */
    .reports-skin .cardy h6, .reports-skin .panel h6, .reports-skin .table-shell h6, 
    .reports-skin .section-title, .reports-skin .stat h6, .reports-skin .cardy .k {
        background-color: #26c6da !important;
        color: white !important;
        text-align: center !important;
        font-weight: bold !important;
        font-size: 16px !important;
        padding: 10px !important;
        margin: 0 0 15px 0 !important;
        display: block !important;
        position: relative !important;
    }

    /* Cyan header cutouts (simulating photo style tags) */
    .reports-skin .cardy h6::before, .reports-skin .panel h6::before, .reports-skin .table-shell h6::before, 
    .reports-skin .section-title::before, .reports-skin .stat h6::before, .reports-skin .cardy .k::before {
        content: '' !important;
        position: absolute !important;
        top: 50% !important; left: -5px !important;
        width: 10px !important; height: 10px !important;
        background: white !important; border-radius: 50% !important;
        transform: translateY(-50%) !important;
        border-right: 1px solid #26c6da !important;
    }
    .reports-skin .cardy h6::after, .reports-skin .panel h6::after, .reports-skin .table-shell h6::after, 
    .reports-skin .section-title::after, .reports-skin .stat h6::after, .reports-skin .cardy .k::after {
        content: '' !important;
        position: absolute !important;
        top: 50% !important; right: -5px !important;
        width: 10px !important; height: 10px !important;
        background: white !important; border-radius: 50% !important;
        transform: translateY(-50%) !important;
        border-left: 1px solid #26c6da !important;
    }

    /* Prevent default grid gaps destroying flex */
    .reports-skin .stats { gap: 10px !important; }
    
    /* Inner Padding for content (so it doesn't touch borders) */
    .reports-skin .cardy > div:not(h6):not(.section-title):not(.k), 
    .reports-skin .panel > div:not(h6):not(.section-title), 
    .reports-skin .table-shell > div:not(h6):not(.section-title) {
        padding: 0 15px 15px 15px !important;
    }

    /* Table styling to match photo (dark blue table headers) */
    .reports-skin table {
        border-collapse: collapse !important;
        width: 100% !important;
        margin-bottom: 0 !important;
    }
    .reports-skin table th {
        background-color: #2b3a8c !important;
        color: white !important;
        text-align: center !important;
        font-weight: 600 !important;
        border: 1px solid #2b3a8c !important;
        padding: 8px !important;
    }
    .reports-skin table td {
        border: 1px solid #dcdcdc !important;
        text-align: center !important;
        padding: 8px !important;
        color: #333 !important;
    }
    .reports-skin .val, .reports-skin .v, .reports-skin .js-sr-avg, .reports-skin .js-sr-time {
        font-size: 20px !important; font-weight: bold !important; text-align: center !important;
    }
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
      selectAtLeastOne: "{{ __('Please select at least one card to print.') }}"
    });
    window.DEFAULT_AVATAR = "{{ asset('images/default-avatar.png') }}";
  </script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
  <script src="{{ asset('js/reports.js') }}"></script>
@endpush
