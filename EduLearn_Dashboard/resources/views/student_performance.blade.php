@extends('layouts.app')

@section('content')
<div class="row g-3">
  <div class="col-12">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <nav aria-label="breadcrumb">
          <ol class="breadcrumb mb-1">
            <li class="breadcrumb-item"><a href="{{ route('students.index') }}" class="text-decoration-none">{{ __('Students') }}</a></li>
            <li class="breadcrumb-item active" aria-current="page">{{ $student->full_name }}</li>
          </ol>
        </nav>
        <h5 class="mb-1 text-dark fw-bold">{{ $pageTitle }}</h5>
        <small class="text-muted">{{ $pageSubtitle }}</small>
      </div>
    </div>

    @if(empty($performanceList))
        <div class="sa-empty py-5 text-center bg-white rounded border shadow-sm">
            <i class="bi bi-person-x display-4 text-muted opacity-50 mb-3 d-block"></i>
            <h6 class="fw-bold">{{ __('No Data Available') }}</h6>
            <p class="text-muted small">{{ __('This student is not enrolled in any subjects with tracked performance.') }}</p>
        </div>
    @else
        <div class="row g-3">
            @foreach($performanceList as $perf)
                <div class="col-md-12">
                    <div class="card-panel h-100 border-0 shadow-sm" style="background: var(--card);">
                        <div class="d-flex justify-content-between align-items-center mb-3 pb-3 border-bottom">
                            <h5 class="fw-bold mb-0 text-primary">
                                <i class="bi bi-journal-bookmark me-2"></i> 
                                {{ app()->getLocale() == 'ar' ? $perf['subject']->name_ar : $perf['subject']->name_en }}
                            </h5>
                            <div class="text-end">
                                <span class="badge {{ $perf['avg_score'] >= 50 ? 'bg-success' : 'bg-danger' }} bg-opacity-10 {{ $perf['avg_score'] >= 50 ? 'text-success' : 'text-danger' }} px-3 py-2 rounded-pill fs-6 border {{ $perf['avg_score'] >= 50 ? 'border-success' : 'border-danger' }} border-opacity-25">
                                    {{ __('Avg Score') }}: {{ $perf['avg_score'] }}%
                                </span>
                            </div>
                        </div>

                        <div class="row g-4 pt-2">
                            <div class="col-md-4 border-end">
                                <h6 class="text-muted small fw-bold mb-3 text-uppercase tracking-wider">{{ __('Lesson Progress') }}</h6>
                                
                                <div class="d-flex justify-content-between align-items-center mb-1">
                                    <span class="text-dark fw-semibold fs-5">{{ $perf['progress_percent'] }}%</span>
                                    <span class="text-muted small">{{ $perf['completed_lessons'] }} / {{ $perf['total_lessons'] }} {{ __('Lessons') }}</span>
                                </div>
                                <div class="progress" style="height: 8px;">
                                    <div class="progress-bar bg-primary" role="progressbar" style="width: {{ $perf['progress_percent'] }}%"></div>
                                </div>
                                <div class="mt-3">
                                    <p class="text-muted small mb-0"><i class="bi bi-clock-history me-1"></i> {{ __('Total Study Time') }}: <strong class="text-dark">{{ $perf['total_study_time'] }} {{ __('min') }}</strong></p>
                                </div>
                            </div>
                            
                            <div class="col-md-8">
                                <h6 class="text-muted small fw-bold mb-3 text-uppercase tracking-wider">{{ __('Exercises & Quizzes') }}</h6>
                                @if($perf['attempts']->isEmpty())
                                    <div class="text-center py-4 bg-light rounded text-muted small">
                                        <i class="bi bi-file-earmark-x mb-2 d-block fs-5 opacity-50"></i>
                                        {{ __('No exercise attempts recorded yet.') }}
                                    </div>
                                @else
                                    <div class="table-responsive" style="max-height: 200px;">
                                        <table class="table table-sm table-hover align-middle mb-0">
                                            <thead class="bg-light sticky-top">
                                                <tr>
                                                    <th class="text-muted small">{{ __('Exercise Set / Lesson') }}</th>
                                                    <th class="text-muted small text-center">{{ __('Score') }}</th>
                                                    <th class="text-muted small text-end">{{ __('Date') }}</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                @foreach($perf['attempts'] as $attempt)
                                                    <tr>
                                                        <td>
                                                            <div class="fw-semibold small text-dark">{{ $attempt->exerciseSet->title ?? __('Unknown Exercise') }}</div>
                                                            <div class="text-muted" style="font-size: 0.70rem;">{{ $attempt->lesson->title ?? '' }}</div>
                                                        </td>
                                                        <td class="text-center">
                                                            <span class="badge {{ ($attempt->score / max($attempt->total_points, 1)) >= 0.5 ? 'bg-success' : 'bg-danger' }} rounded-pill">
                                                                {{ $attempt->score }} / {{ $attempt->total_points }}
                                                            </span>
                                                        </td>
                                                        <td class="text-end text-muted small">
                                                            {{ $attempt->submitted_at ? $attempt->submitted_at->format('M d, Y') : '--' }}
                                                        </td>
                                                    </tr>
                                                @endforeach
                                            </tbody>
                                        </table>
                                    </div>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    @endif
  </div>
</div>
@endsection
