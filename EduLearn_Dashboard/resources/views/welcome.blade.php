<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="EduLearn – The next-generation school management platform. AI-powered analytics, real-time tracking, and seamless administration.">
  <title>EduLearn – Smart School Platform</title>
  <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900&family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css"/>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    :root {
      --bg-deep: #001020;
      --bg-card: rgba(0,26,51,0.55);
      --border: rgba(255,255,255,0.08);
      --navy: #003366;
      --navy-light: #004080;
      --orange: #FF6600;
      --orange-light: #FF8533;
      --orange-glow: rgba(255,102,0,0.3);
      --text: #e2e8f0;
      --muted: #94a3b8;
      --white: #ffffff;
    }
    html { scroll-behavior: smooth; }
    body {
      font-family: {{ app()->getLocale() == 'ar' ? "'Cairo', sans-serif" : "'Inter', sans-serif" }};
      background: var(--bg-deep);
      color: var(--text);
      overflow-x: hidden;
      min-height: 100vh;
    }

    /* ═══ AMBIENT BG ═══ */
    .ambient-bg {
      position: fixed; inset: 0; z-index: 0; pointer-events: none;
      background:
        radial-gradient(ellipse 80% 60% at 20% 10%, rgba(0,51,102,0.25) 0%, transparent 60%),
        radial-gradient(ellipse 60% 50% at 80% 30%, rgba(255,102,0,0.12) 0%, transparent 55%),
        radial-gradient(ellipse 70% 70% at 50% 90%, rgba(0,51,102,0.15) 0%, transparent 50%);
    }
    .orb {
      position: fixed; border-radius: 50%; filter: blur(80px); opacity: 0.35;
      animation: orbFloat 20s ease-in-out infinite alternate;
      pointer-events: none; z-index: 0;
    }
    .orb-1 { width: 500px; height: 500px; background: rgba(0,51,102,0.4); top: -10%; left: -5%; }
    .orb-2 { width: 400px; height: 400px; background: rgba(255,102,0,0.2); top: 50%; right: -10%; animation-delay: -7s; }
    .orb-3 { width: 350px; height: 350px; background: rgba(0,64,128,0.25); bottom: -5%; left: 30%; animation-delay: -14s; }
    @keyframes orbFloat {
      0% { transform: translate(0,0) scale(1); }
      33% { transform: translate(30px,-40px) scale(1.05); }
      66% { transform: translate(-20px,20px) scale(0.95); }
      100% { transform: translate(10px,-10px) scale(1.02); }
    }
    .grid-pattern {
      position: fixed; inset: 0; z-index: 0; pointer-events: none;
      background-image:
        linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px);
      background-size: 60px 60px;
    }

    /* ═══ NAV ═══ */
    .landing-nav {
      position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
      padding: 1rem 2rem;
      display: flex; align-items: center; justify-content: space-between;
      background: rgba(0,16,32,0.6);
      backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
      border-bottom: 1px solid var(--border);
      transition: all 0.3s ease;
    }
    .landing-nav.scrolled { background: rgba(0,16,32,0.92); box-shadow: 0 10px 40px rgba(0,0,0,0.4); }
    .nav-brand { display: flex; align-items: center; gap: 0.75rem; text-decoration: none; }
    .nav-brand-icon {
      width: 40px; height: 40px; border-radius: 12px;
      overflow: hidden;
    }
    .nav-brand-icon img { width: 100%; height: 100%; object-fit: cover; border-radius: 12px; }
    .nav-brand-text {
      font-size: 1.4rem; font-weight: 800; letter-spacing: -0.02em;
      background: linear-gradient(135deg, #4da6ff, var(--orange));
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    }
    .nav-links { display: flex; align-items: center; gap: 0.5rem; }
    .nav-links a {
      padding: 0.6rem 1.25rem; border-radius: 12px;
      text-decoration: none; font-weight: 600; font-size: 0.9rem;
      transition: all 0.25s ease; border: 1px solid transparent;
    }
    .nav-link-ghost { color: var(--muted); }
    .nav-link-ghost:hover { color: var(--white); background: rgba(255,255,255,0.05); }
    .nav-link-outline { color: var(--white); border: 1px solid var(--border); }
    .nav-link-outline:hover { border-color: var(--orange); color: var(--orange); }
    .nav-link-primary {
      color: #fff;
      background: linear-gradient(135deg, var(--orange), #e65c00);
      box-shadow: 0 4px 15px var(--orange-glow);
    }
    .nav-link-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(255,102,0,0.4); }

    /* ═══ HERO ═══ */
    .hero {
      position: relative; z-index: 1;
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
      padding: 7rem 2rem 4rem; text-align: center;
    }
    .hero-inner { max-width: 860px; }
    .hero-badge {
      display: inline-flex; align-items: center; gap: 0.5rem;
      padding: 0.5rem 1.25rem; border-radius: 999px;
      background: rgba(255,102,0,0.1); border: 1px solid rgba(255,102,0,0.25);
      color: var(--orange-light); font-size: 0.8rem; font-weight: 600;
      margin-bottom: 2rem;
      animation: fadeSlideUp 0.8s cubic-bezier(0.16,1,0.3,1) 0.1s both;
    }
    .hero-badge .pulse-dot {
      width: 8px; height: 8px; border-radius: 50%; background: var(--orange);
      animation: pulse 2s ease-in-out infinite;
    }
    @keyframes pulse { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:0.5; transform:scale(0.8); } }

    .hero h1 {
      font-size: clamp(2.5rem,6vw,4.5rem); font-weight: 900;
      line-height: 1.1; letter-spacing: -0.03em;
      margin-bottom: 1.5rem;
      animation: fadeSlideUp 0.8s cubic-bezier(0.16,1,0.3,1) 0.2s both;
    }
    .hero h1 .gradient-text {
      background: linear-gradient(135deg, #4da6ff, var(--orange), var(--orange-light));
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      background-size: 200% auto;
      animation: gradientShift 4s ease-in-out infinite;
    }
    @keyframes gradientShift { 0%,100% { background-position:0% center; } 50% { background-position:100% center; } }

    .hero-sub {
      font-size: clamp(1rem,2vw,1.2rem); color: var(--muted);
      max-width: 600px; margin: 0 auto 2.5rem; line-height: 1.7;
      animation: fadeSlideUp 0.8s cubic-bezier(0.16,1,0.3,1) 0.35s both;
    }
    .hero-actions {
      display: flex; flex-wrap: wrap; gap: 1rem; justify-content: center;
      animation: fadeSlideUp 0.8s cubic-bezier(0.16,1,0.3,1) 0.5s both;
    }
    .btn-hero {
      padding: 1rem 2.5rem; border-radius: 16px; font-weight: 700;
      font-size: 1rem; text-decoration: none;
      display: inline-flex; align-items: center; gap: 0.6rem;
      transition: all 0.3s cubic-bezier(0.4,0,0.2,1);
      border: none; cursor: pointer;
    }
    .btn-hero-primary {
      color: #fff;
      background: linear-gradient(135deg, var(--orange), #e65c00);
      box-shadow: 0 8px 30px var(--orange-glow);
    }
    .btn-hero-primary:hover { transform: translateY(-3px) scale(1.02); box-shadow: 0 15px 40px rgba(255,102,0,0.45); }
    .btn-hero-secondary {
      color: var(--white);
      background: rgba(0,51,102,0.4);
      border: 1px solid rgba(0,100,200,0.3);
      backdrop-filter: blur(10px);
    }
    .btn-hero-secondary:hover { background: rgba(0,51,102,0.6); border-color: rgba(0,150,255,0.4); transform: translateY(-3px); }
    @keyframes fadeSlideUp { from { opacity:0; transform:translateY(30px); } to { opacity:1; transform:translateY(0); } }

    /* ═══ FEATURES ═══ */
    .floating-showcase {
      position: relative; z-index: 1;
      padding: 4rem 2rem 6rem; max-width: 1200px; margin: 0 auto;
    }
    .showcase-heading { text-align: center; margin-bottom: 3rem; }
    .showcase-heading h2 { font-size: clamp(1.8rem,3.5vw,2.5rem); font-weight: 800; margin-bottom: 0.75rem; }
    .showcase-heading p { color: var(--muted); font-size: 1.05rem; max-width: 500px; margin: 0 auto; }
    .features-grid {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 1.5rem;
    }
    .feature-card {
      background: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: 24px; padding: 2rem;
      backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
      transition: all 0.4s cubic-bezier(0.4,0,0.2,1);
      position: relative; overflow: hidden;
      transform-style: preserve-3d; perspective: 800px;
    }
    .feature-card::before {
      content: ''; position: absolute; inset: 0; border-radius: 24px;
      background: linear-gradient(135deg, rgba(0,51,102,0.08), rgba(255,102,0,0.04));
      opacity: 0; transition: opacity 0.4s ease;
    }
    .feature-card:hover::before { opacity: 1; }
    .feature-card:hover {
      transform: translateY(-8px) rotateX(2deg) rotateY(-2deg);
      border-color: rgba(255,102,0,0.3);
      box-shadow: 0 20px 60px rgba(255,102,0,0.1), 0 0 0 1px rgba(255,102,0,0.1);
    }
    .feature-icon {
      width: 56px; height: 56px; border-radius: 16px;
      display: grid; place-items: center; font-size: 1.5rem;
      margin-bottom: 1.25rem; position: relative; z-index: 1;
    }
    .fi-navy { background: rgba(0,51,102,0.2); color: #4da6ff; }
    .fi-orange { background: rgba(255,102,0,0.15); color: var(--orange); }
    .fi-green { background: rgba(16,185,129,0.12); color: #10b981; }
    .fi-amber { background: rgba(245,158,11,0.12); color: #f59e0b; }
    .fi-pink { background: rgba(236,72,153,0.12); color: #ec4899; }
    .fi-teal { background: rgba(20,184,166,0.12); color: #14b8a6; }
    .feature-card h3 { font-size: 1.15rem; font-weight: 700; margin-bottom: 0.5rem; position: relative; z-index: 1; }
    .feature-card p { color: var(--muted); font-size: 0.9rem; line-height: 1.6; position: relative; z-index: 1; }

    /* ═══ CHARTS ═══ */
    .charts-section {
      position: relative; z-index: 1;
      padding: 2rem 2rem 4rem; max-width: 1200px; margin: 0 auto;
    }
    .charts-grid {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr));
      gap: 1.5rem;
    }
    .chart-card {
      background: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: 24px; padding: 1.75rem;
      backdrop-filter: blur(12px);
    }
    .chart-card h3 { font-size: 1rem; font-weight: 700; margin-bottom: 1rem; display: flex; align-items: center; gap: 0.5rem; }
    .chart-card h3 i { color: var(--orange); }
    .chart-wrap { position: relative; height: 220px; }

    /* ═══ STATS ═══ */
    .stats-section { position: relative; z-index: 1; padding: 4rem 2rem; margin: 0 auto; max-width: 1000px; }
    .stats-bar {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 1.5rem; text-align: center;
      padding: 2.5rem; border-radius: 24px;
      background: var(--bg-card); border: 1px solid var(--border);
      backdrop-filter: blur(12px);
    }
    .stat-item h3 {
      font-size: 2.5rem; font-weight: 900; letter-spacing: -0.02em;
      background: linear-gradient(135deg, #4da6ff, var(--orange));
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    }
    .stat-item p { color: var(--muted); font-size: 0.85rem; margin-top: 0.3rem; font-weight: 500; }

    /* ═══ CTA ═══ */
    .cta-section { position: relative; z-index: 1; padding: 6rem 2rem; text-align: center; }
    .cta-card {
      max-width: 700px; margin: 0 auto; padding: 3.5rem 2.5rem;
      border-radius: 32px;
      background: linear-gradient(135deg, rgba(0,51,102,0.2), rgba(255,102,0,0.08));
      border: 1px solid rgba(255,102,0,0.15);
      backdrop-filter: blur(16px);
    }
    .cta-card h2 { font-size: 2rem; font-weight: 800; margin-bottom: 1rem; }
    .cta-card p { color: var(--muted); margin-bottom: 2rem; font-size: 1.05rem; }

    /* ═══ FOOTER ═══ */
    .landing-footer {
      position: relative; z-index: 1;
      padding: 2rem; text-align: center;
      border-top: 1px solid var(--border);
      color: var(--muted); font-size: 0.8rem;
    }

    /* ═══ RESPONSIVE ═══ */
    @media (max-width: 768px) {
      .landing-nav { padding: 0.75rem 1rem; }
      .nav-brand-text { font-size: 1.2rem; }
      .nav-brand-icon { width: 32px; height: 32px; }
      .nav-links { gap: 0.5rem; }
      .nav-links a { padding: 0.5rem 0.85rem; font-size: 0.75rem; border-radius: 10px; }
      .hero { padding: 6.5rem 1.25rem 3rem; }
      .hero h1 { font-size: 2.5rem; }
      .hero-sub { font-size: 0.95rem; margin-bottom: 2rem; }
      .hero-actions { flex-direction: column; align-items: stretch; width: 100%; max-width: 320px; margin: 0 auto; }
      .btn-hero { justify-content: center; width: 100%; padding: 1rem 1.5rem; }
      .stats-bar { grid-template-columns: repeat(2, 1fr); padding: 1.5rem; gap: 1rem; }
      .stat-item h3 { font-size: 1.6rem; }
      .charts-grid { grid-template-columns: 1fr; }
      .cta-card { padding: 2.5rem 1.5rem; }
      .cta-card h2 { font-size: 1.5rem; }
    }
    .lang-pill {
      padding: 0.4rem 0.8rem; border-radius: 8px; font-size: 0.78rem;
      color: var(--muted); text-decoration: none; font-weight: 600;
      transition: all 0.2s ease; border: 1px solid transparent;
    }
    .lang-pill:hover { color: var(--white); border-color: var(--border); }
  </style>
</head>
<body>

<div class="ambient-bg"></div>
<div class="orb orb-1"></div>
<div class="orb orb-2"></div>
<div class="orb orb-3"></div>
<div class="grid-pattern"></div>

<!-- ═══ NAV ═══ -->
<nav class="landing-nav" id="landingNav">
  <a href="{{ url('/') }}" class="nav-brand">
    <div class="nav-brand-icon"><img src="{{ asset('favicon.png') }}" alt="EduLearn"></div>
    <span class="nav-brand-text">EduLearn</span>
  </a>
  <div class="nav-links">
    @if(app()->getLocale() == 'ar')
      <a href="{{ route('locale.switch', 'en') }}" class="lang-pill">English 🇺🇸</a>
    @else
      <a href="{{ route('locale.switch', 'ar') }}" class="lang-pill">العربية 🇸🇦</a>
    @endif
    <a href="{{ route('login') }}" class="nav-link-primary" id="mainEntryNav">
      <i class="bi bi-rocket-takeoff"></i> {{ __('Get Started') }}
    </a>
  </div>

</nav>

<!-- ═══ HERO ═══ -->
<section class="hero">
  <div class="hero-inner">
    <div class="hero-badge">
      <span class="pulse-dot"></span>
      {{ __('Next-Generation School Platform') }}
    </div>
    <h1>
      {{ __('Manage Your School') }}<br>
      <span class="gradient-text">{{ __('Smarter & Faster') }}</span>
    </h1>
    <p class="hero-sub">
      {{ __('An integrated educational platform powered by AI analytics, real-time student tracking, and seamless administration tools for modern schools.') }}
    </p>
    <div class="hero-actions" style="justify-content: center;">
      <a href="{{ route('login') }}" class="btn-hero btn-hero-primary" style="min-width: 240px; justify-content: center;">
        <i class="bi bi-rocket-takeoff-fill"></i>
        {{ __('Get Started Now') }}
      </a>
    </div>

  </div>
</section>

<!-- ═══ FEATURES ═══ -->
<section class="floating-showcase">
  <div class="showcase-heading">
    <h2>{{ __('Everything You Need') }}</h2>
    <p>{{ __('Powerful tools designed for modern educational institutions') }}</p>
  </div>
  <div class="features-grid">
    <div class="feature-card">
      <div class="feature-icon fi-navy"><i class="bi bi-mortarboard"></i></div>
      <h3>{{ __('Student Management') }}</h3>
      <p>{{ __('Comprehensive student profiles, enrollment tracking, and academic records all in one place.') }}</p>
    </div>
    <div class="feature-card">
      <div class="feature-icon fi-orange"><i class="bi bi-stars"></i></div>
      <h3>{{ __('AI-Powered Analytics') }}</h3>
      <p>{{ __('Get intelligent insights and predictions about student performance powered by Gemini AI.') }}</p>
    </div>
    <div class="feature-card">
      <div class="feature-icon fi-green"><i class="bi bi-graph-up-arrow"></i></div>
      <h3>{{ __('Real-time Reports') }}</h3>
      <p>{{ __('Instant performance reports, attendance analytics, and comprehensive class-level breakdowns.') }}</p>
    </div>
    <div class="feature-card">
      <div class="feature-icon fi-amber"><i class="bi bi-people"></i></div>
      <h3>{{ __('Teacher & Staff') }}</h3>
      <p>{{ __('Manage teacher assignments, class schedules, and staff availability with flexible tools.') }}</p>
    </div>
    <div class="feature-card">
      <div class="feature-icon fi-pink"><i class="bi bi-phone"></i></div>
      <h3>{{ __('Mobile App') }}</h3>
      <p>{{ __('Students learn on-the-go with our Flutter mobile app — exercises, lessons, and AI tutoring.') }}</p>
    </div>
    <div class="feature-card">
      <div class="feature-icon fi-teal"><i class="bi bi-shield-lock"></i></div>
      <h3>{{ __('Secure & Multi-tenant') }}</h3>
      <p>{{ __('Enterprise-grade security with complete data isolation for every school and branch.') }}</p>
    </div>
  </div>
</section>

<!-- ═══ CHARTS ═══ -->
<section class="charts-section">
  <div class="showcase-heading">
    <h2>{{ __('Platform Growth') }}</h2>
    <p>{{ __('Real-time metrics from the EduLearn ecosystem') }}</p>
  </div>
  <div class="charts-grid">
    <div class="chart-card">
      <h3><i class="bi bi-graph-up"></i> {{ __('Monthly Enrollments') }}</h3>
      <div class="chart-wrap"><canvas id="enrollChart"></canvas></div>
    </div>
    <div class="chart-card">
      <h3><i class="bi bi-pie-chart"></i> {{ __('Distribution by Stage') }}</h3>
      <div class="chart-wrap"><canvas id="stageChart"></canvas></div>
    </div>
    <div class="chart-card">
      <h3><i class="bi bi-bar-chart-line"></i> {{ __('Student Performance') }}</h3>
      <div class="chart-wrap"><canvas id="perfChart"></canvas></div>
    </div>
  </div>
</section>

<!-- ═══ STATS ═══ -->
<section class="stats-section">
  <div class="stats-bar">
    <div class="stat-item">
      <h3><span class="count-up" data-target="500">0</span>+</h3>
      <p>{{ __('Schools Onboarded') }}</p>
    </div>
    <div class="stat-item">
      <h3><span class="count-up" data-target="25000">0</span>+</h3>
      <p>{{ __('Active Students') }}</p>
    </div>
    <div class="stat-item">
      <h3><span class="count-up" data-target="3000">0</span>+</h3>
      <p>{{ __('Teachers') }}</p>
    </div>
    <div class="stat-item">
      <h3><span class="count-up" data-target="98">0</span>%</h3>
      <p>{{ __('Uptime') }}</p>
    </div>
  </div>
</section>

<!-- ═══ CTA ═══ -->
<section class="cta-section">
  <div class="cta-card">
    <h2>{{ __('Ready to Transform Your School?') }}</h2>
    <p>{{ __('Join hundreds of schools already using EduLearn to deliver better education outcomes.') }}</p>
    <div class="hero-actions" style="justify-content: center;">
      <a href="{{ route('login') }}" class="btn-hero btn-hero-primary" style="margin: 0 auto;">
        <i class="bi bi-rocket-takeoff-fill"></i>
        {{ __('Get Started Free') }}
      </a>
    </div>

  </div>
</section>

<footer class="landing-footer">
  <p>&copy; {{ date('Y') }} EduLearn Platform. {{ __('All rights reserved.') }}</p>
</footer>

<script>
  // Nav scroll
  const nav = document.getElementById('landingNav');
  window.addEventListener('scroll', () => nav.classList.toggle('scrolled', window.scrollY > 50));

  // Intersection Observer fade-in
  const observer = new IntersectionObserver(entries => {
    entries.forEach(e => { if (e.isIntersecting) e.target.style.opacity = '1'; });
  }, { threshold: 0.1 });
  document.querySelectorAll('.feature-card, .chart-card, .stats-bar, .cta-card').forEach(el => {
    el.style.opacity = '0'; el.style.transition = 'opacity 0.8s ease, transform 0.8s ease';
    observer.observe(el);
  });

  // Count-up
  const countObs = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const el = entry.target, target = parseInt(el.dataset.target), dur = 2000, start = performance.now();
        const step = now => { const p = Math.min((now-start)/dur,1); el.textContent = Math.floor((1-Math.pow(1-p,3))*target).toLocaleString(); if(p<1) requestAnimationFrame(step); };
        requestAnimationFrame(step); countObs.unobserve(el);
      }
    });
  }, { threshold: 0.5 });
  document.querySelectorAll('.count-up').forEach(el => countObs.observe(el));

  // 3D tilt
  document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('mousemove', e => {
      const r = card.getBoundingClientRect(), x = e.clientX-r.left, y = e.clientY-r.top;
      card.style.transform = `translateY(-8px) rotateX(${(y-r.height/2)/r.height*-6}deg) rotateY(${(x-r.width/2)/r.width*6}deg)`;
    });
    card.addEventListener('mouseleave', () => { card.style.transform = ''; });
  });

  // ═══ CHARTS ═══
  const chartDefaults = { color: '#94a3b8', borderColor: 'transparent' };
  Chart.defaults.color = '#94a3b8';

  // Enrollment Line Chart
  new Chart(document.getElementById('enrollChart'), {
    type: 'line',
    data: {
      labels: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
      datasets: [{
        label: 'Schools',
        data: [12,25,38,52,75,95,110,140,185,230,310,500],
        borderColor: '#FF6600',
        backgroundColor: 'rgba(255,102,0,0.08)',
        tension: 0.4, fill: true, pointRadius: 3, pointBackgroundColor: '#FF6600',
        borderWidth: 2.5
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { font: { size: 10 } } },
        y: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { font: { size: 10 } } }
      }
    }
  });

  // Stage Doughnut
  new Chart(document.getElementById('stageChart'), {
    type: 'doughnut',
    data: {
      labels: ['{{ __("Elementary") }}', '{{ __("Preparatory/Secondary") }}', '{{ __("Composite (Primary to Secondary)") }}'],
      datasets: [{
        data: [45, 35, 20],
        backgroundColor: ['#003366', '#FF6600', '#4da6ff'],
        borderWidth: 0, hoverOffset: 12
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false, cutout: '65%',
      plugins: { legend: { position: 'bottom', labels: { padding: 16, usePointStyle: true, font: { size: 11 } } } }
    }
  });

  // Performance Bar
  new Chart(document.getElementById('perfChart'), {
    type: 'bar',
    data: {
      labels: ['{{ __("Arabic") }}', '{{ __("English") }}', 'Math', 'Science', 'Social'],
      datasets: [{
        label: '{{ __("Average Score") }}',
        data: [78, 82, 71, 85, 76],
        backgroundColor: ['#003366','#FF6600','#4da6ff','#10b981','#f59e0b'],
        borderRadius: 8, barPercentage: 0.6
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { font: { size: 10 } } },
        y: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { font: { size: 10 } }, max: 100 }
      }
    }
  });
</script>
</body>
</html>
