@extends('layouts.app')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-3">
  <div class="d-flex gap-2">
    <button class="btn btn-outline-secondary" id="importExcelBtn">
      <i class="bi bi-upload"></i> Import from CSV / Excel
    </button>
    <input type="file" id="excelInput" class="d-none" accept=".csv,.xls,.xlsx" />
  </div>
  <div>
    <button class="btn btn-primary" id="openStudentFormBtn">
      <i class="bi bi-plus"></i> Add New Student
    </button>
  </div>
</div>

<!-- View 1: List -->
<div id="studentsListView">
  <div class="row g-3">
    <div class="col-lg-8">
      <div class="table-shell">
        <div class="row g-2 mb-2">
          <div class="col-md-6">
            <div class="input-group">
              <span class="input-group-text bg-white border-end-0">
                <i class="bi bi-search"></i>
              </span>
              <input
                type="text"
                class="form-control border-start-0"
                id="studentSearch"
                placeholder="Search by name or ID..."
              />
            </div>
          </div>
          <div class="col-md-6">
            <select class="form-select" id="gradeFilter">
              <option value="">All Grades</option>
              @for ($i = 1; $i <= 12; $i++)
                <option value="Grade {{ $i }}">Grade {{ $i }}</option>
              @endfor
            </select>
          </div>
        </div>

        <!-- Scrollable table container with fixed height -->
        <div style="max-height: 500px; overflow-y: auto; border: 1px solid #dee2e6; border-radius: 8px;">
          <table class="table table-hover align-middle mb-0" id="studentsTable">
            <thead style="position: sticky; top: 0; background-color: white; z-index: 10;">
              <tr>
                <th>Full Name</th>
                <th>Academic ID</th>
                <th>Grade &amp; Class</th>
                <th>Status</th>
                <th class="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
              <!-- filled by JS -->
            </tbody>
          </table>
        </div>
        
        <!-- Optional: Show record count -->
        <div class="mt-2 text-muted small" id="recordCount">
          Loading students...
        </div>
      </div>
    </div>

    <!-- Side card -->
    <div class="col-lg-4">
      <div class="profile-shell" id="studentProfile">
        <div class="profile-header mb-3">
          <div class="avatar-circle" id="studentAvatar">ST</div>
          <div>
            <h6 class="profile-name mb-0" id="studentName">Select a student</h6>
            <div class="profile-meta small text-muted" id="studentId">Academic ID: --</div>
          </div>
        </div>

        <div class="mb-2">
          <strong>Date of Birth:</strong>
          <div id="studentDob" class="text-muted small">--</div>
        </div>

        <div class="mb-2">
          <strong>Email:</strong>
          <div id="studentEmail" class="text-muted small">--</div>
        </div>

        <div class="mb-2">
          <strong>Address:</strong>
          <div id="studentAddress" class="text-muted small">--</div>
        </div>

        <hr class="my-2" />

        <div class="mb-2">
          <strong>Guardian:</strong>
          <div id="studentGuardian" class="text-muted small">--</div>
        </div>

        <div class="mb-2">
          <strong>Guardian Phone:</strong>
          <div id="studentGuardianPhone" class="text-muted small">--</div>
        </div>

        <div class="mb-2">
          <strong>Grade / Section:</strong>
          <div id="studentGradeSection" class="text-muted small">--</div>
        </div>

        <hr class="my-2" />

        <div class="d-flex justify-content-between mb-1">
          <span class="small text-muted">Performance Average</span>
          <span id="studentPerformance" class="fw-semibold">--</span>
        </div>
        <div class="d-flex justify-content-between">
          <span class="small text-muted">Attendance Rate</span>
          <span id="studentAttendance" class="fw-semibold">--</span>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- View 2: Form -->
<div id="studentFormView" class="card-panel" style="display:none;">
  <div class="d-flex justify-content-between align-items-center mb-3">
    <div>
      <h5 class="mb-1" id="formTitle">Add New Student</h5>
      <small class="text-muted">Fill the form to register a new student</small>
    </div>
    <button class="btn btn-outline-secondary btn-sm" id="backToStudentsBtn">
      <i class="bi bi-arrow-left"></i> Back to Students
    </button>
  </div>

  <input type="hidden" id="stDbId" />

  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">Full Name</label>
      <input type="text" class="form-control" id="stFullName" required>
    </div>
    <div class="col-md-2">
      <label class="form-label">Gender</label>
      <select class="form-select" id="stGender">
        <option value="">Select</option>
        <option>Male</option>
        <option>Female</option>
      </select>
    </div>
    <div class="col-md-3">
      <label class="form-label">Birth Date</label>
      <input type="date" class="form-control" id="stBirthdate">
    </div>
    <div class="col-md-3">
      <label class="form-label">Status</label>
      <select class="form-select" id="stStatus">
        <option>Active</option>
        <option>Suspended</option>
      </select>
    </div>
  </div>

  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <label class="form-label">Email</label>
      <input type="email" class="form-control" id="stEmail" placeholder="student@mail.com">
    </div>
    <div class="col-md-3">
      <label class="form-label">Grade</label>
      <select class="form-select" id="stGrade">
        <option value="">Select Grade</option>
        @foreach ($grades as $g)
          <option value="{{ $g }}">{{ $g }}</option>
        @endforeach
      </select>
    </div>
    <div class="col-md-3">
      <label class="form-label">Class / Section (Optional)</label>
      <input type="text" class="form-control" id="stClassSection" placeholder="e.g. A, B, C...">
    </div>
    <div class="col-md-3">
      <label class="form-label">Notes</label>
      <input type="text" class="form-control" id="stNotes" placeholder="Optional">
    </div>
  </div>

  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">Student Photo</label>
      <input type="file" class="form-control" id="stPhoto" accept="image/*">
    </div>
  </div>

  <h6 class="mb-2 mt-4">Address</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">Governorate</label>
      <input type="text" class="form-control" id="stGov">
    </div>
    <div class="col-md-4">
      <label class="form-label">City</label>
      <input type="text" class="form-control" id="stCity">
    </div>
    <div class="col-md-4">
      <label class="form-label">Street</label>
      <input type="text" class="form-control" id="stStreet">
    </div>
  </div>

  <h6 class="mb-2 mt-4">Guardian Information</h6>
  <div class="row g-3 mb-3">
    <div class="col-md-4">
      <label class="form-label">Guardian Name</label>
      <input type="text" class="form-control" id="guardianName" placeholder="e.g. Mohammed Ahmed">
    </div>
    <div class="col-md-3">
      <label class="form-label">Relationship</label>
      <select class="form-select" id="guardianRelation">
        <option value="">Select</option>
        <option>Father</option>
        <option>Mother</option>
        <option>Brother</option>
        <option value="other">Other...</option>
      </select>
    </div>
    <div class="col-md-3">
      <label class="form-label">Guardian Phone</label>
      <input type="text" class="form-control" id="guardianPhone" placeholder="77xxxxxxx">
    </div>
    <div class="col-md-2 d-none" id="guardianRelationOtherWrap">
      <label class="form-label">Custom Relation</label>
      <input type="text" class="form-control" id="guardianRelationOther" placeholder="Specify">
    </div>
  </div>

  <div class="d-flex gap-2 mt-4">
    <button class="btn btn-primary" type="button" id="saveStudentBtn">
      <i class="bi bi-check2"></i> Save Student
    </button>
    <button class="btn btn-light" type="button" id="cancelStudentBtn">Cancel</button>
  </div>

  <div class="alert alert-success mt-3 d-none" id="studentSavedAlert"></div>
</div>

<!-- Delete Modal -->
<div class="modal fade" id="deleteStudentModal" tabindex="-1" aria-labelledby="deleteStudentLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="deleteStudentLabel">Confirm Delete</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        Are you sure you want to delete this student?
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button type="button" class="btn btn-danger" id="confirmDeleteStudentBtn">Delete</button>
      </div>
    </div>
  </div>
</div>

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
  window.STUDENTS_ROUTES = {
    list: "{{ route('students.list') }}",
    store: "{{ route('students.store') }}",
    update: function(id) {
      return "{{ url('/students') }}/" + id;
    },
    destroy: function(id) {
      return "{{ url('/students') }}/" + id;
    },
    import: "{{ route('students.import') }}"
  };

  window.STORAGE_BASE_URL = "{{ asset('storage') }}";
</script>
<script src="{{ asset('js/students.js') }}"></script>
@endpush