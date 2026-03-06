{{-- resources/views/dashboard.blade.php --}}
@extends('layouts.app')

@section('content')
<div class="row g-3 mb-3">
  <div class="col-md-2 col-sm-6">
    <div class="stat-card">
      <div class="text-muted">Total Teachers</div>
      <h3 class="mt-1 mb-1" id="dashTeachers">{{ $stats['teachers'] ?? 0 }}</h3>
      <div class="text-success fw-semibold">+2 this month</div>
    </div>
  </div>
  <div class="col-md-2 col-sm-6">
    <div class="stat-card">
      <div class="text-muted">Total Students</div>
      <h3 class="mt-1 mb-1" id="dashStudents">{{ $stats['students'] ?? 0 }}</h3>
      <div class="text-success fw-semibold">+15 this month</div>
    </div>
  </div>
  <div class="col-md-2 col-sm-6">
    <div class="stat-card">
      <div class="text-muted">Total Classes</div>
      <h3 class="mt-1 mb-1" id="dashClasses">{{ $stats['classes'] ?? 0 }}</h3>
      <div class="text-success fw-semibold">+1 this month</div>
    </div>
  </div>
  <div class="col-md-2 col-sm-6">
    <div class="stat-card">
      <div class="text-muted">Total Subjects</div>
      <h3 class="mt-1 mb-1" id="dashSubjects">{{ $stats['subjects'] ?? 0 }}</h3>
      <div class="text-muted">+0 this month</div>
    </div>
  </div>
  <div class="col-md-4 col-sm-12">
    <div class="stat-card d-flex justify-content-between align-items-center">
      <div>
        <div class="text-muted">Daily Attendance</div>
        <h3 class="mt-1 mb-1" id="dashAttendance">{{ $stats['attendance'] ?? 0 }}%</h3>
        <div class="text-danger fw-semibold">-1.5% from yesterday</div>
      </div>
      <i class="bi bi-activity fs-1 text-primary"></i>
    </div>
  </div>
</div>

<div class="row g-3 mb-3">
  <div class="col-lg-4">
    <div class="card-panel h-100">
      <div class="section-title mb-1">Overall Student Performance</div>
      <div class="d-flex align-items-center gap-1 mb-1">
        <h2 class="mb-0">B+ Average</h2>
        <span class="text-success fw-semibold" style="font-size:.8rem;">+2.1%</span>
      </div>
      <p class="text-muted mb-2">Grade distribution</p>
      <canvas id="gradeChart" height="180"></canvas>
    </div>
  </div>
  <div class="col-lg-8">
    <div class="card-panel h-100">
      <div class="d-flex justify-content-between align-items-center mb-1">
        <div>
          <div class="section-title mb-0">Weekly Attendance Trend</div>
          <small class="text-danger">-0.5%</small>
        </div>
        <div class="text-muted small">93% Avg.</div>
      </div>
      <canvas id="attendanceChart" height="100"></canvas>
    </div>
  </div>
</div>

<div class="row g-3">
  <div class="col-lg-6">
    <div class="card-panel">
      <div class="section-title">Recent Activities</div>
      <p class="text-muted mb-1">• 3 new students enrolled</p>
      <p class="text-muted mb-1">• 1 class created (Grade 8 – A)</p>
      <p class="text-muted mb-0">• Attendance report generated</p>
    </div>
  </div>
  <div class="col-lg-6">
    <div class="card-panel">
      <div class="section-title">Alerts</div>
      <p class="text-muted mb-1">• 2 classes have attendance below 85%</p>
      <p class="text-muted mb-1">• Teacher Jane Smith marked absent</p>
      <p class="text-muted mb-0">• Backup is due in 2 days</p>
    </div>
  </div>
</div>
@endsection

@push('scripts')
<script>
  (function () {
    if (typeof window.Chart === 'undefined') {
      console.error('⚠️ Chart.js library not loaded. تأكد من إضافته في الـ layout');
      return;
    }

    // المخطط الأول
    const gradeCanvas = document.getElementById('gradeChart');
    if (gradeCanvas) {
      const oldGradeChart = Chart.getChart(gradeCanvas);
      if (oldGradeChart) oldGradeChart.destroy();

      const gradeCtx = gradeCanvas.getContext('2d');
      new Chart(gradeCtx, {
        type: 'bar',
        data: {
          labels: ['A', 'B', 'C', 'D', 'F'],
          datasets: [{
            data: [12, 35, 25, 9, 2],
            backgroundColor: 'rgba(19,91,236,.22)',
            borderColor: 'rgba(19,91,236,1)',
            borderWidth: 1.4,
            borderRadius: 8,
            maxBarThickness: 36
          }]
        },
        options: {
          plugins: { legend: { display: false } },
          scales: {
            x: { grid: { display: false } },
            y: {
              beginAtZero: true,
              grid: { color: 'rgba(148,163,184,.15)' },
              ticks: { stepSize: 10 }
            }
          }
        }
      });
    }

    // المخطط الثاني
    const attendanceCanvas = document.getElementById('attendanceChart');
    if (attendanceCanvas) {
      const oldAttendanceChart = Chart.getChart(attendanceCanvas);
      if (oldAttendanceChart) oldAttendanceChart.destroy();

      const attendanceCtx = attendanceCanvas.getContext('2d');
      new Chart(attendanceCtx, {
        type: 'line',
        data: {
          labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          datasets: [{
            data: [92, 93, 91, 90, 95, 97, 94],
            borderColor: 'rgba(19,91,236,1)',
            backgroundColor: 'rgba(19,91,236,.12)',
            tension: .5,
            fill: true,
            pointBackgroundColor: '#fff',
            pointBorderColor: 'rgba(19,91,236,1)',
            pointRadius: 4
          }]
        },
        options: {
          plugins: { legend: { display: false } },
          scales: {
            x: { grid: { display: false } },
            y: {
              beginAtZero: false,
              min: 80,
              max: 100,
              grid: { color: 'rgba(148,163,184,.12)' },
              ticks: {
                callback: val => val + '%'
              }
            }
          }
        }
      });
    }
  })();
</script>
@endpush
