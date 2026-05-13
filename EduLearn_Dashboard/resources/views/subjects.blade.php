@extends('layouts.app')

@section('content')
<div class="row g-3 anim-fade-up">
  <div class="col-12">
    <!-- Premium Page Header -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center mb-4 gap-3">
      <div class="d-flex align-items-center gap-3">
        <div class="rounded-circle d-flex align-items-center justify-content-center shadow-sm" style="width: 54px; height: 54px; background: linear-gradient(135deg, var(--primary), #004080); color: white;">
          <i class="bi bi-book fs-3"></i>
        </div>
        <div>
          <h2 class="page-title mb-1 fw-bold" style="color: var(--title);">{{ __('Subjects') }}</h2>
          <p class="text-muted small mb-0">{{ __('Manage academic curriculum, content, and tracking features.') }}</p>
        </div>
      </div>
      <div class="d-flex gap-2 flex-wrap">
        <button class="btn btn-soft d-flex align-items-center gap-2 tilt-3d js-refresh-list" title="{{ __('Refresh') }}">
          <i class="bi bi-arrow-clockwise"></i> <span class="d-none d-sm-inline">{{ __('Refresh') }}</span>
        </button>
         <!-- For SuperAdmin, or dynamic later: -->
        <button id="btnAddSubject" class="btn btn-primary shadow-sm d-flex align-items-center gap-2 tilt-3d">
          <i class="bi bi-plus-lg"></i> {{ __('Add Subject') }}
        </button> 
        
      </div>
    </div>

    <!-- Stats Grid -->
    <div class="row row-cols-1 row-cols-sm-2 row-cols-md-3 g-3 mb-4">
      <div class="col">
        <div class="stat-card h-100 tilt-3d anim-fade-up anim-delay-1 mb-0">
          <h6 class="text-muted fw-semibold mb-2" style="font-size: 0.85rem; letter-spacing: 0.5px;">{{ mb_strtoupper(__('Total Active Subjects')) }}</h6>
          <div class="d-flex align-items-center justify-content-between">
            <div class="h3 mb-0 fw-bold text-dark js-stat-total">—</div>
            <div class="rounded-circle d-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: rgba(0, 51, 102, 0.08); color: var(--primary);">
              <i class="bi bi-journal-bookmark-fill fs-5"></i>
            </div>
          </div>
        </div>
      </div>
      <div class="col">
        <div class="stat-card h-100 tilt-3d anim-fade-up anim-delay-2 mb-0">
          <h6 class="text-muted fw-semibold mb-2" style="font-size: 0.85rem; letter-spacing: 0.5px;">{{ mb_strtoupper(__('Assigned Teachers')) }}</h6>
          <div class="d-flex align-items-center justify-content-between">
            <div class="h3 mb-0 fw-bold text-dark js-stat-teachers">—</div>
            <div class="rounded-circle d-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: rgba(16, 185, 129, 0.1); color: #10b981;">
              <i class="bi bi-pen-fill fs-5"></i>
            </div>
          </div>
        </div>
      </div>
      <div class="col">
        <div class="stat-card h-100 tilt-3d anim-fade-up anim-delay-3 mb-0">
          <h6 class="text-muted fw-semibold mb-2" style="font-size: 0.85rem; letter-spacing: 0.5px;">{{ mb_strtoupper(__('Curriculum Coverage')) }}</h6>
          <div class="d-flex align-items-center justify-content-between">
            <div class="h3 mb-0 fw-bold text-dark js-stat-coverage">—</div>
            <div class="rounded-circle d-flex align-items-center justify-content-center" style="width: 48px; height: 48px; background: rgba(56, 189, 248, 0.1); color: #0284c7;">
              <i class="bi bi-pie-chart-fill fs-5"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Data Table -->
    <div class="table-shell anim-fade-up anim-delay-4">
      <div class="d-flex justify-content-between align-items-center mb-3 px-1">
        <h6 class="fw-bold mb-0 text-dark">{{ __('Core Subjects List') }}</h6>
      </div>
      <div class="table-responsive" style="max-height: 550px; overflow-y: auto;">
        <table class="table table-hover align-middle mb-0" id="subjects-table">
          <thead style="position: sticky; top: 0; background: var(--card); z-index: 10;">
            <tr class="text-muted small text-uppercase fw-bold" style="letter-spacing: 0.05em;">
              <th style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">#</th>
              <th style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Subject Info') }}</th>
              <th class="d-none d-md-table-cell" style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Name (Arabic)') }}</th>
              <th class="text-center" style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Status') }}</th>
              <th class="text-end pe-4" style="padding-bottom: 12px; border-bottom: 2px solid var(--border) !important;">{{ __('Actions') }}</th>
            </tr>
          </thead>
          <tbody>
            {{-- via JS --}}
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

{{-- Modal --}}
<div class="modal fade" id="subjectModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form id="subjectForm">
        @csrf
        <input type="hidden" id="subject_id">

        <div class="modal-header">
          <h5 class="modal-title" id="subjectModalTitle">{{ __('Add Subject') }}</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label">{{ __('Code') }}</label>
            <input type="text" class="form-control" id="code" required>
            <small class="text-muted">{{ __('e.g. quran, islamic, math') }}</small>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Name (English)') }}</label>
            <input type="text" class="form-control" id="name_en" required>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Name (Arabic)') }}</label>
            <input type="text" class="form-control" id="name_ar">
          </div>

          <div class="mb-3">
            <label class="form-label fw-bold d-flex align-items-center gap-2 mb-2" style="color: var(--primary);">
                <i class="bi bi-people-fill fs-5"></i> {{ __('Assign to Classes') }}
            </label>
            <div id="classCheckboxes" class="custom-scroll border rounded-3 p-3" 
                 style="max-height: 200px; overflow-y: auto; background: #fafbfc; border: 1px solid #eef2f7 !important; box-shadow: inset 0 2px 6px rgba(0,0,0,0.02);">
              <div class="text-center small text-muted py-3">
                  <div class="spinner-border spinner-border-sm text-primary mb-2"></div>
                  <div class="opacity-75">{{ __('Loading classes...') }}</div>
              </div>
            </div>
            <div class="alert alert-info py-2 px-3 mt-2 mb-0 border-0 shadow-none d-flex align-items-center gap-2" style="background: rgba(56, 189, 248, 0.08); border-radius: 8px;">
                <i class="bi bi-info-circle-fill text-info" style="font-size: 1.1rem;"></i>
                <small class="text-dark opacity-75">{{ __('Select the classes that will study this subject.') }}</small>
            </div>
          </div>

          <div class="form-check mt-3">
            <input class="form-check-input" type="checkbox" id="is_active" checked>
            <label class="form-check-label" for="is_active">{{ __('Active') }}</label>
          </div>

          <div id="subjectError" class="text-danger small mt-2" style="display:none;"></div>
        </div>

        <div class="modal-footer bg-light">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
          <button type="submit" class="btn btn-primary d-flex align-items-center gap-2">
            <i class="bi bi-check2-circle"></i> {{ __('Save Subject') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
@endsection

@push('scripts')
<script>
  Object.assign(window.I18N, {
    addSubject: "{{ __('Add Subject') }}",
    editSubject: "{{ __('Edit Subject') }}",
    deleteSubjectConfirm: "{{ __('Delete this subject from the system?') }}",
    loading: "{{ __('Loading subjects...') }}",
    noData: "{{ __('No subjects found for your school.') }}",
    active: "{{ __('Active') }}",
    inactive: "{{ __('Inactive') }}",
    content: "{{ __('Content') }}",
    loadingClasses: "{{ __('Loading classes...') }}"
  });

  window.SUBJECTS_ROUTES = @json($SUBJECTS_ROUTES);
  window.CLASSES_API = @json($CLASSES_API);
</script>
<script src="{{ asset('js/subjects.js') }}?v={{ filemtime(public_path('js/subjects.js')) }}"></script>
@endpush
