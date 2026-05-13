<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('Force Password Change') }} | EduLearn</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.rtl.min.css" rel="stylesheet"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css"/>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Cairo', sans-serif;
            background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .security-card {
            max-width: 500px;
            width: 100%;
            background: #ffffff;
            border-radius: 24px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.08);
            overflow: hidden;
            border: 1px solid #f1f5f9;
        }
        .security-header {
            background: #135bec;
            color: #ffffff;
            padding: 40px 30px;
            text-align: center;
        }
        .security-icon {
            width: 70px;
            height: 70px;
            background: rgba(255,255,255,0.2);
            border-radius: 50%;
            display: grid;
            place-items: center;
            font-size: 2rem;
            margin: 0 auto 20px;
        }
        .security-body {
            padding: 40px;
        }
        .form-control {
            border-radius: 12px;
            padding: 12px 18px;
            border: 1px solid #e2e8f0;
            background: #f8fafc;
            transition: all 0.2s ease;
        }
        .form-control:focus {
            background: #ffffff;
            border-color: #135bec;
            box-shadow: 0 0 0 4px rgba(19, 91, 236, 0.1);
        }
        .btn-primary {
            background: #135bec;
            border: none;
            border-radius: 12px;
            padding: 14px;
            font-weight: 700;
            box-shadow: 0 4px 12px rgba(19, 91, 236, 0.2);
        }
        .btn-primary:hover {
            background: #0d47a1;
            transform: translateY(-2px);
        }
        .password-requirement {
            font-size: 0.82rem;
            color: #64748b;
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .password-requirement i {
            font-size: 1rem;
        }
    </style>
</head>
<body>

<div class="security-card">
    <div class="security-header">
        <div class="security-icon">
            <i class="bi bi-shield-lock-fill"></i>
        </div>
        <h3 class="fw-bold mb-2">{{ __('Mandatory Security Update') }}</h3>
        <p class="text-white-50 mb-0">{{ __('يرجى تحديث كلمة المرور المؤقتة لمتابعة استخدام النظام') }}</p>
    </div>

    <div class="security-body">
        @if(session('warning'))
            <div class="alert alert-warning border-0 shadow-sm mb-4 small">
                {{ session('warning') }}
            </div>
        @endif

        @if($errors->any())
            <div class="alert alert-danger border-0 shadow-sm mb-4">
                <ul class="mb-0 small">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('auth.force-password-change.update') }}" method="POST">
            @csrf
            
            <div class="mb-4">
                <label class="form-label fw-bold">{{ __('Current Temporary Password') }}</label>
                <div class="input-group">
                    <span class="input-group-text bg-transparent border-end-0"><i class="bi bi-key text-muted"></i></span>
                    <input type="password" name="current_password" class="form-control border-start-0" placeholder="{{ __('Temporary credentials') }}" required autofocus>
                </div>
            </div>

            <div class="mb-4">
                <label class="form-label fw-bold">{{ __('New Secure Password') }}</label>
                <div class="input-group">
                    <span class="input-group-text bg-transparent border-end-0"><i class="bi bi-lock text-muted"></i></span>
                    <input type="password" name="password" class="form-control border-start-0" placeholder="{{ __('New Password') }}" required>
                </div>
                <div class="mt-3">
                    <div class="password-requirement"><i class="bi bi-check-circle text-success"></i> {{ __('Minimum 8 characters') }}</div>
                </div>
            </div>

            <div class="mb-5">
                <label class="form-label fw-bold">{{ __('Confirm New Password') }}</label>
                <div class="input-group">
                    <span class="input-group-text bg-transparent border-end-0"><i class="bi bi-lock-check text-muted"></i></span>
                    <input type="password" name="password_confirmation" class="form-control border-start-0" placeholder="{{ __('Confirm password') }}" required>
                </div>
            </div>

            <button type="submit" class="btn btn-primary w-100 mb-3">
                <i class="bi bi-check-circle-fill me-2"></i> {{ __('Update and Continue') }}
            </button>

            <div class="text-center mt-4">
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="btn btn-link text-muted text-decoration-none small">
                        <i class="bi bi-box-arrow-left me-1"></i> {{ __('Log out and cancel update') }}
                    </button>
                </form>
            </div>
        </form>
    </div>
</div>

</body>
</html>
