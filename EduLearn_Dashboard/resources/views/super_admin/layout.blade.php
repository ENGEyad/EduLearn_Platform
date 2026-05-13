<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Super Admin') - EduLearn Platform</title>
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    @if(app()->getLocale() == 'ar')
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
    @else
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    @endif
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
    @stack('head')
    <style>
        :root {
            --bg-deep: #001020;
            --navy: #001A33;
            --navy-light: #003366;
            --navy-card: rgba(0,26,51,0.65);
            --orange: #FF6600;
            --orange-light: #FF8533;
            --orange-glow: rgba(255,102,0,0.3);
            --border: rgba(255,255,255,0.08);
            --text: #e2e8f0;
            --muted: #94a3b8;
            --white: #fff;
        }
        body {
            font-family: {{ app()->getLocale() == 'ar' ? "'Cairo', sans-serif" : "'Inter', sans-serif" }};
            background: var(--bg-deep); color: var(--text); min-height: 100vh; position: relative;
        }
        body::before {
            content: ''; position: fixed; inset: 0; z-index: 0; pointer-events: none;
            background:
                radial-gradient(ellipse 70% 50% at 15% 10%, rgba(0,51,102,0.25) 0%, transparent 55%),
                radial-gradient(ellipse 50% 40% at 85% 30%, rgba(255,102,0,0.1) 0%, transparent 50%),
                radial-gradient(ellipse 60% 50% at 50% 90%, rgba(0,51,102,0.15) 0%, transparent 45%);
        }
        body::after {
            content: ''; position: fixed; inset: 0; z-index: 0; pointer-events: none;
            background-image:
                linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px);
            background-size: 60px 60px;
        }
        .sa-sidebar {
            width: 280px; position: fixed; top: 0; height: 100vh; z-index: 1050;
            background: rgba(0,16,32,0.95);
            backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
            border-inline-end: 1px solid var(--border);
            padding: 1.5rem 1rem; display: flex; flex-direction: column;
            overflow-y: auto;
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        @media (max-width: 991px) {
            .sa-sidebar { transform: translateX(-100%); }
            [dir="rtl"] .sa-sidebar { transform: translateX(100%); }
            .sidebar-open .sa-sidebar { transform: translateX(0) !important; }
            .sa-sidebar-overlay {
                position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1040;
                display: none; backdrop-filter: blur(4px);
            }
            .sidebar-open .sa-sidebar-overlay { display: block; }
        }
        [dir="rtl"] .sa-sidebar { right: 0; } [dir="ltr"] .sa-sidebar { left: 0; }
        .sa-brand { display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem 0.75rem; margin-bottom: 2rem; }
        .sa-brand img { width: 40px; height: 40px; border-radius: 12px; }
        .sa-brand-text { font-size: 1.3rem; font-weight: 800; }
        .sa-brand-text span { color: var(--orange); }
        .sa-nav { list-style: none; padding: 0; margin: 0; flex: 1; }
        .sa-nav li { margin-bottom: 0.25rem; }
        .sa-nav a, .sa-nav button {
            display: flex; align-items: center; gap: 0.75rem;
            padding: 0.85rem 1rem; border-radius: 14px;
            color: var(--muted); text-decoration: none; font-weight: 600; font-size: 0.9rem;
            transition: all 0.25s ease; border: none; background: transparent; width: 100%;
            text-align: inherit; cursor: pointer;
        }
        .sa-nav a:hover, .sa-nav button:hover { color: var(--white); background: rgba(255,255,255,0.05); }
        .sa-nav a.active {
            color: var(--white); background: linear-gradient(135deg, var(--orange), #e65c00);
            box-shadow: 0 4px 15px var(--orange-glow);
        }
        .sa-nav a.active i { color: var(--white) !important; }
        .sa-nav a i { font-size: 1.1rem; color: var(--muted); transition: color 0.2s; }
        .sa-nav-divider { border-top: 1px solid var(--border); margin: 1rem 0; }
        .sa-main { position: relative; z-index: 1; padding: 1.5rem 1rem; }
        @media (min-width: 992px) {
            .sa-main { padding: 2rem 2.5rem; }
            [dir="rtl"] .sa-main { margin-right: 280px; } 
            [dir="ltr"] .sa-main { margin-left: 280px; }
        }
        .sa-mobile-toggle {
            display: none; width: 42px; height: 42px; border-radius: 12px;
            background: var(--navy-card); border: 1px solid var(--border);
            color: var(--white); align-items: center; justify-content: center;
            font-size: 1.25rem; cursor: pointer; transition: all 0.2s;
        }
        @media (max-width: 991px) { .sa-mobile-toggle { display: flex; } }
        .sa-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; padding-bottom: 1.5rem; border-bottom: 1px solid var(--border); gap: 1rem; flex-wrap: wrap; }
        .sa-header h1 { font-size: 1.6rem; font-weight: 800; margin: 0; }
        .sa-header p { color: var(--muted); margin: 0.25rem 0 0; font-size: 0.9rem; }
        .sa-card {
            background: var(--navy-card); backdrop-filter: blur(12px);
            border: 1px solid var(--border); border-radius: 20px; padding: 1.5rem;
            transition: all 0.35s cubic-bezier(0.4,0,0.2,1);
        }
        .sa-card:hover { transform: translateY(-4px); box-shadow: 0 15px 40px rgba(0,0,0,0.3); border-color: rgba(255,102,0,0.15); }
        .sa-card h5 { font-weight: 700; font-size: 1.05rem; margin-bottom: 1rem; }
        .sa-card h5 i { color: var(--orange); }
        .sa-stat { position: relative; overflow: hidden; }
        .sa-stat-icon { position: absolute; bottom: 10px; font-size: 3rem; opacity: 0.08; color: var(--white); }
        [dir="rtl"] .sa-stat-icon { left: 15px; } [dir="ltr"] .sa-stat-icon { right: 15px; }
        .sa-stat .label { color: var(--muted); font-size: 0.8rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
        .sa-stat .value { font-size: 2rem; font-weight: 800; margin-top: 0.3rem; }
        .sa-alert { padding: 1rem 1.25rem; border-radius: 14px; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.75rem; backdrop-filter: blur(12px); font-size: 0.9rem; }
        .sa-alert-success { background: rgba(16,185,129,0.1); border: 1px solid rgba(16,185,129,0.2); color: #10b981; }
        .sa-alert-info { background: rgba(56,189,248,0.1); border: 1px solid rgba(56,189,248,0.2); color: #38bdf8; }
        .modal-content { background: var(--navy); border: 1px solid var(--border); color: var(--text); }
        .modal-header { border-bottom: 1px solid var(--border); }
        .modal-footer { border-top: 1px solid var(--border); }
        .form-control, .form-select { background: rgba(255,255,255,0.05); border: 1px solid var(--border); color: var(--white); border-radius: 12px; }
        .form-control:focus, .form-select:focus { background: rgba(255,255,255,0.08); border-color: var(--orange); box-shadow: 0 0 0 3px rgba(255,102,0,0.1); color: var(--white); }
        .form-label { color: var(--muted); font-weight: 600; }
        .btn-close { filter: invert(1); }
        .sa-badge { display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.35rem 0.9rem; border-radius: 999px; font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; }
        .sa-badge-pending { background: rgba(245,158,11,0.15); color: #f59e0b; border: 1px solid rgba(245,158,11,0.3); }
        .sa-badge-active { background: rgba(16,185,129,0.15); color: #10b981; border: 1px solid rgba(16,185,129,0.3); }
        .sa-table { width: 100%; }
        .sa-table thead th { padding: 0.9rem 1rem; font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); background: rgba(255,255,255,0.02); border-bottom: 1px solid var(--border); }
        .sa-table tbody td { padding: 1rem; border-bottom: 1px solid var(--border); vertical-align: middle; font-size: 0.9rem; }
        .sa-table tbody tr { transition: background 0.2s; } .sa-table tbody tr:hover { background: rgba(255,255,255,0.02); }
        .sa-table tbody tr:last-child td { border-bottom: 0; }
        .sa-btn { padding: 0.5rem 1.25rem; border-radius: 12px; font-size: 0.85rem; font-weight: 600; border: none; cursor: pointer; transition: all 0.25s; }
        .sa-btn-primary { background: linear-gradient(135deg, var(--orange), #e65c00); color: #fff; box-shadow: 0 4px 15px var(--orange-glow); }
        .sa-btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(255,102,0,0.4); }
        .sa-btn-outline { background: transparent; color: var(--text); border: 1px solid var(--border); }
        .sa-btn-outline:hover { border-color: var(--orange); color: var(--orange); }
        .sa-empty { padding: 4rem; text-align: center; color: var(--muted); }
        .sa-empty i { font-size: 3rem; opacity: 0.3; margin-bottom: 1rem; display: block; }
        @stack('styles')
    </style>
</head>
@php
    $logoSetting = \App\Models\SystemSetting::where('key', 'site_logo')->first();
    $logoUrl = ($logoSetting && $logoSetting->value) ? asset('storage/' . $logoSetting->value) : asset('favicon.png');
    $titleArSetting = \App\Models\SystemSetting::where('key', 'site_name_ar')->first();
    $titleEnSetting = \App\Models\SystemSetting::where('key', 'site_name_en')->first();
    $siteTitle = app()->getLocale() == 'ar' ? ($titleArSetting->value ?? 'إديوليرن') : ($titleEnSetting->value ?? 'EduLearn');
@endphp
<body>
    <div class="sa-sidebar-overlay" onclick="toggleSidebar()"></div>
    <div class="sa-sidebar">
        <div class="d-lg-none mb-3 text-end">
            <button class="btn btn-link text-white p-0" onclick="toggleSidebar()">
                <i class="bi bi-x-lg fs-4"></i>
            </button>
        </div>
        <div class="sa-brand">
            <img src="{{ $logoUrl }}" alt="{{ $siteTitle }}" style="object-fit: cover;">
            <div class="sa-brand-text" style="font-size: 1.1rem; line-height: 1.2;">{{ $siteTitle }} <br><span style="font-size: 0.85rem">Admin Dashboard</span></div>
        </div>
        <ul class="sa-nav">
            <li><a href="{{ route('super-admin.dashboard') }}" class="{{ request()->routeIs('super-admin.dashboard') ? 'active' : '' }}"><i class="bi bi-grid-1x2-fill"></i> {{ __('School Management') }}</a></li>
            <li><a href="{{ route('super-admin.analytics.index') }}" class="{{ request()->routeIs('super-admin.analytics*') ? 'active' : '' }}"><i class="bi bi-bar-chart-fill"></i> {{ __('Platform Analytics') }}</a></li>
            <li><a href="{{ route('super-admin.subjects.index') }}" class="{{ request()->routeIs('super-admin.subjects*') ? 'active' : '' }}"><i class="bi bi-book-half"></i> {{ __('Global Subjects') }}</a></li>
            <li><a href="{{ route('super-admin.notifications.index') }}" class="{{ request()->routeIs('super-admin.notifications*') ? 'active' : '' }}"><i class="bi bi-bell-fill"></i> {{ __('Notifications') }}</a></li>
            <li><a href="{{ route('super-admin.support.index') }}" class="{{ request()->routeIs('super-admin.support*') ? 'active' : '' }}"><i class="bi bi-headset"></i> {{ __('Support') }}</a></li>
            <li><a href="{{ route('super-admin.settings.index') }}" class="{{ request()->routeIs('super-admin.settings*') ? 'active' : '' }}"><i class="bi bi-gear-fill"></i> {{ __('Settings') }}</a></li>
            <li class="sa-nav-divider"></li>
            <li>
                <form action="{{ route('logout') }}" method="POST">@csrf
                    <button type="submit" style="color: #ef4444;"><i class="bi bi-box-arrow-right" style="color: #ef4444;"></i> {{ __('Logout') }}</button>
                </form>
            </li>
        </ul>
    </div>

    <div class="sa-main">
        <div class="d-lg-none mb-4 d-flex align-items-center justify-content-between no-print">
            <div class="sa-brand mb-0 p-0">
                <img src="{{ $logoUrl }}" alt="{{ $siteTitle }}" style="width: 32px; height: 32px;">
                <span class="sa-brand-text" style="font-size: 1rem;">{{ $siteTitle }}</span>
            </div>
            <button class="sa-mobile-toggle" onclick="toggleSidebar()">
                <i class="bi bi-list"></i>
            </button>
        </div>
        @if(session('success'))
            <div class="sa-alert sa-alert-success"><i class="bi bi-check-circle-fill fs-5"></i> {{ session('success') }}</div>
        @endif
        @if(session('info'))
            <div class="sa-alert sa-alert-info"><i class="bi bi-info-circle-fill fs-5"></i> {{ session('info') }}</div>
        @endif
        @yield('content')
    </div>

    <script>
        window.API_BASE_URL = @json(rtrim((string) config('app.api_base_url', ''), '/'));
    </script>
    <script src="{{ asset('js/api-client.js') }}"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function toggleSidebar() {
            document.body.classList.toggle('sidebar-open');
        }
    </script>
    @stack('scripts')
</body>
</html>
