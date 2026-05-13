import 'package:flutter/foundation.dart';

enum TeacherHomeLessonStatus {
  published,
  draft,
}

enum TeacherHomeDraftSource {
  server,
  local,
}

@immutable
class TeacherHomeClassContext {
  final int assignmentId;
  final int classSectionId;
  final int subjectId;
  final String classTitle;
  final String classKey;
  final int studentsCount;
  final String grade;
  final String section;
  final String subjectName;

  const TeacherHomeClassContext({
    required this.assignmentId,
    required this.classSectionId,
    required this.subjectId,
    required this.classTitle,
    required this.classKey,
    required this.studentsCount,
    required this.grade,
    required this.section,
    required this.subjectName,
  });
}

@immutable
class TeacherHomeModuleContext {
  final int moduleId;
  final String moduleTitle;
  final TeacherHomeClassContext classContext;

  const TeacherHomeModuleContext({
    required this.moduleId,
    required this.moduleTitle,
    required this.classContext,
  });
}

@immutable
class TeacherHomeLessonItem {
  final int? lessonId;
  final String title;
  final TeacherHomeLessonStatus status;

  final int? assignmentId;
  final int? classSectionId;
  final int? subjectId;
  final int? moduleId;

  final String classTitle;
  final String classKey;
  final String moduleTitle;
  final int studentsCount;

  final String grade;
  final String section;
  final String subjectName;

  final TeacherHomeDraftSource? draftSource;
  final bool hasLocalDraft;
  final bool hasServerDraft;
  final String? localLessonState;

  const TeacherHomeLessonItem({
    required this.lessonId,
    required this.title,
    required this.status,
    required this.assignmentId,
    required this.classSectionId,
    required this.subjectId,
    required this.moduleId,
    required this.classTitle,
    required this.classKey,
    required this.moduleTitle,
    required this.studentsCount,
    required this.grade,
    required this.section,
    required this.subjectName,
    required this.draftSource,
    required this.hasLocalDraft,
    required this.hasServerDraft,
    required this.localLessonState,
  });

  bool get isPublished => status == TeacherHomeLessonStatus.published;

  bool get isDraft => status == TeacherHomeLessonStatus.draft;

  bool get canOpenDirectly =>
      assignmentId != null &&
      classSectionId != null &&
      subjectId != null &&
      moduleId != null;

  String get safeTitle => title.trim().isNotEmpty ? title.trim() : 'Untitled Lesson';

  String get locationLabel {
    final parts = <String>[];

    if (classTitle.trim().isNotEmpty) {
      parts.add(classTitle.trim());
    } else {
      if (grade.trim().isNotEmpty) {
        parts.add(grade.trim());
      }
      if (section.trim().isNotEmpty) {
        parts.add('Section ${section.trim()}');
      }
      if (subjectName.trim().isNotEmpty) {
        parts.add(subjectName.trim());
      }
    }

    if (moduleTitle.trim().isNotEmpty) {
      parts.add(moduleTitle.trim());
    }

    return parts.join(' • ');
  }

  TeacherHomeLessonItem copyWith({
    int? lessonId,
    String? title,
    TeacherHomeLessonStatus? status,
    int? assignmentId,
    int? classSectionId,
    int? subjectId,
    int? moduleId,
    String? classTitle,
    String? classKey,
    String? moduleTitle,
    int? studentsCount,
    String? grade,
    String? section,
    String? subjectName,
    TeacherHomeDraftSource? draftSource,
    bool? hasLocalDraft,
    bool? hasServerDraft,
    String? localLessonState,
  }) {
    return TeacherHomeLessonItem(
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      status: status ?? this.status,
      assignmentId: assignmentId ?? this.assignmentId,
      classSectionId: classSectionId ?? this.classSectionId,
      subjectId: subjectId ?? this.subjectId,
      moduleId: moduleId ?? this.moduleId,
      classTitle: classTitle ?? this.classTitle,
      classKey: classKey ?? this.classKey,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      studentsCount: studentsCount ?? this.studentsCount,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      subjectName: subjectName ?? this.subjectName,
      draftSource: draftSource ?? this.draftSource,
      hasLocalDraft: hasLocalDraft ?? this.hasLocalDraft,
      hasServerDraft: hasServerDraft ?? this.hasServerDraft,
      localLessonState: localLessonState ?? this.localLessonState,
    );
  }

  factory TeacherHomeLessonItem.fromServerLesson({
    required Map<String, dynamic> lesson,
    required TeacherHomeModuleContext moduleContext,
  }) {
    final int? lessonId = _asInt(lesson['id']);
    final String rawStatus = (lesson['status'] ?? 'published').toString().trim();

    final TeacherHomeLessonStatus status =
        rawStatus == 'draft'
            ? TeacherHomeLessonStatus.draft
            : TeacherHomeLessonStatus.published;

    return TeacherHomeLessonItem(
      lessonId: lessonId,
      title: (lesson['title'] ?? '').toString().trim(),
      status: status,
      assignmentId: moduleContext.classContext.assignmentId,
      classSectionId: moduleContext.classContext.classSectionId,
      subjectId: moduleContext.classContext.subjectId,
      moduleId: moduleContext.moduleId,
      classTitle: moduleContext.classContext.classTitle,
      classKey: moduleContext.classContext.classKey,
      moduleTitle: moduleContext.moduleTitle,
      studentsCount: moduleContext.classContext.studentsCount,
      grade: moduleContext.classContext.grade,
      section: moduleContext.classContext.section,
      subjectName: moduleContext.classContext.subjectName,
      draftSource:
          status == TeacherHomeLessonStatus.draft
              ? TeacherHomeDraftSource.server
              : null,
      hasLocalDraft: false,
      hasServerDraft: status == TeacherHomeLessonStatus.draft,
      localLessonState: null,
    );
  }

  factory TeacherHomeLessonItem.fromLocalDraft({
    required String title,
    required int? lessonId,
    required TeacherHomeModuleContext? moduleContext,
    required String? localLessonState,
  }) {
    return TeacherHomeLessonItem(
      lessonId: lessonId,
      title: title.trim(),
      status: TeacherHomeLessonStatus.draft,
      assignmentId: moduleContext?.classContext.assignmentId,
      classSectionId: moduleContext?.classContext.classSectionId,
      subjectId: moduleContext?.classContext.subjectId,
      moduleId: moduleContext?.moduleId,
      classTitle: moduleContext?.classContext.classTitle ?? '',
      classKey: moduleContext?.classContext.classKey ?? '',
      moduleTitle: moduleContext?.moduleTitle ?? '',
      studentsCount: moduleContext?.classContext.studentsCount ?? 0,
      grade: moduleContext?.classContext.grade ?? '',
      section: moduleContext?.classContext.section ?? '',
      subjectName: moduleContext?.classContext.subjectName ?? '',
      draftSource: TeacherHomeDraftSource.local,
      hasLocalDraft: true,
      hasServerDraft: false,
      localLessonState: localLessonState,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

@immutable
class TeacherHomeActivityItem {
  final int? id;
  final String eventType;
  final String title;
  final String body;
  final String actorType;
  final int? actorId;
  final int? classSectionId;
  final int? subjectId;
  final int? lessonId;
  final int? exerciseSetId;
  final DateTime? createdAt;

  const TeacherHomeActivityItem({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.actorType,
    required this.actorId,
    required this.classSectionId,
    required this.subjectId,
    required this.lessonId,
    required this.exerciseSetId,
    required this.createdAt,
  });

  String get safeTitle =>
      title.trim().isNotEmpty ? title.trim() : _fallbackTitle(eventType);

  String get safeBody => body.trim();

  String get timeLabel {
    final DateTime? value = createdAt;
    if (value == null) return '';

    final Duration diff = DateTime.now().difference(value.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  factory TeacherHomeActivityItem.fromJson(Map<String, dynamic> json) {
    return TeacherHomeActivityItem(
      id: _asInt(json['id']),
      eventType: (json['event_type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['description'] ?? '').toString(),
      actorType: (json['actor_type'] ?? '').toString(),
      actorId: _asInt(json['actor_id']),
      classSectionId: _asInt(json['class_section_id']),
      subjectId: _asInt(json['subject_id']),
      lessonId: _asInt(json['lesson_id']),
      exerciseSetId: _asInt(json['exercise_set_id']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String _fallbackTitle(String type) {
    switch (type) {
      case 'lesson_completed':
      case 'student_completed_lesson':
        return 'Lesson completed';
      case 'exercise_submitted':
      case 'student_submitted_exercise':
      case 'exercise_graded':
        return 'Exercise submitted';
      case 'teacher_published_lesson':
      case 'lesson_published':
        return 'Lesson published';
      case 'teacher_updated_lesson':
      case 'lesson_updated':
        return 'Lesson updated';
      case 'teacher_published_exercise':
      case 'exercise_published':
        return 'Exercise published';
      case 'teacher_updated_exercise':
      case 'exercise_updated':
        return 'Exercise updated';
      default:
        return 'Learning activity';
    }
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

@immutable
class TeacherHomeSnapshot {
  final List<TeacherHomeLessonItem> publishedLessons;
  final List<TeacherHomeLessonItem> serverDraftLessons;
  final List<TeacherHomeLessonItem> localContinuationLessons;
  final List<TeacherHomeActivityItem> recentActivities;

  const TeacherHomeSnapshot({
    required this.publishedLessons,
    required this.serverDraftLessons,
    required this.localContinuationLessons,
    required this.recentActivities,
  });

  factory TeacherHomeSnapshot.empty() {
    return const TeacherHomeSnapshot(
      publishedLessons: <TeacherHomeLessonItem>[],
      serverDraftLessons: <TeacherHomeLessonItem>[],
      localContinuationLessons: <TeacherHomeLessonItem>[],
      recentActivities: <TeacherHomeActivityItem>[],
    );
  }

  int get publishedCount => publishedLessons.length;

  int get serverDraftCount => serverDraftLessons.length;

  int get localContinuationCount => localContinuationLessons.length;

  bool get hasPublishedLessons => publishedLessons.isNotEmpty;

  bool get hasServerDraftLessons => serverDraftLessons.isNotEmpty;

  bool get hasLocalContinuationLessons => localContinuationLessons.isNotEmpty;

  bool get hasRecentActivities => recentActivities.isNotEmpty;
}