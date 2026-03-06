@extends('layouts.app')

@section('content')
  <div class="card-panel">
    <h5 class="mb-1">{{ $pageTitle ?? 'Page' }}</h5>
    <p class="text-muted mb-0">{{ $pageSubtitle ?? '' }}</p>
    <p class="mt-3 mb-0">This page is not implemented yet.</p>
  </div>
@endsection
