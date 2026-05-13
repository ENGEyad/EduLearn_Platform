@extends('super_admin.layout')
@section('title', __('System Settings'))

@push('styles')
<style>
    .nav-tabs { border-bottom: 1px solid var(--border); }
    .nav-tabs .nav-link { border: none; padding: 12px 25px; color: var(--muted); font-weight: 600; border-bottom: 3px solid transparent; transition: all 0.3s; }
    .nav-tabs .nav-link:hover { color: var(--white); }
    .nav-tabs .nav-link.active { color: var(--orange); border-bottom-color: var(--orange); background: transparent; }
</style>
@endpush

@section('content')
<div class="sa-header">
    <div>
        <h1><i class="bi bi-gear-fill me-2" style="color: var(--orange);"></i>{{ __('System Settings') }}</h1>
        <p>{{ __('Customize platform identity, contact info, and operation settings') }}</p>
    </div>
</div>

<div class="sa-card">
    @if(session('success'))
        <div class="alert alert-success alert-dismissible fade show border-0 mb-4 rounded-4 shadow-sm" role="alert">
            <i class="bi bi-check-circle-fill me-2"></i> {{ session('success') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    @endif

    @if(session('error'))
        <div class="alert alert-danger alert-dismissible fade show border-0 mb-4 rounded-4 shadow-sm" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-2"></i> {{ session('error') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    @endif

    <form id="settingsForm" action="{{ route('super-admin.settings.update') }}" method="POST" enctype="multipart/form-data">
        @csrf
        <ul class="nav nav-tabs mb-4" id="settingsTab">
            <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#general">{{ __('Branding') }}</a></li>
            <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#contact">{{ __('Contact Info') }}</a></li>
            <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#social">{{ __('Social Links') }}</a></li>
        </ul>

        <div class="tab-content p-2">
            <div class="tab-pane fade show active" id="general">
                <div class="row g-4">
                    <div class="col-md-6">
                        <label class="form-label">{{ __('Site Name (Arabic)') }}</label>
                        <input type="text" name="site_name_ar" class="form-control" value="{{ $settings['branding']['site_name_ar'] ?? 'إديوليرن' }}">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">{{ __('Site Name (English)') }}</label>
                        <input type="text" name="site_name_en" class="form-control" value="{{ $settings['branding']['site_name_en'] ?? 'EduLearn' }}">
                    </div>
                    <div class="col-md-12">
                        <label class="form-label">{{ __('Site Description') }}</label>
                        <textarea name="site_description" class="form-control" rows="3">{{ $settings['branding']['site_description'] ?? 'أفضل منصة لإدارة المدارس والتعليم الذكي' }}</textarea>
                    </div>
                    <div class="col-md-12">
                        <label class="form-label">{{ __('Site Logo') }}</label>
                        <input type="file" name="site_logo" class="form-control" accept="image/*">
                        @php
                            $logoSetting = \App\Models\SystemSetting::where('key', 'site_logo')->first();
                        @endphp
                        @if($logoSetting && $logoSetting->value)
                            <div class="mt-3">
                                <img src="{{ asset('storage/' . $logoSetting->value) }}" alt="Site Logo" style="max-height: 80px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                            </div>
                        @endif
                    </div>
                </div>
                <div class="mt-4 d-flex justify-content-end">
                    <button type="button" class="sa-btn sa-btn-outline px-4" onclick="switchTab('#contact')">{{ __('Next') }} <i class="bi bi-arrow-right ms-2"></i></button>
                </div>
            </div>
            
            <div class="tab-pane fade" id="contact">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h5 class="fw-bold mb-0">{{ __('Dynamic Contact Channels') }}</h5>
                    <button type="button" class="sa-btn sa-btn-outline px-3 py-1" onclick="addContactChannel()">
                        <i class="bi bi-plus-lg me-1"></i> {{ __('Add Channel') }}
                    </button>
                </div>
                
                <div id="contact-channels-container" class="row g-3">
                    @php
                        $channels = json_decode($settings['contact']['contact_channels'] ?? '[]', true);
                        if (empty($channels)) {
                            // Fallback to existing individual fields if any
                            $channels = [
                                ['type' => 'email', 'label' => 'Official Support', 'value' => $settings['contact']['official_email'] ?? 'support@edulearn.com'],
                                ['type' => 'whatsapp', 'label' => 'WhatsApp Support', 'value' => $settings['contact']['whatsapp_url'] ?? 'https://wa.me/967778682204']
                            ];
                        }
                    @endphp

                    @foreach($channels as $index => $channel)
                        <div class="col-md-6 contact-channel-item">
                            <div class="p-3 border rounded-4 position-relative" style="background: rgba(0, 0, 0, 0.2); border-color: rgba(255,255,255,0.05) !important;">
                                <button type="button" class="btn-close position-absolute top-0 end-0 m-2" onclick="removeChannel(this)" style="font-size: 0.7rem; filter: invert(1);"></button>
                                <div class="row g-2">
                                    <div class="col-4">
                                        <label class="small text-muted mb-1">{{ __('Type') }}</label>
                                        <select name="contact_channels[{{ $index }}][type]" class="form-select form-select-sm bg-dark text-white border-0">
                                            <option value="email" {{ $channel['type'] == 'email' ? 'selected' : '' }}>📧 {{ __('Email') }}</option>
                                            <option value="whatsapp" {{ $channel['type'] == 'whatsapp' ? 'selected' : '' }}>💬 {{ __('WhatsApp') }}</option>
                                            <option value="phone" {{ $channel['type'] == 'phone' ? 'selected' : '' }}>📞 {{ __('Phone') }}</option>
                                            <option value="telegram" {{ $channel['type'] == 'telegram' ? 'selected' : '' }}>✈️ {{ __('Telegram') }}</option>
                                            <option value="link" {{ $channel['type'] == 'link' ? 'selected' : '' }}>🔗 {{ __('Website/Link') }}</option>
                                        </select>
                                    </div>
                                    <div class="col-8">
                                        <label class="small text-muted mb-1">{{ __('Label') }}</label>
                                        <input type="text" name="contact_channels[{{ $index }}][label]" class="form-control form-control-sm bg-dark text-white border-0" value="{{ $channel['label'] }}" required>
                                    </div>
                                    <div class="col-12 mt-2">
                                        <label class="small text-muted mb-1">{{ __('Value') }}</label>
                                        <input type="text" name="contact_channels[{{ $index }}][value]" class="form-control form-control-sm bg-dark text-white border-0" value="{{ $channel['value'] }}" required>
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
                <div class="mt-4 d-flex justify-content-between">
                    <button type="button" class="sa-btn sa-btn-outline px-4" onclick="switchTab('#general')"><i class="bi bi-arrow-left me-2"></i> {{ __('Previous') }}</button>
                    <button type="button" class="sa-btn sa-btn-outline px-4" onclick="switchTab('#social')">{{ __('Next') }} <i class="bi bi-arrow-right ms-2"></i></button>
                </div>
            </div>

            <script>
                function addContactChannel() {
                    const container = document.getElementById('contact-channels-container');
                    const timestamp = Date.now(); // Guaranteed unique index for the current request
                    const html = `
                        <div class="col-md-6 contact-channel-item anim-fade-up">
                            <div class="p-3 border rounded-4 position-relative" style="background: rgba(0, 0, 0, 0.3); border-color: rgba(255,255,255,0.05) !important;">
                                <button type="button" class="btn-close position-absolute top-0 end-0 m-2" onclick="removeChannel(this)" style="font-size: 0.7rem; filter: invert(1);"></button>
                                <div class="row g-2">
                                    <div class="col-4">
                                        <label class="small text-muted mb-1">{{ __('Type') }}</label>
                                        <select name="contact_channels[${timestamp}][type]" class="form-select form-select-sm bg-dark text-white border-0 shadow-none">
                                            <option value="email">📧 {{ __('Email') }}</option>
                                            <option value="whatsapp">💬 {{ __('WhatsApp') }}</option>
                                            <option value="phone">📞 {{ __('Phone') }}</option>
                                            <option value="telegram">✈️ {{ __('Telegram') }}</option>
                                            <option value="link">🔗 {{ __('Website/Link') }}</option>
                                        </select>
                                    </div>
                                    <div class="col-8">
                                        <label class="small text-muted mb-1">{{ __('Label') }}</label>
                                        <input type="text" name="contact_channels[${timestamp}][label]" class="form-control form-control-sm bg-dark text-white border-0 shadow-none" required placeholder="New Channel">
                                    </div>
                                    <div class="col-12 mt-2">
                                        <label class="small text-muted mb-1">{{ __('Value') }}</label>
                                        <input type="text" name="contact_channels[${timestamp}][value]" class="form-control form-control-sm bg-dark text-white border-0 shadow-none" required placeholder="Link or info">
                                    </div>
                                </div>
                            </div>
                        </div>
                    `;
                    container.insertAdjacentHTML('beforeend', html);
                }

                function removeChannel(btn) {
                    btn.closest('.contact-channel-item').remove();
                }
            </script>

            <div class="tab-pane fade" id="social">
                <div class="row g-4">
                    <div class="col-md-6">
                        <label class="form-label">{{ __('Facebook URL') }}</label>
                        <input type="url" name="facebook_url" class="form-control" value="{{ $settings['social']['facebook_url'] ?? '#' }}">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">{{ __('Twitter/X URL') }}</label>
                        <input type="url" name="twitter_url" class="form-control" value="{{ $settings['social']['twitter_url'] ?? '#' }}">
                    </div>
                </div>
                <div class="mt-4 d-flex justify-content-start">
                    <button type="button" class="sa-btn sa-btn-outline px-4" onclick="switchTab('#contact')"><i class="bi bi-arrow-left me-2"></i> {{ __('Previous') }}</button>
                </div>
            </div>
        </div>

        <div class="mt-5 border-top pt-4" id="form-footer" style="display: none;">
            <button type="submit" id="save-btn" class="sa-btn sa-btn-primary px-5">{{ __('Save Settings') }}</button>
            <button type="reset" class="sa-btn sa-btn-outline ms-2">{{ __('Reset') }}</button>
        </div>
    </form>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const tabs = document.querySelectorAll('a[data-bs-toggle="tab"]');
        const footer = document.getElementById('form-footer');
        const saveBtn = document.getElementById('save-btn');

        function updateFooterVisibility(activeTabHash) {
            if (activeTabHash === '#social') {
                footer.style.display = 'block';
                saveBtn.textContent = "{{ __('Save Settings') }}";
            } else {
                footer.style.display = 'none';
            }
        }

        // Initialize on load
        const activeTab = document.querySelector('.nav-link.active');
        if (activeTab) updateFooterVisibility(activeTab.getAttribute('href'));

        // Listen for tab changes
        tabs.forEach(tab => {
            tab.addEventListener('shown.bs.tab', function (e) {
                updateFooterVisibility(e.target.getAttribute('href'));
            });
        });

        // Global switch function
        window.switchTab = function(targetHash) {
            const nextTabLink = document.querySelector(`a[href="${targetHash}"]`);
            if (nextTabLink) {
                const tabTrigger = new bootstrap.Tab(nextTabLink);
                tabTrigger.show();
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        };
    });
</script>
@endsection
