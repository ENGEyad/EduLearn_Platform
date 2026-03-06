@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <div>
        <h5 class="mb-1">Class Subjects</h5>
        <small class="text-muted">
          Activate subjects for each grade & section
        </small>
      </div>
    </div>

    <div class="card-panel mb-3">
      <div class="row g-2 align-items-end">
        <div class="col-md-4">
          <label class="form-label">Class (Grade / Section)</label>
          <select class="form-select" id="class_section_id">
            <option value="">Select class</option>
          </select>
        </div>
        <div class="col-md-4">
          <div id="selectedClassInfo" class="text-muted small">
            {{-- سيتم تعبئتها بالـ JS --}}
          </div>
        </div>
        <div class="col-md-4 text-end">
          <button class="btn btn-primary" id="btnSaveClassSubjects" disabled>
            Save subjects
          </button>
        </div>
      </div>
    </div>

    <div class="table-shell">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <div class="fw-semibold">Subjects for selected class</div>
      </div>

      <div id="noClassSelected" class="alert alert-light border d-flex align-items-center mb-0">
        <i class="bi bi-info-circle me-2"></i>
        <span>Please select a class (grade & section) to manage its subjects.</span>
      </div>

      <div class="table-responsive" id="subjectsTableWrapper" style="display:none;">
        <table class="table align-middle mb-0" id="class-subjects-table">
          <thead>
            <tr>
              <th style="width: 50px;">#</th>
              <th style="width: 80px;">Code</th>
              <th>Name (EN)</th>
              <th>Name (AR)</th>
              <th style="width: 80px;">Active</th>
              <th style="width: 80px;">Assigned</th>
            </tr>
          </thead>
          <tbody>
            {{-- via JS --}}
          </tbody>
        </table>
      </div>

      <div id="classSubjectsError" class="text-danger small mt-2" style="display:none;"></div>
      <div id="classSubjectsSuccess" class="text-success small mt-2" style="display:none;"></div>
    </div>
  </div>
</div>
@endsection

@push('scripts')
<script>
  window.CLASS_SUBJECT_ROUTES = @json($CLASS_SUBJECT_ROUTES);
  window.CLASSES_API          = @json($CLASSES_API);
  window.SUBJECTS_API         = @json($SUBJECTS_API);
</script>
<script src="{{ asset('js/class_subjects.js') }}"></script>
@endpush
