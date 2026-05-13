<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() == 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('System Initialization') }} - EduLearn Welcome</title>
    @if(app()->getLocale() == 'ar')
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
    @else
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    @endif
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        :root {
            --primary-glow: conic-gradient(from 180deg at 50% 50%, #16abff33 0deg, #0885ff33 55deg, #54d6ff33 120deg, #0071ff33 160deg, transparent 360deg);
            --secondary-glow: radial-gradient(rgba(255, 255, 255, 1), rgba(255, 255, 255, 0));
        }
        body {
            font-family: 'Cairo', sans-serif;
            background: #0a0f18;
            color: #fff;
            min-height: 100vh;
            overflow-x: hidden;
        }
        .bg-glow {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: 
                radial-gradient(circle at 20% 30%, rgba(99, 102, 241, 0.15) 0%, transparent 50%),
                radial-gradient(circle at 80% 70%, rgba(168, 85, 247, 0.15) 0%, transparent 50%);
            z-index: -1;
        }
        .wizard-container {
            max-width: 900px;
            margin: 60px auto;
            padding: 20px;
        }
        .glass-card {
            background: rgba(255, 255, 255, 0.03);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            padding: 40px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
        }
        .step-indicator {
            display: flex;
            justify-content: space-between;
            margin-bottom: 50px;
            position: relative;
        }
        .step-indicator::before {
            content: '';
            position: absolute;
            top: 24px; left: 0; right: 0;
            height: 2px;
            background: rgba(255, 255, 255, 0.1);
            z-index: 0;
        }
        .step-item {
            position: relative;
            z-index: 1;
            text-align: center;
            flex: 1;
        }
        .step-number {
            width: 50px; height: 50px;
            background: #1e293b;
            border: 2px solid rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 10px;
            font-weight: 700;
            color: #64748b;
            transition: all 0.4s ease;
        }
        .step-item.active .step-number {
            background: linear-gradient(135deg, #6366f1, #a855f7);
            color: white;
            border-color: transparent;
            box-shadow: 0 0 20px rgba(99, 102, 241, 0.4);
        }
        .step-item.completed .step-number {
            background: #22c55e;
            color: white;
            border-color: transparent;
        }
        .step-label { font-size: 14px; font-weight: 600; color: #64748b; }
        .step-item.active .step-label { color: #fff; }

        .form-section { display: none; }
        .form-section.active { display: block; animation: fadeIn 0.5s ease; }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .subject-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .subject-card {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            padding: 15px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        .subject-card:hover { background: rgba(255, 255, 255, 0.08); transform: scale(1.02); }
        .subject-card.selected {
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.2), rgba(168, 85, 247, 0.2));
            border-color: #6366f1;
            box-shadow: 0 0 15px rgba(99, 102, 241, 0.2);
        }
        .subject-card input { display: none; }
        .subject-icon { font-size: 1.5rem; margin-bottom: 8px; color: #818cf8; }

        .btn-wizard {
            padding: 12px 35px;
            border-radius: 12px;
            font-weight: 700;
            transition: all 0.3s;
        }
        .btn-prev { background: rgba(255, 255, 255, 0.1); color: #fff; border: none; }
        .btn-next, .btn-submit { background: linear-gradient(135deg, #6366f1, #a855f7); color: #fff; border: none; }
        .btn-next:hover, .btn-submit:hover { opacity: 0.9; transform: translateY(-2px); }

        .form-control, .form-select {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            color: #fff;
            border-radius: 12px;
            padding: 12px;
        }
        .form-control:focus, .form-select:focus {
            background: rgba(255, 255, 255, 0.1);
            border-color: #6366f1;
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.2);
            color: #fff;
        }
        select option { background-color: #0a0f18; color: #fff; }
    </style>
</head>
<body>
    <div class="bg-glow"></div>

    <div class="wizard-container">
        <div class="text-center mb-5">
            <h1 class="fw-bold">{{ __('Welcome to') }} <span class="text-info">EduLearn</span></h1>
            <p class="text-secondary">{{ __('Let\'s initialize your school system in a few minutes') }}</p>
        </div>

        <div class="glass-card">
            <!-- Progress Bar -->
            <div class="step-indicator">
                <div class="step-item active" id="step-head-1">
                    <div class="step-number">1</div>
                    <div class="step-label">{{ __('Formation') }}</div>
                </div>
                <div class="step-item" id="step-head-2">
                    <div class="step-number">2</div>
                    <div class="step-label">{{ __('Subjects') }}</div>
                </div>
                <div class="step-item" id="step-head-3">
                    <div class="step-number">3</div>
                    <div class="step-label">{{ __('Review') }}</div>
                </div>
            </div>

            <form id="wizardForm" action="{{ route('school-setup.initialize') }}" method="POST">
                @csrf
                
                <!-- Step 1: Base Configuration -->
                <div class="form-section active" id="step-1">
                    <h4 class="fw-bold mb-4">{{ __('Step 1: Define School Type') }}</h4>
                    <div class="row g-4">
                        <div class="col-md-6">
                            <label class="form-label text-secondary small">{{ __('School Stage') }}</label>
                            <select name="school_type" class="form-select" required>
                                <option value="">{{ __('Choose Stage...') }}</option>
                                <option value="Primary">{{ __('Primary Only') }}</option>
                                <option value="Secondary">{{ __('Preparatory/Secondary') }}</option>
                                <option value="Primary/Secondary">{{ __('Composite (Primary to Secondary)') }}</option>
                                <option value="Other">{{ __('Other') }}</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label text-secondary small">{{ __('Specialization (Optional)') }}</label>
                            <select name="section" class="form-select">
                                <option value="">{{ __('General Education') }}</option>
                                <option value="Scientific">{{ __('Scientific') }}</option>
                                <option value="Literary">{{ __('Literary') }}</option>
                                <option value="Scientific/Literary">{{ __('Common (Scientific & Literary)') }}</option>
                            </select>
                        </div>
                        <div class="col-12">
                            <div class="alert alert-info bg-info bg-opacity-10 border-info border-opacity-25 text-info small">
                                <i class="bi bi-info-circle-fill me-2"></i>
                                {{ __('This information will be used to initialize appropriate schedules and reports for your school.') }}
                            </div>
                        </div>
                    </div>
                    <div class="d-flex justify-content-end mt-5">
                        <button type="button" class="btn btn-wizard btn-next" onclick="nextStep(2)">
                            {{ __('Next: Choose Subjects') }} 
                            <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'left' : 'right' }} ms-2"></i>
                        </button>
                    </div>
                </div>

                <!-- Step 2: Subjects -->
                <div class="form-section" id="step-2">
                    <h4 class="fw-bold mb-2">{{ __('Step 2: Activate Subjects') }}</h4>
                    <p class="text-secondary small mb-4">{{ __('Choose all subjects taught in your school to activate them in the system.') }}</p>
                    
                    <div class="subject-grid">
                        @foreach($subjects as $subject)
                        <label class="subject-card" id="card-{{ $subject->id }}">
                            <input type="checkbox" name="subject_ids[]" value="{{ $subject->id }}" onchange="toggleSubject(this, {{ $subject->id }})">
                            <div class="subject-icon">
                                <i class="bi bi-journal-check"></i>
                            </div>
                            <div class="fw-bold small">{{ app()->getLocale() == 'ar' ? $subject->name_ar : $subject->name_en }}</div>
                            <div class="text-secondary" style="font-size: 10px;">{{ app()->getLocale() == 'ar' ? $subject->name_en : $subject->name_ar }}</div>
                        </label>
                        @endforeach
                    </div>

                    <div class="d-flex justify-content-between mt-5">
                        <button type="button" class="btn btn-wizard btn-prev" onclick="nextStep(1)">
                            <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'right' : 'left' }} me-2"></i> 
                            {{ __('Previous') }}
                        </button>
                        <button type="button" class="btn btn-wizard btn-next" onclick="nextStep(3)">
                            {{ __('Next: Review') }} 
                            <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'left' : 'right' }} ms-2"></i>
                        </button>
                    </div>
                </div>

                <!-- Step 3: Review -->
                <div class="form-section" id="step-3">
                    <h4 class="fw-bold mb-4">{{ __('Step 3: Review Data') }}</h4>
                    
                    <div class="bg-white bg-opacity-5 rounded-4 p-4 mb-4">
                        <div class="row g-3">
                            <div class="col-6">
                                <div class="text-secondary small">{{ __('School Name') }}</div>
                                <div class="fw-bold text-info">{{ $school->name ?? __('Not Set') }}</div>
                            </div>
                            <div class="col-6">
                                <div class="text-secondary small">{{ __('Stage') }}</div>
                                <div class="fw-bold" id="review-type">-</div>
                            </div>
                            <div class="col-12 mt-3">
                                <div class="text-secondary small mb-2">{{ __('Number of activated subjects:') }} <span class="text-white fw-bold" id="review-count">0</span></div>
                                <div id="review-subjects" class="d-flex flex-wrap gap-2">
                                    <span class="text-secondary italic small">{{ __('No subjects selected yet') }}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="alert alert-warning bg-warning bg-opacity-10 border-warning border-opacity-25 text-warning small">
                        <i class="bi bi-exclamation-triangle-fill me-2"></i>
                        {{ __('Once you click Finish, the initialization process for your school\'s database will begin. This may take a few seconds.') }}
                    </div>

                    <div class="d-flex justify-content-between mt-5">
                        <button type="button" class="btn btn-wizard btn-prev" onclick="nextStep(2)">
                            <i class="bi bi-arrow-{{ app()->getLocale() == 'ar' ? 'right' : 'left' }} me-2"></i> 
                            {{ __('Previous') }}
                        </button>
                        <button type="submit" class="btn btn-wizard btn-submit">
                            {{ __('Finish Initialization & Start Using') }} 
                            <i class="bi bi-rocket-takeoff ms-2"></i>
                        </button>
                    </div>
                </div>

            </form>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script>
        let isDirty = false;
        window.onbeforeunload = function() {
            if (isDirty) return "{{ __('You have unsaved changes, do you really want to leave?') }}";
        };

        document.getElementById('wizardForm').addEventListener('submit', function() {
            isDirty = false; // Disable warning on legitimate submit
        });

        function nextStep(step) {
            if (step > 1) isDirty = true;
            // Update Headers
            document.querySelectorAll('.step-item').forEach((el, index) => {
                el.classList.remove('active');
                if (index < step - 1) el.classList.add('completed');
                else el.classList.remove('completed');
                
                if (index === step - 1) el.classList.add('active');
            });

            // Update Form Sections
            document.querySelectorAll('.form-section').forEach(el => el.classList.remove('active'));
            document.getElementById('step-' + step).classList.add('active');

            if (step === 3) {
                updateReview();
            }
        }

        function toggleSubject(checkbox, id) {
            const card = document.getElementById('card-' + id);
            if (checkbox.checked) {
                card.classList.add('selected');
            } else {
                card.classList.remove('selected');
            }
        }

        function updateReview() {
            const type = document.querySelector('select[name="school_type"] option:checked').text;
            document.getElementById('review-type').innerText = type;

            const selected = document.querySelectorAll('input[name="subject_ids[]"]:checked');
            document.getElementById('review-count').innerText = selected.length;

            const reviewSubjects = document.getElementById('review-subjects');
            reviewSubjects.innerHTML = '';
            
            if (selected.length === 0) {
                reviewSubjects.innerHTML = '<span class="text-danger small">{{ __('Warning: No subjects selected!') }}</span>';
            } else {
                selected.forEach(cb => {
                    const name = cb.closest('label').querySelector('.fw-bold').innerText;
                    const badge = document.createElement('span');
                    badge.className = 'badge bg-primary bg-opacity-25 border border-primary border-opacity-25 text-primary-emphasis px-3 py-2';
                    badge.innerText = name;
                    reviewSubjects.appendChild(badge);
                });
            }
        }
    </script>
</body>
</html>
