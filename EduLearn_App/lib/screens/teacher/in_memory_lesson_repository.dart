import 'package:flutter/foundation.dart';

class Lesson {
  final String id;
  final String classKey;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isDraft;

  Lesson({
    required this.id,
    required this.classKey,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isDraft,
  });
}

class InMemoryLessonRepository {
  InMemoryLessonRepository._internal();

  static final InMemoryLessonRepository _instance =
      InMemoryLessonRepository._internal();

  factory InMemoryLessonRepository() => _instance;

  final Map<String, List<Lesson>> _lessonsByClass = {};

  List<Lesson> getLessonsForClass(String classKey) {
    final list = _lessonsByClass[classKey] ?? <Lesson>[];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  void addLesson(Lesson lesson) {
    final list =
        _lessonsByClass.putIfAbsent(lesson.classKey, () => <Lesson>[]);
    list.add(lesson);

    if (kDebugMode) {
      print(
          'Lesson added for classKey=${lesson.classKey}, total=${list.length}');
    }
  }
}
