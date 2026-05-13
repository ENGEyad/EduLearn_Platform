class TeacherProgressMetricGroup {
  final Map<String, dynamic> raw;

  const TeacherProgressMetricGroup(this.raw);

  int get totalLessons => _readInt(raw['total_lessons']);
  int get completedLessons => _readInt(raw['completed_lessons']);
  int get inProgressLessons => _readInt(raw['in_progress_lessons']);
  int get notStartedLessons => _readInt(raw['not_started_lessons']);
  int get lessonCompletionRate => _readInt(raw['completion_rate']);

  int get totalExerciseSets => _readInt(raw['total_exercise_sets']);
  int get completedExerciseSets => _readInt(raw['completed_exercise_sets']);
  int get inProgressExerciseSets => _readInt(raw['in_progress_exercise_sets']);
  int get notStartedExerciseSets => _readInt(raw['not_started_exercise_sets']);
  int get exerciseCompletionRate => _readInt(raw['completion_rate']);
  int get accuracyRate => _readInt(raw['accuracy_rate']);
  double get score => _readDouble(raw['score']);
  double get totalPoints => _readDouble(raw['total_points']);
  int get questionCount => _readInt(raw['question_count']);
  int get answeredCount => _readInt(raw['answered_count']);
  int get unansweredCount => _readInt(raw['unanswered_count']);
  int get correctCount => _readInt(raw['correct_count']);
  int get wrongCount => _readInt(raw['wrong_count']);
  int get timeSpentSeconds => _readInt(raw['time_spent_seconds']);

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class TeacherStudentSubjectProgress {
  final Map<String, dynamic> raw;

  const TeacherStudentSubjectProgress(this.raw);

  factory TeacherStudentSubjectProgress.fromJson(Map<String, dynamic> json) {
    return TeacherStudentSubjectProgress(json);
  }

  Map<String, dynamic> get student {
    final value = raw['student'];
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  int get subjectId => _readInt(raw['subject_id']);
  int get classSectionId => _readInt(raw['class_section_id']);
  int get overallProgress => _readInt(raw['overall_progress']);
  int get totalStudyTimeSeconds => _readInt(raw['total_study_time_seconds']);

  TeacherProgressMetricGroup get lessons {
    final value = raw['lessons'];
    return TeacherProgressMetricGroup(
      value is Map<String, dynamic> ? value : <String, dynamic>{},
    );
  }

  TeacherProgressMetricGroup get exercises {
    final value = raw['exercises'];
    return TeacherProgressMetricGroup(
      value is Map<String, dynamic> ? value : <String, dynamic>{},
    );
  }

  String get studentName => (student['full_name'] ?? '').toString();
  String get academicId => (student['academic_id'] ?? '').toString();

  double get overallProgressValue => (overallProgress.clamp(0, 100)) / 100.0;
  double get lessonCompletionValue => (lessons.lessonCompletionRate.clamp(0, 100)) / 100.0;
  double get exerciseCompletionValue => (exercises.exerciseCompletionRate.clamp(0, 100)) / 100.0;
  double get accuracyValue => (exercises.accuracyRate.clamp(0, 100)) / 100.0;

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
