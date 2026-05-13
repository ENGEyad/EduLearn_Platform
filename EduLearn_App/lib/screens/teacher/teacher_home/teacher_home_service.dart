import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/lesson_service.dart';
import '../../../services/teacher_service.dart';
import 'teacher_home_models.dart';

class TeacherHomeService {
  const TeacherHomeService._();

  static Future<TeacherHomeSnapshot> buildSnapshot({
    required String teacherCode,
    required List<dynamic> assignments,
  }) async {
    final List<TeacherHomeClassContext> classContexts = _extractClassContexts(assignments);
    final List<TeacherHomeActivityItem> recentActivities = await _loadRecentActivities();

    if (classContexts.isEmpty) {
      return TeacherHomeSnapshot(
        publishedLessons: const [],
        serverDraftLessons: const [],
        localContinuationLessons: const [],
        recentActivities: recentActivities,
      );
    }

    final List<TeacherHomeModuleContext> moduleContexts = await _loadModuleContexts(
      teacherCode: teacherCode,
      classContexts: classContexts,
    );

    if (moduleContexts.isEmpty) {
      final List<TeacherHomeLessonItem> localContinuationLessons =
          await _loadLocalContinuationLessons(
            moduleContexts: const [],
            allServerLessonsByLessonId: const {},
          );
      return TeacherHomeSnapshot(
        publishedLessons: const [],
        serverDraftLessons: const [],
        localContinuationLessons: _sortLessons(localContinuationLessons),
        recentActivities: recentActivities,
      );
    }

    final List<TeacherHomeLessonItem> serverLessons = await _loadServerLessons(
      moduleContexts: moduleContexts,
    );

    final List<TeacherHomeLessonItem> publishedLessons = serverLessons
        .where((item) => item.status == TeacherHomeLessonStatus.published)
        .toList();
    final List<TeacherHomeLessonItem> serverDraftLessons = serverLessons
        .where((item) => item.status == TeacherHomeLessonStatus.draft)
        .toList();

    final Map<int, TeacherHomeLessonItem> allServerLessonsByLessonId = {};
    for (final item in serverLessons) {
      final int? lessonId = item.lessonId;
      if (lessonId != null) allServerLessonsByLessonId[lessonId] = item;
    }

    final List<TeacherHomeLessonItem> localContinuationLessons =
        await _loadLocalContinuationLessons(
          moduleContexts: moduleContexts,
          allServerLessonsByLessonId: allServerLessonsByLessonId,
        );

    return TeacherHomeSnapshot(
      publishedLessons: _sortLessons(publishedLessons),
      serverDraftLessons: _sortLessons(serverDraftLessons),
      localContinuationLessons: _sortLessons(localContinuationLessons),
      recentActivities: recentActivities,
    );
  }

  // ------------------------------------------------
  // تمت إزالة teacherCode من استدعاء خدمة الأنشطة
  // ------------------------------------------------
  static Future<List<TeacherHomeActivityItem>> _loadRecentActivities() async {
    try {
      final page = await TeacherService.fetchTeacherActivities(limit: 8);
      return page.activities
          .map(TeacherHomeActivityItem.fromJson)
          .where((item) => item.safeTitle.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<TeacherHomeClassContext> _extractClassContexts(List<dynamic> assignments) {
    final List<TeacherHomeClassContext> results = [];
    for (final dynamic item in assignments) {
      if (item is! Map) continue;
      final Map<String, dynamic> map = Map<String, dynamic>.from(item.cast<String, dynamic>());
      final int? assignmentId = _asInt(map['assignment_id']);
      final int? classSectionId = _asInt(map['class_section_id']);
      final int? subjectId = _asInt(map['subject_id']);
      if (assignmentId == null || classSectionId == null || subjectId == null) continue;

      results.add(TeacherHomeClassContext(
        assignmentId: assignmentId,
        classSectionId: classSectionId,
        subjectId: subjectId,
        classTitle: _buildClassTitle(map),
        classKey: _buildClassKey(map),
        studentsCount: _asInt(map['students_count']) ?? 0,
        grade: (map['class_grade'] ?? '').toString().trim(),
        section: (map['class_section'] ?? '').toString().trim(),
        subjectName: (map['subject_name'] ?? '').toString().trim(),
      ));
    }
    return results;
  }

  static String _buildClassTitle(Map<String, dynamic> map) {
    final grade = (map['class_grade'] ?? '').toString().trim();
    final section = (map['class_section'] ?? '').toString().trim();
    final subject = (map['subject_name'] ?? '').toString().trim();
    final parts = <String>[];
    if (grade.isNotEmpty) parts.add(grade);
    if (section.isNotEmpty) parts.add('Section $section');
    if (subject.isNotEmpty) parts.add(subject);
    return parts.join(' - ');
  }

  static String _buildClassKey(Map<String, dynamic> map) {
    final grade = (map['class_grade'] ?? '').toString().trim();
    final section = (map['class_section'] ?? '').toString().trim();
    final subject = (map['subject_name'] ?? '').toString().trim();
    return '${grade}_${section}_$subject';
  }

  static Future<List<TeacherHomeModuleContext>> _loadModuleContexts({
    required String teacherCode,
    required List<TeacherHomeClassContext> classContexts,
  }) async {
    final futures = classContexts.map((ctx) async {
      try {
        // ✅ added teacherCode parameter
        final modules = await LessonService.fetchLessonModules(
          teacherCode: teacherCode,
          assignmentId: ctx.assignmentId,
          classSectionId: ctx.classSectionId,
          subjectId: ctx.subjectId,
        );
        return modules
            .whereType<Map>()
            .map((m) {
              final id = _asInt(m['id']);
              if (id == null) return null;
              return TeacherHomeModuleContext(
                moduleId: id,
                moduleTitle: (m['title'] ?? '').toString().trim(),
                classContext: ctx,
              );
            })
            .whereType<TeacherHomeModuleContext>()
            .toList();
      } catch (_) {
        return <TeacherHomeModuleContext>[];
      }
    });
    final resolved = await Future.wait(futures);
    return resolved.expand((e) => e).toList();
  }

  static Future<List<TeacherHomeLessonItem>> _loadServerLessons({
    required List<TeacherHomeModuleContext> moduleContexts,
  }) async {
    final futures = moduleContexts.map((mCtx) async {
      try {
        final lessons = await LessonService.fetchLessonsForModule(
          moduleId: mCtx.moduleId,
        );
        return lessons
            .whereType<Map>()
            .map((l) => TeacherHomeLessonItem.fromServerLesson(
                  lesson: Map<String, dynamic>.from(l.cast<String, dynamic>()),
                  moduleContext: mCtx,
                ))
            .toList();
      } catch (_) {
        return <TeacherHomeLessonItem>[];
      }
    });
    final resolved = await Future.wait(futures);
    return resolved.expand((e) => e).toList();
  }

  static Future<List<TeacherHomeLessonItem>> _loadLocalContinuationLessons({
    required List<TeacherHomeModuleContext> moduleContexts,
    required Map<int, TeacherHomeLessonItem> allServerLessonsByLessonId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('lesson_draft_')).toList();
    if (keys.isEmpty) return [];

    final moduleMap = {for (final m in moduleContexts) m.moduleId: m};
    final results = <TeacherHomeLessonItem>[];

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final draft = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
        final title = (draft['title'] ?? '').toString().trim();
        final lessonId = _asInt(draft['lesson_id']);
        final state = (draft['lesson_state'] ?? '').toString().trim();

        if (!_shouldKeep(state)) continue;

        TeacherHomeModuleContext? ctx;
        if (lessonId != null) {
          final server = allServerLessonsByLessonId[lessonId];
          if (server != null && server.moduleId != null) {
            ctx = moduleMap[server.moduleId];
          }
        }
        if (ctx == null) {
          final parsed = _parseNewDraftKey(key);
          if (parsed != null) {
            final exact = moduleMap[parsed.moduleId];
            if (exact != null &&
                exact.classContext.classSectionId == parsed.classSectionId &&
                exact.classContext.subjectId == parsed.subjectId) {
              ctx = exact;
            }
          }
        }

        results.add(TeacherHomeLessonItem.fromLocalDraft(
          title: title,
          lessonId: lessonId,
          moduleContext: ctx,
          localLessonState: state,
        ));
      } catch (_) {}
    }
    return results;
  }

  static bool _shouldKeep(String state) {
    final s = state.trim().toLowerCase();
    return s == 'unsaved' || s == 'draft';
  }

  static List<TeacherHomeLessonItem> _sortLessons(List<TeacherHomeLessonItem> items) {
    final copy = List.of(items);
    copy.sort((a, b) => a.safeTitle.toLowerCase().compareTo(b.safeTitle.toLowerCase()));
    return copy;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  static _ParsedNewDraftKey? _parseNewDraftKey(String key) {
    const prefix = 'lesson_draft_new_';
    if (!key.startsWith(prefix)) return null;
    final parts = key.substring(prefix.length).split('_');
    if (parts.length != 3) return null;
    final classSectionId = int.tryParse(parts[0]);
    final subjectId = int.tryParse(parts[1]);
    final moduleId = int.tryParse(parts[2]);
    if (classSectionId == null || subjectId == null || moduleId == null) return null;
    return _ParsedNewDraftKey(
      classSectionId: classSectionId,
      subjectId: subjectId,
      moduleId: moduleId,
    );
  }
}

class _ParsedNewDraftKey {
  final int classSectionId;
  final int subjectId;
  final int moduleId;
  const _ParsedNewDraftKey({
    required this.classSectionId,
    required this.subjectId,
    required this.moduleId,
  });
}