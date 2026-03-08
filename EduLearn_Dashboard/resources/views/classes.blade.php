@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <div>
        <h5 class="mb-1">الفصول الدراسية</h5>
        <small class="text-muted">إدارة الصفوف والأقسام</small>
      </div>
      <button id="btnAddClass" class="btn btn-primary">
        <i class="bi bi-plus-lg me-1"></i> إضافة فصل
      </button>
    </div>

    <div class="table-shell">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <div class="fw-semibold">قائمة الفصول</div>
      </div>

      <div class="table-responsive">
        <table class="table align-middle mb-0" id="classes-table">
          <thead>
            <tr>
              <th>#</th>
              <th>الصف</th>
              <th>القسم</th>
              <th>الاسم</th>
              <th>المرحلة</th>
              <th>نشط</th>
              <th style="width: 140px;">إجراءات</th>
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
          <h5 class="modal-title" id="classModalTitle">إضافة فصل</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="mb-3">
            <label class="form-label">الصف</label>
            <input type="text" class="form-control" id="grade" required>
            <small class="text-muted">مثال: 1, 2, 3, 9</small>
          </div>

          <div class="mb-3">
            <label class="form-label">القسم</label>
            <input type="text" class="form-control" id="section" required>
            <small class="text-muted">مثال: A, B, 1, 2</small>
          </div>

          <div class="mb-3">
            <label class="form-label">الاسم</label>
            <input type="text" class="form-control" id="name" required>
            <small class="text-muted">مثال: الصف 2 - أ</small>
          </div>

          <div class="mb-3">
            <label class="form-label">المرحلة (اختياري)</label>
            <input type="text" class="form-control" id="stage">
            <small class="text-muted">مثال: ابتدائي, متوسط, ثانوي</small>
          </div>

          <div class="form-check">
            <input class="form-check-input" type="checkbox" id="class_is_active" checked>
            <label class="form-check-label" for="class_is_active">
              نشط
            </label>
          </div>

          <div id="classError" class="text-danger small mt-2" style="display:none;"></div>
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
  window.CLASSES_ROUTES = @json($CLASSES_ROUTES);
</script>
<script src="{{ asset('js/classes.js') }}"></script>
@endpush
