@extends('super_admin.layout')
@section('title', __('Global Subjects'))

@push('styles')
<style>
    .subject-icon-preview { width: 48px; height: 48px; border-radius: 14px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; }
    .icon-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(45px, 1fr)); gap: 10px; max-height: 200px; overflow-y: auto; padding: 10px; border: 1px solid var(--border); border-radius: 12px; }
    .icon-item { cursor: pointer; padding: 8px; border-radius: 8px; text-align: center; transition: all 0.2s; border: 1px solid transparent; color: var(--muted); }
    .icon-item:hover { background: rgba(255,255,255,0.05); border-color: var(--border); color: var(--white); }
    .icon-item.selected { background: rgba(255,102,0,0.15); border-color: var(--orange); color: var(--orange); }
    .sa-action-icon { padding: 0.45rem 0.65rem; border-radius: 10px; font-size: 0.85rem; border: 1px solid var(--border); background: rgba(255,255,255,0.04); color: var(--text); cursor: pointer; transition: all 0.2s; }
    .sa-action-icon:hover { border-color: var(--orange); color: var(--orange); }
    .sa-action-icon.danger:hover { border-color: #ef4444; color: #ef4444; }
    .form-control-color { height: 44px; border-radius: 12px; }
</style>
@endpush

@section('content')
<div class="sa-header">
    <div>
        <h1><i class="bi bi-book-half me-2" style="color: var(--orange);"></i>{{ __('Global Subjects') }}</h1>
        <p>{{ __('Define subjects schools can use and set their visual identity') }}</p>
    </div>
    <button class="sa-btn sa-btn-primary" data-bs-toggle="modal" data-bs-target="#addSubjectModal">
        <i class="bi bi-plus-lg me-2"></i> {{ __('Add Subject') }}
    </button>
</div>

<div class="sa-card" style="padding: 0; overflow: hidden;">
    <div style="overflow-x: auto;">
        <table class="sa-table">
            <thead>
                <tr>
                    <th class="ps-4">{{ __('Subject') }}</th>
                    <th>{{ __('Code') }}</th>
                    <th>{{ __('Visual Identity') }}</th>
                    <th>{{ __('Status') }}</th>
                    <th class="text-center pe-4">{{ __('Actions') }}</th>
                </tr>
            </thead>
            <tbody>
                @foreach($subjects as $subject)
                <tr>
                    <td class="ps-4">
                        <div class="fw-bold">{{ $subject->name_ar }}</div>
                        <div class="small" style="color: var(--muted);">{{ $subject->name_en }}</div>
                    </td>
                    <td><code style="color: var(--orange); background: rgba(255,102,0,0.08); padding: 0.2rem 0.6rem; border-radius: 6px;">{{ $subject->code }}</code></td>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <div class="subject-icon-preview" style="background-color: {{ $subject->color ?? '#003366' }}; color: white;">
                                <i class="bi {{ $subject->icon ?? 'bi-book' }}"></i>
                            </div>
                            <span class="small" style="color: var(--muted);">{{ $subject->color ?? 'Default' }}</span>
                        </div>
                    </td>
                    <td>
                        @if($subject->is_active)
                            <span class="sa-badge sa-badge-active"><i class="bi bi-check-circle"></i> {{ __('Active') }}</span>
                        @else
                            <span class="sa-badge" style="background: rgba(148,163,184,0.15); color: #94a3b8; border: 1px solid rgba(148,163,184,0.3);">{{ __('Inactive') }}</span>
                        @endif
                    </td>
                    <td class="text-center pe-4">
                        <button class="sa-action-icon me-1" data-bs-toggle="modal" data-bs-target="#editSubjectModal{{ $subject->id }}"><i class="bi bi-pencil"></i></button>
                        <form action="{{ route('super-admin.subjects.destroy', $subject) }}" method="POST" class="d-inline">
                            @csrf @method('DELETE')
                            <button class="sa-action-icon danger" onclick="return confirm('{{ __('Confirm Delete') }}?')"><i class="bi bi-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <!-- Edit Modal -->
                <div class="modal fade" id="editSubjectModal{{ $subject->id }}" tabindex="-1">
                    <div class="modal-dialog">
                        <form action="{{ route('super-admin.subjects.update', $subject) }}" method="POST">
                            @csrf @method('PUT')
                            <div class="modal-content">
                                <div class="modal-header" style="background: rgba(255,102,0,0.06);">
                                    <h5 class="modal-title fw-bold">{{ __('Edit') }}: {{ $subject->name_ar }}</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body p-4">
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <label class="form-label">{{ __('Name (Arabic)') }}</label>
                                            <input type="text" name="name_ar" class="form-control" value="{{ $subject->name_ar }}" required>
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label">{{ __('Name (English)') }}</label>
                                            <input type="text" name="name_en" class="form-control" value="{{ $subject->name_en }}" required>
                                        </div>
                                        <div class="col-md-12">
                                            <label class="form-label">{{ __('Code') }}</label>
                                            <input type="text" name="code" class="form-control" value="{{ $subject->code }}" required>
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label">{{ __('Color') }}</label>
                                            <input type="color" name="color" class="form-control form-control-color w-100" value="{{ $subject->color ?? '#FF6600' }}">
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label">{{ __('Status') }}</label>
                                            <select name="is_active" class="form-select">
                                                <option value="1" {{ $subject->is_active ? 'selected' : '' }}>{{ __('Active') }}</option>
                                                <option value="0" {{ !$subject->is_active ? 'selected' : '' }}>{{ __('Inactive') }}</option>
                                            </select>
                                        </div>
                                        <div class="col-md-12">
                                            <label class="form-label">{{ __('Icon') }}</label>
                                            <input type="text" name="icon" class="form-control mb-2" value="{{ $subject->icon }}" id="iconInput{{ $subject->id }}" placeholder="bi-book">
                                            <div class="icon-grid" data-target="#iconInput{{ $subject->id }}"></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="sa-btn sa-btn-outline" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                                    <button type="submit" class="sa-btn sa-btn-primary">{{ __('Save Changes') }}</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                @endforeach
            </tbody>
        </table>
    </div>
</div>

<!-- Add Modal -->
<div class="modal fade" id="addSubjectModal" tabindex="-1">
    <div class="modal-dialog">
        <form action="{{ route('super-admin.subjects.store') }}" method="POST">
            @csrf
            <div class="modal-content">
                <div class="modal-header" style="background: rgba(255,102,0,0.06);">
                    <h5 class="modal-title fw-bold">{{ __('Add Subject') }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body p-4">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label">{{ __('Name (Arabic)') }}</label>
                            <input type="text" name="name_ar" class="form-control" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">{{ __('Name (English)') }}</label>
                            <input type="text" name="name_en" class="form-control" required>
                        </div>
                        <div class="col-md-12">
                            <label class="form-label">{{ __('Code') }}</label>
                            <input type="text" name="code" class="form-control" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">{{ __('Color') }}</label>
                            <input type="color" name="color" class="form-control form-control-color w-100" value="#FF6600">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">{{ __('Icon') }}</label>
                            <input type="text" name="icon" class="form-control" id="addIconInput" placeholder="bi-book">
                        </div>
                        <div class="col-md-12">
                            <div class="icon-grid" data-target="#addIconInput"></div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="sa-btn sa-btn-outline" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                    <button type="submit" class="sa-btn sa-btn-primary">{{ __('Add Subject') }}</button>
                </div>
            </div>
        </form>
    </div>
</div>
@endsection

@push('scripts')
<script>
    const commonIcons = [
        'bi-book', 'bi-calculator', 'bi-pencil-square', 'bi-mortarboard', 'bi-globe', 'bi-translate',
        'bi-music-note-beamed', 'bi-palette', 'bi-cpu', 'bi-code-slash', 'bi-graph-up', 'bi-virus',
        'bi-infinity', 'bi-lightning-charge', 'bi-compass', 'bi-star', 'bi-heart', 'bi-shield-check'
    ];
    document.querySelectorAll('.icon-grid').forEach(grid => {
        const targetInput = document.querySelector(grid.dataset.target);
        commonIcons.forEach(icon => {
            const item = document.createElement('div');
            item.className = 'icon-item';
            item.innerHTML = `<i class="bi ${icon} fs-4"></i>`;
            item.onclick = () => {
                grid.querySelectorAll('.icon-item').forEach(i => i.classList.remove('selected'));
                item.classList.add('selected');
                targetInput.value = icon;
            };
            grid.appendChild(item);
        });
    });
</script>
@endpush
