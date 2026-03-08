@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <div>
        <h5 class="mb-1">التعيينات</h5>
        <small class="text-muted">ربط المعلمين بالفصول والمواد</small>
      </div>
      <button id="btnAddAssignment" class="btn btn-primary">
        <i class="bi bi-plus-lg me-1"></i> تعيين جديد
      </button>
    </div>

    <div class="card-panel mb-3">
      <div class="row g-2 align-items-end">
        <div class="col-md-3">
          <label class="form-label">المعلم</label>
          <select class="form-select" id="filterTeacher">
            <option value="">جميع المعلمين</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">الصف</label>
          <select class="form-select" id="filterGrade">
            <option value="">جميع الصفوف</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">المادة</label>
          <select class="form-select" id="filterSubject">
            <option value="">جميع المواد</option>
          </select>
        </div>
        <div class="col-md-3 text-end">
          <button class="btn btn-light" id="btnResetFilters">إعادة تعيين</button>
        </div>
      </div>
    </div>

    <div class="table-shell">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <div class="fw-semibold">قائمة التعيينات</div>
      </div>
      <div class="table-responsive">
        <table class="table align-middle mb-0" id="assignments-table">
          <thead>
            <tr>
              <th>#</th>
              <th>المعلم</th>
              <th>الفصل</th>
              <th>الصف</th>
              <th>القسم</th>
              <th>المادة</th>
              <th>الحصص الأسبوعية</th>
              <th>نشط</th>
              <th style="width: 120px;">إجراءات</th>
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
          <h5 class="modal-title" id="assignmentModalTitle">تعيين جديد</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label">المعلم</label>
            <select class="form-select" id="teacher_id" required></select>
          </div>

          <div class="mb-3">
            <label class="form-label">الفصل</label>
            <select class="form-select" id="class_section_id" required></select>
          </div>

          <div class="mb-3">
            <label class="form-label">المادة</label>
            <select class="form-select" id="subject_id" required></select>
          </div>

          <div class="mb-3">
            <label class="form-label">الحصص الأسبوعية (اختياري)</label>
            <input type="number" min="0" max="40" class="form-control" id="weekly_load">
          </div>

          <div class="form-check">
            <input class="form-check-input" type="checkbox" id="assign_is_active" checked>
            <label class="form-check-label" for="assign_is_active">نشط</label>
          </div>

          <div id="assignError" class="text-danger small mt-2" style="display:none;"></div>
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
  window.ASSIGN_ROUTES = @json($ASSIGN_ROUTES);
  window.TEACHERS_API  = @json($TEACHERS_API);
  window.CLASSES_API   = @json($CLASSES_API);
  window.SUBJECTS_API  = @json($SUBJECTS_API);
</script>
<script src="{{ asset('js/assignments.js') }}"></script>
@endpush
