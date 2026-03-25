@extends('layouts.app')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-3" id="teachersHeader">
  <div class="d-flex gap-2">
    <button class="btn btn-outline-secondary" id="importTeachersBtn">
      <i class="bi bi-upload"></i> استيراد دفعي
    </button>
    <button class="btn btn-primary" id="openTeacherFormBtn">
      <i class="bi bi-plus"></i> إضافة معلم جديد
    </button>
  </div>
</div>

<!-- list view -->
<div id="teachersListView">
  <div class="row g-3">
    <!-- جدول الأساتذة -->
    <div class="col-lg-8">
      <div class="table-shell mb-3">
        <div class="row g-2 align-items-center mb-2">
          <div class="col-md-4">
            <div class="input-group">
              <span class="input-group-text bg-white border-end-0">
                <i class="bi bi-search"></i>
              </span>
              <input
                type="text"
                id="teacherSearch"
                class="form-control border-start-0"
                placeholder="ابحث بالاسم أو الرمز..."
              />
            </div>
          </div>
          <div class="col-md-3">
            <select class="form-select" id="teacherSubjectFilter">
              <option value="">تصفية حسب المادة</option>
              <option>رياضيات</option>
              <option>تاريخ</option>
              <option>أحياء</option>
            </select>
          </div>
          <div class="col-md-3">
            <select class="form-select" id="teacherStatusFilter">
              <option value="">تصفية حسب الحالة</option>
              <option value="Active">نشط</option>
              <option value="Inactive">غير نشط</option>
            </select>
          </div>
        </div>

        <!-- Scrollable table container with fixed height -->
        <div style="max-height: 500px; overflow-y: auto; border: 1px solid #dee2e6; border-radius: 8px;">
          <table class="table align-middle mb-0" id="teachersTable">
            <thead style="position: sticky; top: 0; background-color: white; z-index: 10;">
              <tr>
                <th>الاسم الكامل</th>
                <th>رمز المعلم</th>
                <th>المواد المدرسة</th>
                <th>الطلاب</th>
                <th>الحالة</th>
                <th class="text-end">إجراءات</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
        </div>

        <!-- Optional: Show record count -->
        <div class="mt-2 text-muted small" id="recordCount">
          جاري تحميل المعلمين...
        </div>
      </div>
    </div>

    <!-- البطاقة الجانبية للأستاذ -->
    <div class="col-lg-4">
      <div class="profile-shell" id="teacherProfile">
        <div class="profile-header mb-3">
          <div class="avatar-circle" id="teacherAvatar">TC</div>
          <div>
            <h6 class="profile-name mb-0" id="teacherName">تحديد معلم</h6>
            <div class="profile-meta small text-muted" id="teacherId">رمز المعلم: --</div>
          </div>
        </div>

        <div class="mb-2">
          <strong>تاريخ الميلاد:</strong>
          <div class="text-muted small" id="spTcBirthdate">--</div>
        </div>

        <div class="mb-2">
          <strong>البريد الإلكتروني:</strong>
          <div class="text-muted small" id="spTcEmail">--</div>
        </div>

        <div class="mb-2">
          <strong>العنوان:</strong>
          <div class="text-muted small" id="spTcAddress">--</div>
        </div>

        <hr class="my-2" />

        <div class="mb-2">
          <strong>الهاتف:</strong>
          <div class="text-muted small" id="spTcPhone">--</div>
        </div>
        <div class="mb-2">
          <strong>الفصول / الأقسام:</strong>
          <div class="text-muted small" id="spTcClassSection">--</div>
        </div>
        <div class="mb-2">
          <strong>المواد:</strong>
          <div class="text-muted small" id="spTcSubjects">--</div>
        </div>

        <hr class="my-2" />

        <div class="d-flex justify-content-between mb-1">
          <span class="small text-muted">متوسط الأداء</span>
          <span id="spTcPerformance" class="fw-semibold">--</span>
        </div>
        <div class="d-flex justify-content-between">
          <span class="small text-muted">نسبة الحضور</span>
          <span id="spTcAttendance" class="fw-semibold">--</span>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- form view -->
<div id="teacherFormView" class="card-panel" style="display:none;">
  <input type="hidden" id="tcDbId" value="">

  <div class="d-flex justify-content-between align-items-center mb-3">
    <div>
      <h5 class="mb-1" id="teacherFormTitle">إضافة معلم جديد</h5>
      <small class="text-muted">أدخل بيانات المعلم الشخصية والتواصل</small>
    </div>
    <button class="btn btn-outline-secondary btn-sm" id="backToTeachersBtn">
      <i class="bi bi-arrow-right"></i> الرجوع للمعلمين
    </button>
  </div>

  {{-- Personal Information --}}
  <h6 class="mb-2">المعلومات الشخصية</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">الاسم الكامل</label>
      <input type="text" class="form-control" id="tcFullName" placeholder="مثال: ياسر عبدالله حسن" required>
    </div>
    <div class="col-md-3">
      <label class="form-label">تاريخ الميلاد</label>
      <input type="date" class="form-control" id="tcBirthdate">
    </div>
    <div class="col-md-2">
      <label class="form-label">العمر</label>
      <div class="input-group">
        <input type="text" class="form-control" id="tcAge" readonly>
        <button class="btn btn-outline-secondary" type="button" id="calcAgeBtn">حساب</button>
      </div>
    </div>
  </div>

  {{-- Duty & Attendance --}}
  <h6 class="mb-2 mt-4">بيانات الدوام</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <label class="form-label">الفترة</label>
      <select class="form-select" id="tcShift">
        <option value="">اختير</option>
        <option>صباحية</option>
        <option>مسائية</option>
      </select>
    </div>
    <div class="col-md-3">
      <label class="form-label">هاتف المعلم</label>
      <input type="text" class="form-control" id="tcPhone" placeholder="77xxxxxxx">
    </div>
    <div class="col-md-4">
      <label class="form-label">البريد الإلكتروني (اختياري)</label>
      <input type="email" class="form-control" id="tcEmail" placeholder="example@school.com">
    </div>
  </div>

  {{-- Photo + Assigned classes (read only) --}}
  <h6 class="mb-2 mt-4">الصورة والفصول المعينة</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">صورة المعلم</label>
      <input type="file" class="form-control" id="tcPhoto" accept="image/*">
    </div>
    <div class="col-md-8">
      <label class="form-label">الفصول / الأقسام (من التعيينات)</label>
      <input type="text" class="form-control" id="tcAssignedClasses" placeholder="تملأ تلقائياً من التعيينات" readonly>
    </div>
  </div>

  {{-- Social & Address --}}
  <h6 class="mb-2 mt-4">العنوان</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <label class="form-label">المحافظة</label>
      <input type="text" class="form-control" id="tcDistrict" placeholder="المحافظة">
    </div>
    <div class="col-md-3">
      <label class="form-label">الحي</label>
      <input type="text" class="form-control" id="tcNeighborhood" placeholder="الحي">
    </div>
    <div class="col-md-3">
      <label class="form-label">الشارع</label>
      <input type="text" class="form-control" id="tcStreet" placeholder="الشارع">
    </div>
  </div>

  <div class="d-flex gap-2 mt-4">
    <button class="btn btn-primary" type="button" id="saveTeacherBtn">
      <i class="bi bi-check2"></i> حفظ المعلم
    </button>
    <button class="btn btn-light" type="button" id="cancelTeacherBtn">إلغاء</button>
  </div>

  <div class="alert alert-success mt-3 d-none" id="teacherSavedAlert"></div>
</div>

<input type="file" id="importTeachersInput" class="d-none" />

<style>
  /* Ensure the page layout remains stable */
  .table-shell {
    height: 100%;
  }
  
  /* Custom scrollbar styling for better visibility (optional) */
  div[style*="overflow-y: auto"]::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }
  
  div[style*="overflow-y: auto"]::-webkit-scrollbar-track {
    background: #f1f1f1;
    border-radius: 4px;
  }
  
  div[style*="overflow-y: auto"]::-webkit-scrollbar-thumb {
    background: #c1c1c1;
    border-radius: 4px;
  }
  
  div[style*="overflow-y: auto"]::-webkit-scrollbar-thumb:hover {
    background: #a8a8a8;
  }
  
  /* Keep table header sticky and visible */
  .table thead th {
    background-color: white;
    border-bottom: 2px solid #dee2e6;
  }
</style>

@endsection

@push('scripts')
<script>
  window.TEACHERS_ROUTES = {
    list: @json($TEACHERS_ROUTES['list']),
    store: @json($TEACHERS_ROUTES['store']),
    update: @json($TEACHERS_ROUTES['update']),
    destroy: @json($TEACHERS_ROUTES['destroy']),
    import: @json($TEACHERS_ROUTES['import']),
  };

  window.STORAGE_BASE_URL = "{{ asset('storage') }}";
</script>
<script src="{{ asset('js/teachers.js') }}"></script>
@endpush