<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
  <meta charset="UTF-8" />
  <title>{{ $title ?? 'EduLearn – School Admin Panel' }}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="csrf-token" content="{{ csrf_token() }}">
  <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">

  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&display=swap" rel="stylesheet">

  <!-- Bootstrap RTL + Icons -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.rtl.min.css" rel="stylesheet"/>
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
      
      /* Soft Buttons */
      --btn-soft-bg: #f3f4f6;
      --btn-soft-text: #374151;
      --btn-soft-border: #e5e7eb;
      --btn-soft-hover-bg: #e5e7eb;
      --btn-soft-hover-text: #111827;
      
      --btn-danger-soft-bg: #fee2e2;
      --btn-danger-soft-text: #b91c1c;
      --btn-danger-soft-border: #fecaca;

      /* Notifications */
      --notif-bg-unread: #ffffff;
      --notif-bg-read: #f8f9fa;
      --notif-border-unread: #dee2e6;
      --notif-icon-bg-unread: #e0e7ff; /* primary-subtle */
      --notif-icon-bg-read: #f1f5f9; /* secondary-subtle */
    }

    /* Dark Mode Variables */
    body.dark-mode {
      --bg: #0f172a;
      --card: #1e293b;
      --card-bg: #1e293b;
      --title: #ffffff;
      --text: #e2e8f0;
      --muted: #94a3b8;
      --border: #334155;
      --link: #38bdf8;
      --shadow: 0 1px 2px rgba(0,0,0,.3);
      --shadow-sm: 0 10px 30px rgba(0, 0, 0, 0.2);
      
      /* Soft Buttons Dark */
      --btn-soft-bg: rgba(255, 255, 255, 0.08);
      --btn-soft-text: #ffffff;
      --btn-soft-border: rgba(255, 255, 255, 0.15);
      --btn-soft-hover-bg: rgba(255, 255, 255, 0.15);
      --btn-soft-hover-text: #ffffff;

      /* Theme Danger Soft Dark */
      --btn-danger-soft-bg: rgba(239, 68, 68, 0.2);
      --btn-danger-soft-text: #ffffff;
      --btn-danger-soft-border: rgba(239, 68, 68, 0.4);

      /* Notifications Dark Mode */
      --notif-bg-unread: rgba(56, 189, 248, 0.05); 
      --notif-bg-read: rgba(255, 255, 255, 0.02);
      --notif-border-unread: rgba(56, 189, 248, 0.3);
      --notif-icon-bg-unread: rgba(56, 189, 248, 0.15);
      --notif-icon-bg-read: rgba(148, 163, 184, 0.1);
    }

    * { box-sizing: border-box; }
    body {
      background: var(--bg);
      font-family: "Cairo", system-ui, -apple-system, sans-serif;
      color: var(--text);
      height: 100vh;
      overflow: hidden;
    }

    /* Sidebar */
    .sidebar {
      position: fixed; top: 0; width: var(--sidebar-width); height: 100vh;
      background: var(--card); border-inline-end: 1px solid var(--border);
      padding: 1.2rem 1rem 1.5rem;
      display: flex; flex-direction: column; gap: 1rem; z-index: 100;
    }
    
    [dir="rtl"] .sidebar { right: 0; left: auto; }
    [dir="ltr"] .sidebar { left: 0; right: auto; }

    .brand-box { display:flex; align-items:center; gap:.75rem; margin-bottom:.5rem; }
    .brand-avatar { width:38px;height:38px;border-radius:999px;background:#106d63;display:grid;place-items:center;color:#fff;font-weight:600;font-size:.7rem; }
    .sidebar small { color:var(--muted); }
    .sidebar .nav a {
      border:0; background:transparent; width:100%; text-align:start;
      display:flex; gap:.65rem; align-items:center; padding:.55rem .75rem; border-radius:var(--radius-md);
      color:var(--text); font-weight:500; font-size:.92rem; transition:.15s;
      text-decoration:none;
    }
    .sidebar .nav a .icon-wrap {
      width:30px; height:30px; display:grid; place-items:center; background:var(--bg); border-radius:10px; color:var(--primary);
      transition:.15s;
    }
    
    body.dark-mode .sidebar .nav a .icon-wrap {
      background: rgba(255,255,255,0.05); color: var(--link);
    }

    .sidebar .nav a.active, .sidebar .nav a:hover { 
      background: var(--primary); color: #ffffff; 
    }
    .status-pill.active { background: #ffffff; color: var(--primary); }
    
    .sidebar .nav a.active .icon-wrap, .sidebar .nav a:hover .icon-wrap {
      background: rgba(255,255,255,0.2); color: #ffffff;
    }
    .sidebar .bottom-links { margin-top:auto; border-top:1px solid var(--border); padding-top:1rem; }

    /* Main wrapper */
    .main-wrapper { height: 100vh; display:flex; flex-direction:column; overflow: hidden; }
    [dir="rtl"] .main-wrapper { margin-right: var(--sidebar-width); margin-left: 0; }
    [dir="ltr"] .main-wrapper { margin-left: var(--sidebar-width); margin-right: 0; }

    .topbar { flex-shrink: 0; height:64px; background:var(--card); border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; padding:0 1.5rem; }
    .content-area { padding: 1.5rem 1.5rem 2.5rem; overflow-y: auto; flex-grow: 1; }
    
    /* Custom Scrollbar for Content Area */
    .content-area::-webkit-scrollbar { width: 8px; }
    .content-area::-webkit-scrollbar-track { background: transparent; }
    .content-area::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.1); border-radius: 10px; }
    body.dark-mode .content-area::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); }
    .content-area::-webkit-scrollbar-thumb:hover { background: rgba(0,0,0,0.2); }
    body.dark-mode .content-area::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.2); }

    /* Shared cards used elsewhere */
    .stat-card{ background:var(--card); border-radius:16px; padding:1.15rem 1.15rem 1.05rem; border:1px solid var(--border); box-shadow:var(--shadow-sm); }
    .card-panel{ background:var(--card); border-radius:18px; border:1px solid var(--border); padding:1.15rem 1.15rem 1.1rem; box-shadow:var(--shadow-sm); }
    .table-shell{ background:var(--card); border:1px solid var(--border); border-radius:18px; box-shadow:var(--shadow-sm); padding:1rem 1rem .5rem; }
    .table-shell thead th{ font-size:.7rem; text-transform:uppercase; letter-spacing:.04em; color:#94a3b8; border-bottom:none; background:transparent; }

    .status-pill{ border-radius:999px; padding:.35rem .7rem; font-size:.68rem; font-weight:500; }
    .status-active{ background:#d1fae5; color:#065f46; }
    .status-suspended{ background:#fee2e2; color:#b91c1c; }
    .status-graduated{ background:#dbeafe; color:#1e40af; }
    .status-inactive{ background:#e5e7eb; color:#374151; }

    .profile-shell{ background:var(--card); border:1px solid var(--border); border-radius:18px; padding:1rem 1rem .6rem; box-shadow:var(--shadow-sm); min-height:400px; }
    .profile-header{ display:flex; align-items:center; gap:.9rem; margin-bottom:.6rem; }
    .profile-shell .avatar-circle{ width:64px; height:64px; border-radius:999px; background:#e8ecff; display:grid; place-items:center; font-weight:700; font-size:1.15rem; color:#1f2937; }
    .profile-tabs.nav-tabs{ border-bottom:1px solid #eef2f7; gap:.4rem; }
    .profile-tabs .nav-link{ border:0!important; background:transparent!important; color:#6b7280; padding:.4rem .2rem; margin-right:1rem; border-bottom:2px solid transparent!important; font-weight:500; }
    .profile-tabs .nav-link.active{ color:var(--primary)!important; border-bottom-color:var(--primary)!important; }

    @media (max-width: 992px){ 
      .sidebar { width: 210px; } 
      [dir="rtl"] .main-wrapper { margin-right: 210px; }
      [dir="ltr"] .main-wrapper { margin-left: 210px; }
    }
    @media (max-width: 768px){
      .sidebar { position: static; width: 100%; height: auto; flex-direction: row; overflow-x: auto; border-inline-end: 0; border-bottom: 1px solid var(--border); }
      .main-wrapper { margin-right: 0; margin-left: 0; }
      .topbar { flex-wrap: wrap; gap: .75rem; }
    }

    /* Additional Dark Mode Overrides */
    body.dark-mode .topbar { background: var(--card); border-bottom: 1px solid var(--border); }
    body.dark-mode .dropdown-menu { background: var(--card); border: 1px solid var(--border); color: var(--text); }
    body.dark-mode .dropdown-item { color: var(--text); }
    body.dark-mode .dropdown-item:hover { background: rgba(255,255,255,0.05); color: var(--link); }
    body.dark-mode .dropdown-header { background: rgba(255,255,255,0.02) !important; color: var(--title) !important; border-bottom: 1px solid var(--border) !important; }
    body.dark-mode .text-dark { color: var(--title) !important; }
    body.dark-mode .btn-light { background: rgba(255,255,255,0.05); color: var(--title); border: 0; }
    body.dark-mode .btn-light:hover { background: rgba(255,255,255,0.1); color: var(--title); }

    /* Performance Overrides for Dark Mode */
    body.dark-mode .card-panel, 
    body.dark-mode .stat-card, 
    body.dark-mode .table-shell, 
    body.dark-mode .profile-shell {
        background: var(--card);
        border-color: var(--border);
    }

    /* Soft Buttons Global */
    .btn-soft {
        background-color: var(--btn-soft-bg);
        color: var(--btn-soft-text);
        border: 1px solid var(--btn-soft-border);
        transition: all 0.2s ease;
    }
    .btn-soft:hover {
        background-color: var(--btn-soft-hover-bg);
        color: var(--btn-soft-hover-text);
        box-shadow: var(--shadow-sm);
    }
    .btn-soft-danger {
        background-color: var(--btn-danger-soft-bg);
        color: var(--btn-danger-soft-text);
        border: 1px solid var(--btn-danger-soft-border);
    }
    .btn-soft-danger:hover {
        background-color: var(--btn-danger-soft-text);
        color: #fff;
    }
    body.dark-mode .notification-dropdown .bg-light { background: rgba(255,255,255,0.03) !important; border-top-color: var(--border) !important; }
    body.dark-mode .sidebar .bottom-links button { color: rgba(255,255,255,0.6) !important; }
    body.dark-mode .sidebar .bottom-links button:hover { color: #fff !important; }
    body.dark-mode #pageSubtitle { color: #ffffff !important; }
    
    /* Dark Mode Form Controls */
    body.dark-mode .form-control,
    body.dark-mode .form-select,
    body.dark-mode .input-group-text {
        background-color: var(--card) !important;
        color: var(--text) !important;
        border-color: var(--border) !important;
    }
    body.dark-mode .form-control::placeholder {
        color: var(--muted) !important;
    }
    
    /* Dark Mode Tables Global */
    body.dark-mode .table {
        color: var(--text) !important;
    }
    body.dark-mode .table thead th {
        color: var(--muted) !important;
        border-bottom-color: var(--border) !important;
    }
    body.dark-mode .table tbody td {
        border-bottom-color: var(--border) !important;
    }
    body.dark-mode .table-hover tbody tr:hover {
        background-color: rgba(255, 255, 255, 0.03) !important;
    }

    body.dark-mode .text-muted { color: rgba(255, 255, 255, 0.7) !important; }
    
    /* Soft Danger Button - Dark Mode Hover Fix */
    body.dark-mode .btn-soft-danger:hover {
        background-color: rgba(239, 68, 68, 0.15) !important;
        color: #ff8080 !important;
        border-color: rgba(239, 68, 68, 0.3) !important;
    }

    /* Dropdown alignment fix for English */
    [dir="ltr"] .dropdown-item {
        text-align: left !important;
    }
    [dir="rtl"] .dropdown-item {
        text-align: right !important;
    }

    /* Custom Notification Item Classes */
    .notif-item-unread {
        background-color: var(--notif-bg-unread) !important;
        border-color: var(--notif-border-unread) !important;
    }
    .notif-item-read {
        background-color: var(--notif-bg-read) !important;
        border-color: var(--border) !important;
        opacity: 0.8;
    }
    .notif-icon-unread {
        background-color: var(--notif-icon-bg-unread) !important;
    }
    .notif-icon-read {
        background-color: var(--notif-icon-bg-read) !important;
    }
    body.dark-mode .notification-item p {
        color: #ffffff !important;
        opacity: 0.85;
    }
    body.dark-mode .notification-item h6 {
        color: #ffffff !important;
    }
    body.dark-mode .notification-item .text-muted {
        color: rgba(255, 255, 255, 0.6) !important;
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
  .reports-skin .input-group>.input-group-text{background:var(--card);border-right:0;border-color:var(--border);border-top-left-radius:10px;border-bottom-left-radius:10px;color:var(--text)}
  .reports-skin .input-group>.form-control{background:var(--card);border-left:0;border-color:var(--border);border-top-right-radius:10px;border-bottom-right-radius:10px;box-shadow:none;color:var(--text)}
  .reports-skin .form-select{border-radius:10px;border:1px solid var(--border);box-shadow:none;background-color:var(--card);color:var(--text)}
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
<body class="{{ ($themeMode ?? 'light') == 'dark' ? 'dark-mode' : '' }}">

  <!-- Print-only Header -->
  <div class="d-none d-print-block mb-4 border-bottom pb-3" id="globalPrintHeader">
    <div class="d-flex align-items-center justify-content-between">
      <div class="d-flex align-items-center gap-3">
        @if(auth()->user()?->school?->logo_path)
          <img src="{{ asset('storage/' . auth()->user()->school->logo_path) }}" alt="Logo" width="60" height="60" style="object-fit:cover; border-radius: 8px;">
        @endif
        <div>
          <h3 class="mb-0 fw-bold text-dark">{{ auth()->user()?->school?->name ?? 'EduLearn' }}</h3>
          <p class="mb-0 text-muted">{{ auth()->user()?->school?->academic_year ?? '' }}</p>
        </div>
      </div>
      <div class="text-end">
        <h4 class="mb-1 fw-bold text-primary" id="printReportTitle">REPORT</h4>
        <p class="mb-0 text-muted" id="printReportDate">{{ now()->format('Y-m-d') }}</p>
      </div>
    </div>
  </div>

  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="brand-box">
      <img src="{{ (auth()->user()?->school && auth()->user()?->school?->logo_path) ? asset('storage/' . auth()->user()->school->logo_path) : asset('favicon.png') }}" alt="School Logo" width="38" height="38" style="border-radius:12px;object-fit:cover;" loading="lazy">
      <div>
        <div class="fw-semibold text-truncate" style="max-width: 150px;">{{ auth()->user()?->school?->name ?? 'EduLearn' }}</div>
        <small>{{ auth()->user()?->school?->academic_year ?? __('Dashboard') }}</small>
      </div>
    </div>

    <nav class="nav flex-column gap-1" id="sidebarNav">
  <a href="{{ url('/') }}" class="{{ request()->is('/') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-grid-1x2"></i></span>
    <span>{{ __('Dashboard') }}</span>
  </a>
  <a href="{{ url('/students') }}" class="{{ request()->is('students*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-person-lines-fill"></i></span>
    <span>{{ __('Students') }}</span>
  </a>
  <a href="{{ url('/teachers') }}" class="{{ request()->is('teachers*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-person-badge"></i></span>
    <span>{{ __('Teachers') }}</span>
  </a>
  <a href="{{ url('/classes') }}" class="{{ request()->is('classes*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-journal-text"></i></span>
    <span>{{ __('Classes') }}</span>
  </a>
  <a href="{{ url('/subjects') }}" class="{{ request()->is('subjects*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-journal-bookmark"></i></span>
    <span>{{ __('Subjects') }}</span>
  </a>


<a href="{{ url('/class-subjects') }}" class="{{ request()->is('class-subjects*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-journal-check"></i></span>
    <span>{{ __('Class Subjects') }}</span>
  </a>
  
  <a href="{{ url('/assignments') }}" class="{{ request()->is('assignments*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-diagram-3"></i></span>
    <span>{{ __('Assignments') }}</span>
  </a>
  <a href="{{ url('/reports') }}" class="{{ request()->is('reports*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-bar-chart"></i></span>
    <span>{{ __('Reports') }}</span>
  </a>
  <a href="{{ url('/notifications') }}" class="{{ request()->is('notifications*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-bell"></i></span>
    <span>{{ __('Notifications') }}</span>
  </a>
  <a href="{{ route('settings.index') }}" class="{{ request()->is('settings*') ? 'active' : '' }}">
    <span class="icon-wrap"><i class="bi bi-gear"></i></span>
    <span>{{ __('Settings') }}</span>
  </a>
</nav>


    <div class="bottom-links">
      <button class="w-100 d-flex align-items-center gap-2 border-0 bg-transparent text-start text-muted mb-2">
        <i class="bi bi-question-circle"></i> {{ __('Help') }}
      </button>
      <button class="w-100 d-flex align-items-center gap-2 border-0 bg-transparent text-start text-muted">
        <i class="bi bi-box-arrow-left"></i> {{ __('Logout') }}
      </button>
    </div>
  </aside>

  <!-- MAIN WRAPPER -->
  <div class="main-wrapper">
    <header class="topbar">
      <div>
        <div class="page-title" id="pageTitle">{{ $pageTitle ?? __('Dashboard') }}</div>
        <small class="text-muted" id="pageSubtitle">{{ $pageSubtitle ?? __('Welcome, :name', ['name' => auth()->user()->name]) }}</small>
      </div>
      <div class="right-area d-flex align-items-center gap-3">
        <div class="dropdown">
          <button class="btn btn-light border-0 dropdown-toggle" type="button" id="timeFilterBtn" data-bs-toggle="dropdown" aria-expanded="false">
            {{ $periodLabel ?? __('This Week') }}
          </button>
          <ul class="dropdown-menu {{ app()->getLocale() == 'en' ? 'dropdown-menu-start' : 'dropdown-menu-end' }} shadow-sm border-0" aria-labelledby="timeFilterBtn">
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('today')">{{ __('Today') }}</a></li>
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('week')">{{ __('This Week') }}</a></li>
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('month')">{{ __('This Month') }}</a></li>
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('year')">{{ __('This Year') }}</a></li>
          </ul>
        </div>
        <div class="dropdown">
          <button class="btn position-relative btn-link text-dark border-0 p-0" type="button" id="notificationDropdown" data-bs-toggle="dropdown" aria-expanded="false">
            <i class="bi bi-bell fs-5"></i>
            @if($unreadNotificationsCount > 0)
              <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 0.65rem; padding: 0.25em 0.5em;">
                {{ $unreadNotificationsCount > 9 ? '9+' : $unreadNotificationsCount }}
              </span>
            @endif
          </button>
          
          <div class="dropdown-menu dropdown-menu-end shadow-lg border-0 p-0 notification-dropdown" aria-labelledby="notificationDropdown">
            <div class="dropdown-header border-bottom bg-light px-3 py-2 d-flex justify-content-between align-items-center rounded-top">
              <span class="fw-bold text-dark">{{ __('Recent Notifications') }}</span>
              <a href="{{ route('notifications.markAllRead') }}" class="text-decoration-none small text-primary" onclick="event.preventDefault(); document.getElementById('mark-all-read-form-mini').submit();">{{ __('Mark all as read') }}</a>
              <form id="mark-all-read-form-mini" action="{{ route('notifications.markAllRead') }}" method="POST" style="display: none;">@csrf</form>
            </div>
            
            <div class="notification-scroll-area" style="max-height: 350px; overflow-y: auto;">
              @if($headerNotifications->isEmpty())
                <div class="p-4 text-center">
                  <i class="bi bi-bell-slash text-muted opacity-50 display-6 d-block mb-2"></i>
                  <small class="text-muted">{{ __('No notifications currently') }}</small>
                </div>
              @else
                @foreach($headerNotifications as $notif)
                  <a href="{{ route('notifications.index') }}" class="dropdown-item px-3 py-2 border-bottom {{ $notif->is_read ? 'notif-item-read' : 'notif-item-unread' }}">
                    <div class="d-flex align-items-start gap-2">
                       <i class="bi {{ $notif->icon ?? 'bi-info-circle' }} p-1 {{ $notif->is_read ? 'notif-icon-read text-secondary' : 'notif-icon-unread text-primary' }} rounded" style="font-size: 1.1rem;"></i>
                       <div class="flex-grow-1 overflow-hidden">
                          <div class="d-flex justify-content-between align-items-center">
                             <div class="fw-semibold small text-truncate" style="max-width: 140px;">{{ $notif->title }}</div>
                             <small class="text-muted opacity-75" style="font-size: 0.65rem;">{{ $notif->created_at->diffForHumans() }}</small>
                          </div>
                          <p class="mb-0 text-muted text-truncate mini-notif-msg" style="font-size: 0.75rem;">{{ $notif->message }}</p>
                       </div>
                    </div>
                  </a>
                @endforeach
              @endif
            </div>
            
            <div class="p-2 border-top text-center rounded-bottom bg-light">
              <a href="{{ route('notifications.index') }}" class="text-primary text-decoration-none small fw-bold">{{ __('View All') }}</a>
            </div>
          </div>
        </div>
      </div>
    </header>

    <main class="content-area">
      @yield('content')
    </main>
  </div>

  <style>
    .notification-dropdown {
      width: 320px;
      margin-top: 10px;
      border-radius: 14px!important;
    }
    .dropdown-item:active {
      background-color: #f8f9fa;
      color: var(--text);
    }
    .mini-notif-msg {
      max-width: 250px;
    }
    .notification-scroll-area::-webkit-scrollbar { width: 4px; }
    .notification-scroll-area::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 4px; }
  </style>

  <!-- Scripts -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" defer></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js" defer></script>
  <script>
    window.I18N = {
        active: "{{ __('Active') }}",
        inactive: "{{ __('Inactive') }}",
        select: "{{ __('Select') }}",
        all: "{{ __('All') }}",
        confirm: "{{ __('Confirm') }}",
        delete: "{{ __('Delete') }}",
        cancel: "{{ __('Cancel') }}",
        save: "{{ __('Save') }}",
        error: "{{ __('Error') }}",
        success: "{{ __('Success') }}",
        loading: "{{ __('Loading') }}..."
    };

    function updateFilter(period) {
      const url = new URL(window.location.href);
      url.searchParams.set('period', period);
      window.location.href = url.toString();
    }
  </script>
  @stack('scripts')
</body>
</html>
