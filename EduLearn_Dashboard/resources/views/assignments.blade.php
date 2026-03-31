@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <div>
        <h5 class="mb-1">{{ __('Assignments') }}</h5>
        <small class="text-muted">{{ __('Link teachers with classes and subjects') }}</small>
      </div>
      <button id="btnAddAssignment" class="btn btn-primary">
        <i class="bi bi-plus-lg me-1"></i> {{ __('New Assignment') }}
      </button>
    </div>

    <div class="card-panel mb-3">
      <div class="row g-2 align-items-end">
        <div class="col-md-3">
          <label class="form-label">{{ __('Teacher') }}</label>
          <select class="form-select" id="filterTeacher">
            <option value="">{{ __('All Teachers') }}</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">{{ __('Grade') }}</label>
          <select class="form-select" id="filterGrade">
            <option value="">{{ __('All Grades') }}</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">{{ __('Subject') }}</label>
          <select class="form-select" id="filterSubject">
            <option value="">{{ __('All Subjects') }}</option>
          </select>
        </div>
        <div class="col-md-3 text-end">
          <button class="btn btn-light" id="btnResetFilters">{{ __('Reset Filters') }}</button>
        </div>
      </div>
    </div>

    <div class="table-shell">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <div class="fw-semibold">{{ __('Assignment List') }}</div>
      </div>
      <div class="table-responsive">
        <table class="table align-middle mb-0" id="assignments-table">
          <thead>
            <tr>
              <th>#</th>
              <th>{{ __('Teacher') }}</th>
              <th>{{ __('Class') }}</th>
              <th>{{ __('Grade') }}</th>
              <th>{{ __('Section') }}</th>
              <th>{{ __('Subject') }}</th>
              <th>{{ __('Weekly Load') }}</th>
              <th>{{ __('Active') }}</th>
              <th style="width: 120px;">{{ __('Actions') }}</th>
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
    allSubjects: "{{ __('All Subjects') }}",
    selectSubject: "{{ __('Select Subject') }}",
    selectClass: "{{ __('Select Class') }}",
    deleteAssignmentConfirm: "{{ __('Delete this assignment?') }}"
  });

  window.ASSIGN_ROUTES = @json($ASSIGN_ROUTES);
  window.TEACHERS_API  = @json($TEACHERS_API);
  window.CLASSES_API   = @json($CLASSES_API);
  window.SUBJECTS_API  = @json($SUBJECTS_API);
</script>
<script src="{{ asset('js/assignments.js') }}"></script>
@endpush
