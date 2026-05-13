@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
      <div>
        <h5 class="fw-bold text-title mb-1">{{ __('Classes') }}</h5>
        <small class="text-muted">{{ __('Manage classes and sections') }}</small>
      </div>
      <div class="d-flex flex-wrap gap-2">
        <button id="btnImportClass" class="btn btn-outline-primary shadow-sm px-4 rounded-pill d-flex align-items-center gap-2 flex-grow-1 flex-md-grow-0 justify-content-center">
          <i class="bi bi-cloud-upload"></i> {{ __('Import') }}
        </button>
        <button id="btnAddClass" class="btn btn-primary shadow-sm px-4 rounded-pill d-flex align-items-center gap-2 flex-grow-1 flex-md-grow-0 justify-content-center">
          <i class="bi bi-plus-lg"></i> {{ __('Add Class') }}
        </button>
      </div>
      <input type="file" id="classCsvInput" class="d-none" accept=".csv">
    </div>

    <div class="table-shell">
      <div class="table-responsive">
        <table class="table align-middle mb-0" id="classes-table">
          <thead>
            <tr class="text-muted small text-uppercase fw-bold" style="letter-spacing: 0.05em;">
              <th>#</th>
              <th>{{ __('Grade') }}</th>
              <th>{{ __('Section') }}</th>
              <th class="d-none d-lg-table-cell">{{ __('Name (English)') }}</th>
              <th class="d-none d-md-table-cell">{{ __('Name (Arabic)') }}</th>
              <th class="d-none d-lg-table-cell">{{ __('Academic Stage') }}</th>
              <th>{{ __('Active') }}</th>
              <th style="width: 140px;" class="text-end pe-4">{{ __('Actions') }}</th>
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
<div class="modal fade" id="classModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form id="classForm">
        @csrf
        <input type="hidden" id="class_id">

        <div class="modal-header">
          <h5 class="modal-title" id="classModalTitle">{{ __('Add Class') }}</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label">{{ __('Grade') }}</label>
            <input type="text" class="form-control" id="grade" required>
            <small class="text-muted">{{ __('e.g. 1, 2, 3, 9') }}</small>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Section') }}</label>
            <input type="text" class="form-control" id="section" required>
            <small class="text-muted">{{ __('e.g. A, B, 1, 2') }}</small>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Name (English)') }}</label>
            <input type="text" class="form-control" id="name_en" required>
            <small class="text-muted">{{ __('e.g. Class 2 - A') }}</small>
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Name (Arabic)') }}</label>
            <input type="text" class="form-control" id="name_ar" required>
            <small class="text-muted">{{ __('مثال: الصف الثاني - أ') }}</small>
          </div>

          <div class="mb-3 d-none">
            <label class="form-label">{{ __('Name (Combined/Internal)') }}</label>
            <input type="text" class="form-control" id="name">
          </div>

          <div class="mb-3">
            <label class="form-label">{{ __('Academic Stage') }} ({{ __('Optional') }})</label>
            <input type="text" class="form-control" id="stage">
            <small class="text-muted">{{ __('e.g. Primary, Preparatory, Secondary') }}</small>
          </div>

          <div class="form-check">
            <input class="form-check-input" type="checkbox" id="class_is_active" checked>
            <label class="form-check-label" for="class_is_active">
              {{ __('Active') }}
            </label>
          </div>

          <div id="classError" class="text-danger small mt-2" style="display:none;"></div>
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
  window.CLASSES_ROUTES = @json($CLASSES_ROUTES);
</script>
<script src="{{ asset('js/classes.js') }}"></script>
@endpush
