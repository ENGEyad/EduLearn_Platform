<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>{{ $title ?? 'EduLearn – School Admin Panel' }}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="csrf-token" content="{{ csrf_token() }}">

  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

  <!-- Bootstrap + Icons -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css"/>

  <style>
    :root {
      --sidebar-width: 240px;
      --bg:#f6f7fb;
      --card:#ffffff;
      --card-bg:#ffffff;
      --title:#0f172a;
      --text:#1f2933;
      --muted:#6b7280;
      --border:#e5e7eb;
      --link:#2563eb;
      --primary:#135bec;
      --radius:14px;
      --radius-lg: 18px;
      --radius-md: 14px;
      --radius-sm: 12px;
      --shadow:0 1px 2px rgba(16,24,40,.06), 0 1px 3px rgba(16,24,40,.08);
      --shadow-sm: 0 10px 30px rgba(15, 23, 42, 0.04);
    }

    * { box-sizing: border-box; }
    body {
      background: var(--bg);
      font-family: "Inter", system-ui, -apple-system, "Segoe UI", sans-serif;
      color: var(--text);
      min-height: 100vh;
    }

    /* Sidebar */
    .sidebar {
      position: fixed; top: 0; left: 0; width: var(--sidebar-width); height: 100vh;
      background: #ffffff; border-right: 1px solid #edf0f7; padding: 1.2rem 1rem 1.5rem;
      display: flex; flex-direction: column; gap: 1rem; z-index: 100;
    }
    .brand-box { display:flex; align-items:center; gap:.75rem; margin-bottom:.5rem; }
    .brand-avatar { width:38px;height:38px;border-radius:999px;background:#106d63;display:grid;place-items:center;color:#fff;font-weight:600;font-size:.7rem; }
    .sidebar small { color:#94a3b8; }
    .sidebar .nav a {
      border:0; background:transparent; width:100%; text-align:left;
      display:flex; gap:.65rem; align-items:center; padding:.55rem .75rem; border-radius:14px;
      color:#1f2937; font-weight:500; font-size:.92rem; transition:.15s ease; text-decoration:none;
    }
    .sidebar .nav a .icon-wrap {
      width:30px; height:30px; display:grid; place-items:center; background:#edf1ff; border-radius:10px; color:#2743ff;
    }
    .sidebar .nav a.active, .sidebar .nav a:hover { background:#e7f1ff; color:#1f2937; }
    .sidebar .bottom-links { margin-top:auto; border-top:1px solid #edf0f7; padding-top:1rem; }

    /* Main wrapper */
    .main-wrapper { margin-left: var(--sidebar-width); min-height: 100vh; display:flex; flex-direction:column; }
    .topbar { height:64px; background:#ffffff; border-bottom:1px solid #edf0f7; display:flex; align-items:center; justify-content:space-between; padding:0 1.5rem; }
    .content-area { padding: 1.5rem 1.5rem 2.5rem; }

    /* Shared cards used elsewhere */
    .stat-card{ background:#fff; border-radius:16px; padding:1.15rem 1.15rem 1.05rem; border:1px solid #edf0f7; box-shadow:var(--shadow-sm); }
    .card-panel{ background:#fff; border-radius:18px; border:1px solid #edf0f7; padding:1.15rem 1.15rem 1.1rem; box-shadow:var(--shadow-sm); }
    .table-shell{ background:#fff; border:1px solid #edf0f7; border-radius:18px; box-shadow:var(--shadow-sm); padding:1rem 1rem .5rem; }
    .table-shell thead th{ font-size:.7rem; text-transform:uppercase; letter-spacing:.04em; color:#94a3b8; border-bottom:none; background:transparent; }

    .status-pill{ border-radius:999px; padding:.35rem .7rem; font-size:.68rem; font-weight:500; }
    .status-active{ background:#d1fae5; color:#065f46; }
    .status-suspended{ background:#fee2e2; color:#b91c1c; }
    .status-graduated{ background:#dbeafe; color:#1e40af; }
    .status-inactive{ background:#e5e7eb; color:#374151; }

    .profile-shell{ background:#fff; border:1px solid #edf0f7; border-radius:18px; padding:1rem 1rem .6rem; box-shadow:var(--shadow-sm); min-height:400px; }
    .profile-header{ display:flex; align-items:center; gap:.9rem; margin-bottom:.6rem; }
    .profile-shell .avatar-circle{ width:64px; height:64px; border-radius:999px; background:#e8ecff; display:grid; place-items:center; font-weight:700; font-size:1.15rem; color:#1f2937; }
    .profile-tabs.nav-tabs{ border-bottom:1px solid #eef2f7; gap:.4rem; }
    .profile-tabs .nav-link{ border:0!important; background:transparent!important; color:#6b7280; padding:.4rem .2rem; margin-right:1rem; border-bottom:2px solid transparent!important; font-weight:500; }
    .profile-tabs .nav-link.active{ color:var(--primary)!important; border-bottom-color:var(--primary)!important; }

    @media (max-width: 992px){ .sidebar { width: 210px; } .main-wrapper { margin-left:210px; } }
    @media (max-width: 768px){
      .sidebar { position: static; width: 100%; height: auto; flex-direction: row; overflow-x: auto; }
      .main-wrapper { margin-left: 0; }
      .topbar { flex-wrap: wrap; gap: .75rem; }
    }

    .reports-skin :root{ --bg:#f6f7fb; --card:#fff; --muted:#6b7280; --border:#e5e7eb; --title:#0f172a; --link:#2563eb; --shadow:0 1px 2px rgba(16,24,40,.06),0 1px 3px rgba(16,24,40,.08); --radius:14px; }

  .reports-skin .content-wrap{max-width:1160px;margin-inline:auto;padding:20px 20px 56px}
  .reports-skin .page{max-width:1160px;margin-inline:auto;padding:20px 20px 56px}
  .reports-skin .page-wrap{max-width:1160px;margin-inline:auto;padding:20px 20px 56px}

  .reports-skin .page-header{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:16px}
  .reports-skin .page-title{font-weight:800;font-size:28px;margin:0}
  .reports-skin .subtitle{color:var(--muted);font-size:14px}
  .reports-skin .crumbs{font-size:14px;color:var(--muted)}
  .reports-skin .crumbs .sep{margin:0 .35rem;color:#cbd5e1}

  /* Buttons */
  .reports-skin .btn{border-radius:12px;box-shadow:var(--shadow)}
  .reports-skin .btn-primary{background:var(--link)!important;border-color:var(--link)!important;font-weight:700}
  .reports-skin .btn-outline{background:#fff;color:#1f2937;border:1px solid var(--border)}
  .reports-skin .btn-soft{background:#eef2ff;color:#3949ab;border:1px solid #e0e7ff;font-weight:600;border-radius:12px;padding:.6rem .9rem}
  .reports-skin .btn-ghost{background:#fff;border:1px solid var(--border);border-radius:12px;padding:.6rem .9rem}
  .reports-skin .btn-cta{background:#e9f0ff;border:1px solid #dbe6ff;color:#0b4de0;border-radius:12px;padding:.6rem .9rem;font-weight:700}

  /* Filters + Table shells */
  .reports-skin .filters{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:12px;display:flex;gap:10px;flex-wrap:wrap;box-shadow:var(--shadow)}
  .reports-skin .input-group>.input-group-text{background:#fff;border-right:0;border-color:var(--border);border-top-left-radius:10px;border-bottom-left-radius:10px}
  .reports-skin .input-group>.form-control{border-left:0;border-color:var(--border);border-top-right-radius:10px;border-bottom-right-radius:10px;box-shadow:none}
  .reports-skin .form-select{border-radius:10px;border:1px solid var(--border);box-shadow:none;background-color:#fff}
  .reports-skin .form-select:focus,.reports-skin .form-control:focus{border-color:#c7d2fe;box-shadow:0 0 0 .2rem rgba(37,99,235,.08)}

  .reports-skin .table-shell{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:8px;box-shadow:var(--shadow)}
  .reports-skin .table{margin:0}
  .reports-skin .table>thead th{color:var(--muted);font-weight:600;font-size:12.5px;border-bottom:1px solid var(--border)!important;background:transparent}
  .reports-skin .table>tbody td{vertical-align:middle}
  .reports-skin .table>tbody tr:hover{background:#f7faff}
  .reports-skin .pagination-wrap{display:flex;justify-content:flex-end}
  .reports-skin .pagination .page-link{color:var(--title);border:1px solid var(--border);background:#fff;border-radius:10px;margin:0 3px;box-shadow:var(--shadow)}
  .reports-skin .pagination .page-item.active .page-link{background:#eef2ff;border-color:#dbe6ff;color:#0b4de0}

  /* Cards + stats */
  .reports-skin .cardy{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow)}
  .reports-skin .panel{padding:16px}
  .reports-skin .panel h6{font-size:15px;font-weight:800;margin-bottom:10px}

  .reports-skin .stats{display:grid;grid-template-columns:repeat(5,1fr);gap:16px;margin-top:14px}
  .reports-skin .stat{padding:16px}
  .reports-skin .stat .k{font-size:13px;color:var(--muted);margin-bottom:6px}
  .reports-skin .stat .v{font-size:26px;font-weight:800}
  .reports-skin .delta{font-size:12px;font-weight:700;margin-top:4px}
  .reports-skin .delta.g{color:#16a34a}.reports-skin .delta.r{color:#dc2626}

  /* Student header (avatar/pill) */
  .reports-skin .page-head{display:flex;align-items:center;justify-content:space-between;margin:10px 0 14px}
  .reports-skin .page-title{font-weight:700;font-size:22px}
  .reports-skin .student-head{padding:16px 18px}
  .reports-skin .avatar{width:56px;height:56px;border-radius:50%;background:#fde68a;display:inline-grid;place-items:center;font-weight:700;color:#78350f}
  .reports-skin .kvs{display:flex;align-items:center;gap:14px}
  .reports-skin .meta .name{font-weight:700}
  .reports-skin .meta .sub{font-size:13px;color:var(--muted)}
  .reports-skin .status-pill{margin-left:auto;padding:6px 10px;background:#eaf7ef;color:#15803d;border-radius:999px;font-size:13px;font-weight:600;display:inline-flex;align-items:center;gap:6px}
  .reports-skin .status-dot{width:8px;height:8px;border-radius:50%;background:#22c55e}

  /* Student stats */
  .reports-skin .stats--student{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-top:10px}
  .reports-skin .stat h6{font-size:13px;color:var(--muted);margin:0 0 8px}
  .reports-skin .stat .val{font-size:28px;font-weight:800}

  /* Charts rows + wrappers */
  .reports-skin .row-charts{display:grid;grid-template-columns:2fr 1fr;gap:16px;margin-top:12px}
  .reports-skin .chart-wrap{position:relative;height:220px}

  /* Mini stats + achievements (Chemistry page style) */
  .reports-skin .mini-two{display:grid;grid-template-columns:1fr 1fr;gap:16px}
  .reports-skin .stat-mini{display:flex;align-items:center;gap:12px;padding:16px}
  .reports-skin .icn-badge{width:42px;height:42px;border-radius:12px;background:#eef2ff;display:grid;place-items:center;color:#3856e8;font-size:20px}
  .reports-skin .stat-mini .label{font-size:13px;color:var(--muted);margin-bottom:2px}
  .reports-skin .stat-mini .val{font-size:26px;font-weight:800}
  .reports-skin .trend-note{font-size:13px;color:#16a34a;font-weight:700;display:flex;align-items:center;gap:6px}
  .reports-skin .trend-note .muted{color:var(--muted);font-weight:600}
  .reports-skin .muted{color:var(--muted)}
  .reports-skin .section-title{font-weight:800;font-size:16px;margin:2px 0 8px}
  .reports-skin .ach-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}
  .reports-skin .ach-card{padding:18px;display:flex;align-items:center;gap:14px;border:1px dashed #e2e8f0;border-radius:12px}
  .reports-skin .ach-icn{width:46px;height:46px;border-radius:50%;display:grid;place-items:center}
  .reports-skin .ach-icn.star{background:#fff7e6;color:#d97706}
  .reports-skin .ach-icn.book{background:#e6fffa;color:#059669}
  .kv-row{
  display:flex;
  justify-content:space-between;
  font-size:.82rem;
  margin-bottom:.25rem;
}
.kv-label{
  color:var(--muted);
}
.kv-value{
  font-weight:500;
}

  /* Badges + links */
  .reports-skin .badge-pass{background:#e8f7ee;color:#118d57;font-weight:700}
  .reports-skin .badge-fail{background:#fee2e2;color:#be123c;font-weight:700}
  .reports-skin .action-link{color:var(--link);font-weight:600;text-decoration:none}

  /* Responsive */
  @media (max-width:1100px){ .reports-skin .stats{grid-template-columns:repeat(3,1fr)} }
  @media (max-width:992px){
    .reports-skin .row-charts{grid-template-columns:1fr}
    .reports-skin .mini-two{grid-template-columns:1fr}
  }
  @media (max-width:720px){ .reports-skin .stats{grid-template-columns:repeat(2,1fr)} }
  @media (max-width:560px){ .reports-skin .kvs{align-items:flex-start}.reports-skin .status-pill{margin-left:0} }

  /* Print */
  @media print{
    .reports-skin .no-print, .reports-skin .filters{display:none!important}
    body{background:#fff}
    .reports-skin .content-wrap,.reports-skin .page,.reports-skin .page-wrap{max-width:100%;padding:0}
    .reports-skin .cardy,.reports-skin .table-shell{box-shadow:none}
  }
  </style>
</head>
<body>

  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="brand-box">
      <div class="brand-avatar">EL</div>
      <div>
        <div class="fw-semibold">EduLearn</div>
        <small>School Admin</small>
      </div>
    </div>

    <nav class="nav flex-column gap-1" id="sidebarNav">
  <a href="{{ url('/') }}" class="{{ request()->is('/') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-grid-1x2"></i></span>
    <span>Dashboard</span>
  </a>
  <a href="{{ url('/students') }}" class="{{ request()->is('students*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-person-lines-fill"></i></span>
    <span>Students</span>
  </a>
  <a href="{{ url('/teachers') }}" class="{{ request()->is('teachers*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-person-badge"></i></span>
    <span>Teachers</span>
  </a>
  <a href="{{ url('/classes') }}" class="{{ request()->is('classes*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-journal-text"></i></span>
    <span>Classes</span>
  </a>
  <a href="{{ url('/subjects') }}" class="{{ request()->is('subjects*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-journal-bookmark"></i></span>
    <span>Subjects</span>
  </a>


<a href="{{ url('/class-subjects') }}" class="{{ request()->is('class-subjects*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-journal-check"></i></span>
    <span>Class Subjects</span>
  </a>
  
  <a href="{{ url('/assignments') }}" class="{{ request()->is('assignments*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-diagram-3"></i></span>
    <span>Assignments</span>
  </a>
  <a href="{{ url('/reports') }}" class="{{ request()->is('reports*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-bar-chart"></i></span>
    <span>Reports</span>
  </a>
  <a href="{{ url('/settings') }}" class="{{ request()->is('settings*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-gear"></i></span>
    <span>Settings</span>
  </a>
</nav>


    <div class="bottom-links">
      <button class="w-100 d-flex align-items-center gap-2 border-0 bg-transparent text-start text-muted mb-2">
        <i class="bi bi-question-circle"></i> Help
      </button>
      <button class="w-100 d-flex align-items-center gap-2 border-0 bg-transparent text-start text-muted">
        <i class="bi bi-box-arrow-left"></i> Logout
      </button>
    </div>
  </aside>

  <!-- MAIN WRAPPER -->
  <div class="main-wrapper">
    <header class="topbar">
      <div>
        <div class="page-title" id="pageTitle">{{ $pageTitle ?? 'Dashboard' }}</div>
        <small class="text-muted" id="pageSubtitle">{{ $pageSubtitle ?? 'Welcome, Admin!' }}</small>
      </div>
      <div class="right-area d-flex align-items-center gap-3">
        <button class="btn btn-light border-0" id="timeFilterBtn">
          This Week
          <i class="bi bi-chevron-down"></i>
        </button>
        <button class="btn position-relative btn-link text-dark">
          <i class="bi bi-bell fs-5"></i>
          <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">3</span>
        </button>
      </div>
    </header>

    <main class="content-area">
      @yield('content')
    </main>
  </div>

  <!-- Scripts -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  @stack('scripts')
</body>
</html>
