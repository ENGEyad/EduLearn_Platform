{{-- resources/views/dashboard.blade.php --}}
@extends('layouts.app')

@section('content')
<!-- Stat Cards Section -->
<div class="row g-3 mb-4">
  <div class="col-md-3 col-sm-6">
    <div class="stat-card">
      <div class="d-flex align-items-center mb-2">
        <div class="icon-box bg-primary-subtle me-2">
          <i class="bi bi-people text-primary"></i>
        </div>
        <div class="text-muted small">إجمالي الطلاب</div>
      </div>
      <h3 class="mt-1 mb-0" id="dashStudents">{{ $stats['students'] ?? 0 }}</h3>
      <div class="text-success small fw-semibold">+{{ rand(5, 15) }} هذا الشهر</div>
    </div>
  </div>
  <div class="col-md-3 col-sm-6">
    <div class="stat-card">
      <div class="d-flex align-items-center mb-2">
        <div class="icon-box bg-success-subtle me-2">
          <i class="bi bi-person-badge text-success"></i>
        </div>
        <div class="text-muted small">إجمالي المعلمين</div>
      </div>
      <h3 class="mt-1 mb-0" id="dashTeachers">{{ $stats['teachers'] ?? 0 }}</h3>
      <div class="text-success small fw-semibold">+{{ rand(1, 4) }} هذا الشهر</div>
    </div>
  </div>
  <div class="col-md-3 col-sm-6">
    <div class="stat-card">
      <div class="d-flex align-items-center mb-2">
        <div class="icon-box bg-info-subtle me-2">
          <i class="bi bi-door-open text-info"></i>
        </div>
        <div class="text-muted small">إجمالي الفصول</div>
      </div>
      <h3 class="mt-1 mb-0" id="dashClasses">{{ $stats['classes'] ?? 0 }}</h3>
      <div class="text-muted small">نشط حالياً</div>
    </div>
  </div>
  <div class="col-md-3 col-sm-6">
    <div class="stat-card text-white" style="background: linear-gradient(135deg, #135bec 0%, #0a2e7a 100%);">
      <div class="d-flex align-items-center mb-2 text-white-50">
        <i class="bi bi-activity me-2"></i>
        <div class="small">متوسط الحضور</div>
      </div>
      <h3 class="mt-1 mb-0 text-white" id="dashAttendance">{{ $stats['attendance'] ?? 0 }}%</h3>
      <div class="text-white-50 small fw-semibold">مستقر إحصائياً</div>
    </div>
  </div>
</div>

<!-- AI Analytics & Main Charts Section -->
<div class="row g-3 mb-4">
  <!-- AI Insights Panel -->
  <div class="col-lg-12">
    <div class="card-panel border-start border-4 border-primary" style="background: #f8fbff;">
      <div class="d-flex justify-content-between align-items-start mb-3">
        <div>
          <h5 class="section-title mb-0 d-flex align-items-center">
            <i class="bi bi-stars text-primary me-2"></i>
            تقرير تحليل البيانات والذكاء الاصطناعي
          </h5>
          <p class="text-muted small mb-0">تحليل فوري بناءً على البيانات الحقيقية في النظام</p>
        </div>
        <span class="badge bg-primary-subtle text-primary border border-primary-subtle">AI Powered</span>
      </div>
      <div class="ai-report-content px-3 py-2 bg-white rounded shadow-sm border">
        <p class="mb-0 text-dark" style="line-height: 1.8; white-space: pre-line;">
          {!! $aiInsight !!}
        </p>
      </div>
    </div>
  </div>

  <!-- Grades Chart -->
  <div class="col-lg-5">
    <div class="card-panel h-100 shadow-sm">
      <div class="section-title mb-1">أداء الطلاب العام</div>
      <div class="d-flex align-items-center gap-1 mb-3">
        <h2 class="mb-0">{{ $stats['performance'] }}%</h2>
        <span class="badge bg-success-subtle text-success">+2.1%</span>
      </div>
      <canvas id="gradeChart" height="240"></canvas>
    </div>
  </div>

  <!-- Weekly Attendance -->
  <div class="col-lg-7">
    <div class="card-panel h-100 shadow-sm">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
          <div class="section-title mb-0">اتجاه الحضور الأسبوعي</div>
          <small class="text-muted">آخر 7 أيام عمل</small>
        </div>
        <div class="text-primary fw-bold">{{ $stats['attendance'] }}% متوسط</div>
      </div>
      <canvas id="attendanceChart" height="150"></canvas>
    </div>
  </div>
</div>

<!-- Footer Info -->
<div class="row g-3">
  <div class="col-md-6">
    <div class="card-panel">
      <div class="section-title"><i class="bi bi-lightning-charge me-2 text-warning"></i>تنبيهات النظام</div>
      <ul class="list-unstyled mb-0">
        <li class="text-muted mb-2 small d-flex align-items-center">
          <i class="bi bi-circle-fill text-danger me-2" style="font-size: 6px;"></i>
          فصلان بحضور أقل من 85% هذا الأسبوع
        </li>
        <li class="text-muted mb-2 small d-flex align-items-center">
          <i class="bi bi-circle-fill text-warning me-2" style="font-size: 6px;"></i>
          هناك {{ $stats['danglingStudents'] }} طلاب غير مسجلين في فصول.
        </li>
      </ul>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card-panel">
      <div class="section-title"><i class="bi bi-clock-history me-2 text-info"></i>إحصائيات سريعة</div>
      <div class="row g-2">
        <div class="col-6">
          <div class="p-2 border rounded bg-light">
            <div class="text-muted small">إجمالي المواد</div>
            <div class="fw-bold">{{ $stats['subjects'] }}</div>
          </div>
        </div>
        <div class="col-6">
          <div class="p-2 border rounded bg-light">
            <div class="text-muted small">نسبة الأداء</div>
            <div class="fw-bold">{{ $stats['performance'] }}%</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<style>
.icon-box {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
}
.stat-card {
  transition: transform 0.2s;
}
.stat-card:hover {
  transform: translateY(-3px);
}
.ai-report-content {
  border-left: 3px solid #135bec !important;
}
</style>
@endsection

@push('scripts')
<script>
  (function () {
    if (typeof window.Chart === 'undefined') return;

    // Grades Chart
    const gradeCtx = document.getElementById('gradeChart').getContext('2d');
    new Chart(gradeCtx, {
      type: 'bar',
      data: {
        labels: ['A (90+)', 'B (80+)', 'C (70+)', 'D (60+)', 'F (<60)'],
        datasets: [{
          data: [{{ rand(10, 20) }}, {{ rand(30, 45) }}, {{ rand(20, 30) }}, {{ rand(5, 15) }}, {{ rand(1, 5) }}],
          backgroundColor: 'rgba(19, 91, 236, 0.7)',
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
      }
    });

    // Attendance Chart
    const attendanceCtx = document.getElementById('attendanceChart').getContext('2d');
    new Chart(attendanceCtx, {
      type: 'line',
      data: {
        labels: ['الأحد', 'الأثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'],
        datasets: [{
          label: 'الحضور',
          data: [94, 95, 92, 91, 93],
          borderColor: '#135bec',
          tension: 0.4,
          fill: true,
          backgroundColor: 'rgba(19, 91, 236, 0.05)'
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { min: 80, max: 100 } }
      }
    });
  })();
</script>
@endpush
