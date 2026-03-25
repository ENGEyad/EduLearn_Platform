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

        <table class="table table-hover align-middle mb-0" id="studentsTable">
          <thead>
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
  <!-- نفس الكود بدون أي تعديل -->
</div>

<!-- Delete Modal -->
<div class="modal fade" id="deleteStudentModal" tabindex="-1" aria-labelledby="deleteStudentLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Confirm Delete</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        Are you sure you want to delete this student?
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button class="btn btn-danger" id="confirmDeleteStudentBtn">Delete</button>
      </div>
    </div>
  </div>
</div>
@endsection

@push('scripts')

<style>
#studentsTable {
    width: 100%;
    border-collapse: collapse;
}

#studentsTable thead {
    position: sticky;
    top: 0;
    background: #fff;
    z-index: 2;
}

#studentsTable tbody {
    display: block;
    max-height: 420px;
    overflow-y: auto;
}

#studentsTable thead,
#studentsTable tbody tr {
    display: table;
    width: 100%;
    table-layout: fixed;
}
</style>

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