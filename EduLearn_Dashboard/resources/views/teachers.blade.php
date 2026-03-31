@extends('layouts.app')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-3" id="teachersHeader">
  <div class="d-flex gap-2">
    <button class="btn btn-outline-secondary" id="importTeachersBtn">
      <i class="bi bi-upload"></i> {{ __('Import Teachers') }}
    </button>
    <button class="btn btn-primary" id="openTeacherFormBtn">
      <i class="bi bi-plus"></i> {{ __('Add New Teacher') }}
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
                placeholder="{{ __('Search by name or ID') }}..."
              />
            </div>
          </div>
          <div class="col-md-3">
            <select class="form-select" id="teacherSubjectFilter">
              <option value="">{{ __('Filter by Subject') }}</option>
              <option>{{ __('Math') }}</option>
              <option>{{ __('History') }}</option>
              <option>{{ __('Biology') }}</option>
            </select>
          </div>
          <div class="col-md-3">
            <select class="form-select" id="teacherStatusFilter">
              <option value="">{{ __('Filter by Status') }}</option>
              <option value="Active">{{ __('Active') }}</option>
              <option value="Inactive">{{ __('Inactive') }}</option>
            </select>
          </div>
        </div>

        <!-- Scrollable table container with fixed height -->
        <div style="max-height: 500px; overflow-y: auto; border: 1px solid #dee2e6; border-radius: 8px;">
          <table class="table align-middle mb-0" id="teachersTable">
            <thead style="position: sticky; top: 0; background-color: var(--card); z-index: 10;">
              <tr>
                <th>{{ __('Full Name') }}</th>
                <th>{{ __('Teacher ID') }}</th>
                <th>{{ __('Subjects Taught') }}</th>
                <th>{{ __('Students') }}</th>
                <th>{{ __('Status') }}</th>
                <th class="text-end">{{ __('Actions') }}</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
        </div>

        <!-- Optional: Show record count -->
        <div class="mt-2 text-muted small" id="recordCount">
          {{ __('Loading teachers...') }}
        </div>
      </div>
    </div>

    <!-- البطاقة الجانبية للأستاذ -->
    <div class="col-lg-4">
      <div class="profile-shell" id="teacherProfile">
        <div class="profile-header mb-3">
          <div class="avatar-circle" id="teacherAvatar">TC</div>
          <div>
            <h6 class="profile-name mb-0" id="teacherName">{{ __('Select a teacher') }}</h6>
            <div class="profile-meta small text-muted" id="teacherId">{{ __('Teacher ID') }}: --</div>
          </div>
        </div>

        <div class="mb-2">
          <strong>{{ __('Date of Birth') }}:</strong>
          <div class="text-muted small" id="spTcBirthdate">--</div>
        </div>

        <div class="mb-2">
          <strong>{{ __('Email') }}:</strong>
          <div class="text-muted small" id="spTcEmail">--</div>
        </div>

        <div class="mb-2">
          <strong>{{ __('Address') }}:</strong>
          <div class="text-muted small" id="spTcAddress">--</div>
        </div>

        <hr class="my-2" />

        <div class="mb-2">
          <strong>{{ __('Phone') }}:</strong>
          <div class="text-muted small" id="spTcPhone">--</div>
        </div>
        <div class="mb-2">
          <strong>{{ __('Classes / Sections') }}:</strong>
          <div class="text-muted small" id="spTcClassSection">--</div>
        </div>
        <div class="mb-2">
          <strong>{{ __('Subjects') }}:</strong>
          <div class="text-muted small" id="spTcSubjects">--</div>
        </div>

        <hr class="my-2" />

        <div class="d-flex justify-content-between mb-1">
          <span class="small text-muted">{{ __('Average Performance') }}</span>
          <span id="spTcPerformance" class="fw-semibold">--</span>
        </div>
        <div class="d-flex justify-content-between">
          <span class="small text-muted">{{ __('Attendance Rate') }}</span>
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
      <h5 class="mb-1" id="teacherFormTitle">{{ __('Add New Teacher') }}</h5>
      <small class="text-muted">{{ __('Personal info and contact details') }}</small>
    </div>
    <button class="btn btn-outline-secondary btn-sm" id="backToTeachersBtn">
      <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'right' : 'left' }}"></i> {{ __('Back to Teachers') }}
    </button>
  </div>

  {{-- Personal Information --}}
  <h6 class="mb-2">{{ __('Personal Information') }}</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">{{ __('Full Name') }}</label>
      <input type="text" class="form-control" id="tcFullName" placeholder="{{ __('e.g. Yasser Abdullah Hassan') }}" required>
    </div>
    <div class="col-md-3">
      <label class="form-label">{{ __('Date of Birth') }}</label>
      <input type="date" class="form-control" id="tcBirthdate">
    </div>
    <div class="col-md-2">
      <label class="form-label">{{ __('Age') }}</label>
      <div class="input-group">
        <input type="text" class="form-control" id="tcAge" readonly>
        <button class="btn btn-outline-secondary" type="button" id="calcAgeBtn">{{ __('Calculate') }}</button>
      </div>
    </div>
  </div>

  {{-- Duty & Attendance --}}
  <h6 class="mb-2 mt-4">{{ __('Duty Details') }}</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <label class="form-label">{{ __('Teacher Shift') }}</label>
      <select class="form-select" id="tcShift">
        <option value="">{{ __('Choose...') }}</option>
        <option>{{ __('Morning') }}</option>
        <option>{{ __('Evening') }}</option>
      </select>
    </div>
    <div class="col-md-3">
      <label class="form-label">{{ __('Phone') }}</label>
      <input type="text" class="form-control" id="tcPhone" placeholder="77xxxxxxx">
    </div>
    <div class="col-md-4">
      <label class="form-label">{{ __('Email') }} ({{ __('Optional') }})</label>
      <input type="email" class="form-control" id="tcEmail" placeholder="example@school.com">
    </div>
  </div>

  {{-- Photo + Assigned classes (read only) --}}
  <h6 class="mb-2 mt-4">{{ __('Photo and Assigned Classes') }}</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">{{ __('Teacher Photo') }}</label>
      <input type="file" class="form-control" id="tcPhoto" accept="image/*">
    </div>
    <div class="col-md-8">
      <label class="form-label">{{ __('Classes / Sections') }}</label>
      <input type="text" class="form-control" id="tcAssignedClasses" placeholder="{{ __('Automatically filled from assignments') }}" readonly>
    </div>
  </div>

  {{-- Social & Address --}}
  <h6 class="mb-2 mt-4">{{ __('Address') }}</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <label class="form-label">{{ __('District') }}</label>
      <input type="text" class="form-control" id="tcDistrict" placeholder="{{ __('District') }}">
    </div>
    <div class="col-md-3">
      <label class="form-label">{{ __('Neighborhood') }}</label>
      <input type="text" class="form-control" id="tcNeighborhood" placeholder="{{ __('Neighborhood') }}">
    </div>
    <div class="col-md-3">
      <label class="form-label">{{ __('Street') }}</label>
      <input type="text" class="form-control" id="tcStreet" placeholder="{{ __('Street') }}">
    </div>
  </div>

  <div class="d-flex gap-2 mt-4">
    <button class="btn btn-primary" type="button" id="saveTeacherBtn">
      <i class="bi bi-check2"></i> {{ __('Save Teacher') }}
    </button>
    <button class="btn btn-light" type="button" id="cancelTeacherBtn">{{ __('Cancel') }}</button>
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
  window.I18N = window.I18N || {};
  Object.assign(window.I18N, {
    addNewTeacher: "{{ __('Add New Teacher') }}",
    editTeacher: "{{ __('Edit Teacher') }}",
    teacherCodePrefix: "{{ __('Teacher Code') }}: ",
    confirmDelete: "{{ __('Confirm') }}",
    deleteTeacherQuestion: "{{ __('Delete this teacher?') }}",
    teacherSaved: "{{ __('Teacher saved successfully.') }}",
    savingFailed: "{{ __('Saving failed') }}",
    guardian: "{{ __('Guardian') }}",
    academicIdPrefix: "{{ __('Teacher Code') }}: ",
    active: "{{ __('Active') }}",
    suspended: "{{ __('Suspended') }}",
    unexpectedError: "{{ __('Unexpected error') }}"
  });
</script>
<script src="{{ asset('js/teachers.js') }}"></script>
@endpush