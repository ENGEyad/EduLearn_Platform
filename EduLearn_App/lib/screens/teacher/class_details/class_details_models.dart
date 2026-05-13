part of 'class_details_screen.dart';

class _LessonModule {
  final int id;
  String title;
  int lessonsCount;

  _LessonModule({
    required this.id,
    required this.title,
    required this.lessonsCount,
  });
}

class _LessonSummary {
  final int id;
  final String title;
  final String status;

  _LessonSummary({
    required this.id,
    required this.title,
    required this.status,
  });
}
