@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <div>
        <h5 class="mb-1">المواد الدراسية</h5>
        <small class="text-muted">إضافة وتعديل وإدارة المواد المدرسية</small>
      </div>
      <button id="btnAddSubject" class="btn btn-primary">
        <i class="bi bi-plus-lg me-1"></i> إضافة مادة
      </button>
    </div>

    <div class="table-shell">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <div class="fw-semibold">قائمة المواد</div>
      </div>

      <div class="table-responsive">
        <table class="table align-middle mb-0" id="subjects-table">
          <thead>
            <tr>
              <th>#</th>
              <th>الرمز</th>
              <th>الاسم (إنجليزي)</th>
              <th>الاسم (عربي)</th>
              <th>نشط</th>
              <th style="width: 140px;">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {{-- سيتم تعبئته عبر JS --}}
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
          <h5 class="modal-title" id="subjectModalTitle">إضافة مادة</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label">الرمز</label>
            <input type="text" class="form-control" id="code" required>
            <small class="text-muted">مثال: quran, islamic, math</small>
          </div>

          <div class="mb-3">
            <label class="form-label">الاسم (إنجليزي)</label>
            <input type="text" class="form-control" id="name_en" required>
          </div>

          <div class="mb-3">
            <label class="form-label">الاسم (عربي)</label>
            <input type="text" class="form-control" id="name_ar">
          </div>

          <div class="form-check">
            <input class="form-check-input" type="checkbox" id="is_active" checked>
            <label class="form-check-label" for="is_active">نشط</label>
          </div>

          <div id="subjectError" class="text-danger small mt-2" style="display:none;"></div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-light" data-bs-dismiss="modal">إلغاء</button>
          <button type="submit" class="btn btn-primary">حفظ</button>
        </div>
      </form>
    </div>
  </div>
</div>
@endsection

@push('scripts')
<script>
  window.SUBJECTS_ROUTES = @json($SUBJECTS_ROUTES);
</script>
<script src="{{ asset('js/subjects.js') }}"></script>
@endpush
