@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
      <div>
        <nav aria-label="breadcrumb">
          <ol class="breadcrumb flex-wrap mb-1">
            <li class="breadcrumb-item"><a href="{{ route('subjects.index') }}" class="text-decoration-none">{{ __('Subjects') }}</a></li>
            <li class="breadcrumb-item active" aria-current="page">{{ app()->getLocale() == 'ar' ? $subject->name_ar : $subject->name_en }}</li>
          </ol>
        </nav>
        <h5 class="fw-bold text-title mb-1">{{ $pageTitle }}</h5>
        <small class="text-muted">{{ $pageSubtitle }}</small>
      </div>
    </div>

    <div class="card-panel">
      @if($lessons->isEmpty())
        <div class="sa-empty py-5 text-center">
            <i class="bi bi-journal-x display-4 text-muted opacity-50 mb-3 d-block"></i>
            <h6 class="fw-bold">{{ __('No lessons found') }}</h6>
            <p class="text-muted small">{{ __('Teachers have not added any lessons or exercises for this subject yet.') }}</p>
        </div>
      @else
        <div class="accordion" id="curriculumAccordion">
          @foreach($lessons as $index => $lesson)
            <div class="accordion-item mb-3 border rounded shadow-sm overflow-hidden">
              <h2 class="accordion-header" id="heading{{ $lesson->id }}">
                <button class="accordion-button {{ $index == 0 ? '' : 'collapsed' }} bg-white fw-bold" type="button" data-bs-toggle="collapse" data-bs-toggle="collapse" data-bs-target="#collapse{{ $lesson->id }}" aria-expanded="{{ $index == 0 ? 'true' : 'false' }}" aria-controls="collapse{{ $lesson->id }}">
                  <i class="bi bi-play-circle text-primary me-2"></i> {{ $lesson->title }}
                  @if($lesson->status == 'published')
                    <span class="badge bg-success bg-opacity-10 text-success ms-3 border border-success border-opacity-25">{{ __('Published') }}</span>
                  @else
                    <span class="badge bg-warning bg-opacity-10 text-warning ms-3 border border-warning border-opacity-25">{{ __('Draft') }}</span>
                  @endif
                </button>
              </h2>
              <div id="collapse{{ $lesson->id }}" class="accordion-collapse collapse {{ $index == 0 ? 'show' : '' }}" aria-labelledby="heading{{ $lesson->id }}" data-bs-parent="#curriculumAccordion">
                <div class="accordion-body bg-light">
                  <div class="row g-3">
                    <div class="col-12 col-md-7">
                        <div class="mb-2 mb-md-0">
                            <h6 class="fw-bold text-dark mb-2"><i class="bi bi-info-circle me-1"></i> {{ __('Lesson Details') }}</h6>
                            <p class="text-muted small mb-1">{{ __('Teacher') }}: <strong>{{ $lesson->teacher->full_name ?? __('N/A') }}</strong></p>
                            <p class="text-muted small mb-1">{{ __('Class Section') }}: <strong>{{ $lesson->classSection->grade ?? '' }} - {{ $lesson->classSection->class_section ?? '' }}</strong></p>
                            <p class="text-muted small mb-0">{{ __('Published At') }}: <strong>{{ $lesson->published_at ? $lesson->published_at->format('M d, Y h:i A') : '--' }}</strong></p>
                        </div>
                    </div>
                    <div class="col-12 col-md-5">
                      <div class="bg-white p-3 rounded border shadow-sm h-100">
                          <h6 class="fw-bold text-dark mb-3"><i class="bi bi-ui-checks-grid me-1"></i> {{ __('Exercises & Assessments') }}</h6>
                          @if($lesson->exerciseSet)
                              <div class="d-flex align-items-center mb-2">
                                  <i class="bi bi-check2-square text-success me-2 fs-5"></i>
                                  <div>
                                     <strong class="d-block small">{{ __('Exercise Set Available') }}</strong>
                                     <span class="text-muted" style="font-size: 0.75rem;">{{ $lesson->exerciseSet->title ?? __('Exercises') }}</span>
                                  </div>
                              </div>
                              <div class="mt-3 pt-2 border-top">
                                  <span class="badge bg-primary bg-opacity-10 text-primary">{{ $lesson->exerciseSet->questions()->count() ?? 0 }} {{ __('Questions') }}</span>
                              </div>
                          @else
                              <div class="text-center py-3 text-muted">
                                  <i class="bi bi-x-circle opacity-50 mb-2 d-block fs-4"></i>
                                  <small>{{ __('No exercises assigned') }}</small>
                              </div>
                          @endif
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          @endforeach
        </div>
      @endif
    </div>
  </div>
</div>
@endsection
