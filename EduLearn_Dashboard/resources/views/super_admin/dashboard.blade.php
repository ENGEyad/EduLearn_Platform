@extends('super_admin.layout')

@section('title', __('School Management'))

@section('content')
<!-- Header -->
<div class="sa-header">
    <div>
        <h1>{{ __('Welcome, Super Admin') }} 👋</h1>
        <p>{{ __('Platform overview — school subscriptions and management') }}</p>
    </div>
    <div class="sa-time">
        📅 <strong>{{ now()->format('Y-m-d') }}</strong> &nbsp; 🕐 {{ now()->format('H:i') }}
    </div>
</div>

<!-- Stats -->
<div class="row row-cols-2 row-cols-md-4 g-3 mb-4">
    <div class="col">
        <div class="sa-card sa-stat h-100">
            <div class="label">{{ __('Total Schools') }}</div>
            <div class="value">{{ $stats['total'] }}</div>
            <i class="bi bi-buildings sa-stat-icon"></i>
        </div>
    </div>
    <div class="col">
        <div class="sa-card sa-stat h-100" style="background: linear-gradient(135deg, var(--navy-light), #001A33); border-color: rgba(0,100,200,0.3);">
            <div class="d-flex flex-column flex-sm-row gap-2 gap-sm-4">
                <div>
                    <div class="label">{{ __('Main') }}</div>
                    <div class="value" style="font-size: 1.25rem;">{{ $stats['main_schools'] }}</div>
                </div>
                <div class="border-sm-start ps-sm-3 pt-2 pt-sm-0" style="border-top: 1px solid var(--border); margin-top: 5px; padding-top: 5px;" class="d-sm-none">
                    <div class="label">{{ __('Branch') }}</div>
                    <div class="value" style="font-size: 1.25rem;">{{ $stats['branches'] }}</div>
                </div>
            </div>
            <i class="bi bi-diagram-3-fill sa-stat-icon"></i>
        </div>
    </div>
    <div class="col">
        <div class="sa-card sa-stat h-100">
            <div class="label">{{ __('Pending') }}</div>
            <div class="value" style="color: var(--orange);">{{ $stats['pending'] }}</div>
            <i class="bi bi-hourglass-split sa-stat-icon"></i>
        </div>
    </div>
    <div class="col">
        <div class="sa-card sa-stat h-100">
            <div class="label">{{ __('Active') }}</div>
            <div class="value" style="color: #10b981;">{{ $stats['active'] }}</div>
            <i class="bi bi-check-circle-fill sa-stat-icon"></i>
        </div>
    </div>
</div>

<!-- Schools Table -->
<div class="sa-card p-0 overflow-hidden">
    <div class="p-3 p-md-4 d-flex flex-column flex-md-row justify-content-between align-items-md-center border-bottom border-light border-opacity-10 gap-3">
        <h5 class="mb-0"><i class="bi bi-list-ul me-2" style="color: var(--orange);"></i>{{ __('School Logs') }}</h5>
        <div class="position-relative w-100" style="max-width: 320px;">
            <i class="bi bi-search position-absolute top-50 translate-middle-y text-muted" style="{{ app()->getLocale() == 'ar' ? 'right: 1rem;' : 'left: 1rem;' }}"></i>
            <input type="text" id="schoolSearch" class="form-control ps-5" placeholder="{{ __('Search...') }}" style="{{ app()->getLocale() == 'ar' ? 'padding-right: 2.5rem; padding-left: 1rem;' : 'padding-left: 2.5rem;' }}">
        </div>
    </div>
    <div class="table-responsive">
        <table class="sa-table" id="schoolsTable">
            <thead>
                <tr>
                    <th>{{ __('School') }}</th>
                    <th class="d-none d-lg-table-cell">{{ __('Type') }}</th>
                    <th class="d-none d-md-table-cell">{{ __('Contact') }}</th>
                    <th class="d-none d-xl-table-cell">{{ __('Details') }}</th>
                    <th>{{ __('Status') }}</th>
                    <th class="text-center">{{ __('Actions') }}</th>
                </tr>
            </thead>
            <tbody>
                @forelse($schools as $school)
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-3">
                            <div style="width: 42px; height: 42px; border-radius: 12px; background: rgba(255,255,255,0.05); border: 1px solid var(--border); display: grid; place-items: center; overflow: hidden;">
                                @if($school->logo_path)
                                    <img src="{{ asset('storage/'.$school->logo_path) }}" alt="Logo" style="width: 100%; height: 100%; object-fit: cover;">
                                @else
                                    <i class="bi bi-building fs-5" style="color: var(--muted);"></i>
                                @endif
                            </div>
                            <div>
                                <div class="fw-bold">{{ $school->name }}</div>
                                <div class="small" style="color: var(--muted);">{{ $school->city }}, {{ $school->country }}</div>
                            </div>
                        </div>
                    </td>
                    <td class="d-none d-lg-table-cell">
                        @if($school->isBranch())
                            <span class="sa-badge" style="background: rgba(255,102,0,0.12); color: var(--orange); border: 1px solid rgba(255,102,0,0.3);"><i class="bi bi-diagram-2"></i> {{ __('Branch') }}</span>
                        @else
                            <span class="sa-badge" style="background: rgba(0,51,102,0.2); color: #4da6ff; border: 1px solid rgba(0,100,200,0.3);"><i class="bi bi-star-fill"></i> {{ __('Main') }}</span>
                        @endif
                    </td>
                    <td class="d-none d-md-table-cell">
                        <div class="small fw-bold">{{ $school->admin_name }}</div>
                        <div class="small text-muted">{{ $school->email }}</div>
                    </td>
                    <td class="d-none d-xl-table-cell">
                        <div class="small"><span style="color: var(--muted);">{{ __('Type') }}:</span> {{ $school->school_type }}</div>
                    </td>
                    <td>
                        <span class="sa-badge sa-badge-{{ $school->status }}">
                            @switch($school->status)
                                @case('pending') <i class="bi bi-clock"></i> {{ __('Pending') }} @break
                                @case('active') <i class="bi bi-check-circle"></i> {{ __('Active') }} @break
                                @case('suspended') <i class="bi bi-pause-circle"></i> {{ __('Suspended') }} @break
                                @case('rejected') <i class="bi bi-x-circle"></i> {{ __('Rejected') }} @break
                                @default {{ $school->status }}
                            @endswitch
                        </span>
                    </td>
                    <td class="text-center">
                        <div class="dropdown">
                            <button class="sa-btn sa-btn-outline px-2 py-1" type="button" data-bs-toggle="dropdown">
                                <i class="bi bi-three-dots"></i>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end shadow border-0" style="background: var(--navy); border: 1px solid var(--border) !important;">
                                @if($school->status === 'pending')
                                    <li>
                                        <form action="{{ route('super-admin.schools.approve', $school) }}" method="POST">
                                            @csrf
                                            <button class="dropdown-item py-2" style="color: #10b981;" onclick="confirmAction(event, '{{ __('Are you sure?') }}', '{{ __('This school will be approved and activated immediately.') }}', 'question', '{{ __('Yes, Approve') }}')">
                                                <i class="bi bi-check-circle me-2"></i> {{ __('Approve & Activate') }}
                                            </button>
                                        </form>
                                    </li>
                                    <li>
                                        <button class="dropdown-item py-2" style="color: #ef4444;" data-bs-toggle="modal" data-bs-target="#rejectModal{{ $school->id }}">
                                            <i class="bi bi-x-circle me-2"></i> {{ __('Reject') }}
                                        </button>
                                    </li>
                                    <li>
                                        <button class="dropdown-item py-2" style="color: var(--orange);" data-bs-toggle="modal" data-bs-target="#modifyModal{{ $school->id }}">
                                            <i class="bi bi-pencil-square me-2"></i> {{ __('Request Modification') }}
                                        </button>
                                    </li>
                                @endif
                                @if($school->status === 'active')
                                    <li>
                                        <form action="{{ route('super-admin.schools.suspend', $school) }}" method="POST">
                                            @csrf
                                            <button class="dropdown-item py-2" style="color: var(--muted);">
                                                <i class="bi bi-pause-circle me-2"></i> {{ __('Suspend') }}
                                            </button>
                                        </form>
                                    </li>
                                @endif
                                @if($school->status === 'suspended' || $school->status === 'rejected')
                                    <li>
                                        <form action="{{ route('super-admin.schools.activate', $school) }}" method="POST">
                                            @csrf
                                            <button class="dropdown-item py-2" style="color: #10b981;">
                                                <i class="bi bi-play-circle me-2"></i> {{ __('Reactivate') }}
                                            </button>
                                        </form>
                                    </li>
                                @endif
                                <li><hr class="dropdown-divider" style="border-color: var(--border);"></li>
                                <li>
                                    <button class="dropdown-item py-2" style="color: #25D366;" onclick="sendWhatsApp('{{ $school->phone }}', '{{ __("Hello :name, we are contacting you regarding your registration on EduLearn.", ["name" => $school->admin_name]) }}')">
                                        <i class="bi bi-whatsapp me-2"></i> {{ __('WhatsApp Contact') }}
                                    </button>
                                </li>
                                <li>
                                    <button class="dropdown-item py-2" style="color: #4da6ff;" data-bs-toggle="modal" data-bs-target="#notifyModal{{ $school->id }}">
                                        <i class="bi bi-chat-dots me-2"></i> {{ __('Internal Notification') }}
                                    </button>
                                </li>
                            </ul>
                        </div>
                    </td>
                </tr>

                <!-- Modals per school -->
                <div class="modal fade" id="rejectModal{{ $school->id }}" tabindex="-1">
                    <div class="modal-dialog">
                        <form action="{{ route('super-admin.schools.reject', $school) }}" method="POST">
                            @csrf
                            <div class="modal-content">
                                <div class="modal-header" style="background: rgba(239,68,68,0.1);">
                                    <h5 class="modal-title fw-bold" style="color: #ef4444;">{{ __('Reject') }} {{ $school->name }}</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body p-4">
                                    <label class="form-label">{{ __('Rejection Reason') }}</label>
                                    <textarea name="reason" class="form-control" rows="4" required></textarea>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="sa-btn sa-btn-outline" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                                    <button type="button" class="sa-btn" style="background: #25D366; color: #fff;" onclick="sendWhatsApp('{{ $school->phone }}', '{{ __('Hello :name, unfortunately your school registration has been rejected for the following reason: ', ['name' => $school->admin_name]) }}' + this.closest('.modal-content').querySelector('textarea').value)">
                                        <i class="bi bi-whatsapp me-1"></i> {{ __('Reject & WhatsApp') }}
                                    </button>
                                    <button type="submit" class="sa-btn" style="background: #ef4444; color: #fff;">{{ __('Confirm Rejection') }}</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>

                <div class="modal fade" id="modifyModal{{ $school->id }}" tabindex="-1">
                    <div class="modal-dialog">
                        <form action="{{ route('super-admin.schools.request-modification', $school) }}" method="POST">
                            @csrf
                            <div class="modal-content">
                                <div class="modal-header" style="background: rgba(255,102,0,0.1);">
                                    <h5 class="modal-title fw-bold" style="color: var(--orange);">{{ __('Request Modification') }} - {{ $school->name }}</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body p-4">
                                    <label class="form-label">{{ __('Modification Instructions') }}</label>
                                    <textarea name="instructions" class="form-control" rows="4" required></textarea>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="sa-btn sa-btn-outline" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                                    <button type="button" class="sa-btn" style="background: #25D366; color: #fff;" onclick="sendWhatsApp('{{ $school->phone }}', '{{ __('Hello :name, we need some modifications for your school registration: ', ['name' => $school->admin_name]) }}' + this.closest('.modal-content').querySelector('textarea').value)">
                                        <i class="bi bi-whatsapp me-1"></i> {{ __('Send via WhatsApp') }}
                                    </button>
                                    <button type="submit" class="sa-btn sa-btn-primary">{{ __('Submit') }}</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>

                <div class="modal fade" id="notifyModal{{ $school->id }}" tabindex="-1">
                    <div class="modal-dialog">
                        <form action="{{ route('super-admin.schools.notify', $school) }}" method="POST">
                            @csrf
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title fw-bold">{{ __('Send Message') }} - {{ $school->name }}</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body p-4">
                                    <textarea name="message" class="form-control" rows="4" required></textarea>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="sa-btn sa-btn-outline" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                                    <button type="button" class="sa-btn" style="background: #25D366; color: #fff;" onclick="sendWhatsApp('{{ $school->phone }}', this.closest('.modal-content').querySelector('textarea').value)">
                                        <i class="bi bi-whatsapp me-1"></i> {{ __('Send via WhatsApp') }}
                                    </button>
                                    <button type="submit" class="sa-btn sa-btn-primary">{{ __('Send Internally') }}</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                @empty
                <tr>
                    <td colspan="6">
                        <div class="sa-empty">
                            <i class="bi bi-inbox"></i>
                            <p>{{ __('No schools registered yet') }}</p>
                        </div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script>
    // WhatsApp logic
    function sendWhatsApp(phone, message) {
        if(!phone) {
            Swal.fire('Error', 'No phone number available for this school', 'error');
            return;
        }
        // Remove non-numeric characters except leading plus if any
        let cleanPhone = phone.replace(/[^\d+]/g, '');
        // If it starts with 00, replace with +
        if(cleanPhone.startsWith('00')) cleanPhone = '+' + cleanPhone.substring(2);
        // If it doesn't have a +, and you have a default country code, you could add it here
        // For now, wa.me handles numbers with or without + if they include country code
        const url = `https://wa.me/${cleanPhone.replace('+', '')}?text=${encodeURIComponent(message)}`;
        window.open(url, '_blank');
    }

    // Search logic
    document.getElementById('schoolSearch').addEventListener('keyup', function() {
        let v = this.value.toLowerCase();
        document.querySelectorAll('#schoolsTable tbody tr').forEach(r => {
            r.style.display = r.innerText.toLowerCase().includes(v) ? '' : 'none';
        });
    });

    // Confirm action
    function confirmAction(event, title, text, icon, confirmBtnText) {
        event.preventDefault();
        const form = event.target.closest('form');
        Swal.fire({
            title, text, icon,
            showCancelButton: true,
            confirmButtonColor: '#FF6600',
            cancelButtonColor: '#94a3b8',
            confirmButtonText: confirmBtnText,
            cancelButtonText: '{{ __("Cancel") }}',
            background: '#001A33',
            color: '#e2e8f0',
            customClass: { title: 'fw-bold', confirmButton: 'px-4 py-2', cancelButton: 'px-4 py-2' }
        }).then(result => { if (result.isConfirmed) form.submit(); });
    }

    // 3D Tilt on stat cards
    document.querySelectorAll('.sa-stat').forEach(card => {
        card.addEventListener('mousemove', e => {
            const r = card.getBoundingClientRect();
            const rx = ((e.clientY - r.top) - r.height/2) / r.height * -4;
            const ry = ((e.clientX - r.left) - r.width/2) / r.width * 4;
            card.style.transform = `translateY(-4px) rotateX(${rx}deg) rotateY(${ry}deg)`;
        });
        card.addEventListener('mouseleave', () => { card.style.transform = ''; });
    });
</script>
@endpush
