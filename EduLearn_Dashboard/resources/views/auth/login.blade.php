<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('Welcome') }} - EduLearn Platform</title>
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800;900&family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/choices.js/public/assets/styles/choices.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/choices.js/public/assets/scripts/choices.min.js"></script>
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
            --card-bg: rgba(0,26,51,0.65);
            --transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: {{ app()->getLocale() == 'ar' ? "'Cairo', sans-serif" : "'Inter', sans-serif" }};
            background: var(--bg-deep);
            color: var(--text);
            min-height: 100vh;
            overflow-x: hidden;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            padding: 40px 20px;
        }


        /* ═══ AMBIENT BG ═══ */
        .ambient-bg { position: fixed; inset: 0; z-index: -1; pointer-events: none; }
        .orb {
            position: absolute; border-radius: 50%; filter: blur(80px); opacity: 0.25;
            animation: orbFloat 25s ease-in-out infinite alternate;
        }
        .orb-1 { width: 600px; height: 600px; background: var(--navy-light); top: -10%; left: -5%; }
        .orb-2 { width: 500px; height: 500px; background: var(--orange); bottom: -10%; right: -5%; animation-delay: -10s; }
        @keyframes orbFloat {
            0% { transform: translate(0,0) scale(1); }
            100% { transform: translate(50px, -50px) scale(1.1); }
        }

        /* ═══ AUTH CARD ═══ */
        .auth-container {
            width: 100%; max-width: 520px; padding: 20px;
            transition: max-width 0.6s cubic-bezier(0.77, 0, 0.175, 1);
        }
        .auth-container.is-register { max-width: 850px; }

        .auth-card {
            background: var(--card-bg);
            backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px);
            border: 1px solid var(--border);
            border-radius: 32px;
            padding: 40px;
            box-shadow: 0 40px 80px -20px rgba(0,0,0,0.6);
            overflow: hidden;
            position: relative;
        }

        .auth-card::before {
            content: '';
            position: absolute; inset: 0; border-radius: 32px;
            background: linear-gradient(120deg, transparent, rgba(255,102,0,0.08), transparent);
            opacity: 0; transition: 0.5s; pointer-events: none;
        }
        .auth-card:hover::before { opacity: 1; }

        .auth-header { text-align: center; margin-bottom: 32px; }
        
        /* Branded Logo Button Correction */
        .auth-logo {
            font-size: 2.2rem; font-weight: 950; letter-spacing: -0.03em;
            background: linear-gradient(135deg, #fff 30%, var(--orange));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            margin: 0; display: inline-flex; align-items: center; gap: 10px;
            text-decoration: none; transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }

        .auth-logo:hover { transform: scale(1.05); }
        .auth-logo i { font-size: 1.8rem; background: var(--orange); -webkit-text-fill-color: white; padding: 8px; border-radius: 12px; box-shadow: 0 4px 15px var(--orange-glow); }

        .toggle-wrap {


            background: rgba(255,255,255,0.04);
            padding: 5px; border-radius: 16px;
            display: inline-flex; position: relative;
            border: 1px solid var(--border);
            margin: 0 auto;
        }
        .toggle-btn {
            position: relative; z-index: 1; min-width: 140px;
            padding: 10px 24px; border: none; background: transparent;
            color: var(--muted); font-weight: 700; font-size: 0.9rem;
            cursor: pointer; transition: color 0.3s;
            border-radius: 12px;
        }
        .toggle-btn.active { color: #fff; }
        .toggle-pill {
            position: absolute; top: 5px; inset-inline-start: 5px;
            height: calc(100% - 10px); width: calc(50% - 5px);
            background: linear-gradient(135deg, var(--orange), #cc5200);
            border-radius: 12px; transition: transform 0.6s cubic-bezier(0.77, 0, 0.175, 1);
            box-shadow: 0 4px 15px var(--orange-glow);
        }
        .is-register .toggle-pill { transform: translateX(100%); }
        [dir="rtl"] .is-register .toggle-pill { transform: translateX(-100%); }

        /* Forms Pane */
        .forms-wrapper {
            display: flex; width: 200%;
            transition: transform 0.6s cubic-bezier(0.77, 0, 0.175, 1);
            will-change: transform;
        }
        .is-register .forms-wrapper { transform: translateX(-50%); }
        [dir="rtl"] .is-register .forms-wrapper { transform: translateX(50%); }

        .form-pane {
            width: 50%; opacity: 1;
            transition: opacity 0.4s ease;
        }
        .is-register .login-pane { opacity: 0; pointer-events: none; }
        .register-pane { opacity: 0; pointer-events: none; }
        .is-register .register-pane { opacity: 1; pointer-events: auto; }

        /* Inputs */
        .field-group { margin-bottom: 20px; }
        .field-label {
            display: block; font-size: 0.85rem; font-weight: 700;
            color: var(--muted); margin-bottom: 8px; text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .field-input {
            width: 100%; background: rgba(255,255,255,0.04);
            border: 1px solid var(--border); border-radius: 16px;
            padding: 16px 20px; color: #fff; font-size: 0.95rem;
            transition: all 0.4s cubic-bezier(0.165, 0.84, 0.44, 1);
            display: block;
        }
        .field-input:focus {
            outline: none; border-color: var(--orange);
            background: rgba(255,255,255,0.07);
            box-shadow: 0 0 0 4px rgba(255,102,0,0.12);
            transform: translateY(-1px);
        }
        .field-select {
            cursor: pointer;
        }

        .submit-btn {
            width: 100%; border: none; border-radius: 14px;
            padding: 16px; font-weight: 800; font-size: 1rem;
            color: #fff; cursor: pointer; transition: all 0.3s;
            background: linear-gradient(135deg, var(--orange), #cc5200);
            box-shadow: 0 8px 30px rgba(255,102,0,0.25);
            margin-top: 10px; position: relative;
        }
        .submit-btn:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 15px 40px rgba(255,102,0,0.4); }
        .submit-btn:disabled { opacity: 0.7; cursor: not-allowed; }
        .submit-btn .spinner-border {
            width: 1.2rem; height: 1.2rem; border-width: 0.2em;
            display: none; position: absolute; left: 50%; top: 50%; margin: -0.6rem 0 0 -0.6rem;
        }
        .submit-btn.loading .btn-text { visibility: hidden; }
        .submit-btn.loading .spinner-border { display: block; }

        .text-link { color: var(--orange); text-decoration: none; font-weight: 600; cursor: pointer; }
        .text-link:hover { text-decoration: underline; }
        .alert-box {
            padding: 12px 16px; border-radius: 14px; font-size: 0.9rem;
            margin-bottom: 24px; border: 1px solid transparent;
            display: flex; align-items: center; gap: 10px;
        }
        .alert-error { background: rgba(239, 68, 68, 0.1); border-color: rgba(239, 68, 68, 0.2); color: #f87171; }
        .alert-success { background: rgba(34, 197, 94, 0.1); border-color: rgba(34, 197, 94, 0.2); color: #4ade80; }

        /* Corrected Logo Upload Button */
        .logo-preview-box {
            width: 100px; height: 100px; border-radius: 24px; background: rgba(255,255,255,0.05);
            border: 2px dashed var(--border); display: flex; align-items: center; justify-content: center;
            margin: 0 auto 12px; cursor: pointer; overflow: hidden; position: relative;
            transition: var(--transition);
        }
        .logo-preview-box:hover { border-color: var(--orange); background: rgba(255,102,0,0.05); transform: translateY(-3px); }
        .logo-preview-box img { width: 100%; height: 100%; object-fit: cover; }
        .logo-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; opacity: 0; transition: 0.3s; }
        .logo-preview-box:hover .logo-overlay { opacity: 1; }
        
        .upload-badge {
            display: inline-flex; align-items: center; gap: 8px;
            padding: 6px 16px; border-radius: 999px;
            background: rgba(255,102,0,0.1); border: 1px solid rgba(255,102,0,0.2);
            color: var(--orange); font-weight: 700; font-size: 0.75rem;
            text-transform: uppercase; letter-spacing: 0.05em; transition: 0.3s;
        }
        .logo-preview-box:hover + .upload-badge { background: var(--orange); color: #fff; }


        .lang-switch { position: fixed; top: 30px; right: 30px; z-index: 100; }
        [dir="rtl"] .lang-switch { right: auto; left: 30px; }
        .lang-link { color: var(--muted); text-decoration: none; font-weight: 600; font-size: 0.85rem; padding: 8px 16px; border-radius: 10px; background: rgba(255,255,255,0.05); transition: 0.3s; }
        .lang-link:hover { color: #fff; background: rgba(255,255,255,0.1); }

        .register-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }

        @media (max-width: 768px) { .register-grid { grid-template-columns: 1fr; } .auth-container.is-register { max-width: 520px; } }
        @media (max-width: 600px) {
            .auth-card { padding: 25px; }
            .toggle-btn { min-width: 120px; padding: 8px 14px; font-size: 0.8rem; }
        }

        /* Choices.js Premium Orange Theme */
        .choices { margin-bottom: 0; }
        .choices__inner {
            background: rgba(255,255,255,0.04) !important;
            border: 1px solid var(--border) !important;
            border-radius: 16px !important;
            color: #fff !important;
            padding: 12px 18px !important;
            min-height: 56px !important;
            display: flex; align-items: center;
            transition: all 0.3s ease !important;
        }
        .is-focused .choices__inner {
            border-color: var(--orange) !important;
            box-shadow: 0 0 0 4px rgba(255,102,0,0.1) !important;
            background: rgba(255,255,255,0.07) !important;
        }
        .choices__list--dropdown {
            background: #001A33 !important;
            border: 1px solid var(--border) !important;
            border-radius: 20px !important;
            box-shadow: 0 20px 50px rgba(0,0,0,0.6) !important;
            backdrop-filter: blur(15px);
            padding: 10px !important;
            margin-top: 10px !important;
            animation: dropdownSlide 0.3s ease;
        }
        @keyframes dropdownSlide {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .choices__list--dropdown .choices__item {
            border-radius: 12px !important;
            padding: 12px 16px !important;
            margin-bottom: 4px !important;
            transition: all 0.2s !important;
            font-size: 0.95rem !important;
            color: #cbd5e1 !important;
        }
        .choices__list--dropdown .choices__item--selectable.is-highlighted {
            background: rgba(255, 102, 0, 0.15) !important;
            color: var(--orange) !important;
        }
        .choices__list--dropdown .choices__item--selectable.is-selected {
            background: rgba(255, 102, 0, 0.05) !important;
            color: var(--orange) !important;
        }
        .choices__placeholder { opacity: 1 !important; color: var(--muted) !important; }
        .choices[data-type*="select-one"]::after {
            border-color: var(--muted) transparent transparent transparent !important;
            right: 1.5rem !important;
            transition: transform 0.3s ease;
        }
        .choices.is-open[data-type*="select-one"]::after {
            transform: rotate(180deg);
            margin-top: -5px;
        }
        [dir="rtl"] .choices[data-type*="select-one"]::after { right: auto !important; left: 1.5rem !important; }
        .choices__input {
            background: rgba(255, 255, 255, 0.05) !important;
            border: 1px solid var(--border) !important;
            border-radius: 10px !important;
            color: #fff !important;
            margin-bottom: 8px !important;
        }
    </style>
</head>
<body>
    <div class="ambient-bg">
        <div class="orb orb-1"></div>
        <div class="orb orb-2"></div>
    </div>

    <!-- Platform Logo - High Priority Centering -->
    <div class="mb-5 text-center">
        <a href="{{ url('/') }}" class="auth-logo">
            <i class="bi bi-rocket-takeoff-fill"></i>
            <span>EduLearn</span>
        </a>
    </div>


    <div class="lang-switch">

        @if(app()->getLocale() == 'ar')
            <a href="{{ route('locale.switch', 'en') }}" class="lang-link">English 🇺🇸</a>
        @else
            <a href="{{ route('locale.switch', 'ar') }}" class="lang-link">العربية 🇸🇦</a>
        @endif
    </div>

    <div class="auth-container {{ request()->routeIs('register-school*') ? 'is-register' : '' }}" id="authContainer">
        <div class="auth-card">

            <div class="auth-header text-center">
                <div class="toggle-wrap">
                    <div class="toggle-pill"></div>
                    <button class="toggle-btn {{ !request()->routeIs('register-school*') ? 'active' : '' }}" onclick="switchTab('login')">{{ __('Login') }}</button>
                    <button class="toggle-btn {{ request()->routeIs('register-school*') ? 'active' : '' }}" onclick="switchTab('register')">{{ __('Register New School') }}</button>
                </div>
            </div>


            @if(session('success'))
                <div class="alert-box alert-success">
                    <i class="bi bi-check-circle-fill"></i>
                    <div>{{ session('success') }}</div>
                </div>
            @endif

            @if($errors->any())
                <div class="alert-box alert-error">
                    <i class="bi bi-exclamation-triangle-fill"></i>
                    <div>{{ $errors->first() }}</div>
                </div>
            @endif

            <div class="forms-wrapper">
                <!-- LOGIN PANE -->
                <div class="form-pane login-pane">
                    <form action="{{ route('login.post') }}" method="POST">
                        @csrf
                        <div class="field-group">
                            <label class="field-label">{{ __('Email Address') }}</label>
                            <input type="email" name="email" class="field-input" placeholder="admin@school.com" value="{{ old('email') }}" required>
                        </div>
                        <div class="field-group">
                            <label class="field-label">{{ __('Password') }}</label>
                            <input type="password" name="password" class="field-input" placeholder="••••••••" required>
                        </div>
                        <div class="text-end mb-4">
                            <a href="{{ route('password.request') }}" class="small text-muted text-decoration-none" style="cursor: pointer; transition: color 0.2s;" onmouseover="this.classList.replace('text-muted','text-white')" onmouseout="this.classList.replace('text-white','text-muted')">{{ __('Forgot?') }}</a>
                        </div>
                        <div class="alert-box alert-info" style="background: rgba(14, 165, 233, 0.1); border-color: rgba(14, 165, 233, 0.2); color: #7dd3fc; margin-bottom: 20px; font-size: 0.8rem;">
                            <i class="bi bi-info-circle-fill"></i>
                            <div>
                                {{ __('Branch Admins: Use the login email provided by your school administrator.') }}
                            </div>
                        </div>
                        <button type="submit" class="submit-btn" onclick="this.classList.add('loading')">
                            <span class="btn-text">{{ __('Login to Dashboard') }}</span>
                            <span class="spinner-border spinner-border-sm"></span>
                        </button>
                    </form>
                </div>

                <!-- REGISTER PANE -->
                <div class="form-pane register-pane">
                    <form action="{{ route('register-school.post') }}" method="POST" enctype="multipart/form-data">
                        @csrf
                        <div class="row mb-3">
                            <div class="col-12 d-flex flex-column align-items-center justify-content-center">
                                <div class="logo-preview-box" onclick="document.getElementById('logoInput').click()" title="{{ __('Add School Logo') }}">
                                    <i class="bi bi-cloud-arrow-up fs-3 text-muted" id="logoIcon"></i>
                                    <img src="" id="logoImg" style="display:none;">
                                    <div class="logo-overlay"><i class="bi bi-pencil-square fs-4"></i></div>
                                </div>
                                <input type="file" name="logo" id="logoInput" style="display: none !important;" accept="image/*">
                                <div class="upload-badge">{{ __('Add School Logo') }}</div>
                            </div>
                        </div>


                        <div class="register-grid">
                            <div class="field-group">
                                <label class="field-label">{{ __('School Name') }}</label>
                                <input type="text" name="school_name" class="field-input" placeholder="{{ __('e.g. Al-Noor School') }}" value="{{ old('school_name') }}" required>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Academic Year') }}</label>
                                <input type="text" name="academic_year" class="field-input" placeholder="2024/2025" value="{{ old('academic_year') }}" required>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Official Email') }}</label>
                                <input type="email" name="email" class="field-input" placeholder="contact@school.com" required>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Phone Number') }}</label>
                                <input type="text" name="phone" class="field-input" placeholder="+966..." required>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('School Type') }}</label>
                                <select name="school_type" class="field-input field-select dynamic-other-select" required>
                                    <option value="">{{ __('Choose...') }}</option>
                                    <option value="General">{{ __('General Education') }}</option>
                                    <option value="Private">{{ __('Private') }}</option>
                                    <option value="Azhar">{{ __('Azhar') }}</option>
                                    <option value="other">{{ __('Other') }}</option>
                                </select>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Country') }}</label>
                                <select class="field-input field-select" name="country" id="countrySelector" required></select>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('City') }}</label>
                                <select class="field-input field-select" name="city" id="citySelector" required></select>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Directorate') }}</label>
                                <select class="field-input field-select" name="directorate" id="dirSelector" required></select>
                            </div>
                            <div class="field-group col-span-2" style="grid-column: span 2;">
                                <label class="field-label">{{ __('Detailed Address') }}</label>
                                <input type="text" name="address" class="field-input" placeholder="{{ __('123 Peace Street...') }}" value="{{ old('address') }}" required>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Website') }}</label>
                                <input type="url" name="website" class="field-input" placeholder="https://school.com" value="{{ old('website') }}">
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Admin Full Name') }}</label>
                                <input type="text" name="admin_name" class="field-input" placeholder="{{ __('Director Name') }}" required>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Password') }}</label>
                                <input type="password" name="password" class="field-input" required>
                            </div>
                            <div class="field-group">
                                <label class="field-label">{{ __('Confirm Password') }}</label>
                                <input type="password" name="password_confirmation" class="field-input" required>
                            </div>
                        </div>

                        <button type="submit" class="submit-btn mt-4" onclick="this.classList.add('loading')">
                            <span class="btn-text">{{ __('Submit Registration Request') }}</span>
                            <span class="spinner-border spinner-border-sm"></span>
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="{{ asset('js/locations.js') }}"></script>
    <script>
        const container = document.getElementById('authContainer');
        const toggles = document.querySelectorAll('.toggle-btn');

        function switchTab(tab) {
            const isReg = (tab === 'register');
            if (isReg) container.classList.add('is-register');
            else container.classList.remove('is-register');

            toggles.forEach(btn => btn.classList.remove('active'));
            toggles[isReg ? 1 : 0].classList.add('active');

            const nextUrl = isReg ? '{{ url("/register-school") }}' : '{{ url("/login") }}';
            window.history.replaceState({}, '', nextUrl);
        }

        // Logo Preview
        document.getElementById('logoInput').addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    const img = document.getElementById('logoImg');
                    img.src = e.target.result;
                    img.style.display = 'block';
                    document.getElementById('logoIcon').style.display = 'none';
                }
                reader.readAsDataURL(file);
            }
        });

        // Initialize cascade locations and other selects
        document.addEventListener('DOMContentLoaded', () => {
            const cSelector = document.getElementById('countrySelector');
            const ciSelector = document.getElementById('citySelector');
            const dSelector = document.getElementById('dirSelector');
            
            if (cSelector && typeof initDynamicLocations === 'function') {
                initDynamicLocations(cSelector, ciSelector, dSelector, "{{ old('country') }}", "{{ old('city') }}", "{{ old('directorate') }}");
            }

            // Initialize School Type with Choices
            const typeSelect = document.querySelector('.dynamic-other-select');
            if (typeSelect) {
                const typeChoices = new Choices(typeSelect, { 
                    searchEnabled: false, 
                    itemSelectText: '', 
                    position: 'bottom',
                    shouldSort: false
                });

                typeSelect.addEventListener('change', async function() {
                    if (this.value === 'other') {
                        const { value: newVal } = await Swal.fire({
                            title: "{{ __('New Value') }}",
                            input: 'text',
                            background: '#001A33',
                            color: '#fff',
                            confirmButtonColor: '#FF6600',
                            inputPlaceholder: "{{ __('Type here...') }}",
                            showCancelButton: true,
                            confirmButtonText: "{{ __('Confirm') }}",
                            cancelButtonText: "{{ __('Cancel') }}"
                        });

                        if (newVal && newVal.trim() !== "") {
                            const trimmedVal = newVal.trim();
                            typeChoices.setChoices([{ value: trimmedVal, label: trimmedVal, selected: true }], 'value', 'label', false);
                        } else {
                            typeChoices.setChoiceByValue('');
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>
