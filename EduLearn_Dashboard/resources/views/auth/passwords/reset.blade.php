<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('Reset Password') }} - EduLearn Platform</title>
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900&family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css"/>
    <style>
        :root {
            --bg-deep: #001020;
            --navy: #001A33;
            --navy-light: #003366;
            --orange: #FF6600;
            --orange-glow: rgba(255,102,0,0.3);
            --text: #e2e8f0;
            --muted: #94a3b8;
            --border: rgba(255,255,255,0.08);
            --card-bg: rgba(0, 26, 51, 0.65);
            --transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: {{ app()->getLocale() == 'ar' ? "'Cairo', sans-serif" : "'Inter', sans-serif" }};
            background: var(--bg-deep);
            color: var(--text);
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
            padding: 20px;
            overflow-x: hidden;
            position: relative;
        }

        body::before {
            content: ''; position: fixed; inset: 0; z-index: 0; pointer-events: none;
            background:
                radial-gradient(ellipse 70% 50% at 15% 10%, rgba(0,51,102,0.25) 0%, transparent 55%),
                radial-gradient(ellipse 50% 40% at 85% 30%, rgba(255,102,0,0.1) 0%, transparent 50%);
        }
        body::after {
            content: ''; position: fixed; inset: 0; z-index: 0; pointer-events: none;
            background-image: linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px),
                              linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px);
            background-size: 60px 60px;
        }

        .auth-card {
            background: var(--card-bg);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid var(--border);
            border-radius: 32px;
            padding: 48px;
            width: 100%;
            max-width: 480px;
            box-shadow: 0 40px 80px -20px rgba(0,0,0,0.6);
            position: relative;
            z-index: 1;
            animation: fadeIn 0.8s cubic-bezier(0.16, 1, 0.3, 1);
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .auth-logo {
            display: flex; align-items: center; justify-content: center; gap: 12px;
            text-decoration: none; margin-bottom: 32px;
        }
        .auth-logo i {
            width: 48px; height: 48px; border-radius: 14px;
            background: var(--orange); color: #fff;
            display: grid; place-items: center; font-size: 1.5rem;
            box-shadow: 0 8px 20px var(--orange-glow);
        }
        .auth-logo span {
            font-size: 2rem; font-weight: 900;
            background: linear-gradient(135deg, #fff, var(--orange));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }

        .auth-header { text-align: center; margin-bottom: 32px; }
        .auth-header h1 { font-size: 1.5rem; font-weight: 800; color: #fff; margin-bottom: 8px; }
        .auth-header p { color: var(--muted); font-size: 0.9rem; line-height: 1.5; }

        .field-group { margin-bottom: 24px; }
        .field-label {
            display: block; font-size: 0.85rem; font-weight: 700;
            color: var(--muted); margin-bottom: 10px; text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .field-input {
            width: 100%; background: rgba(255,255,255,0.05);
            border: 1px solid var(--border); border-radius: 16px;
            padding: 16px 20px; color: #fff; font-size: 1rem;
            transition: var(--transition);
        }
        .field-input:focus {
            outline: none; border-color: var(--orange);
            background: rgba(255,255,255,0.08);
            box-shadow: 0 0 0 4px rgba(255,102,0,0.15);
        }

        .submit-btn {
            width: 100%; border: none; border-radius: 16px;
            padding: 18px; font-weight: 800; font-size: 1.05rem;
            color: #fff; cursor: pointer; transition: var(--transition);
            background: linear-gradient(135deg, var(--orange), #e65c00);
            box-shadow: 0 8px 30px var(--orange-glow);
            margin-top: 10px;
        }
        .submit-btn:hover { transform: translateY(-3px) scale(1.02); box-shadow: 0 15px 40px rgba(255,102,0,0.45); }
        
        .alert-box {
            padding: 14px 18px; border-radius: 16px; font-size: 0.9rem;
            margin-bottom: 24px; border: 1px solid transparent;
            display: flex; align-items: center; gap: 12px;
        }
        .alert-error { background: rgba(239, 68, 68, 0.1); border-color: rgba(239, 68, 68, 0.2); color: #f87171; }

        @media (max-width: 600px) {
            .auth-card { padding: 32px 24px; }
        }
    </style>
</head>
<body>
    <div class="auth-card">
        <a href="{{ url('/') }}" class="auth-logo">
            <i class="bi bi-rocket-takeoff-fill"></i>
            <span>EduLearn</span>
        </a>

        <div class="auth-header">
            <h1>{{ __('Reset Password') }}</h1>
            <p>{{ __('Enter your new password below to regain access to your account.') }}</p>
        </div>

        @if($errors->any())
            <div class="alert-box alert-error">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <div>{{ $errors->first() }}</div>
            </div>
        @endif

        <form action="{{ route('password.update') }}" method="POST">
            @csrf
            <input type="hidden" name="token" value="{{ $token }}">

            <div class="field-group">
                <label class="field-label">{{ __('Email Address') }}</label>
                <input type="email" name="email" class="field-input" value="{{ $email ?? old('email') }}" required readonly>
            </div>

            <div class="field-group">
                <label class="field-label">{{ __('New Password') }}</label>
                <input type="password" name="password" class="field-input" placeholder="••••••••" required autofocus>
            </div>

            <div class="field-group">
                <label class="field-label">{{ __('Confirm Password') }}</label>
                <input type="password" name="password_confirmation" class="field-input" placeholder="••••••••" required>
            </div>
            
            <button type="submit" class="submit-btn">
                {{ __('Reset Password') }}
            </button>
        </form>
    </div>
</body>
</html>
