part of 'student_subject_detail_screen.dart';

class _StudentLessonModule {
  final int id;
  final String title;
  final List<_StudentLessonSummary> lessons;

  _StudentLessonModule({
    required this.id,
    required this.title,
    required this.lessons,
  });
}

class _StudentLessonSummary {
  final int id;
  final String title;
  final String durationLabel;
  String status;

  _StudentLessonSummary({
    required this.id,
    required this.title,
    required this.durationLabel,
    required this.status,
  });
}
class _StudentSubjectProgressSummary {
  final int overallProgress;
  final int lessonCompletionRate;
  final int exerciseCompletionRate;
  final int exerciseAccuracyRate;
  final int totalStudyTimeSeconds;
  final int completedLessons;
  final int totalLessons;
  final int completedExerciseSets;
  final int totalExerciseSets;

  const _StudentSubjectProgressSummary({
    required this.overallProgress,
    required this.lessonCompletionRate,
    required this.exerciseCompletionRate,
    required this.exerciseAccuracyRate,
    required this.totalStudyTimeSeconds,
    required this.completedLessons,
    required this.totalLessons,
    required this.completedExerciseSets,
    required this.totalExerciseSets,
  });

  double get overallValue => (overallProgress.clamp(0, 100)) / 100.0;

  String get overallText => '${overallProgress.clamp(0, 100)}%';

  factory _StudentSubjectProgressSummary.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    Map<String, dynamic> readMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return const <String, dynamic>{};
    }

    final lessons = readMap(json['lessons']);
    final exercises = readMap(json['exercises']);

    final int overall = readInt(
      json['overall_progress'] ??
          json['overall_subject_progress'] ??
          json['progress'] ??
          json['progress_percentage'] ??
          0,
    );

    final int lessonRate = readInt(
      json['lesson_completion_rate'] ??
          lessons['completion_rate'] ??
          lessons['lesson_completion_rate'] ??
          0,
    );

    final int exerciseCompletion = readInt(
      json['exercise_completion_rate'] ??
          exercises['completion_rate'] ??
          exercises['exercise_completion_rate'] ??
          0,
    );

    final int exerciseAccuracy = readInt(
      json['exercise_accuracy_rate'] ??
          exercises['accuracy_rate'] ??
          exercises['average_accuracy_rate'] ??
          0,
    );

    return _StudentSubjectProgressSummary(
      overallProgress: overall.clamp(0, 100),
      lessonCompletionRate: lessonRate.clamp(0, 100),
      exerciseCompletionRate: exerciseCompletion.clamp(0, 100),
      exerciseAccuracyRate: exerciseAccuracy.clamp(0, 100),
      totalStudyTimeSeconds: readInt(
        json['total_study_time_seconds'] ??
            lessons['time_spent_seconds'] ??
            exercises['time_spent_seconds'] ??
            0,
      ),
      completedLessons: readInt(
        json['completed_lessons'] ?? lessons['completed_lessons'] ?? 0,
      ),
      totalLessons: readInt(
        json['total_lessons'] ?? lessons['total_lessons'] ?? 0,
      ),
      completedExerciseSets: readInt(
        json['completed_exercise_sets'] ??
            exercises['completed_exercise_sets'] ??
            0,
      ),
      totalExerciseSets: readInt(
        json['total_exercise_sets'] ?? exercises['total_exercise_sets'] ?? 0,
      ),
    );
  }
}
