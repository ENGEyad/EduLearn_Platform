@extends('layouts.app')

@section('content')
<div class="container-fluid px-4 py-2">
<!-- Page Header -->
<div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4 no-print" id="studentsHeader">
  <div>
    <h2 class="fw-bold text-title mb-1">{{ __('Students Management') }}</h2>
    <p class="text-muted small mb-0">{{ __('Advanced student records, performance tracking & profile management') }}</p>
  </div>
  <div class="d-flex flex-wrap gap-2">
    <!-- List Actions -->
    <div id="studentListActions" class="d-flex gap-2">
      <button class="btn btn-soft-success shadow-sm px-4 rounded-pill d-flex align-items-center gap-2" id="importExcelBtn">
        <i class="bi bi-cloud-arrow-up-fill"></i> {{ __('Import CSV') }}
      </button>
      <div class="dropdown">
        <button class="btn btn-soft-secondary shadow-sm px-4 rounded-pill d-flex align-items-center gap-2 dropdown-toggle" type="button" data-bs-toggle="dropdown">
          <i class="bi bi-download"></i> {{ __('Export') }}
        </button>
        <ul class="dropdown-menu border-0 shadow-lg" style="border-radius: 12px;">
          <li><a class="dropdown-item py-2" href="{{ route('exports.students.csv') }}"><i class="bi bi-file-earmark-excel text-success me-2"></i> {{ __('CSV Format') }}</a></li>
          <li><a class="dropdown-item py-2" href="{{ route('exports.students.pdf') }}" target="_blank"><i class="bi bi-file-earmark-pdf text-danger me-2"></i> {{ __('PDF Document') }}</a></li>
        </ul>
      </div>
      <button class="btn btn-primary shadow-sm px-4 rounded-pill d-flex align-items-center gap-2" id="openStudentFormBtn">
        <i class="bi bi-plus-lg"></i> {{ __('Register Student') }}
      </button>
    </div>

    <!-- Form Actions (Hidden by default) -->
    <div id="studentFormActions" class="d-none">
      <button class="btn btn-light shadow-sm px-4 rounded-pill d-flex align-items-center gap-2" id="backToStudentsBtn">
          <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'right' : 'left' }}"></i> {{ __('Back') }}
      </button>
    </div>
  </div>
</div>

<input type="file" id="excelInput" class="d-none" accept=".csv,.xls,.xlsx" />

<!-- Alerts -->
<div id="studentSavedAlert" class="alert alert-success alert-dismissible fade show d-none mb-4 rounded-4 shadow-sm" role="alert">
    <div class="d-flex align-items-center gap-2">
        <i class="bi bi-check-circle-fill"></i>
        <span id="studentSavedAlertMsg">{{ __('Success!') }}</span>
    </div>
    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>

<!-- View 1: List -->
<div id="studentsListView" class="animate__animated animate__fadeIn">
  <div class="row g-4">
    <div class="col-lg-8">
      <div class="card-panel border-0 shadow-sm p-4">
        <!-- Advanced Filters -->
        <div class="row g-3 mb-4 p-3 rounded-4" style="background: var(--bg); border: 1px solid var(--border);">
          <div class="col-12 col-md-5">
            <div class="input-group">
              <span class="input-group-text bg-transparent border-end-0 text-muted">
                <i class="bi bi-search"></i>
              </span>
              <input type="text" class="form-control border-start-0" id="studentSearch" placeholder="{{ __('Search students by name or ID...') }}">
            </div>
          </div>
          <div class="col-12 col-sm-6 col-md-3">
            <select class="form-select" id="gradeFilter">
               <option value="">{{ __('All Grades') }}</option>
               @foreach ($grades as $g)
                 <option value="{{ $g }}">{{ $g }}</option>
               @endforeach
            </select>
          </div>
          <div class="col-12 col-sm-6 col-md-2">
            <select class="form-select" id="genderFilter">
              <option value="">{{ __('All Genders') }}</option>
              <option value="Male">{{ __('Male') }}</option>
              <option value="Female">{{ __('Female') }}</option>
            </select>
          </div>
          <div class="col-12 col-sm-12 col-md-2">
            <select class="form-select" id="statusFilter">
              <option value="">{{ __('All Status') }}</option>
              <option value="Active">{{ __('Active') }}</option>
              <option value="Suspended">{{ __('Suspended') }}</option>
            </select>
          </div>
        </div>

        <!-- Table -->
        <div class="table-responsive" style="max-height: 600px; border-radius: 12px;">
          <table class="table table-hover align-middle mb-0" id="studentsTable">
            <thead class="sticky-top bg-white" style="z-index: 10;">
              <tr class="text-muted small text-uppercase fw-bold" style="letter-spacing: 0.05em; background: #1b456fff;">
                <th class="ps-4 py-3">{{ __('Full Name') }}</th>
                <th class="py-3">{{ __('Academic ID') }}</th>
                <th class="py-3">{{ __('Class') }}</th>
                <th class="py-3">{{ __('Status') }}</th>
                <th class="pe-4 py-3 text-end">{{ __('Actions') }}</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Enhanced Side Profile -->
    <div class="col-lg-4">
      <!-- Actual Profile Card (Hidden by default) -->
      <div class="card-panel border-0 shadow-sm h-100 p-0 overflow-hidden d-none" id="studentProfile">
        <div class="p-4 text-center border-bottom bg-light position-relative overflow-hidden" style="border-radius: 24px 24px 0 0;">
            <!-- Ambient Profile Glow -->
            <div class="position-absolute top-0 start-50 translate-middle-x bg-primary opacity-10" style="width: 200px; height: 100px; filter: blur(50px); border-radius: 50%;"></div>
            
            <div class="position-relative d-inline-block mb-3">
                <div class="avatar-circle-lg mx-auto shadow-lg" id="prof-avatar">ST</div>
                <span class="position-absolute bottom-0 end-0 p-2 bg-success border border-white rounded-circle shadow-sm" style="width: 18px; height: 18px;"></span>
            </div>
            <h5 class="fw-bold text-navy mb-1" id="prof-name">--</h5>
            <div class="badge bg-soft-primary text-primary px-3 rounded-pill border border-primary border-opacity-10" id="prof-id">--</div>
        </div>
        
        <div class="p-4">
            <!-- Sidebar Quick Actions -->
            <div class="d-flex flex-wrap gap-2 mb-4 no-print">
                <button class="btn btn-outline-primary btn-sm flex-fill rounded-pill js-sidebar-edit"><i class="bi bi-pencil me-1"></i> {{ __('Edit') }}</button>
                <button class="btn btn-outline-info btn-sm flex-fill rounded-pill js-sidebar-report"><i class="bi bi-bar-chart me-1"></i> {{ __('Report') }}</button>
                <button class="btn btn-outline-danger btn-sm rounded-circle js-sidebar-delete" style="width: 32px; height: 32px; padding: 0;"><i class="bi bi-trash"></i></button>
            </div>

            <div class="info-grid">
                <!-- Personal & Academic Section -->
                <div class="info-section mb-4 p-3 rounded-4 bg-light shadow-sm border border-white border-opacity-10">
                    <label class="text-muted small fw-bold text-uppercase mb-2 d-block" style="letter-spacing: 0.05em;">{{ __('Student Details') }}</label>
                    <div class="d-flex flex-column gap-2">
                        <div class="d-flex align-items-center gap-3">
                            <div class="bg-primary bg-opacity-10 p-1 rounded-circle" style="width:30px; height:30px; display:grid; place-items:center;"><i class="bi bi-cake2 text-primary small"></i></div>
                            <span id="prof-dob" class="small">--</span>
                        </div>
                        <div class="d-flex align-items-center gap-3">
                            <div class="bg-info bg-opacity-10 p-1 rounded-circle" style="width:30px; height:30px; display:grid; place-items:center;"><i class="bi bi-envelope text-info small"></i></div>
                            <span id="prof-email" class="small text-truncate">--</span>
                        </div>
                        <div class="d-flex align-items-center gap-3">
                            <div class="bg-navy bg-opacity-10 p-1 rounded-circle" style="width:30px; height:30px; display:grid; place-items:center;"><i class="bi bi-door-open-fill text-navy small"></i></div>
                            <span id="prof-grade-section" class="small fw-bold">--</span>
                        </div>
                    </div>
                </div>

                <!-- Guardian Info Section -->
                <div class="info-section mb-4 p-3 rounded-4" style="background: rgba(239, 68, 68, 0.03); border: 1px dashed rgba(239, 68, 68, 0.2);">
                    <label class="text-danger small fw-bold text-uppercase mb-2 d-block" style="letter-spacing: 0.05em;">{{ __('Guardian') }}</label>
                    <div class="fw-medium small mb-1"><i class="bi bi-person-heart text-danger me-2"></i><span id="prof-guardian">--</span></div>
                    <div class="small text-muted"><i class="bi bi-telephone text-success me-2"></i><span id="prof-guardian-phone">--</span></div>
                </div>

                <!-- Address Info -->
                <div class="info-section mb-4 p-3 rounded-4 bg-light shadow-sm border border-white border-opacity-10">
                    <label class="text-muted small fw-bold text-uppercase mb-2 d-block" style="letter-spacing: 0.05em;">{{ __('Address') }}</label>
                    <div class="d-flex align-items-center gap-3">
                        <div class="bg-warning bg-opacity-10 p-1 rounded-circle" style="width:30px; height:30px; display:grid; place-items:center;"><i class="bi bi-geo-alt text-warning small"></i></div>
                        <span id="prof-address" class="small">--</span>
                    </div>
                </div>

                <!-- Performance Metrics -->
                <div class="mt-4">
                    <div class="p-3 rounded-4 mb-2 shadow-sm border border-white" style="background: rgba(0, 51, 102, 0.03);">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <span class="small fw-bold text-primary">{{ __('Score Avg') }}</span>
                            <span id="prof-performance" class="badge bg-primary rounded-pill">--</span>
                        </div>
                        <div class="progress" style="height: 6px; border-radius: 10px; background: rgba(0, 51, 102, 0.1);">
                            <div id="prof-perf-bar" class="progress-bar bg-primary progress-bar-striped progress-bar-animated" style="width: 0%"></div>
                        </div>
                    </div>

                    <div class="p-3 rounded-4 shadow-sm border border-white" style="background: rgba(16, 185, 129, 0.03);">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <span class="small fw-bold text-success">{{ __('Attendance Rate') }}</span>
                            <span id="prof-attendance" class="badge bg-success rounded-pill">--</span>
                        </div>
                        <div class="progress" style="height: 6px; border-radius: 10px; background: rgba(16, 185, 129, 0.1);">
                            <div id="prof-att-bar" class="progress-bar bg-success" style="width: 0%"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
      </div>

      <!-- Empty State for Sidebar -->
      <div id="sidebarEmptyState" class="card-panel border-0 shadow-sm h-100 d-flex flex-column align-items-center justify-content-center p-5 text-center">
         <i class="bi bi-person-bounding-box text-muted mb-3" style="font-size: 4rem; opacity: 0.1;"></i>
         <p class="text-muted">{{ __('Select a student from the list to view their full profile and performance data.') }}</p>
      </div>
    </div>
  </div>
</div>

<!-- View 2: Multi-Tab Form -->
<div id="studentFormView" class="animate__animated animate__fadeIn" style="display:none;">
    <div class="card-panel border-0 shadow-lg p-0 overflow-hidden">
        <div class="p-4 bg-primary text-white d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-3">
            <div>
                <h4 class="fw-bold mb-0" id="formTitle">{{ __('Add New Student') }}</h4>
                <p class="mb-0 text-white-50 small">{{ __('Register a new member to the school system') }}</p>
            </div>
        </div>

        <div class="p-4">
            <input type="hidden" id="stDbId" />
            
            <!-- Tabs Navigation -->
            <ul class="nav nav-pills flex-column flex-sm-row mb-4 gap-2" id="studentTabs">
                <li class="nav-item"><a class="nav-link active rounded-pill px-4 text-center" data-bs-toggle="pill" href="#tab-basic"><i class="bi bi-person-circle me-2"></i>{{ __('Basic Info') }}</a></li>
                <li class="nav-item"><a class="nav-link rounded-pill px-4 text-center" data-bs-toggle="pill" href="#tab-address"><i class="bi bi-geo-alt-fill me-2"></i>{{ __('Address') }}</a></li>
                <li class="nav-item"><a class="nav-link rounded-pill px-4 text-center" data-bs-toggle="pill" href="#tab-guardian"><i class="bi bi-person-heart me-2"></i>{{ __('Guardian') }}</a></li>
            </ul>

            <div class="tab-content">
                <!-- Basic Info Tab -->
                <div class="tab-pane fade show active" id="tab-basic">
                    <div class="row g-3">
                        <div class="col-12 col-md-5">
                            <label class="form-label-badge">{{ __('Full Name') }} <span class="text-danger">*</span></label>
                            <input type="text" class="form-control form-control-lg bg-light border-0" id="stFullName" placeholder="Full name as written in ID" required>
                        </div>
                        <div class="col-12 col-md-3">
                            <label class="form-label-badge">{{ __('Date of Birth') }} <span class="text-danger">*</span></label>
                            <input type="date" class="form-control form-control-lg bg-light border-0" id="stBirthdate" required>
                        </div>
                        <div class="col-12 col-sm-6 col-md-2">
                            <label class="form-label-badge">{{ __('Gender') }} <span class="text-danger">*</span></label>
                            <select class="form-control form-control-lg bg-light border-0" id="stGender" required>
                                <option value="">{{ __('Select') }}</option>
                                <option value="Male">{{ __('Male') }}</option>
                                <option value="Female">{{ __('Female') }}</option>
                            </select>
                        </div>
                        <div class="col-12 col-sm-6 col-md-2">
                            <label class="form-label-badge">{{ __('Status') }}</label>
                            <select class="form-control form-control-lg bg-light border-0" id="stStatus">
                                <option value="Active">🟢 {{ __('Active') }}</option>
                                <option value="Suspended">🔴 {{ __('Suspended') }}</option>
                            </select>
                        </div>
                        <div class="col-12 col-md-4">
                            <label class="form-label-badge">{{ __('Email Address') }}</label>
                            <input type="email" class="form-control bg-light border-0" id="stEmail" placeholder="student@school.com">
                        </div>
                        <div class="col-12 col-sm-6 col-md-4">
                            <label class="form-label-badge">{{ __('Grade') }} <span class="text-danger">*</span></label>
                            <select class="form-control bg-light border-0" id="stGrade" required>
                                <option value="">{{ __('Select Grade') }}</option>
                                @php
                                    $availableGrades = collect($allSections ?? [])->pluck('grade')->unique()->sort();
                                @endphp
                                @foreach ($availableGrades as $g)
                                    <option value="{{ $g }}">{{ __('Grade') }} {{ $g }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4">
                            <label class="form-label-badge">{{ __('Class Section') }} <span class="text-danger">*</span></label>
                            <select class="form-control bg-light border-0" id="stClassSection" required>
                                <option value="">{{ __('Select') }}</option>
                            </select>
                        </div>
                        <div class="col-12 col-md-6">
                            <label class="form-label-badge">{{ __('Profile Photo') }}</label>
                            <div class="d-flex align-items-center gap-3 mb-2">
                                <div id="formPhotoPreview" class="avatar-circle-md shadow-sm border border-white" style="width: 60px; height: 60px; border-radius: 12px; background-size: cover; background-position: center; display: none;"></div>
                                <input type="file" class="form-control bg-light border-0 flex-grow-1" id="stPhoto" accept="image/*">
                            </div>
                        </div>
                        <div class="col-12 col-md-6">
                            <label class="form-label-badge">{{ __('Notes / Remarks') }}</label>
                            <textarea class="form-control bg-light border-0" id="stNotes" rows="1" placeholder="Any special remarks..."></textarea>
                        </div>
                    </div>
                </div>

                <!-- Address Tab -->
                <div class="tab-pane fade" id="tab-address">
                    <div class="row g-3">
                        <div class="col-12 col-md-4">
                            <label class="form-label-badge">{{ __('Governorate') }}</label>
                            <input type="text" class="form-control bg-light border-0" id="stGov" placeholder="e.g. Sana'a">
                        </div>
                        <div class="col-12 col-md-4">
                            <label class="form-label-badge">{{ __('City') }}</label>
                            <input type="text" class="form-control bg-light border-0" id="stCity">
                        </div>
                        <div class="col-12 col-md-4">
                            <label class="form-label-badge">{{ __('Street') }}</label>
                            <input type="text" class="form-control bg-light border-0" id="stStreet">
                        </div>
                    </div>
                </div>

                <!-- Guardian Tab -->
                <div class="tab-pane fade" id="tab-guardian">
                    <div class="row g-3">
                        <div class="col-12 col-md-5">
                            <label class="form-label-badge">{{ __('Guardian Name') }} <span class="text-danger">*</span></label>
                            <input type="text" class="form-control bg-light border-0" id="guardianName" required>
                        </div>
                        <div class="col-12 col-sm-6 col-md-3">
                            <label class="form-label-badge">{{ __('Relationship') }}</label>
                            <select class="form-select bg-light border-0" id="guardianRelation">
                                <option value="">{{ __('Select') }}</option>
                                <option>{{ __('Father') }}</option>
                                <option>{{ __('Mother') }}</option>
                                <option>{{ __('Brother') }}</option>
                                <option value="other">{{ __('Other...') }}</option>
                            </select>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 d-none" id="guardianRelationOtherWrap">
                            <label class="form-label-badge">{{ __('Specify Relationship') }}</label>
                            <input type="text" class="form-control bg-light border-0" id="guardianRelationOther" placeholder="...">
                        </div>
                        <div class="col-12 col-md-4">
                            <label class="form-label-badge">{{ __('Guardian Phone') }} <span class="text-danger">*</span></label>
                            <input type="text" class="form-control bg-light border-0" id="guardianPhone" placeholder="777 000 000" required>
                        </div>
                    </div>
                </div>
            </div>

            </div>

            <div class="d-flex flex-column flex-sm-row gap-2 mt-5 pt-3 border-top">
                <button class="btn btn-primary px-5 rounded-pill shadow w-100 w-sm-auto" id="saveStudentBtn"><i class="bi bi-check2-circle me-2"></i> {{ __('Save Official Records') }}</button>
                <button class="btn btn-light px-4 rounded-pill w-100 w-sm-auto" id="cancelStudentBtn">{{ __('Cancel') }}</button>
            </div>
        </div>
    </div>
</div>

<style>
.avatar-circle-lg {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    background: var(--primary);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2rem;
    font-weight: bold;
    border: 4px solid white;
}
.status-pill {
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
}
.btn-soft-success { 
    background: rgba(16, 185, 129, 0.1); 
    color: #10b981; 
    border: 1px solid rgba(16, 185, 129, 0.2);
}
.btn-soft-secondary { 
    background: rgba(100, 116, 139, 0.1); 
    color: #64748b; 
    border: 1px solid rgba(100, 116, 139, 0.2);
}
body.dark-mode .btn-soft-success {
    color: #34d399 !important;
    background: rgba(52, 211, 153, 0.15);
}
body.dark-mode .btn-soft-secondary {
    color: #cbd5e1 !important;
    background: rgba(203, 213, 225, 0.1);
}
body.dark-mode .text-muted {
    color: #94a3b8 !important;
}
body.dark-mode .text-navy, 
body.dark-mode .table thead th,
body.dark-mode #studentName {
    color: #f1f5f9 !important;
}
body.dark-mode .table {
    color: #cbd5e1;
}
.status-active { background: rgba(16, 185, 129, 0.1); color: #10b981; }
.status-suspended { background: rgba(239, 68, 68, 0.1); color: #ef4444; }
.nav-pills .nav-link { 
    color: var(--text); 
    background: rgba(0, 0, 0, 0.03); 
    margin-bottom: 5px; 
    border: none;
    transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: inset 0 0 0 1px rgba(0,0,0,0.05);
}
body.dark-mode .nav-pills .nav-link {
    background: rgba(255, 255, 255, 0.03);
    box-shadow: inset 0 0 0 1px rgba(255,255,255,0.05);
}
.nav-pills .nav-link.active { 
    background-color: var(--primary); 
    box-shadow: 0 4px 15px rgba(0, 26, 51, 0.2);
}
.card-panel { background: var(--card); border-radius: 24px; border: 1px solid var(--border) !important; }
.form-label {
    font-size: 0.82rem;
    color: #475569;
    margin-bottom: 8px;
    letter-spacing: 0.02em;
    border: 1px solid #ffffff;
    padding: 2px 14px;
    border-radius: 8px;
    display: inline-block;
    background: #ffffff;
    box-shadow: 0 2px 6px rgba(0,0,0,0.05);
    font-weight: 700;
}
body.dark-mode .form-label {
    background: rgba(255, 255, 255, 0.1);
    border-color: rgba(255, 255, 255, 0.2);
    color: #ffffff;
}
.text-navy { color: #001A33; }
.cursor-pointer { cursor: pointer; }
tr.selected-row { background-color: rgba(0, 51, 102, 0.05) !important; }
body.dark-mode tr.selected-row { background-color: rgba(255, 255, 255, 0.08) !important; }

.form-label-badge {
    font-size: 0.82rem;
    color: #475569;
    margin-bottom: 8px;
    letter-spacing: 0.02em;
    border: 1px solid #ffffff;
    padding: 2px 14px;
    border-radius: 8px;
    display: inline-block;
    background: #ffffff;
    box-shadow: 0 2px 6px rgba(0,0,0,0.05);
    font-weight: 700;
}

body.dark-mode .form-label-badge {
    background: rgba(255, 255, 255, 0.1);
    border-color: rgba(255, 255, 255, 0.2);
    color: #ffffff;
}

.form-control, .form-select {
    border-radius: 12px;
    padding: 12px 16px;
    font-size: 0.95rem;
    transition: all 0.3s ease;
    border: 2px solid #ffffff !important;
    
}

body.dark-mode .form-control, body.dark-mode .form-select {
    background-color: rgba(255, 255, 255, 0.05) !important;
    color: #fff !important;
    border-color: rgba(255, 255, 255, 0.1) !important;
}

/* Custom Filter Select & Search Styling */
#gradeFilter, #genderFilter, #statusFilter, #studentSearch {
    color: #ffffff !important;
    background-color: rgba(0, 26, 51, 0.7) !important;
    border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

#gradeFilter, #genderFilter, #statusFilter {
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23ffffff' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2 5l6 6 6-6'/%3e%3c/svg%3e") !important;
}

#studentSearch::placeholder {
    color: rgba(255, 255, 255, 0.8) !important;
}

#gradeFilter option, #genderFilter option, #statusFilter option {
    background-color: #001A33 !important;
    color: #ffffff !important;
}

.nav-pills .nav-link { 
    color: var(--text); 
    background: rgba(0, 0, 0, 0.03); 
    border: none;
    transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: inset 0 0 0 1px rgba(0,0,0,0.05);
}

.nav-pills .nav-link.active { 
    background-color: var(--primary); 
    color: #fff !important;
    box-shadow: 0 4px 15px rgba(0, 26, 51, 0.2);
}

/* .card-panel { background: var(--card); border-radius: 24px; border: 1px solid var(--border) !important; } */

.animate-update { animation: slideUp 0.3s ease-out; }
@keyframes slideUp {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
}

body.dark-mode .bg-light { background-color: rgba(255,255,255,0.05) !important; }
body.dark-mode .text-navy { color: #f1f5f9 !important; }
body.dark-mode .table thead th { color: #f1f5f9 !important; }

/* Custom Filter Select Styling */
#gradeFilter, #genderFilter, #statusFilter, #studentSearch {
    color: #ffffff !important;
    background-color: rgba(0, 26, 51, 0.7) !important;
    border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

.form-select option {
    background-color: #001A33 !important;
    color: #ffffff !important;
}

body.dark-mode .form-select option {
    background-color: #000c19 !important;
}
</style>

<!-- Delete Modal -->
<div class="modal fade" id="deleteStudentModal" tabindex="-1" aria-labelledby="deleteStudentLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content border-0 shadow-lg" style="border-radius: 20px;">
      <div class="modal-header border-0 pb-0">
        <h5 class="modal-title fw-bold text-danger" id="deleteStudentLabel"><i class="bi bi-exclamation-triangle-fill me-2"></i> {{ __('Confirm Delete') }}</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body py-4">
        <p class="mb-0 text-muted">{{ __('Are you sure you want to delete this student record? This action is permanent and cannot be undone.') }}</p>
      </div>
      <div class="modal-footer border-0 pt-0">
        <button type="button" class="btn btn-soft-secondary rounded-pill px-4" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
        <button type="button" class="btn btn-danger rounded-pill px-4" id="confirmDeleteStudentBtn">{{ __('Delete Permenantly') }}</button>
      </div>
    </div>
  </div>
</div>

</div>
@endsection

@push('scripts')
<script>
  window.STUDENTS_ROUTES = {
    list: "{{ route('students.list') }}",
    store: "{{ route('students.store') }}",
    update: function(id) {
      return "{{ url('/students') }}/" + id;
    },
    destroy: function(id) {
      return "{{ url('/students') }}/" + id;
    },
    import: "{{ route('students.import') }}"
  };

  window.STORAGE_BASE_URL = "{{ asset('storage') }}";
  window.ALL_SECTIONS = @json($allSections ?? []);
  window.I18N = window.I18N || {};
  Object.assign(window.I18N, {
    addNewStudent: "{{ __('Register New Student') }}",
    editStudent: "{{ __('Edit Student Profile') }}",
    academicIdPrefix: "{{ __('Academic ID') }}: ",
    guardian: "{{ __('Guardian') }}",
    active: "{{ __('Active') }}",
    suspended: "{{ __('Suspended') }}",
    savingFailed: "{{ __('Saving failed') }}",
    studentSaved: "{{ __('Student records updated successfully.') }}",
    importFailed: "{{ __('Import process failed') }}",
    studentsImported: "{{ __('Students data imported successfully.') }}",
    unexpectedError: "{{ __('Unexpected error occurred') }}",
    confirmUnsaved: "{{ __('You have unsaved changes! Are you sure you want to discard them?') }}",
    requiredFieldsMissing: "{{ __('Required Fields Missing') }}",
    pleaseFill: "{{ __('Please fill in the following fields:') }}",
    fullName: "{{ __('Full Name') }}",
    gender: "{{ __('Gender') }}",
    birthdate: "{{ __('Date of Birth') }}",
    grade: "{{ __('Grade') }}",
    classSection: "{{ __('Class Section') }}",
    guardianName: "{{ __('Guardian Name') }}",
    guardianPhone: "{{ __('Guardian Phone') }}",
    noStudentsRegistered: "{{ __('noStudentsRegistered') }}",
    startByAddingStudent: "{{ __('startByAddingStudent') }}",
    invalidStudentAge: "{{ __('invalidStudentAge') }}"
  });
</script>
<script src="{{ asset('js/students.js') }}"></script>
@endpush