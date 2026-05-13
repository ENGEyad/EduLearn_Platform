import '../../core/app_localizations.dart';

extension StudentLessonViewerL10n on AppLocalizations {
  String get studentLessonViewerRefresh {
    return getValue('student_lesson_viewer_refresh');
  }

  String get studentLessonViewerBlocks {
    return getValue('student_lesson_viewer_blocks');
  }

  String studentLessonViewerSection(int number) {
    return formatValue(
      'student_lesson_viewer_section',
      {'number': number.toString()},
    );
  }

  String get studentLessonViewerErrorTitle {
    return getValue('student_lesson_viewer_error_title');
  }

  String get studentLessonViewerRetry {
    return getValue('student_lesson_viewer_retry');
  }

  String get studentLessonViewerEmptyLessonContent {
    return getValue('student_lesson_viewer_empty_lesson_content');
  }

  String get studentLessonViewerListen {
    return getValue('student_lesson_viewer_listen');
  }

  String get studentLessonViewerExercises {
    return getValue('student_lesson_viewer_exercises');
  }

  String get studentLessonViewerCompleted {
    return getValue('student_lesson_viewer_completed');
  }

  String get studentLessonViewerCompleteLesson {
    return getValue('student_lesson_viewer_complete_lesson');
  }

  String get studentLessonViewerNoAudioContent {
    return getValue('student_lesson_viewer_no_audio_content');
  }

  String get studentLessonViewerNoAudioClip {
    return getValue('student_lesson_viewer_no_audio_clip');
  }

  String get studentLessonViewerAudio {
    return getValue('student_lesson_viewer_audio');
  }

  String get studentLessonViewerImageNotAvailable {
    return getValue('student_lesson_viewer_image_not_available');
  }

  String get studentLessonViewerFileNotAvailable {
    return getValue('student_lesson_viewer_file_not_available');
  }

  String get studentLessonViewerCouldNotOpenFile {
    return getValue('student_lesson_viewer_could_not_open_file');
  }

  String get studentLessonViewerPdfDocumentation {
    return getValue('student_lesson_viewer_pdf_documentation');
  }

  String get studentLessonViewerTapToOpenDocument {
    return getValue('student_lesson_viewer_tap_to_open_document');
  }

  String get studentLessonViewerVideoNotAvailable {
    return getValue('student_lesson_viewer_video_not_available');
  }

  String get studentLessonViewerAudioNotAvailable {
    return getValue('student_lesson_viewer_audio_not_available');
  }

  String get studentLessonViewerAudioPlaybackFailed {
    return getValue('student_lesson_viewer_audio_playback_failed');
  }

  String get studentLessonViewerUnableToLoadVideo {
    return getValue('student_lesson_viewer_unable_to_load_video');
  }
}
