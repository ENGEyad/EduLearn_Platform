@extends('layouts.app')

@section('content')
<div class="container-fluid px-4 py-2">
    <!-- Header Section -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4 no-print" id="teachersHeader">
        <div>
            <h2 class="fw-bold text-navy mb-1">{{ __('Teachers Management') }}</h2>
            <p class="text-muted small mb-0">{{ __('Oversee and manage school faculty and academic assignments') }}</p>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <!-- List Actions -->
            <div id="teacherListActions" class="d-flex gap-2">
                <button class="btn btn-soft-success shadow-sm px-4 rounded-pill d-flex align-items-center gap-2" id="importTeachersBtn">
                    <i class="bi bi-cloud-arrow-up-fill"></i> {{ __('Import CSV') }}
                </button>
                <div class="dropdown">
                    <button class="btn btn-soft-secondary shadow-sm px-4 rounded-pill d-flex align-items-center gap-2 dropdown-toggle" type="button" data-bs-toggle="dropdown">
                        <i class="bi bi-download"></i> {{ __('Export') }}
                    </button>
                    <ul class="dropdown-menu border-0 shadow-lg" style="border-radius: 12px;">
                        <li><a class="dropdown-item py-2" href="{{ route('exports.teachers.csv') }}"><i class="bi bi-file-earmark-spreadsheet me-2 text-success"></i> {{ __('CSV Format') }}</a></li>
                        <li><a class="dropdown-item py-2" href="{{ route('exports.teachers.pdf') }}" target="_blank"><i class="bi bi-file-earmark-pdf text-danger me-2"></i> {{ __('PDF Document') }}</a></li>
                    </ul>
                </div>
                <button class="btn btn-primary shadow-sm px-4 rounded-pill d-flex align-items-center gap-2" id="openTeacherFormBtn">
                    <i class="bi bi-plus-lg"></i> {{ __('Register Teacher') }}
                </button>
            </div>

            <!-- Form Actions (Hidden by default) -->
            <div id="teacherFormActions" class="d-none">
                <button class="btn btn-light shadow-sm px-4 rounded-pill d-flex align-items-center gap-2" id="backToTeachersBtn">
                    <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'right' : 'left' }}"></i> {{ __('Back') }}
                </button>
            </div>
        </div>
    </div>

    <input type="file" id="teacherExcelInput" class="d-none" accept=".csv,.xls,.xlsx" />

    <!-- Main Content Area (List View) -->
    <div id="teachersListView" class="animate__animated animate__fadeIn">
        <div class="row g-4">
            <!-- Table Section -->
            <div class="col-lg-8">
                <div class="card-panel border-0 shadow-sm p-4 mb-3">
                    <!-- Filters Overlay -->
                    <div class="row g-3 mb-4">
                        <div class="col-12 col-md-5">
                            <div class="search-box position-relative">
                                <i class="bi bi-search position-absolute top-50 start-0 translate-middle-y ms-3 text-white"></i>
                                <input type="text" id="teacherSearch" class="form-control rounded-pill ps-5 bg-light border-0" placeholder="{{ __('Search by name, ID or subject...') }}">
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-3">
                            <select class="form-select rounded-pill bg-light border-0" id="teacherSubjectFilter">
                                <option value="">{{ __('All Subjects') }}</option>
                                <!-- Populated via JS or Backend -->
                            </select>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4">
                            <select class="form-select rounded-pill bg-light border-0" id="teacherStatusFilter">
                                <option value="">{{ __('Status') }}</option>
                                <option value="Active">🟢 {{ __('Active') }}</option>
                                <option value="Inactive">🔴 {{ __('Inactive') }}</option>
                            </select>
                        </div>
                    </div>

                    <!-- Modern Table -->
                    <div class="table-responsive" style="max-height: 600px; border-radius: 12px;">
                        <table class="table table-hover align-middle mb-0" id="teachersTable">
                            <thead class="sticky-top bg-white" style="z-index: 10;">
                                <tr class="text-muted small text-uppercase fw-bold" style="letter-spacing: 0.05em; background: #1b456fff;">
                                    <th class="ps-4 py-3">{{ __('Full Name') }}</th>
                                    <th class="py-3">{{ __('Teacher ID') }}</th>
                                    <th class="py-3">{{ __('Subjects') }}</th>
                                    <th class="py-3">{{ __('Status') }}</th>
                                    <th class="pe-4 py-3 text-end">{{ __('Actions') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                <!-- Dynamic Content -->
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- Profile Sidebar Section -->
            <div class="col-lg-4">
                <!-- Empty State -->
                <div id="sidebarEmptyState" class="card-panel border-0 shadow-sm h-100 d-flex flex-column align-items-center justify-content-center p-5 text-center">
                    <i class="bi bi-person-badge text-muted mb-3" style="font-size: 4rem; opacity: 0.1;"></i>
                    <p class="text-muted">{{ __('Select a teacher from the list to view their full profile and assigned classes.') }}</p>
                </div>

                <!-- Actual Profile Card -->
                <div class="card-panel border-0 shadow-sm h-100 p-0 overflow-hidden d-none" id="teacherProfile">
                    <div class="p-4 text-center border-bottom bg-light position-relative overflow-hidden" style="border-radius: 24px 24px 0 0;">
                        <!-- Ambient Profile Glow -->
                        <div class="position-absolute top-0 start-50 translate-middle-x bg-primary opacity-10" style="width: 200px; height: 100px; filter: blur(50px); border-radius: 50%;"></div>
                        
                        <div class="position-relative d-inline-block mb-3">
                            <div class="avatar-circle-lg mx-auto shadow-lg" id="prof-avatar">TC</div>
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
                            <div class="info-section mb-4 p-3 rounded-4 bg-light shadow-sm border border-white border-opacity-10">
                                <label class="text-muted small fw-bold text-uppercase mb-2 d-block" style="letter-spacing: 0.05em;">{{ __('Personal Info') }}</label>
                                <div class="d-flex flex-column gap-2">
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="bg-primary bg-opacity-10 p-2 rounded-circle" style="width:32px; height:32px; display:grid; place-items:center;"><i class="bi bi-envelope text-primary small"></i></div>
                                        <span id="prof-email" class="small text-truncate">--</span>
                                    </div>
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="bg-success bg-opacity-10 p-2 rounded-circle" style="width:32px; height:32px; display:grid; place-items:center;"><i class="bi bi-telephone text-success small"></i></div>
                                        <span id="prof-phone" class="small">--</span>
                                    </div>
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="bg-warning bg-opacity-10 p-2 rounded-circle" style="width:32px; height:32px; display:grid; place-items:center;"><i class="bi bi-cake2 text-warning small"></i></div>
                                        <span id="prof-dob" class="small">--</span>
                                    </div>
                                </div>
                                <div class="mt-3 pt-2 border-top small text-muted">
                                    <i class="bi bi-geo-alt text-danger me-2"></i> <span id="prof-address">--</span>
                                </div>
                            </div>

                            <div class="info-section p-3 rounded-4" style="background: rgba(0, 51, 102, 0.03); border: 1px dashed rgba(0, 51, 102, 0.1);">
                                <label class="text-muted small fw-bold text-uppercase mb-2 d-block" style="letter-spacing: 0.05em;">{{ __('Academic Assignments') }}</label>
                                <div class="mb-2">
                                    <div class="small fw-bold text-navy mb-1"><i class="bi bi-book text-info me-2"></i>{{ __('Subjects') }}</div>
                                    <div id="prof-subjects" class="small text-muted ps-4">--</div>
                                </div>
                                <div>
                                    <div class="small fw-bold text-navy mb-1"><i class="bi bi-door-open-fill text-primary me-2"></i>{{ __('Classes') }}</div>
                                    <div id="prof-classes" class="small text-muted ps-4">--</div>
                                </div>
                            </div>
                        </div>

                        <!-- Stats Progress Bars -->
                        <div class="mt-4 p-3 rounded-4 mb-2" style="background: rgba(0, 26, 51, 0.05); border: 1px dashed #bdd6f5;">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <span class="small fw-bold text-primary">{{ __('Student Performance') }}</span>
                                <span id="prof-performance" class="badge bg-primary">--</span>
                            </div>
                            <div class="progress" style="height: 6px; border-radius: 10px; background: rgba(0, 26, 51, 0.05);">
                                <div id="prof-perf-bar" class="progress-bar bg-primary" style="width: 0%"></div>
                            </div>
                        </div>

                        <div class="p-3 rounded-4" style="background: rgba(16, 185, 129, 0.05); border: 1px dashed #a7f3d0;">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <span class="small fw-bold text-success">{{ __('Attendance Rate') }}</span>
                                <span id="prof-attendance" class="badge bg-success">--</span>
                            </div>
                            <div class="progress" style="height: 6px; border-radius: 10px; background: rgba(16, 185, 129, 0.1);">
                                <div id="prof-att-bar" class="progress-bar bg-success" style="width: 0%"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Multi-Tab Teacher Form -->
    <div id="teacherFormView" class="animate__animated animate__fadeIn" style="display:none;">
        <div class="card-panel border-0 shadow-lg p-0 overflow-hidden">
            <div class="p-4 bg-primary text-white d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-3">
                <div>
                    <h4 class="fw-bold mb-0" id="teacherFormTitle">{{ __('Register New Teacher') }}</h4>
                    <p class="mb-0 text-white-50 small">{{ __('Complete all faculty records to ensure system parity') }}</p>
                </div>
            </div>

            <div class="p-4">
                <input type="hidden" id="tcDbId" value="">
                
                <ul class="nav nav-pills flex-column flex-sm-row mb-4 gap-2" id="teacherTabs">
                    <li class="nav-item"><a class="nav-link active rounded-pill px-4 text-center" data-bs-toggle="pill" href="#tab-basic"><i class="bi bi-person-circle me-2"></i>{{ __('Basic Info') }}</a></li>
                    <li class="nav-item"><a class="nav-link rounded-pill px-4 text-center" data-bs-toggle="pill" href="#tab-assignments"><i class="bi bi-journal-plus me-2"></i>{{ __('Duty & Assignments') }}</a></li>
                    <li class="nav-item"><a class="nav-link rounded-pill px-4 text-center" data-bs-toggle="pill" href="#tab-address-tc"><i class="bi bi-geo-alt-fill me-2"></i>{{ __('Address') }}</a></li>
                </ul>

                <div class="tab-content border-0">
                    <!-- Basic Info Tab -->
                    <div class="tab-pane fade show active" id="tab-basic">
                        <div class="row g-3">
                            <div class="col-12 col-md-5">
                                <label class="form-label-badge">{{ __('Full Name') }} <span class="text-danger">*</span></label>
                                <input type="text" class="form-control form-control-lg bg-light border-white" id="tcFullName" required>
                            </div>
                            <div class="col-12 col-md-3">
                                <label class="form-label-badge">{{ __('Birthdate') }} <span class="text-danger">*</span></label>
                                <input type="date" class="form-control form-control-lg bg-light border-white" id="tcBirthdate" required>
                            </div>
                            <div class="col-12 col-sm-6 col-md-2">
                                <label class="form-label-badge">{{ __('Gender') }} <span class="text-danger">*</span></label>
                                <select class="form-select form-select-lg bg-light border-white" id="tcGender" required>
                                    <option value="">{{ __('Select Gender') }}</option>
                                    <option value="Male">👨 {{ __('Male') }}</option>
                                    <option value="Female">👩 {{ __('Female') }}</option>
                                </select>
                            </div>
                            <div class="col-12 col-sm-6 col-md-2">
                                <label class="form-label-badge">{{ __('Status') }}</label>
                                <select class="form-select form-select-lg bg-light border-white" id="tcStatus">
                                    <option value="">{{ __('Select Status') }}</option>
                                    <option value="Active">🟢 {{ __('Active') }}</option>
                                    <option value="Inactive">🔴 {{ __('Inactive') }}</option>
                                </select>
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label-badge">{{ __('Email') }}</label>
                                <input type="email" class="form-control bg-light border-white" id="tcEmail">
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label-badge">{{ __('Phone') }}</label>
                                <input type="text" class="form-control bg-light border-white" id="tcPhone">
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label-badge">{{ __('Shift') }} <span class="text-danger">*</span></label>
                                <select class="form-select bg-light border-white" id="tcShift" required>
                                    <option value="Morning">☀️ {{ __('Morning') }}</option>
                                    <option value="Evening">🌙 {{ __('Evening') }}</option>
                                </select>
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label-badge">{{ __('Profile Photo') }}</label>
                                <input type="file" class="form-control bg-light border-white" id="tcPhoto" accept="image/*">
                            </div>
                        </div>
                    </div>

                    <!-- Assignments Tab -->
                    <div class="tab-pane fade" id="tab-assignments">
                        <div class="alert alert-soft-primary d-flex align-items-center mb-3">
                            <i class="bi bi-info-circle-fill me-3 fs-4"></i>
                            <div>{{ __('Assign the teacher to specific classes and subjects. You can add multiple assignments.') }}</div>
                        </div>
                        
                        <div id="assignmentsContainer" class="d-flex flex-column gap-3 p-3 rounded-4 bg-light">
                            <!-- JS populated rows -->
                        </div>
                        <button class="btn btn-outline-primary btn-sm mt-3 rounded-pill px-4" id="addAssignmentRowBtn">
                            <i class="bi bi-plus-lg me-2"></i> {{ __('Add New Assignment') }}
                        </button>
                    </div>

                    <!-- Address Tab -->
                    <div class="tab-pane fade" id="tab-address-tc">
                        <div class="row g-3">
                            <div class="col-12 col-md-4">
                                <label class="form-label-badge">{{ __('District') }}</label>
                                <input type="text" class="form-control bg-light border-white" id="tcDistrict">
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label-badge">{{ __('Neighborhood') }}</label>
                                <input type="text" class="form-control bg-light border-white" id="tcNeighborhood">
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label-badge">{{ __('Street') }}</label>
                                <input type="text" class="form-control bg-light border-white" id="tcStreet">
                            </div>
                        </div>
                    </div>
                </div>

                <div class="d-flex flex-column flex-sm-row gap-2 mt-5 pt-3 border-top">
                    <button class="btn btn-primary px-5 rounded-pill shadow w-100 w-sm-auto" id="saveTeacherBtn"><i class="bi bi-check2-circle me-2"></i> {{ __('Save Official Records') }}</button>
                    <button class="btn btn-light px-4 rounded-pill w-100 w-sm-auto" id="cancelTeacherBtn">{{ __('Cancel') }}</button>
                </div>
            </div>
        </div>
    </div>
</div>

<input type="file" id="importTeachersInput" class="d-none" />

<style>
/* CSS Architecture for Teachers */
.text-navy { color: #001A33; }
.cursor-pointer { cursor: pointer; }
tr.selected-row { background-color: rgba(0, 51, 102, 0.05) !important; }
body.dark-mode tr.selected-row { background-color: rgba(255, 255, 255, 0.08) !important; }

.btn-soft-success {
    background: rgba(52, 211, 153, 0.15);
    color: #059669;
    border: 1px solid rgba(52, 211, 153, 0.2);
}

.btn-soft-success:hover {
    background: #059669;
    color: #ffffff;
}

body.dark-mode .btn-soft-success {
    color: #34d399 !important;
    background: rgba(52, 211, 153, 0.15);
}

.btn-soft-secondary { 
    background: rgba(100, 116, 139, 0.1); 
    color: #64748b; 
    border: 1px solid rgba(100, 116, 139, 0.2);
}

.btn-soft-secondary:hover {
    background: #64748b;
    color: #ffffff;
}

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

.card-panel { background: var(--card); border-radius: 24px; border: 1px solid var(--border) !important; }

.avatar-circle-lg {
    width: 90px;
    height: 90px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--primary) 0%, #001A33 100%);
    color: #ffffff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2.2rem;
    font-weight: 700;
    border: 4px solid #ffffff;
    box-shadow: 0 10px 20px rgba(0,0,0,0.1);
    transition: all 0.3s ease;
}

body.dark-mode .avatar-circle-lg {
    border-color: rgba(255, 255, 255, 0.1);
    box-shadow: 0 10px 25px rgba(0,0,0,0.3);
}

.animate-update { animation: slideUp 0.3s ease-out; }
@keyframes slideUp {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
}

body.dark-mode .bg-light { background-color: rgba(255,255,255,0.03) !important; }
body.dark-mode .text-navy { color: #f1f5f9 !important; }
body.dark-mode .table thead th { color: #f1f5f9 !important; }

/* Custom Filter Select Styling */
#teacherSubjectFilter, #teacherStatusFilter, #teacherSearch {
    color: #ffffff !important;
    background-color: rgba(0, 26, 51, 0.7) !important;
    border: 1px solid rgba(255, 255, 255, 0.1) !important;
}

#teacherSubjectFilter, #teacherStatusFilter {
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23ffffff' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2 5l6 6 6-6'/%3e%3c/svg%3e") !important;
}

#teacherSearch::placeholder {
    color: #ffffff !important;
}

/* Styling for selects that are always dark (top filters) */
#teacherSubjectFilter option, #teacherStatusFilter option {
    background-color: #001A33 !important;
    color: #ffffff !important;
}

/* Styling for general selects (like those in the registration form) */
.form-select option {
    background-color: #ffffff;
    color: #001A33;
}

body.dark-mode .form-select option {
    background-color: #1a222c !important;
    color: #ffffff !important;
}
</style>

<!-- Delete Modal -->
<div class="modal fade" id="deleteTeacherModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold text-danger"><i class="bi bi-exclamation-triangle-fill me-2"></i> {{ __('Confirm Delete') }}</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body py-4 text-muted">
                {{ __('Are you sure you want to delete this teacher record? This will also affect their assignments.') }}
            </div>
            <div class="modal-footer border-0 pt-0">
                <button class="btn btn-soft-secondary rounded-pill px-4" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                <button class="btn btn-danger rounded-pill px-4" id="confirmDeleteTeacherBtn">{{ __('Delete Permanently') }}</button>
            </div>
        </div>
    </div>
</div>

@endsection

@push('scripts')
<script>
    window.TEACHERS_ROUTES = {
        list: @json($TEACHERS_ROUTES['list']),
        store: @json($TEACHERS_ROUTES['store']),
        update: (id) => @json($TEACHERS_ROUTES['update']).replace('__ID__', id),
        destroy: (id) => @json($TEACHERS_ROUTES['destroy']).replace('__ID__', id),
        import: @json($TEACHERS_ROUTES['import']),
    };

    window.STORAGE_BASE_URL = "{{ asset('storage') }}";
    window.I18N = window.I18N || {};
    Object.assign(window.I18N, {
        addNewTeacher: "{{ __('Add New Teacher') }}",
        editTeacher: "{{ __('Edit Teacher Profile') }}",
        active: "{{ __('Active') }}",
        suspended: "{{ __('Suspended') }}",
        teacherSaved: "{{ __('Teacher record updated successfully.') }}",
        savingFailed: "{{ __('Saving failed') }}",
        academicIdPrefix: "{{ __('Teacher Code') }}: ",
        unexpectedError: "{{ __('Unexpected error occurred') }}",
        noTeachersRegistered: "{{ __('noTeachersRegistered') }}",
        startByAddingTeacher: "{{ __('startByAddingTeacher') }}",
        invalidTeacherAge: "{{ __('invalidTeacherAge') }}",
        importFailed: "{{ __('Import process failed') }}",
        teachersImported: "{{ __('Teachers data imported successfully.') }}"
    });

    window.CLASSES_API = "{{ $CLASSES_API }}";
    window.CLASS_SUBJECTS_API = "{{ $CLASS_SUBJECTS_API }}";
    window.ALL_CLASSES = @json($allSections);
</script>
<script src="{{ asset('js/teachers.js') }}?v={{ time() }}"></script>
@endpush