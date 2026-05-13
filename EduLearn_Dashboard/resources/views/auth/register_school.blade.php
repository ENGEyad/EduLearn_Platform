<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('School Registration') }} - EduLearn Platform</title>
    @if(app()->getLocale() == 'ar')
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
    @else
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    @endif
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/choices.js/10.2.0/choices.min.css" />
    <style>
        :root {
            --primary: #FF6600; /* Deep Orange */
            --accent: #FF8533;
            --bg: #001A33; /* Deep Navy */
            --card-bg: rgba(0, 26, 51, 0.4);
            --border: rgba(255, 255, 255, 0.08);
            --navy-light: #002B52;
            --orange: #FF6600;
        }
        body {
            font-family: {{ app()->getLocale() == 'ar' ? "'Cairo', sans-serif" : "'Inter', sans-serif" }};
            background: radial-gradient(circle at top right, #002B52, #001A33);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            padding: 40px 20px;
        }
        .register-card {
            background: var(--card-bg);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: 24px;
            padding: 48px;
            width: 100%;
            max-width: 800px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6);
            animation: fadeIn 0.8s cubic-bezier(0.16, 1, 0.3, 1);
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .register-header h2 {
            font-weight: 800;
            margin-bottom: 8px;
            background: linear-gradient(135deg, #FF6600, #FFD700);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 2.25rem;
            letter-spacing: -0.02em;
        }
        .form-label { font-weight: 600; color: #94a3b8; font-size: 0.875rem; margin-bottom: 12px; display: block; }
        .form-control, .form-select {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border);
            color: #fff;
            border-radius: 12px;
            padding: 14px 18px;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            font-size: 0.95rem;
        }
        .form-control:focus, .form-select:focus {
            background: rgba(255, 255, 255, 0.1);
            border-color: var(--primary);
            box-shadow: 0 0 0 4px rgba(255, 102, 0, 0.15);
            color: #fff;
            outline: none;
        }
        .form-select {
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%2394a3b8' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m2 5 6 6 6-6'/%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: {{ app()->getLocale() == 'ar' ? 'left' : 'right' }} 1rem center;
            background-size: 16px 12px;
            padding-{{ app()->getLocale() == 'ar' ? 'left' : 'right' }}: 40px;
        }
        .form-select option { background-color: #1e293b; color: #fff; padding: 12px; }



        .btn-register {
            background: linear-gradient(135deg, var(--primary), #FF4500);
            border: none;
            padding: 16px;
            border-radius: 14px;
            font-weight: 700;
            margin-top: 24px;
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            color: white;
            font-size: 1.1rem;
            letter-spacing: 0.02em;
        }
        .btn-register:hover {
            transform: translateY(-3px) scale(1.02);
            box-shadow: 0 20px 30px -10px rgba(255, 102, 0, 0.4);
            filter: brightness(1.1);
        }
        .login-link { color: var(--orange); text-decoration: none; font-weight: 700; border-bottom: 1px solid transparent; transition: all 0.2s; }
        .login-link:hover { border-bottom-color: var(--orange); }
        .lang-switch { position: absolute; top: 24px; right: 24px; z-index: 100; }
        [dir="rtl"] .lang-switch { right: auto; left: 24px; }
        .school-logo-preview {
            width: 120px;
            height: 120px;
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.03);
            border: 2px dashed var(--border);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            overflow: hidden;
            transition: all 0.3s ease;
        }
        .school-logo-preview:hover {
            border-color: var(--primary);
            background: rgba(255, 255, 255, 0.06);
        }
        .school-logo-preview i { font-size: 2.5rem; color: #475569; }
        /* Choices.js Premium Styling */
        .choices { margin-bottom: 0; }
        .choices__inner {
            background: rgba(255, 255, 255, 0.04) !important;
            border: 1px solid var(--border) !important;
            border-radius: 14px !important;
            padding: 10px 16px !important;
            min-height: 54px !important;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
            display: flex;
            align-items: center;
        }
        .is-focused .choices__inner {
            border-color: var(--primary) !important;
            box-shadow: 0 0 0 4px rgba(255, 102, 0, 0.1) !important;
            background: rgba(255, 255, 255, 0.07) !important;
        }
        .choices__list--dropdown {
            background: #001A33 !important;
            border: 1px solid var(--border) !important;
            border-radius: 18px !important;
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.5) !important;
            margin-top: 10px !important;
            padding: 10px !important;
            animation: dropdownFadeIn 0.3s ease;
        }
        @keyframes dropdownFadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .choices__list--dropdown .choices__list {
            max-height: 280px !important;
            scrollbar-width: thin;
            scrollbar-color: var(--border) transparent;
        }
        .choices__list--dropdown .choices__item {
            border-radius: 12px !important;
            padding: 12px 16px !important;
            margin-bottom: 6px !important;
            transition: all 0.2s ease !important;
            font-size: 0.95rem !important;
            color: #cbd5e1 !important;
        }
        .choices__list--dropdown .choices__item--selectable.is-highlighted {
            background: rgba(255, 102, 0, 0.1) !important;
            color: var(--orange) !important;
        }
        .choices__list--dropdown .choices__item--selectable.is-selected {
            background: rgba(255, 102, 0, 0.05) !important;
            color: var(--orange) !important;
        }
        .choices__item--selectable::after { display: none !important; }
        .choices[data-type*="select-one"]::after {
            border-color: #64748b transparent transparent transparent !important;
            right: 1.5rem !important;
            transition: transform 0.3s ease;
        }
        .choices.is-open[data-type*="select-one"]::after {
            transform: rotate(180deg);
            margin-top: -5px;
        }
        [dir="rtl"] .choices[data-type*="select-one"]::after { right: auto !important; left: 1.5rem !important; }
        .choices__placeholder { opacity: 1 !important; color: #64748b !important; }
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
    <div class="lang-switch">
        @if(app()->getLocale() == 'ar')
            <a href="{{ route('locale.switch', 'en') }}" class="btn btn-outline-light btn-sm border-0 opacity-75">English 🇺🇸</a>
        @else
            <a href="{{ route('locale.switch', 'ar') }}" class="btn btn-outline-light btn-sm border-0 opacity-75">العربية 🇸🇦</a>
        @endif
    </div>

    <div class="register-card {{ app()->getLocale() == 'ar' ? 'text-end' : '' }}">
        <div class="register-header mb-5 text-center">
            <h2>EduLearn</h2>
            <p class="text-secondary">{{ __('Register your school and join our advanced management platform') }}</p>
        </div>

        @if(session('success'))
            <div class="alert alert-success bg-success bg-opacity-10 border-0 text-success small mb-4">
                <i class="bi bi-check-circle me-2"></i> {{ session('success') }}
            </div>
        @endif

        @if($errors->any())
            <div class="alert alert-danger bg-danger bg-opacity-10 border-0 text-danger small mb-4">
                <i class="bi bi-exclamation-triangle me-2"></i> {{ $errors->first() }}
            </div>
        @endif

        <form action="{{ route('register-school.post') }}" method="POST" enctype="multipart/form-data">
            @csrf
            <div class="row">
                <div class="col-md-12 mb-4 text-center">
                    <div class="school-logo-preview" id="logoPreview">
                        <i class="bi bi-cloud-arrow-up"></i>
                    </div>
                    <label class="form-label d-block">{{ __('School Logo') }}</label>
                    <div class="d-flex justify-content-center">
                        <input type="file" name="logo" id="logoInput" class="form-control w-50" accept="image/*">
                    </div>
                    <small class="text-secondary mt-2 d-block">{{ __('Preferred format PNG or JPG (Max 2MB)') }}</small>
                </div>

                <div class="col-md-12 mb-3">
                    <label class="form-label">{{ __('School Name') }}</label>
                    <input type="text" name="school_name" class="form-control" placeholder="{{ __('e.g. Al-Noor International School') }}" value="{{ old('school_name') }}" required>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">{{ __('Official Email') }}</label>
                    <input type="email" name="email" class="form-control" placeholder="admin@school.com" value="{{ old('email') }}" required>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">{{ __('Phone Number') }}</label>
                    <input type="text" name="phone" class="form-control" placeholder="00966..." value="{{ old('phone') }}" required>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">{{ __('Academic Year') }} <span class="text-danger">*</span></label>
                    <input type="text" name="academic_year" class="form-control" placeholder="{{ __('e.g. 2025/2026') }}" value="{{ old('academic_year') }}" required>
                </div>

                <div class="col-md-12 mb-4">
                    <label class="form-label">{{ __('School Type') }} <span class="text-danger">*</span></label>
                    <select class="form-select" name="school_type" id="schoolTypeSelector" required>
                        <option value="">{{ __('Choose...') }}</option>
                        <option value="General Education" {{ old('school_type') == 'General Education' ? 'selected' : '' }}>{{ __('General Education') }}</option>
                        <option value="Private Education" {{ old('school_type') == 'Private Education' ? 'selected' : '' }}>{{ __('Private Education') }}</option>
                        <option value="Azhar" {{ old('school_type') == 'Azhar' ? 'selected' : '' }}>{{ __('Azhar') }}</option>
                        <option value="other" {{ old('school_type') && !in_array(old('school_type'), ['General Education', 'Private Education', 'Azhar']) ? 'selected' : '' }}>{{ __('Other') }}</option>
                        @if(old('school_type') && !in_array(old('school_type'), ['General Education', 'Private Education', 'Azhar']))
                            <option value="{{ old('school_type') }}" selected>{{ old('school_type') }}</option>
                        @endif
                    </select>
                </div>

                <div class="col-md-4 mb-3">
                    <label class="form-label">{{ __('Country') }} <span class="text-danger">*</span></label>
                    <select class="form-select" name="country" id="countrySelector" data-placeholder="{{ __('Choose...') }}" required></select>
                </div>

                <div class="col-md-4 mb-3">
                    <label class="form-label">{{ __('City') }} <span class="text-danger">*</span></label>
                    <select class="form-select" name="city" id="citySelector" data-placeholder="{{ __('Choose...') }}" required></select>
                </div>

                <div class="col-md-4 mb-3">
                    <label class="form-label">{{ __('Directorate/Management') }} <span class="text-danger">*</span></label>
                    <select class="form-select" name="directorate" id="dirSelector" data-placeholder="{{ __('Choose...') }}" required></select>
                </div>

                <div class="col-md-12 mb-3">
                    <label class="form-label">{{ __('Detailed Address') }} <span class="text-danger">*</span></label>
                    <input type="text" name="address" class="form-control" placeholder="{{ __('123 Peace Street...') }}" value="{{ old('address') }}" required>
                </div>

                <div class="col-md-12 mb-4">
                    <label class="form-label">{{ __('Website') }}</label>
                    <input type="url" name="website" class="form-control" placeholder="https://school.com" value="{{ old('website') }}">
                </div>

                <hr class="opacity-10 mb-4">

                <div class="col-md-12 mb-3">
                    <label class="form-label">{{ __('Admin Name') }}</label>
                    <input type="text" name="admin_name" class="form-control" placeholder="{{ __('Full Name') }}" value="{{ old('admin_name') }}" required>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">{{ __('Password') }}</label>
                    <input type="password" name="password" class="form-control" required>
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label">{{ __('Confirm Password') }}</label>
                    <input type="password" name="password_confirmation" class="form-control" required>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-register w-100 mt-4">{{ __('Submit Registration Request') }}</button>
            
            <div class="text-center mt-5 text-secondary small">
                <span>{{ __('Already have an account?') }} </span>
                <a href="{{ url('/login') }}" class="login-link">{{ __('Login') }}</a>
            </div>
        </form>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/choices.js/10.2.0/choices.min.js"></script>
    <script src="{{ asset('js/locations.js') }}"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Logo Preview
            document.getElementById('logoInput').addEventListener('change', function(e) {
                const preview = document.getElementById('logoPreview');
                const file = e.target.files[0];
                if (file) {
                    const reader = new FileReader();
                    reader.onload = function(e) {
                        preview.innerHTML = `<img src="${e.target.result}" style="width:100%; height:100%; object-fit:cover;">`;
                    }
                    reader.readAsDataURL(file);
                }
            });

            // Initialize cascade locations
            const cSelector = document.getElementById('countrySelector');
            const ciSelector = document.getElementById('citySelector');
            const dSelector = document.getElementById('dirSelector');
            
            initDynamicLocations(cSelector, ciSelector, dSelector, "{{ old('country') }}", "{{ old('city') }}", "{{ old('directorate') }}");

            // Initialize school type selector
            const typeSelector = document.getElementById('schoolTypeSelector');
            const typeChoices = new Choices(typeSelector, { searchEnabled: false, itemSelectText: '', position: 'bottom', shouldSort: false });

            typeSelector.addEventListener('change', async function() {
                if (this.value === 'other') {
                    const { value: newVal } = await Swal.fire({
                        title: "{{ __('Please enter the new value') }}",
                        input: 'text',
                        background: '#001A33',
                        color: '#fff',
                        confirmButtonColor: '#FF6600',
                        inputPlaceholder: "{{ __('Type here...') }}",
                        showCancelButton: true,
                        confirmButtonText: "{{ __('Confirm') }}",
                        cancelButtonText: "{{ __('Cancel') }}",
                        customClass: { popup: 'border border-primary rounded-4' }
                    });

                    if (newVal && newVal.trim() !== "") {
                        const trimmedVal = newVal.trim();
                        // Add the new value to the list and select it
                        typeChoices.setChoices([{ value: trimmedVal, label: trimmedVal, selected: true }], 'value', 'label', false);
                    } else {
                        typeChoices.setChoiceByValue('');
                    }
                }
            });
        });
    </script>
</body>
</html>
