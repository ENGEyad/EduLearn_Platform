@extends('layouts.app')

@section('content')
<div class="row g-3 anim-fade-up">
  <div class="col-12">
    <!-- Premium Page Header -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center mb-4 gap-3">
      <div class="d-flex align-items-center gap-3">
        <div class="rounded-circle d-flex align-items-center justify-content-center shadow-sm" style="width: 54px; height: 54px; background: linear-gradient(135deg, var(--primary), #004080); color: white;">
          <i class="bi bi-diagram-3 fs-3"></i>
        </div>
        <div>
          <h2 class="page-title mb-1 fw-bold" style="color: var(--title);">{{ __('Teacher Assignments') }}</h2>
          <p class="text-muted small mb-0">{{ __('Manage and optimize the link between teachers, classes, and academic subjects.') }}</p>
        </div>
      </div>
      <div class="d-flex gap-2 flex-wrap">
        <button class="btn btn-soft d-flex align-items-center gap-2 js-refresh-list tilt-3d" title="{{ __('Refresh') }}">
          <i class="bi bi-arrow-clockwise"></i> <span class="d-none d-sm-inline">{{ __('Refresh') }}</span>
        </button>
        <button class="btn btn-soft d-flex align-items-center gap-2 tilt-3d" onclick="document.getElementById('csv_file').click()">
          <i class="bi bi-file-earmark-arrow-up"></i> {{ __('Import CSV') }}
        </button>
        <button class="btn btn-primary shadow-sm d-flex align-items-center gap-2 tilt-3d" data-bs-toggle="modal" data-bs-target="#assignmentModal">
          <i class="bi bi-plus-lg"></i> {{ __('New Assignment') }}
        </button>
        <input type="file" id="csv_file" class="d-none" accept=".csv">
      </div>
    </div>

    <!-- Stats Grid -->
    <div class="row row-cols-2 row-cols-md-4 g-3 mb-4">
      <div class="col">
        <div class="stat-card h-100 tilt-3d anim-fade-up anim-delay-1 mb-0">
          <h6 class="text-muted fw-semibold mb-2" style="font-size: 0.85rem; letter-spacing: 0.5px;">{{ mb_strtoupper(__('Total Assignments')) }}</h6>
          <div class="d-flex align-items-center justify-content-between">
            <div class="h3 mb-0 fw-bold text-dark js-stat-total">—</div>
            <div class="rounded-circle d-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: rgba(0, 51, 102, 0.08); color: var(--primary);">
              <i class="bi bi-diagram-2-fill fs-5"></i>
            </div>
          </div>
        </div>
      </div>
      <div class="col">
        <div class="stat-card h-100 tilt-3d anim-fade-up anim-delay-2 mb-0">
          <h6 class="text-muted fw-semibold mb-2" style="font-size: 0.85rem; letter-spacing: 0.5px;">{{ mb_strtoupper(__('Avg Weekly Load')) }}</h6>
          <div class="d-flex align-items-center justify-content-between">
            <div class="h3 mb-0 fw-bold text-dark js-stat-avg-load">—</div>
            <div class="rounded-circle d-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: rgba(16, 185, 129, 0.1); color: #10b981;">
              <i class="bi bi-clock-history fs-5"></i>
            </div>
          </div>
        </div>
      </div>
      <div class="col">
        <div class="stat-card h-100 tilt-3d anim-fade-up anim-delay-3 mb-0">
          <h6 class="text-muted fw-semibold mb-2" style="font-size: 0.85rem; letter-spacing: 0.5px;">{{ mb_strtoupper(__('Active Coverage')) }}</h6>
          <div class="d-flex align-items-center justify-content-between">
            <div class="h3 mb-0 fw-bold text-dark js-stat-coverage">—</div>
            <div class="rounded-circle d-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: rgba(56, 189, 248, 0.1); color: #0284c7;">
              <i class="bi bi-shield-check fs-5"></i>
            </div>
          </div>
        </div>
      </div>
      <div class="col">
        <div class="stat-card h-100 tilt-3d anim-fade-up anim-delay-4 mb-0">
          <h6 class="text-muted fw-semibold mb-2" style="font-size: 0.85rem; letter-spacing: 0.5px;">{{ mb_strtoupper(__('Teacher Pool')) }}</h6>
          <div class="d-flex align-items-center justify-content-between">
            <div class="h3 mb-0 fw-bold text-dark js-stat-teachers">—</div>
            <div class="rounded-circle d-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: rgba(245, 158, 11, 0.1); color: #d97706;">
              <i class="bi bi-people-fill fs-5"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Filters Panel -->
    <div class="card-panel mb-4 anim-fade-up anim-delay-5" style="padding: 1rem 1.25rem;">
      <div class="row g-3 align-items-center">
        <div class="col-12 col-md-4 col-lg-3">
          <div class="input-group input-group-sm">
            <span class="input-group-text bg-light border-end-0"><i class="bi bi-person text-muted"></i></span>
            <select class="form-select border-start-0 ps-0 bg-light" id="filterTeacher" style="box-shadow: none;">
              <option value="">{{ __('All Teachers') }}</option>
            </select>
          </div>
        </div>
        <div class="col-6 col-md-2">
          <div class="input-group input-group-sm">
            <span class="input-group-text bg-light border-end-0"><i class="bi bi-layers text-muted"></i></span>
            <select class="form-select border-start-0 ps-0 bg-light" id="filterGrade" style="box-shadow: none;">
              <option value="">{{ __('All Grades') }}</option>
            </select>
          </div>
        </div>
        <div class="col-6 col-md-2">
          <div class="input-group input-group-sm">
            <span class="input-group-text bg-light border-end-0"><i class="bi bi-grid text-muted"></i></span>
            <select class="form-select border-start-0 ps-0 bg-light" id="filterSection" style="box-shadow: none;">
              <option value="">{{ __('All Sections') }}</option>
            </select>
          </div>
        </div>
        <div class="col-12 col-md-4 col-lg-3">
          <div class="input-group input-group-sm">
            <span class="input-group-text bg-light border-end-0"><i class="bi bi-book text-muted"></i></span>
            <select class="form-select border-start-0 ps-0 bg-light" id="filterSubject" style="box-shadow: none;">
              <option value="">{{ __('All Subjects') }}</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <!-- Data Table -->
    <div class="table-shell anim-fade-up anim-delay-6">
      <div class="d-flex justify-content-between align-items-center mb-3 px-1">
        <h6 class="fw-bold mb-0 text-dark">{{ __('Current Assignments') }}</h6>
      </div>
      <div class="table-responsive" style="max-height: 550px; overflow-y: auto;">
        <table class="table table-hover align-middle mb-0" id="assignments-table">
          <thead style="position: sticky; top: 0; background: var(--card); z-index: 10;">
            <tr class="text-muted small text-uppercase fw-bold" style="letter-spacing: 0.05em;">
              <th style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Teacher') }}</th>
              <th style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Class/Section') }}</th>
              <th style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Subject') }}</th>
              <th class="d-none d-lg-table-cell" style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Workload') }}</th>
              <th class="text-center d-none d-md-table-cell" style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Status') }}</th>
              <th class="text-end pe-4" style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Actions') }}</th>
            </tr>
          </thead>
          <tbody>
            {{-- via JS --}}
          </tbody>
        </table>
      </div>
    </div>
    <div id="unassigned-alert" class="mt-4" style="display: none;">
      <div class="cardy" style="border: 1px dashed var(--warning); background: rgba(255, 193, 7, 0.05); border-radius: 12px;">
        <div class="d-flex align-items-center gap-3 p-3">
          <div class="rounded-circle bg-warning text-dark d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; min-width: 40px;">
            <i class="bi bi-exclamation-triangle-fill"></i>
          </div>
          <div class="flex-grow-1">
            <h6 class="mb-1 text-warning-emphasis" style="font-weight: 700;">{{ __('Unassigned Teachers') }}</h6>
            <div class="small text-muted" id="unassigned-list"></div>
          </div>
          <button class="btn btn-sm btn-warning text-dark px-3 fw-bold" data-bs-toggle="modal" data-bs-target="#assignmentModal">
            {{ __('Quick Assign') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</div>

{{-- Modal --}}
<div class="modal fade" id="assignmentModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form id="assignmentForm">
        @csrf
        <div class="modal-header">
          <h5 class="modal-title" id="assignmentModalTitle">{{ __('New Assignment') }}</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label">{{ __('Teacher') }}</label>
            <select class="form-select" id="teacher_id" required></select>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Class') }}</label>
            <select class="form-select" id="class_section_id" required></select>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Subject') }}</label>
            <select class="form-select" id="subject_id" required></select>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Weekly Load') }} ({{ __('Optional') }})</label>
            <input type="number" min="0" max="40" class="form-control" id="weekly_load">
          </div>

          <div class="form-check">
            <input class="form-check-input" type="checkbox" id="assign_is_active" checked>
            <label class="form-check-label" for="assign_is_active">{{ __('Active') }}</label>
          </div>

          <div id="assignError" class="text-danger small mt-2" style="display:none;"></div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
          <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
        </div>
      </form>
    </div>
  </div>
</div>
@endsection

@push('scripts')
<script>
  Object.assign(window.I18N, {
    allTeachers: "{{ __('All Teachers') }}",
    selectTeacher: "{{ __('Select Teacher') }}",
    allGrades: "{{ __('All Grades') }}",
    allSections: "{{ __('All Sections') }}",
    allSubjects: "{{ __('All Subjects') }}",
    selectSubject: "{{ __('Select Subject') }}",
    selectClass: "{{ __('Select Class') }}",
    editAssignment: "{{ __('Modify Assignment') }}",
    deleteAssignmentConfirm: "{{ __('Delete this assignment?') }}",
    unassignedLabel: "{{ __('These teachers have no active assignments:') }}"
  });

  window.ASSIGN_ROUTES = @json($ASSIGN_ROUTES);
  window.TEACHERS_API  = @json($TEACHERS_API);
  window.CLASSES_API   = @json($CLASSES_API);
  window.SUBJECTS_API  = @json($SUBJECTS_API);
  window.CLASS_SUBJECTS_API = "{{ route('class-subjects.list') }}";
</script>
<script src="{{ asset('js/assignments.js') }}"></script>
@endpush
