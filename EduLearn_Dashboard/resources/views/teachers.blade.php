@extends('layouts.app')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-3" id="teachersHeader">
  <div class="d-flex gap-2">
    <button class="btn btn-outline-secondary" id="importTeachersBtn">
      <i class="bi bi-upload"></i> Bulk Import
    </button>
    <button class="btn btn-primary" id="openTeacherFormBtn">
      <i class="bi bi-plus"></i> Add New Teacher
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
                placeholder="Search by name or ID..."
              />
            </div>
          </div>
          <div class="col-md-3">
            <select class="form-select" id="teacherSubjectFilter">
              <option value="">Filter by Subject</option>
              <option>Mathematics</option>
              <option>History</option>
              <option>Biology</option>
            </select>
          </div>
          <div class="col-md-3">
            <select class="form-select" id="teacherStatusFilter">
              <option value="">Filter by Status</option>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>
          </div>
        </div>

        <table class="table align-middle" id="teachersTable">
          <thead>
            <tr>
              <th>Full Name</th>
              <th>Teacher ID</th>
              <th>Subjects Taught</th>
              <th>Students</th>
              <th>Status</th>
              <th class="text-end">Actions</th>
            </tr>
          </thead>
          <tbody></tbody>
        </table>
      </div>
    </div>

    <!-- البطاقة الجانبية للأستاذ -->
    <div class="col-lg-4">
      <div class="profile-shell" id="teacherProfile">
        <div class="profile-header mb-3">
          <div class="avatar-circle" id="teacherAvatar">TC</div>
          <div>
            <h6 class="profile-name mb-0" id="teacherName">Select a teacher</h6>
            <div class="profile-meta small text-muted" id="teacherId">Teacher Code: --</div>
          </div>
        </div>

        <div class="mb-2">
          <strong>Date of Birth:</strong>
          <div class="text-muted small" id="spTcBirthdate">--</div>
        </div>

        <div class="mb-2">
          <strong>Email:</strong>
          <div class="text-muted small" id="spTcEmail">--</div>
        </div>

        <div class="mb-2">
          <strong>Address:</strong>
          <div class="text-muted small" id="spTcAddress">--</div>
        </div>

        <hr class="my-2" />

        <div class="mb-2">
          <strong>Phone:</strong>
          <div class="text-muted small" id="spTcPhone">--</div>
        </div>
        <div class="mb-2">
          <strong>Classes / Sections:</strong>
          <div class="text-muted small" id="spTcClassSection">--</div>
        </div>
        <div class="mb-2">
          <strong>Subjects:</strong>
          <div class="text-muted small" id="spTcSubjects">--</div>
        </div>

        <hr class="my-2" />

        <div class="d-flex justify-content-between mb-1">
          <span class="small text-muted">Performance Average</span>
          <span id="spTcPerformance" class="fw-semibold">--</span>
        </div>
        <div class="d-flex justify-content-between">
          <span class="small text-muted">Attendance Rate</span>
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
      <h5 class="mb-1" id="teacherFormTitle">Add New Teacher</h5>
      <small class="text-muted">Enter teacher personal and contact details</small>
    </div>
    <button class="btn btn-outline-secondary btn-sm" id="backToTeachersBtn">
      <i class="bi bi-arrow-left"></i> Back to Teachers
    </button>
  </div>

  {{-- Personal Information --}}
  <h6 class="mb-2">Personal Information</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">Full Name</label>
      <input type="text" class="form-control" id="tcFullName" placeholder="e.g. Yasser Abdullah Hassan" required>
    </div>
    <div class="col-md-3">
      <label class="form-label">Date of Birth</label>
      <input type="date" class="form-control" id="tcBirthdate">
    </div>
    <div class="col-md-2">
      <label class="form-label">Age</label>
      <div class="input-group">
        <input type="text" class="form-control" id="tcAge" readonly>
        <button class="btn btn-outline-secondary" type="button" id="calcAgeBtn">Calc</button>
      </div>
    </div>
  </div>

  {{-- Duty & Attendance --}}
  <h6 class="mb-2 mt-4">Duty & Attendance</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <label class="form-label">Shift</label>
      <select class="form-select" id="tcShift">
        <option value="">Select</option>
        <option>Morning</option>
        <option>Evening</option>
      </select>
    </div>
    <div class="col-md-3">
      <label class="form-label">Teacher Phone</label>
      <input type="text" class="form-control" id="tcPhone" placeholder="77xxxxxxx">
    </div>
    <div class="col-md-4">
      <label class="form-label">Email (optional)</label>
      <input type="email" class="form-control" id="tcEmail" placeholder="example@school.com">
    </div>
  </div>

  {{-- Photo + Assigned classes (read only) --}}
  <h6 class="mb-2 mt-4">Photo & Assigned Classes</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">Teacher Photo</label>
      <input type="file" class="form-control" id="tcPhoto" accept="image/*">
    </div>
    <div class="col-md-8">
      <label class="form-label">Classes / Sections (from Assignments)</label>
      <input
        type="text"
        class="form-control"
        id="tcAssignedClasses"
        placeholder="Filled automatically from Assignments"
        readonly
      >
    </div>
  </div>

  {{-- Social & Address --}}
  <h6 class="mb-2 mt-4">Social & Address</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <label class="form-label">District</label>
      <input type="text" class="form-control" id="tcDistrict" placeholder="District">
    </div>
    <div class="col-md-3">
      <label class="form-label">Neighborhood</label>
      <input type="text" class="form-control" id="tcNeighborhood" placeholder="Neighborhood">
    </div>
    <div class="col-md-3">
      <label class="form-label">Block / Street</label>
      <input type="text" class="form-control" id="tcStreet" placeholder="Street">
    </div>
  </div>

  <div class="d-flex gap-2 mt-4">
    <button class="btn btn-primary" type="button" id="saveTeacherBtn">
      <i class="bi bi-check2"></i> Save Teacher
    </button>
    <button class="btn btn-light" type="button" id="cancelTeacherBtn">Cancel</button>
  </div>

  <div class="alert alert-success mt-3 d-none" id="teacherSavedAlert"></div>
</div>

<input type="file" id="importTeachersInput" class="d-none" />

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
