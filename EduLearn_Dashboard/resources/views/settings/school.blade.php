@extends('layouts.app')

@section('content')
<div class="reports-skin">
    <div class="page-header mb-4">
        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
            <div>
                <h2 class="page-title mb-1">{{ __('School Settings') }}</h2>
                <p class="subtitle mb-0">{{ __('Manage school data, logo and general information') }}</p>
            </div>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm mb-4">
            {{ session('success') }}
        </div>
    @endif

    <div class="cardy panel mb-4">
        <form action="{{ route('settings.update') }}" method="POST" enctype="multipart/form-data">
            @csrf
            
            <div class="row g-4">
                <!-- Branding Section -->
                <div class="col-12 col-md-4 border-md-end border-bottom border-md-bottom-0 pb-4 pb-md-0">
                    <h6 class="mb-4 text-primary fw-bold text-uppercase small tracking-wider"><i class="bi bi-palette me-2"></i>{{ __('School Identity') }}</h6>
                    
                    <div class="text-center mb-4">
                        <div class="mb-3">
                            <img src="{{ $school->logo_path ? asset('storage/' . $school->logo_path) : asset('favicon.png') }}" 
                                 alt="{{ __('School Logo') }}" id="logoPreview"
                                 class="shadow-sm transition-all"
                                 loading="lazy"
                                 style="width: 140px; height: 140px; border-radius: 24px; object-fit: cover; border: 4px solid #f8fafc;">
                        </div>
                        <div class="mb-3">
                            <label class="btn btn-soft btn-sm px-4 rounded-pill">
                                <i class="bi bi-upload me-1"></i> {{ __('Change Logo') }}
                                <input type="file" name="logo" class="d-none" onchange="previewImage(this)">
                            </label>
                        </div>
                        <small class="text-muted d-block">{{ __('Preferred format PNG or JPG (Max 2MB)') }}</small>
                    </div>
                </div>

                <!-- Basic Info Section -->
                <div class="col-12 col-md-8">
                    <h6 class="mb-4 text-primary fw-bold text-uppercase small tracking-wider"><i class="bi bi-info-circle me-2"></i>{{ __('Basic Information') }}</h6>
                    
                    <div class="row g-3">
                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('School Name') }}</label>
                            <input type="text" name="name" class="form-control" value="{{ $school->name }}" required>
                        </div>
                        
                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('Official Email') }}</label>
                            <input type="email" name="email" class="form-control" value="{{ $school->email }}" required>
                        </div>

                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('Phone Number') }}</label>
                            <input type="text" name="phone" class="form-control" value="{{ $school->phone }}" required>
                        </div>

                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('Current Academic Year') }} <span class="text-danger">*</span></label>
                            <input type="text" name="academic_year" class="form-control" value="{{ $school->academic_year }}" placeholder="{{ __('e.g. 2024/2025') }}" required>
                        </div>

                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('School Type') }} <span class="text-danger">*</span></label>
                            <select name="school_type" class="form-select dynamic-other-select" required>
                                <option value="">{{ __('Choose Type...') }}</option>
                                <option value="التعليم العام (حكومي)" {{ $school->school_type == 'التعليم العام (حكومي)' ? 'selected' : '' }}>{{ __('Public Education') }}</option>
                                <option value="تعليم خاص (لغات/عربي)" {{ $school->school_type == 'تعليم خاص (لغات/عربي)' ? 'selected' : '' }}>{{ __('Private Education') }}</option>
                                <option value="أزهري" {{ $school->school_type == 'أزهري' ? 'selected' : '' }}>{{ __('Azhar') }}</option>
                                <option value="other" {{ (!in_array($school->school_type, ['التعليم العام (حكومي)', 'تعليم خاص (لغات/عربي)', 'أزهري', '', null])) ? 'selected' : '' }}>{{ __('Other') }}</option>
                                @if(!in_array($school->school_type, ['التعليم العام (حكومي)', 'تعليم خاص (لغات/عربي)', 'أزهري', '', null]))
                                    <option value="{{ $school->school_type }}" selected>{{ $school->school_type }}</option>
                                @endif
                            </select>
                        </div>

                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('Country') }} <span class="text-danger">*</span></label>
                            <select class="form-select" name="country" id="countrySelector" data-placeholder="{{ __('Choose...') }}" required>
                                <!-- populated by JS -->
                            </select>
                        </div>

                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('City / Governorate') }} <span class="text-danger">*</span></label>
                            <select class="form-select" name="city" id="citySelector" data-placeholder="{{ __('Choose...') }}" required>
                                <!-- populated by JS -->
                            </select>
                        </div>

                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('Directorate') }} ({{ __('Directorate/Management') }}) <span class="text-danger">*</span></label>
                            <select class="form-select" name="directorate" id="dirSelector" data-placeholder="{{ __('Choose...') }}" required>
                                <!-- populated by JS -->
                            </select>
                        </div>

                        <div class="col-12 col-sm-6">
                            <label class="form-label fw-bold small">{{ __('Website') }} <span class="text-danger">*</span></label>
                            <input type="url" name="website" class="form-control" value="{{ $school->website }}" placeholder="https://example.com" required>
                        </div>

                        <div class="col-12">
                            <label class="form-label fw-bold small">{{ __('Detailed Address') }} <span class="text-danger">*</span></label>
                            <textarea name="address" class="form-control" rows="2" required>{{ $school->address }}</textarea>
                        </div>
                    </div>

                    <div class="mt-4 pt-3 border-top text-end">
                        <button type="submit" class="btn btn-primary px-5 rounded-pill shadow-sm">
                            <i class="bi bi-check-lg me-1"></i> {{ __('Save Changes') }}
                        </button>
                    </div>
                </div>
            </div>
        </form>
    </div>

    <!-- Account Security Section -->
    <div class="cardy panel">
        <h6 class="mb-4 text-primary"><i class="bi bi-shield-lock me-2"></i>{{ __('Account Security') }}</h6>
        
        <!-- Display validation errors for security form -->
        @if ($errors->any())
            <div class="alert alert-danger shadow-sm border-0 mb-4">
                <ul class="mb-0">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('settings.security.update') }}" method="POST">
            @csrf
            <div class="row g-4">
                <div class="col-md-6">
                    <label class="form-label fw-bold">{{ __('User Name') }} <span class="text-danger">*</span></label>
                    <input type="text" name="user_name" class="form-control" value="{{ old('user_name', auth()->user()->name) }}" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold">{{ __('Login Email') }} <span class="text-danger">*</span></label>
                    <input type="email" name="user_email" class="form-control" value="{{ old('user_email', auth()->user()->email) }}" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold">{{ __('New Password') }}</label>
                    <input type="password" name="password" class="form-control" placeholder="{{ __('Leave blank to keep current password') }}">
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold">{{ __('Confirm New Password') }}</label>
                    <input type="password" name="password_confirmation" class="form-control" placeholder="{{ __('Confirm if changing password') }}">
                </div>
            </div>

            <div class="mt-4 pt-3 border-top text-end">
                <button type="submit" class="btn btn-outline-primary px-5">
                    <i class="bi bi-shield-check me-1"></i> {{ __('Update Security') }}
                </button>
            </div>
        </form>
    </div>
</div>

<script>
    function previewImage(input) {
        if (input.files && input.files[0]) {
            var reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('logoPreview').src = e.target.result;
            }
            reader.readAsDataURL(input.files[0]);
        }
    }

    document.addEventListener('DOMContentLoaded', function() {
        // Initialize the cascade dropdowns
        const cSelector = document.getElementById('countrySelector');
        const ciSelector = document.getElementById('citySelector');
        const dSelector = document.getElementById('dirSelector');
        
        let initialCountry = @json($school->country);
        let initialCity = @json($school->city);
        let initialDir = @json($school->directorate);
        
        // If they exist but not in ARAB_LOCATIONS, they will fallback to 'other' safely via populateDropdown and the other input logic
        
        // Load external cities map script
        initDynamicLocations(cSelector, ciSelector, dSelector, initialCountry, initialCity, initialDir);
        
        // Setup values for original 'other' inputs before the general updateVisibility triggers
        if (initialCountry && !document.querySelector('#countrySelector option[value="'+initialCountry+'"]')) {
            let opt = document.createElement('option');
            opt.value = initialCountry;
            opt.text = initialCountry;
            cSelector.add(opt, cSelector.options[cSelector.selectedIndex]);
            cSelector.value = initialCountry;
        }
        if (initialCity && !document.querySelector('#citySelector option[value="'+initialCity+'"]')) {
            let opt = document.createElement('option');
            opt.value = initialCity;
            opt.text = initialCity;
            ciSelector.add(opt, ciSelector.options[ciSelector.selectedIndex]);
            ciSelector.value = initialCity;
        }
        if (initialDir && !document.querySelector('#dirSelector option[value="'+initialDir+'"]')) {
            let opt = document.createElement('option');
            opt.value = initialDir;
            opt.text = initialDir;
            dSelector.add(opt, dSelector.options[dSelector.selectedIndex]);
            dSelector.value = initialDir;
        }


            document.querySelectorAll('.dynamic-other-select').forEach(function(select) {
                
                select.addEventListener('change', async function() {
                    let val = this.value;
                    if (val === 'other') {
                        let newVal = "";
                        if (typeof Swal !== 'undefined') {
                            const result = await Swal.fire({
                                title: "{{ __('Please enter the new value') }}",
                                input: 'text',
                                background: '#1e293b',
                                color: '#fff',
                                confirmButtonColor: '#6366f1',
                                inputPlaceholder: "{{ __('Type here...') }}",
                                showCancelButton: true,
                                confirmButtonText: "{{ __('Confirm') }}",
                                cancelButtonText: "{{ __('Cancel') }}",
                                customClass: { popup: 'border border-primary' }
                            });
                            newVal = result.value;
                        } else {
                            newVal = prompt("{{ __('Please enter the new value') }}");
                        }

                        if (newVal && newVal.trim() !== "") {
                            newVal = newVal.trim();
                            let opt = document.createElement('option');
                            opt.value = newVal;
                            opt.text = newVal;
                            this.add(opt, this.options[this.selectedIndex]);
                            this.value = newVal;
                            this.style.backgroundColor = '#e0f2fe';
                            this.style.color = '#0369a1';
                        } else {
                            this.value = '';
                            this.style.backgroundColor = '';
                            this.style.color = '';
                        }
                    } else {
                        // Also clear if they change away
                        this.style.backgroundColor = '';
                        this.style.color = '';
                    }
                });
                
                // Set initial colors if pre-selected externally
                if (select.value && select.value !== '' && select.value !== 'other' && select.querySelector('option[value="' + select.value + '"]') && select.querySelector('option[value="' + select.value + '"]').text === select.value && !['التعليم العام (حكومي)', 'تعليم خاص (لغات/عربي)', 'أزهري'].includes(select.value)) {
                    select.style.backgroundColor = '#e0f2fe';
                    select.style.color = '#0369a1';
                }
            });
    });
</script>
<script src="{{ asset('js/locations.js') }}"></script>
@endsection
