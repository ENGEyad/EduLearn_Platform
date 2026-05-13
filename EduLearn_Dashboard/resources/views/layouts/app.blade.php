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
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.rtl.min.css" rel="stylesheet" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/choices.js/public/assets/styles/choices.min.css" />
  <script src="https://cdn.jsdelivr.net/npm/choices.js/public/assets/scripts/choices.min.js"></script>

  <style>
    :root {
      --sidebar-width: 240px;
      --bg: #f0f2f7;
      --card: #ffffff;
      --card-bg: #ffffff;
      --title: #001A33;
      --text: #1f2933;
      --muted: #6b7280;
      --border: #e0e4eb;
      --link: #FF6600;
      --primary: #003366;
      --accent: #FF6600;
      --radius: 14px;
      --radius-lg: 18px;
      --radius-md: 14px;
      --radius-sm: 12px;
      --shadow: 0 1px 2px rgba(16, 24, 40, .06), 0 1px 3px rgba(16, 24, 40, .08);
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

      --btn-info-soft-bg: #e0f2fe;
      --btn-info-soft-text: #0369a1;
      --btn-info-soft-border: #bae6fd;

      /* Notifications */
      --notif-bg-unread: #ffffff;
      --notif-bg-read: #f8f9fa;
      --notif-border-unread: #dee2e6;
      --notif-icon-bg-unread: #e0e7ff;
      /* primary-subtle */
      --notif-icon-bg-read: #f1f5f9;
      /* secondary-subtle */
    }

    /* Dark Mode Variables */
    body.dark-mode {
      --bg: #001020;
      --card: #001A33;
      --card-bg: #001A33;
      --title: #ffffff;
      --text: #e2e8f0;
      --muted: #94a3b8;
      --border: #0d3868;
      --link: #FF8533;
      --primary: #003366;
      --accent: #FF6600;
      --shadow: 0 1px 2px rgba(0, 0, 0, .3);
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

      --btn-info-soft-bg: rgba(14, 165, 233, 0.15);
      --btn-info-soft-text: #ffffff;
      --btn-info-soft-border: rgba(14, 165, 233, 0.3);

      /* Notifications Dark Mode */
      --notif-bg-unread: rgba(56, 189, 248, 0.05);
      --notif-bg-read: rgba(255, 255, 255, 0.02);
      --notif-border-unread: rgba(56, 189, 248, 0.3);
      --notif-icon-bg-unread: rgba(56, 189, 248, 0.15);
      --notif-icon-bg-read: rgba(148, 163, 184, 0.1);
    }

    * {
      box-sizing: border-box;
    }

    body {
      background: var(--bg);
      font-family: "Cairo", system-ui, -apple-system, sans-serif;
      color: var(--text);
      height: 100vh;
      overflow: hidden;
      position: relative;
    }

    /* Ambient Background — global */
    body::before {
      content: '';
      position: fixed;
      inset: 0;
      z-index: 0;
      pointer-events: none;
      background:
        radial-gradient(ellipse 70% 50% at 15% 10%, rgba(0, 51, 102, 0.10) 0%, transparent 55%),
        radial-gradient(ellipse 50% 40% at 85% 30%, rgba(255, 102, 0, 0.07) 0%, transparent 50%),
        radial-gradient(ellipse 60% 50% at 50% 90%, rgba(0, 51, 102, 0.06) 0%, transparent 45%);
    }

    body.dark-mode::before {
      background:
        radial-gradient(ellipse 70% 50% at 15% 10%, rgba(0, 51, 102, 0.25) 0%, transparent 55%),
        radial-gradient(ellipse 50% 40% at 85% 30%, rgba(255, 102, 0, 0.12) 0%, transparent 50%),
        radial-gradient(ellipse 60% 50% at 50% 90%, rgba(0, 51, 102, 0.15) 0%, transparent 45%);
    }

    /* ═══ ANIMATIONS ═══ */
    @keyframes fadeSlideUp {
      from {
        opacity: 0;
        transform: translateY(20px);
      }

      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    @keyframes fadeSlideIn {
      from {
        opacity: 0;
        transform: translateX(-15px);
      }

      to {
        opacity: 1;
        transform: translateX(0);
      }
    }

    .anim-fade-up {
      animation: fadeSlideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
    }

    .anim-delay-1 {
      animation-delay: 0.05s;
    }

    .anim-delay-2 {
      animation-delay: 0.1s;
    }

    .anim-delay-3 {
      animation-delay: 0.15s;
    }

    .anim-delay-4 {
      animation-delay: 0.2s;
    }

    .anim-delay-5 {
      animation-delay: 0.25s;
    }

    .anim-delay-6 {
      animation-delay: 0.3s;
    }

    /* ═══ 3D PERSPECTIVE ═══ */
    .perspective-container {
      perspective: 1000px;
    }

    .tilt-3d {
      transform-style: preserve-3d;
      transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.35s ease;
    }

    .tilt-3d:hover {
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.12), 0 0 0 1px rgba(19, 91, 236, 0.08) !important;
    }

    body.dark-mode .tilt-3d:hover {
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(56, 189, 248, 0.15) !important;
    }

    /* Choices.js Global Premium Styling */
    .choices__inner {
      background: var(--bg) !important;
      border: 1px solid var(--border) !important;
      border-radius: var(--radius-md) !important;
      color: var(--text) !important;
      padding: 8px 12px !important;
      min-height: 48px !important;
      transition: all 0.3s ease !important;
    }
    .is-focused .choices__inner {
      border-color: var(--primary) !important;
      box-shadow: 0 0 0 4px rgba(0, 51, 102, 0.1) !important;
    }
    .choices__list--dropdown {
      background: var(--card) !important;
      border: 1px solid var(--border) !important;
      border-radius: var(--radius-lg) !important;
      box-shadow: 0 15px 35px rgba(0,0,0,0.1) !important;
      z-index: 2000 !important;
      padding: 8px !important;
    }
    body.dark-mode .choices__list--dropdown {
      background: #001A33 !important;
      box-shadow: 0 20px 50px rgba(0,0,0,0.4) !important;
    }
    .choices__list--dropdown .choices__item--selectable.is-highlighted {
      background: var(--accent) !important;
      color: #fff !important;
      border-radius: var(--radius-sm) !important;
    }
    .choices__placeholder { opacity: 1 !important; color: var(--muted) !important; }

    /* Sidebar – Glassmorphism */
    .sidebar {
      position: fixed;
      top: 0;
      width: var(--sidebar-width);
      height: 100vh;
      background: rgba(255, 255, 255, 0.7);
      backdrop-filter: blur(18px) saturate(180%);
      -webkit-backdrop-filter: blur(18px) saturate(180%);
      border-inline-end: 1px solid var(--border);
      padding: 1.5rem 1rem;
      display: flex;
      flex-direction: column;
      overflow-y: auto;
      transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      z-index: 100;
    }

    body.dark-mode .sidebar {
      background: rgba(15, 23, 42, 0.75);
    }

    [dir="rtl"] .sidebar {
      right: 0;
      left: auto;
    }

    [dir="ltr"] .sidebar {
      left: 0;
      right: auto;
    }

    .brand-box {
      display: flex;
      align-items: center;
      gap: .75rem;
      margin-bottom: .5rem;
    }

    .brand-avatar {
      width: 38px;
      height: 38px;
      border-radius: 999px;
      background: #106d63;
      display: grid;
      place-items: center;
      color: #fff;
      font-weight: 600;
      font-size: .7rem;
    }

    .sidebar small {
      color: var(--muted);
    }

    .sidebar .nav a {
      border: 0;
      background: transparent;
      width: 100%;
      text-align: start;
      display: flex;
      gap: .65rem;
      align-items: center;
      padding: .55rem .75rem;
      border-radius: var(--radius-md);
      color: var(--text);
      font-weight: 500;
      font-size: .92rem;
      transition: .15s;
      text-decoration: none;
    }

    .sidebar .nav a .icon-wrap {
      width: 30px;
      height: 30px;
      display: grid;
      place-items: center;
      background: var(--bg);
      border-radius: 10px;
      color: var(--primary);
      transition: .15s;
    }

    body.dark-mode .sidebar .nav a .icon-wrap {
      background: rgba(255, 255, 255, 0.05);
      color: var(--link);
    }

    .sidebar .nav a.active,
    .sidebar .nav a:hover {
      background: var(--primary);
      color: #ffffff;
    }

    .status-pill.active {
      background: #ffffff;
      color: var(--primary);
    }

    .sidebar .nav a.active .icon-wrap,
    .sidebar .nav a:hover .icon-wrap {
      background: rgba(255, 255, 255, 0.2);
      color: #ffffff;
    }

    .sidebar .bottom-links {
      margin-top: auto;
      border-top: 1px solid var(--border);
      padding-top: 1rem;
    }

    /* Main wrapper */
    .main-wrapper {
      height: 100vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    [dir="rtl"] .main-wrapper {
      margin-right: var(--sidebar-width);
      margin-left: 0;
    }

    [dir="ltr"] .main-wrapper {
      margin-left: var(--sidebar-width);
      margin-right: 0;
    }

    .topbar {
      flex-shrink: 0;
      height: 64px;
      background: rgba(255, 255, 255, 0.7);
      backdrop-filter: blur(18px) saturate(180%);
      -webkit-backdrop-filter: blur(18px) saturate(180%);
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 1.5rem;
      transition: background 0.3s ease;
      position: relative;
      z-index: 1000;
    }

    body.dark-mode .topbar {
      background: rgba(30, 41, 59, 0.7);
    }

    .content-area {
      padding: 1rem 1rem 2rem;
      overflow-y: auto;
      flex-grow: 1;
    }

    @media (min-width: 769px) {
      .content-area {
        padding: 1.5rem 1.5rem 2.5rem;
      }
    }

    /* Custom Scrollbar for Content Area */
    .content-area::-webkit-scrollbar {
      width: 8px;
    }

    .content-area::-webkit-scrollbar-track {
      background: transparent;
    }

    .content-area::-webkit-scrollbar-thumb {
      background: rgba(0, 0, 0, 0.1);
      border-radius: 10px;
    }

    body.dark-mode .content-area::-webkit-scrollbar-thumb {
      background: rgba(255, 255, 255, 0.1);
    }

    .content-area::-webkit-scrollbar-thumb:hover {
      background: rgba(0, 0, 0, 0.2);
    }

    body.dark-mode .content-area::-webkit-scrollbar-thumb:hover {
      background: rgba(255, 255, 255, 0.2);
    }

    /* Shared cards used elsewhere */
    .stat-card {
      background: var(--card);
      border-radius: 16px;
      padding: 1.15rem 1.15rem 1.05rem;
      border: 1px solid var(--border);
      box-shadow: var(--shadow-sm);
    }

    .card-panel {
      background: var(--card);
      border-radius: 18px;
      border: 1px solid var(--border);
      padding: 1.15rem 1.15rem 1.1rem;
      box-shadow: var(--shadow-sm);
    }

    .table-shell {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 18px;
      box-shadow: var(--shadow-sm);
      padding: 1rem 1rem .5rem;
    }

    .table-shell thead th {
      font-size: .7rem;
      text-transform: uppercase;
      letter-spacing: .04em;
      color: #94a3b8;
      border-bottom: none;
      background: transparent;
    }

    .status-pill {
      border-radius: 999px;
      padding: .35rem .7rem;
      font-size: .68rem;
      font-weight: 500;
    }

    .status-active {
      background: #d1fae5;
      color: #065f46;
    }

    .status-suspended {
      background: #fee2e2;
      color: #b91c1c;
    }

    .status-graduated {
      background: #dbeafe;
      color: #1e40af;
    }

    .status-inactive {
      background: #e5e7eb;
      color: #374151;
    }

    .profile-shell {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 1rem 1rem .6rem;
      box-shadow: var(--shadow-sm);
      min-height: 400px;
    }

    .profile-header {
      display: flex;
      align-items: center;
      gap: .9rem;
      margin-bottom: .6rem;
    }

    .profile-shell .avatar-circle {
      width: 64px;
      height: 64px;
      border-radius: 999px;
      background: #e8ecff;
      display: grid;
      place-items: center;
      font-weight: 700;
      font-size: 1.15rem;
      color: #1f2937;
    }

    .profile-tabs.nav-tabs {
      border-bottom: 1px solid #eef2f7;
      gap: .4rem;
    }

    .profile-tabs .nav-link {
      border: 0 !important;
      background: transparent !important;
      color: #6b7280;
      padding: .4rem .2rem;
      margin-right: 1rem;
      border-bottom: 2px solid transparent !important;
      font-weight: 500;
    }

    .profile-tabs .nav-link.active {
      color: var(--primary) !important;
      border-bottom-color: var(--primary) !important;
    }

    @media (max-width: 992px) {
      .sidebar {
        width: 210px;
      }

      [dir="rtl"] .main-wrapper {
        margin-right: 210px;
      }

      [dir="ltr"] .main-wrapper {
        margin-left: 210px;
      }
    }

    @media (max-width: 768px) {
      .sidebar {
        position: fixed;
        top: 0;
        bottom: 0;
        width: 260px;
        z-index: 10001;
        overflow-y: auto;
        transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }

      [dir="rtl"] .sidebar {
        right: 0;
        transform: translateX(100%);
      }

      [dir="ltr"] .sidebar {
        left: 0;
        transform: translateX(-100%);
      }

      body.sidebar-open .sidebar {
        transform: translateX(0);
      }

      .sidebar-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        backdrop-filter: blur(4px);
        z-index: 10000;
        display: none;
      }

      body.sidebar-open .sidebar-overlay {
        display: block;
      }

      .main-wrapper {
        margin-right: 0 !important;
        margin-left: 0 !important;
      }

      .topbar {
        padding: 0 1rem;
        gap: 0.5rem;
      }

      .topbar .page-title {
        font-size: 1.1rem;
      }

      .topbar .right-area .dropdown:not(:last-child) {
        display: none !important;
      }
      
      .mobile-toggle {
        display: flex !important;
      }
    }

    .mobile-toggle {
      display: none;
      width: 38px;
      height: 38px;
      align-items: center;
      justify-content: center;
      border: 0;
      background: var(--btn-soft-bg);
      color: var(--primary);
      border-radius: 10px;
      cursor: pointer;
    }

    body.dark-mode .mobile-toggle {
      color: var(--link);
    }

    /* Additional Dark Mode Overrides */
    body.dark-mode .topbar {
      background: var(--card);
      border-bottom: 1px solid var(--border);
    }

    body.dark-mode .dropdown-menu {
      background: var(--card);
      border: 1px solid var(--border);
      color: var(--text);
    }

    body.dark-mode .dropdown-item {
      color: var(--text);
    }

    body.dark-mode .dropdown-item:hover {
      background: rgba(255, 255, 255, 0.05);
      color: var(--link);
    }

    body.dark-mode .dropdown-header {
      background: rgba(255, 255, 255, 0.02) !important;
      color: var(--title) !important;
      border-bottom: 1px solid var(--border) !important;
    }

    body.dark-mode .text-dark {
      color: var(--title) !important;
    }

    body.dark-mode .btn-light {
      background: rgba(255, 255, 255, 0.05);
      color: var(--title);
      border: 0;
    }

    body.dark-mode .btn-light:hover {
      background: rgba(255, 255, 255, 0.1);
      color: var(--title);
    }

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

    .btn-soft-info {
      background-color: var(--btn-info-soft-bg) !important;
      color: var(--btn-info-soft-text) !important;
      border: 1px solid var(--btn-info-soft-border) !important;
    }

    .btn-soft-info:hover {
      background-color: var(--btn-info-soft-bg) !important;
      color: var(--btn-info-soft-text) !important;
      border-color: var(--btn-info-soft-border) !important;
      box-shadow: none !important;
      transform: none !important;
    }



    body.dark-mode .notification-dropdown .bg-light,
    body.dark-mode .bg-light,
    body.dark-mode .bg-white {
      background-color: rgba(255, 255, 255, 0.03) !important;
      color: var(--text) !important;
      border-color: var(--border) !important;
    }

    body.dark-mode .sidebar .bottom-links button {
      color: rgba(255, 255, 255, 0.6) !important;
    }

    body.dark-mode .sidebar .bottom-links button:hover {
      color: #fff !important;
    }

    body.dark-mode #pageSubtitle {
      color: #ffffff !important;
    }

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
      background-color: transparent !important;
      --bs-table-bg: transparent !important;
      --bs-table-color: var(--text) !important;
      --bs-table-border-color: var(--border) !important;
      --bs-table-striped-bg: rgba(255, 255, 255, 0.02) !important;
      /* --bs-table-hover-bg: rgba(255, 255, 255, 0.05) !important; */
    }

    /* Dark Mode Modals Fix */
    body.dark-mode .modal-content {
      background-color: var(--card) !important;
      border: 1px solid var(--border) !important;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5) !important;
      color: var(--text) !important;
    }

    body.dark-mode .modal-header,
    body.dark-mode .modal-footer {
      border-color: var(--border) !important;
      background-color: rgba(255, 255, 255, 0.02) !important;
    }

    body.dark-mode .modal-title {
      color: var(--title) !important;
    }

    body.dark-mode .btn-close {
      filter: invert(1) grayscale(100%) brightness(200%);
    }

    body.dark-mode .modal-backdrop {
      background-color: #000 !important;
    }

    body.dark-mode .modal-backdrop.show {
      opacity: 0.7 !important;
    }

    body.dark-mode .table thead th {
      color: var(--muted) !important;
      border-bottom-color: var(--border) !important;
    }

    body.dark-mode .table tbody td {
      border-bottom-color: var(--border) !important;
    }

    /* Scrollbar Dark Mode Overrides for internal divs */
    body.dark-mode div::-webkit-scrollbar-track {
      background: rgba(255, 255, 255, 0.02) !important;
    }

    body.dark-mode div::-webkit-scrollbar-thumb {
      background: rgba(255, 255, 255, 0.1) !important;
    }

    body.dark-mode div::-webkit-scrollbar-thumb:hover {
      background: rgba(255, 255, 255, 0.2) !important;
    }

    /* Dark Mode SweetAlert2 Fix */
    body.dark-mode .swal2-popup {
      background-color: var(--card) !important;
      color: var(--text) !important;
      border: 1px solid var(--border) !important;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5) !important;
    }

    body.dark-mode .swal2-title,
    body.dark-mode .swal2-content,
    body.dark-mode .swal2-html-container {
      color: var(--text) !important;
    }

    body.dark-mode .swal2-success-circular-line-left,
    body.dark-mode .swal2-success-circular-line-right,
    body.dark-mode .swal2-success-fix {
      background-color: var(--card) !important;
    }

    body.dark-mode .swal2-confirm {
      background-color: var(--primary) !important;
      box-shadow: 0 4px 12px rgba(0, 51, 102, 0.4) !important;
    }

    body.dark-mode .swal2-cancel {
      background-color: rgba(255, 255, 255, 0.05) !important;
      color: #fff !important;
    }

    /* body.dark-mode .table-hover tbody tr:hover {
      background-color: rgba(255, 255, 255, 0.02) !important;
    } */

    /* Disable hover on reports page specifically as requested */
    body.dark-mode .reports-skin table tbody tr:hover,
    /* body.dark-mode .reports-skin .table-hover tbody tr:hover {
      background-color: transparent !important;
    } */

    body.dark-mode .page-link {
      background-color: var(--card) !important;
      border-color: var(--border) !important;
      color: var(--text) !important;
    }

    body.dark-mode .page-link:hover {
      background-color: var(--primary) !important;
      color: #fff !important;
    }

    body.dark-mode .page-item.active .page-link {
      background-color: var(--primary) !important;
      border-color: var(--primary) !important;
      color: #fff !important;
    }

    body.dark-mode .page-item.disabled .page-link {
      background-color: rgba(255, 255, 255, 0.02) !important;
      color: var(--muted) !important;
    }

    body.dark-mode .text-muted {
      color: rgba(255, 255, 255, 0.7) !important;
    }

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

    .reports-skin :root {
      --bg: #f6f7fb;
      --card: #fff;
      --muted: #6b7280;
      --border: #e5e7eb;
      --title: #0f172a;
      --link: #2563eb;
      --shadow: 0 1px 2px rgba(16, 24, 40, .06), 0 1px 3px rgba(16, 24, 40, .08);
      --radius: 14px;
    }

    .reports-skin .content-wrap {
      max-width: 1160px;
      margin-inline: auto;
      padding: 20px 20px 56px
    }

    .reports-skin .page {
      max-width: 1160px;
      margin-inline: auto;
      padding: 20px 20px 56px
    }

    .reports-skin .page-wrap {
      max-width: 1160px;
      margin-inline: auto;
      padding: 20px 20px 56px
    }

    .reports-skin .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 16px
    }

    .reports-skin .page-title {
      font-weight: 800;
      font-size: 28px;
      margin: 0
    }

    .reports-skin .subtitle {
      color: var(--muted);
      font-size: 14px
    }

    .reports-skin .crumbs {
      font-size: 14px;
      color: var(--muted)
    }

    .reports-skin .crumbs .sep {
      margin: 0 .35rem;
      color: #cbd5e1
    }

    /* Buttons */
    .reports-skin .btn {
      border-radius: 12px;
      box-shadow: var(--shadow)
    }

    .reports-skin .btn-primary {
      background: var(--link) !important;
      border-color: var(--link) !important;
      font-weight: 700
    }

    .reports-skin .btn-outline {
      background: #fff;
      color: #1f2937;
      border: 1px solid var(--border)
    }

    .reports-skin .btn-soft {
      background: #eef2ff;
      color: #3949ab;
      border: 1px solid #e0e7ff;
      font-weight: 600;
      border-radius: 12px;
      padding: .6rem .9rem
    }

    .reports-skin .btn-ghost {
      background: #fff;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: .6rem .9rem
    }

    .reports-skin .btn-cta {
      background: #e9f0ff;
      border: 1px solid #dbe6ff;
      color: #0b4de0;
      border-radius: 12px;
      padding: .6rem .9rem;
      font-weight: 700
    }

    /* Filters + Table shells */
    .reports-skin .filters {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 12px;
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      box-shadow: var(--shadow)
    }

    .reports-skin .input-group>.input-group-text {
      background: var(--card);
      border-right: 0;
      border-color: var(--border);
      border-top-left-radius: 10px;
      border-bottom-left-radius: 10px;
      color: var(--text)
    }

    .reports-skin .input-group>.form-control {
      background: var(--card);
      border-left: 0;
      border-color: var(--border);
      border-top-right-radius: 10px;
      border-bottom-right-radius: 10px;
      box-shadow: none;
      color: var(--text)
    }

    .reports-skin .form-select {
      border-radius: 10px;
      border: 1px solid var(--border);
      box-shadow: none;
      background-color: var(--card);
      color: var(--text)
    }

    .reports-skin .form-select:focus,
    .reports-skin .form-control:focus {
      border-color: #c7d2fe;
      box-shadow: 0 0 0 .2rem rgba(37, 99, 235, .08)
    }

    .reports-skin .table-shell {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 8px;
      box-shadow: var(--shadow)
    }

    .reports-skin .table {
      margin: 0
    }

    .reports-skin .table>thead th {
      color: var(--muted);
      font-weight: 600;
      font-size: 12.5px;
      border-bottom: 1px solid var(--border) !important;
      background: transparent
    }

    .reports-skin .table>tbody td {
      vertical-align: middle
    }

    .reports-skin .table>tbody tr:hover {
      background: #f7faff
    }

    .reports-skin .pagination-wrap {
      display: flex;
      justify-content: flex-end
    }

    .reports-skin .pagination .page-link {
      color: var(--title);
      border: 1px solid var(--border);
      background: #fff;
      border-radius: 10px;
      margin: 0 3px;
      box-shadow: var(--shadow)
    }

    .reports-skin .pagination .page-item.active .page-link {
      background: #eef2ff;
      border-color: #dbe6ff;
      color: #0b4de0
    }

    /* Cards + stats */
    .reports-skin .cardy {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow)
    }

    .reports-skin .panel {
      padding: 16px
    }

    .reports-skin .panel h6 {
      font-size: 15px;
      font-weight: 800;
      margin-bottom: 10px
    }

    .reports-skin .stats {
      display: grid;
      grid-template-columns: repeat(5, 1fr);
      gap: 16px;
      margin-top: 14px
    }

    .reports-skin .stat {
      padding: 16px
    }

    .reports-skin .stat .k {
      font-size: 13px;
      color: var(--muted);
      margin-bottom: 6px
    }

    .reports-skin .stat .v {
      font-size: 26px;
      font-weight: 800
    }

    .reports-skin .delta {
      font-size: 12px;
      font-weight: 700;
      margin-top: 4px
    }

    .reports-skin .delta.g {
      color: #16a34a
    }

    .reports-skin .delta.r {
      color: #dc2626
    }

    /* Student header (avatar/pill) */
    .reports-skin .page-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin: 10px 0 14px
    }

    .reports-skin .page-title {
      font-weight: 700;
      font-size: 22px
    }

    .reports-skin .student-head {
      padding: 16px 18px
    }

    .reports-skin .avatar {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: #fde68a;
      display: inline-grid;
      place-items: center;
      font-weight: 700;
      color: #78350f
    }

    .reports-skin .kvs {
      display: flex;
      align-items: center;
      gap: 14px
    }

    .reports-skin .meta .name {
      font-weight: 700
    }

    .reports-skin .meta .sub {
      font-size: 13px;
      color: var(--muted)
    }

    .reports-skin .status-pill {
      margin-left: auto;
      padding: 6px 10px;
      background: #eaf7ef;
      color: #15803d;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 600;
      display: inline-flex;
      align-items: center;
      gap: 6px
    }

    .reports-skin .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #22c55e
    }

    /* Student stats */
    .reports-skin .stats--student {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
      margin-top: 10px
    }

    .reports-skin .stat h6 {
      font-size: 13px;
      color: var(--muted);
      margin: 0 0 8px
    }

    .reports-skin .stat .val {
      font-size: 28px;
      font-weight: 800
    }

    /* Charts rows + wrappers */
    .reports-skin .row-charts {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 16px;
      margin-top: 12px
    }

    .reports-skin .chart-wrap {
      position: relative;
      height: 220px
    }

    /* Mini stats + achievements (Chemistry page style) */
    .reports-skin .mini-two {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px
    }

    .reports-skin .stat-mini {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px
    }

    .reports-skin .icn-badge {
      width: 42px;
      height: 42px;
      border-radius: 12px;
      background: #eef2ff;
      display: grid;
      place-items: center;
      color: #3856e8;
      font-size: 20px
    }

    .reports-skin .stat-mini .label {
      font-size: 13px;
      color: var(--muted);
      margin-bottom: 2px
    }

    .reports-skin .stat-mini .val {
      font-size: 26px;
      font-weight: 800
    }

    .reports-skin .trend-note {
      font-size: 13px;
      color: #16a34a;
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 6px
    }

    .reports-skin .trend-note .muted {
      color: var(--muted);
      font-weight: 600
    }

    .reports-skin .muted {
      color: var(--muted)
    }

    .reports-skin .section-title {
      font-weight: 800;
      font-size: 16px;
      margin: 2px 0 8px
    }

    .reports-skin .ach-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px
    }

    .reports-skin .ach-card {
      padding: 18px;
      display: flex;
      align-items: center;
      gap: 14px;
      border: 1px dashed #e2e8f0;
      border-radius: 12px
    }

    .reports-skin .ach-icn {
      width: 46px;
      height: 46px;
      border-radius: 50%;
      display: grid;
      place-items: center
    }

    .reports-skin .ach-icn.star {
      background: #fff7e6;
      color: #d97706
    }

    .reports-skin .ach-icn.book {
      background: #e6fffa;
      color: #059669
    }

    .kv-row {
      display: flex;
      justify-content: space-between;
      font-size: .82rem;
      margin-bottom: .25rem;
    }

    .kv-label {
      color: var(--muted);
    }

    .kv-value {
      font-weight: 500;
    }

    /* Badges + links */
    .reports-skin .badge-pass {
      background: #e8f7ee;
      color: #118d57;
      font-weight: 700
    }

    .reports-skin .badge-fail {
      background: #fee2e2;
      color: #be123c;
      font-weight: 700
    }

    .reports-skin .action-link {
      color: var(--link);
      font-weight: 600;
      text-decoration: none
    }

    /* Responsive */
    @media (max-width:1100px) {
      .reports-skin .stats {
        grid-template-columns: repeat(3, 1fr)
      }
    }

    @media (max-width:992px) {
      .reports-skin .row-charts {
        grid-template-columns: 1fr
      }

      .reports-skin .mini-two {
        grid-template-columns: 1fr
      }
    }

    @media (max-width:720px) {
      .reports-skin .stats {
        grid-template-columns: repeat(2, 1fr)
      }
    }

    @media (max-width:560px) {
      .reports-skin .kvs {
        align-items: flex-start
      }

      .reports-skin .status-pill {
        margin-left: 0
      }
    }

    /* Print */
    @media print {

      .reports-skin .no-print,
      .reports-skin .filters {
        display: none !important
      }

      body {
        background: #fff
      }

      .reports-skin .content-wrap,
      .reports-skin .page,
      .reports-skin .page-wrap {
        max-width: 100%;
        padding: 0
      }

      .reports-skin .cardy,
      .reports-skin .table-shell {
        box-shadow: none
      }
    }
  </style>
</head>

<body class="{{ ($themeMode ?? 'light') == 'dark' ? 'dark-mode' : '' }}">

  <!-- Global Loading Bar -->
  <div id="global-loader" class="progress"
    style="position: fixed; top: 0; left: 0; right: 0; height: 3px; z-index: 10001; display: none; border-radius: 0; background-color: rgba(255,255,255,0.1);">
    <div class="progress-bar progress-bar-striped progress-bar-animated bg-accent" role="progressbar"
      style="width: 100%"></div>
  </div>

  <script>
    window.API_BASE_URL = @json(rtrim((string) config('app.api_base_url', ''), '/'));
  </script>
  <script src="{{ asset('js/api-client.js') }}"></script>

  <script>
    window.loadingManager = {
      loader: null,
      activeRequests: 0,
      start: function () {
        if (!this.loader) this.loader = document.getElementById('global-loader');
        this.activeRequests++;
        if (this.loader) this.loader.style.display = 'flex';
      },
      stop: function (results) {
        if (!this.loader) this.loader = document.getElementById('global-loader');
        this.activeRequests = Math.max(0, this.activeRequests - 1);

        if (this.activeRequests === 0 && this.loader) {
          this.loader.style.display = 'none';
        }

        // Only show the summary modal if results (counts) are explicitly provided (usually from imports)
        if (results && (results.success !== undefined || results.failed !== undefined)) {
          if (window.Swal) {
            Swal.fire({
              title: window.I18N?.importResults || 'Import Results',
              html: `
                            <div class="text-start">
                                <div class="mb-2"><span class="badge bg-success me-2">${results.success || 0}</span> ${window.I18N?.successful || 'Successful'}</div>
                                <div class="mb-0"><span class="badge bg-danger me-2">${results.failed || 0}</span> ${window.I18N?.failed || 'Failed'}</div>
                            </div>
                        `,
              icon: (results.failed > 0) ? 'warning' : 'success',
              confirmButtonText: window.I18N?.ok || 'OK'
            });
          }
        }
      }
    };

    // Global Fetch Interceptor
    const originalFetch = window.fetch;
    window.fetch = function () {
      // Prepare Toast Helper
      const showToast = (title, icon) => {
        if (window.Swal) {
          const Toast = Swal.mixin({
            toast: true,
            position: 'top-end',
            showConfirmButton: false,
            timer: 3000,
            timerProgressBar: true,
            didOpen: (toast) => {
              toast.addEventListener('mouseenter', Swal.stopTimer)
              toast.addEventListener('mouseleave', Swal.resumeTimer)
            }
          });
          Toast.fire({ icon, title });
        }
      };

      window.loadingManager.start();

      // Exclude showing the "fetching" message for some specific calls like background polls if needed,
      // but by default show it for all as requested.
      const requestUrl = arguments[0] || '';
      const isImport = typeof requestUrl === 'string' && requestUrl.includes('/import');

      if (!isImport) {
        showToast(window.I18N?.fetchingData || 'جاري مزامنة البيانات مع السيرفر...', 'info');
      }

      return originalFetch.apply(this, arguments).then(response => {
        const isImport = response.url.includes('/import');
        const contentType = response.headers.get("content-type");

        if (contentType && contentType.includes("application/json")) {
          return response.clone().json().then(data => {
            window.loadingManager.stop(data);

            // Show success toast for non-import JSON requests that succeeded
            if (response.ok && !isImport) {
              const method = response.url.includes('?') ? 'GET' : 'POST/PUT/DELETE';
              // Only show success for non-GET requests (like save, update, delete) to avoid spamming on page loads
              // But since user requested "when I move to any screen that has data loading", let's show it for GET if they want.
              // Actually, showing "Data loaded successfully" on every GET request (like fetching student list) can be annoying.
              // Let's show it for all for now, as requested: "اريد ان تظهر معها رسالة نجاح تحميل او فشل"
              if (data && data.message) {
                showToast(data.message, 'success');
              } else if (arguments[0] && (typeof arguments[0] === 'string' && arguments[0].includes('?t='))) {
                showToast(window.I18N?.dataLoaded || 'تم تحميل البيانات بنجاح', 'success');
              }
            } else if (!response.ok) {
              showToast(data.message || 'حدث خطأ', 'error');
            }
            return response;
          }).catch(() => {
            window.loadingManager.stop();
            if (!response.ok) showToast('Error response received', 'error');
            return response;
          });
        }

        window.loadingManager.stop();
        if (response.ok && !isImport && response.headers.get("content-type")?.includes("html")) {
          // Ignore HTML page loads
        } else if (!response.ok) {
          showToast('Request failed', 'error');
        }
        return response;
      }).catch(error => {
        window.loadingManager.stop();
        showToast('Connection error', 'error');
        throw error;
      });
    };
  </script>

  <!-- Print-only Header -->
  <div class="d-none d-print-block mb-4 border-bottom pb-3" id="globalPrintHeader">
    <div class="d-flex align-items-center justify-content-between">
      <div class="d-flex align-items-center gap-3">
        @php
          $sysLogo = \App\Models\SystemSetting::where('key', 'site_logo')->first();
          $sysLogoUrl = ($sysLogo && $sysLogo->value) ? asset('storage/' . $sysLogo->value) : asset('favicon.png');
          $sysTitleAr = \App\Models\SystemSetting::where('key', 'site_name_ar')->first();
          $sysTitleEn = \App\Models\SystemSetting::where('key', 'site_name_en')->first();
          $sysTitle = app()->getLocale() == 'ar' ? ($sysTitleAr->value ?? 'إديوليرن') : ($sysTitleEn->value ?? 'EduLearn');

          $school = auth()->user()?->school;
          $schoolLogo = ($school && $school->logo_path) ? asset('storage/' . $school->logo_path) : null;
          $schoolName = $school?->name ?? $sysTitle;
        @endphp
        @if($schoolLogo)
          <img src="{{ $schoolLogo }}" alt="Logo" width="60" height="60" style="object-fit:cover; border-radius: 8px;">
        @else
          <div class="brand-avatar" style="width:60px; height:60px; font-size: 1.5rem;">
            {{ mb_substr($schoolName, 0, 1) }}
          </div>
        @endif
        <div>
          <h3 class="mb-0 fw-bold text-dark">{{ $schoolName }}</h3>
          <p class="mb-0 text-muted">{{ auth()->user()?->school?->academic_year ?? '' }}</p>
        </div>
      </div>
      <div class="text-end">
        <h4 class="mb-1 fw-bold text-primary" id="printReportTitle">REPORT</h4>
        <p class="mb-0 text-muted" id="printReportDate">{{ now()->format('Y-m-d') }}</p>
      </div>
    </div>
  </div>

  <!-- Sidebar Overlay -->
  <div class="sidebar-overlay" onclick="toggleSidebar()"></div>

  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="brand-box">
      @if($schoolLogo)
        <img src="{{ $schoolLogo }}" alt="School Logo" width="38" height="38" style="border-radius:12px;object-fit:cover;"
          loading="lazy">
      @else
        <div class="brand-avatar">
          {{ mb_substr($schoolName, 0, 1) }}
        </div>
      @endif
      <div>
        <div class="fw-semibold text-truncate" style="max-width: 150px;">{{ $schoolName }}</div>
        <small>{{ auth()->user()?->school?->academic_year ?? __('Dashboard') }}</small>
      </div>
    </div>

    <nav class="nav flex-column gap-1" id="sidebarNav">
      <a href="{{ url('/') }}" class="{{ request()->is('/') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-grid-1x2"></i></span>
        <span>{{ __('Dashboard') }}</span>
      </a>
      @branchCan('manage_students')
      <a href="{{ url('/students') }}" class="{{ request()->is('students*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-person-lines-fill"></i></span>
        <span>{{ __('Students') }}</span>
      </a>
      @endbranchCan
      @branchCan('manage_teachers')
      <a href="{{ url('/teachers') }}" class="{{ request()->is('teachers*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-person-badge"></i></span>
        <span>{{ __('Teachers') }}</span>
      </a>
      @endbranchCan
      @branchCan('manage_classes')
      <a href="{{ url('/classes') }}" class="{{ request()->is('classes*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-journal-text"></i></span>
        <span>{{ __('Classes') }}</span>
      </a>
      @endbranchCan
      @branchCan('manage_subjects')
      <a href="{{ url('/subjects') }}" class="{{ request()->is('subjects*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-journal-bookmark"></i></span>
        <span>{{ __('Subjects') }}</span>
      </a>
      @endbranchCan


      @branchCan('manage_subjects')
      <a href="{{ url('/class-subjects') }}" class="{{ request()->is('class-subjects*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-journal-check"></i></span>
        <span>{{ __('Class Subjects') }}</span>
      </a>
      @endbranchCan

      @branchCan('manage_subjects')
      <a href="{{ url('/assignments') }}" class="{{ request()->is('assignments*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-diagram-3"></i></span>
        <span>{{ __('Assignments') }}</span>
      </a>
      @endbranchCan
      @branchCan('view_reports')
      <a href="{{ url('/reports') }}" class="{{ request()->is('reports*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-bar-chart"></i></span>
        <span>{{ __('Reports') }}</span>
      </a>
      @endbranchCan
      <a href="{{ url('/notifications') }}" class="{{ request()->is('notifications*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-bell"></i></span>
        <span>{{ __('Notifications') }}</span>
      </a>
      @if(auth()->user()->isSchoolAdmin() || auth()->user()->isSuperAdmin())
        <a href="{{ route('settings.branches.index') }}"
          class="{{ request()->is('settings/branches*') ? 'active' : '' }}">
          <span class="icon-wrap"><i class="bi bi-diagram-2"></i></span>
          <span>{{ __('Branches') }}</span>
        </a>
      @endif

      @branchCan('manage_settings')
      <a href="{{ route('settings.index') }}" class="{{ request()->is('settings*') ? 'active' : '' }}">
        <span class="icon-wrap"><i class="bi bi-gear"></i></span>
        <span>{{ __('Settings') }}</span>
      </a>
      @endbranchCan
    </nav>


    <div class="bottom-links">
      <a href="{{ route('support.index') }}"
        class="w-100 d-flex align-items-center gap-2 border-0 bg-transparent text-start text-muted mb-2 text-decoration-none {{ request()->is('support*') ? 'text-primary fw-bold' : '' }}">
        <i class="bi bi-question-circle"></i> {{ __('Help') }}
      </a>
      <button class="w-100 d-flex align-items-center gap-2 border-0 bg-transparent text-start text-muted"
        onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
        <i class="bi bi-box-arrow-left"></i> {{ __('Logout') }}
      </button>
      <form id="logout-form" action="{{ route('logout') }}" method="POST" style="display: none;">@csrf</form>
    </div>
  </aside>

  <!-- MAIN WRAPPER -->
  <div class="main-wrapper">
    <header class="topbar">
      <div class="d-flex align-items-center gap-2">
        <button class="mobile-toggle" onclick="toggleSidebar()" type="button">
          <i class="bi bi-list fs-4"></i>
        </button>
        <div>
          <div class="page-title text-truncate" id="pageTitle" style="max-width: 150px;">{{ $pageTitle ?? __('Dashboard') }}</div>
          <small class="text-muted d-none d-sm-block"
            id="pageSubtitle">{{ $pageSubtitle ?? __('Welcome, :name', ['name' => auth()->user()->name]) }}</small>
        </div>
      </div>
      <div class="right-area d-flex align-items-center gap-3">
        <!-- Theme Switcher -->
        <form id="theme-toggle-form" action="{{ route('settings.preferences.update') }}" method="POST" class="d-none">
          @csrf
          <input type="hidden" name="theme_mode" value="{{ ($themeMode ?? 'light') == 'dark' ? 'light' : 'dark' }}">
          <input type="hidden" name="language" value="{{ app()->getLocale() }}">
        </form>
        <button class="btn btn-light border-0 d-flex align-items-center justify-content-center"
          style="width: 38px; height: 38px;" type="button"
          onclick="document.getElementById('theme-toggle-form').submit();" title="{{ __('Toggle Theme') }}">
          @if(($themeMode ?? 'light') == 'dark')
            <i class="bi bi-sun fs-5 text-warning"></i>
          @else
            <i class="bi bi-moon-stars fs-5 text-primary"></i>
          @endif
        </button>

        <!-- Language Switcher -->
        <div class="dropdown">
          <button class="btn btn-light border-0 dropdown-toggle d-flex align-items-center gap-2" type="button"
            id="langSwitcher" data-bs-toggle="dropdown" aria-expanded="false">
            @if(app()->getLocale() == 'ar')
              <span class="fs-6">🇸🇦</span> {{ __('Arabic') }}
            @else
              <span class="fs-6">🇺🇸</span> {{ __('English') }}
            @endif
          </button>
          <ul
            class="dropdown-menu {{ app()->getLocale() == 'en' ? 'dropdown-menu-start' : 'dropdown-menu-end' }} shadow-sm border-0"
            aria-labelledby="langSwitcher">
            <li>
              <a class="dropdown-item small d-flex align-items-center gap-2" href="{{ route('locale.switch', 'en') }}">
                <span class="fs-6">🇺🇸</span> English ({{ __('English') }})
              </a>
            </li>
            <li>
              <a class="dropdown-item small d-flex align-items-center gap-2" href="{{ route('locale.switch', 'ar') }}">
                <span class="fs-6">🇸🇦</span> العربية ({{ __('Arabic') }})
              </a>
            </li>
          </ul>
        </div>

        <div class="dropdown">
          <button class="btn btn-light border-0 dropdown-toggle" type="button" id="timeFilterBtn"
            data-bs-toggle="dropdown" aria-expanded="false">
            {{ $periodLabel ?? __('This Week') }}
          </button>
          <ul
            class="dropdown-menu {{ app()->getLocale() == 'en' ? 'dropdown-menu-start' : 'dropdown-menu-end' }} shadow-sm border-0"
            aria-labelledby="timeFilterBtn">
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('today')">{{ __('Today') }}</a></li>
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('week')">{{ __('This Week') }}</a></li>
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('month')">{{ __('This Month') }}</a></li>
            <li><a class="dropdown-item small" href="#" onclick="updateFilter('year')">{{ __('This Year') }}</a></li>
          </ul>
        </div>
        <div class="dropdown">
          <button class="btn position-relative btn-link text-dark border-0 p-0" type="button" id="notificationDropdown"
            data-bs-toggle="dropdown" aria-expanded="false">
            <i class="bi bi-bell fs-5"></i>
            @if($unreadNotificationsCount > 0)
              <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger"
                style="font-size: 0.65rem; padding: 0.25em 0.5em;">
                {{ $unreadNotificationsCount > 9 ? '9+' : $unreadNotificationsCount }}
              </span>
            @endif
          </button>

          <div class="dropdown-menu dropdown-menu-end shadow-lg border-0 p-0 notification-dropdown"
            aria-labelledby="notificationDropdown">
            <div class="dropdown-header border-bottom px-3 py-2 d-flex justify-content-between align-items-center">
              <span class="fw-bold text-dark">{{ __('Recent Notifications') }}</span>
              <a href="{{ route('notifications.markAllRead') }}" class="text-decoration-none small text-primary"
                onclick="event.preventDefault(); document.getElementById('mark-all-read-form-mini').submit();">{{ __('Mark all as read') }}</a>
              <form id="mark-all-read-form-mini" action="{{ route('notifications.markAllRead') }}" method="POST"
                style="display: none;">@csrf</form>
            </div>

            <div class="notification-scroll-area" style="max-height: 400px; overflow-y: auto;">
              @if($headerNotifications->isEmpty())
                <div class="p-4 text-center">
                  <i class="bi bi-bell-slash text-muted opacity-50 display-6 d-block mb-2"></i>
                  <small class="text-muted">{{ __('No notifications currently') }}</small>
                </div>
              @else
                @foreach($headerNotifications as $notif)
                  <a href="{{ route('notifications.index') }}"
                    class="dropdown-item notification-item px-3 py-3 border-bottom {{ $notif->is_read ? 'notif-item-read' : 'notif-item-unread' }}">
                    <div class="d-flex align-items-start gap-2">
                      <i class="bi {{ $notif->icon ?? 'bi-info-circle' }} p-1 {{ $notif->is_read ? 'notif-icon-read text-secondary' : 'notif-icon-unread text-primary' }} rounded"
                        style="font-size: 1.1rem;"></i>
                      <div class="flex-grow-1 overflow-hidden">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                          <div class="fw-bold small text-truncate" style="max-width: 140px;">
                            {{ __($notif->title, $notif->data ?? []) }}</div>
                          <small class="text-muted opacity-75"
                            style="font-size: 0.65rem;">{{ $notif->created_at->diffForHumans() }}</small>
                        </div>
                        <p class="mb-0 text-muted mini-notif-msg" style="font-size: 0.78rem;">
                          {{ __($notif->message, $notif->data ?? []) }}</p>
                      </div>
                    </div>
                  </a>
                @endforeach
              @endif
            </div>

            <div class="p-3 dropdown-footer text-center">
              <a href="{{ route('notifications.index') }}"
                class="text-primary text-decoration-none small fw-bold">{{ __('View All') }}</a>
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
      width: 360px;
      margin-top: 12px;
      border-radius: 18px !important;
      border: 1px solid rgba(var(--border-rgb, 0, 0, 0), 0.1);
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.15) !important;
      backdrop-filter: blur(20px) saturate(180%);
      -webkit-backdrop-filter: blur(20px) saturate(180%);
      background-color: rgba(255, 255, 255, 0.85) !important;
      overflow: hidden;
    }

    body.dark-mode .notification-dropdown {
      background-color: rgba(30, 41, 59, 0.85) !important;
      border-color: rgba(255, 255, 255, 0.1) !important;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.4) !important;
    }

    .notification-item {
      transition: all 0.2s ease;
      position: relative;
    }

    .notification-item:hover {
      background-color: rgba(0, 0, 0, 0.03) !important;
      transform: scale(0.985);
    }

    body.dark-mode .notification-item:hover {
      background-color: rgba(255, 255, 255, 0.03) !important;
    }

    .mini-notif-msg {
      max-width: 280px;
      line-height: 1.4;
    }

    .notification-scroll-area::-webkit-scrollbar {
      width: 4px;
    }

    .notification-scroll-area::-webkit-scrollbar-thumb {
      background: rgba(0, 0, 0, 0.1);
      border-radius: 4px;
    }

    body.dark-mode .notification-scroll-area::-webkit-scrollbar-thumb {
      background: rgba(255, 255, 255, 0.1);
    }

    .dropdown-footer {
      background: rgba(var(--bg-rgb, 248, 249, 250), 0.5);
      border-top: 1px solid var(--border);
    }
  </style>

  <!-- Scripts -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" defer></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js" defer></script>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11" defer></script>
  <script src="https://cdn.jsdelivr.net/npm/pusher-js@8.3.0/dist/web/pusher.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/laravel-echo@1.16.1/dist/echo.iife.js"></script>

  <script>
    // ═══ 3D Card Tilt Effect ═══
    document.addEventListener('DOMContentLoaded', function () {
      document.querySelectorAll('.stat-card, .card-panel, .table-shell').forEach(function (card) {
        card.classList.add('tilt-3d');
        card.addEventListener('mousemove', function (e) {
          var rect = card.getBoundingClientRect();
          var x = e.clientX - rect.left;
          var y = e.clientY - rect.top;
          var centerX = rect.width / 2;
          var centerY = rect.height / 2;
          var rotateX = ((y - centerY) / centerY) * -4;
          var rotateY = ((x - centerX) / centerX) * 4;
          card.style.transform = 'rotateX(' + rotateX + 'deg) rotateY(' + rotateY + 'deg) translateY(-4px)';
        });
        card.addEventListener('mouseleave', function () {
          card.style.transform = 'rotateX(0) rotateY(0) translateY(0)';
        });
      });
    });

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

    document.addEventListener('DOMContentLoaded', function () {
      const reverbEnabled = @json((bool) env('REVERB_FRONTEND_ENABLED', false));
      const reverbConfigured = @json((bool) (env('REVERB_APP_KEY') && env('REVERB_PORT')));
      const reverbHost = @json(env('REVERB_HOST'));

      // Initialize Laravel Echo for Reverb only when explicitly enabled.
      if (reverbEnabled && reverbConfigured && reverbHost && typeof Echo !== 'undefined') {
        window.Echo = new Echo({
          broadcaster: 'reverb',
          key: "{{ env('REVERB_APP_KEY') }}",
          wsHost: reverbHost,
          wsPort: "{{ env('REVERB_PORT') }}",
          wssPort: "{{ env('REVERB_PORT') }}",
          forceTLS: "{{ env('REVERB_SCHEME') }}" === 'https',
          enabledTransports: ['ws', 'wss'],
        });

        // Listen for Global/School Specific events
        @if(auth()->check() && auth()->user()->school_id)
          window.Echo.private("school.{{ auth()->user()->school_id }}")
            .listen('SchoolStatusUpdated', (e) => {
              console.log('Real-time update:', e);

              Swal.fire({
                title: 'Status Update',
                text: e.message,
                icon: e.status === 'active' ? 'success' : (e.status === 'rejected' ? 'error' : 'info'),
                confirmButtonText: 'OK',
                timer: 10000,
                timerProgressBar: true
              }).then(() => {
                if (e.status === 'active') window.location.reload();
              });
            });
        @endif

        // Global System Alerts (Broadcasting for all roles)
        window.Echo.channel("notifications.all")
          .listen('.system.alert', (data) => {
            showSystemNotification(data.notification);
          });

        // Role-Specific Alerts
        @if(auth()->check())
          window.Echo.channel("notifications.{{ auth()->user()->role }}")
            .listen('.system.alert', (data) => {
              showSystemNotification(data.notification);
            });
        @endif
        }
    });

    function showSystemNotification(notif) {
      // Track the view immediately
      fetch(`/super-admin/notifications/${notif.id}/track-read`, {
        method: 'POST',
        headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}', 'Accept': 'application/json' }
      });

      Swal.fire({
        title: notif.title,
        text: notif.message,
        icon: notif.priority === 'urgent' ? 'error' : (notif.priority === 'high' ? 'warning' : 'info'),
        showConfirmButton: notif.action_url ? true : false,
        confirmButtonText: "{{ __('View Details') }}",
        footer: '<small class="text-muted">{{ __('Official System Alert') }}</small>',
        toast: notif.priority === 'normal',
        position: notif.priority === 'normal' ? 'top-end' : 'center',
        timer: notif.priority === 'normal' ? 6000 : null,
        timerProgressBar: true,
        background: document.body.classList.contains('dark-mode') ? '#1e293b' : '#fff',
        color: document.body.classList.contains('dark-mode') ? '#fff' : '#000',
      }).then((result) => {
        if (result.isConfirmed && notif.action_url) {
          // Track the interaction (click)
          fetch(`/super-admin/notifications/${notif.id}/track-read`, {
            method: 'POST',
            headers: {
              'X-CSRF-TOKEN': '{{ csrf_token() }}',
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: JSON.stringify({ interacted: true })
          });
          window.open(notif.action_url, '_blank');
        }
      });
    }

  </script>
  @stack('scripts')
  <script>
    function toggleSidebar() {
      document.body.classList.toggle('sidebar-open');
    }

    // Auto-close sidebar on window resize if open
    window.addEventListener('resize', () => {
      if (window.innerWidth > 768 && document.body.classList.contains('sidebar-open')) {
        document.body.classList.remove('sidebar-open');
      }
    });
  </script>
</body>
</html>
