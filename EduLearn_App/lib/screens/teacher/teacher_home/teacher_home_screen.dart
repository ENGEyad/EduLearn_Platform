import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_home_l10n.dart';

import '../../../theme.dart';
import '../../../services/teacher_data_service.dart';
import '../lesson_builder/lesson_builder_screen.dart';
import 'teacher_home_models.dart';
import 'teacher_home_service.dart';

part 'teacher_home_widgets.dart';

class TeacherHomeScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherHomeScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  TeacherHomeSnapshot _snapshot = TeacherHomeSnapshot.empty();
  bool _isLoadingCards = true;
  bool _isRefreshing = false;
  String? _loadError;

  String get fullName => (widget.teacher['full_name'] ?? '').toString();
  String get teacherCode => (widget.teacher['teacher_code'] ?? '').toString();
  String? get imageUrl => widget.teacher['image'] as String?;

  String get _firstName {
    final parts = fullName.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return fullName.trim();
    return parts.first;
  }

  List<_StudentActivityItemData> _sampleActivities(AppLocalizations l10n) => [
    _StudentActivityItemData(
      title: l10n.sampleActivity1Title,
      subtitle: l10n.sampleActivity1Subtitle,
      icon: Icons.menu_book_rounded,
    ),
    _StudentActivityItemData(
      title: l10n.sampleActivity2Title,
      subtitle: l10n.sampleActivity2Subtitle,
      icon: Icons.quiz_rounded,
    ),
    _StudentActivityItemData(
      title: l10n.sampleActivity3Title,
      subtitle: l10n.sampleActivity3Subtitle,
      icon: Icons.checklist_rounded,
    ),
  ];

  List<_PerformanceMetricData> _sampleMetrics(AppLocalizations l10n) => [
    _PerformanceMetricData(
      label: l10n.metricLessonsCompletion,
      value: 0.76,
      valueText: '76%',
    ),
    _PerformanceMetricData(
      label: l10n.metricExercisesProgress,
      value: 0.63,
      valueText: '63%',
    ),
    _PerformanceMetricData(
      label: l10n.metricQuizPerformance,
      value: 0.58,
      valueText: '58%',
    ),
  ];

  IconData _iconForActivityType(String eventType) {
    switch (eventType) {
      case 'lesson_completed':
      case 'student_completed_lesson':
        return Icons.task_alt_rounded;
      case 'exercise_submitted':
      case 'student_submitted_exercise':
      case 'exercise_graded':
        return Icons.quiz_rounded;
      case 'teacher_published_lesson':
      case 'teacher_updated_lesson':
      case 'lesson_published':
      case 'lesson_updated':
        return Icons.menu_book_rounded;
      case 'teacher_published_exercise':
      case 'teacher_updated_exercise':
      case 'exercise_published':
      case 'exercise_updated':
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  List<_StudentActivityItemData> _activityItems(AppLocalizations l10n) {
    if (_snapshot.recentActivities.isEmpty) {
      return const [
        _StudentActivityItemData(
          title: 'No student activity yet',
          subtitle: 'Completed lessons and submitted exercises will appear here.',
          icon: Icons.notifications_none_rounded,
        ),
      ];
    }

    return _snapshot.recentActivities.map((activity) {
      final subtitleParts = <String>[
        if (activity.safeBody.isNotEmpty) activity.safeBody,
        if (activity.timeLabel.isNotEmpty) activity.timeLabel,
      ];
      return _StudentActivityItemData(
        title: activity.safeTitle,
        subtitle: subtitleParts.join(' • '),
        icon: _iconForActivityType(activity.eventType),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadHomeSnapshot();
  }

  Future<void> _loadHomeSnapshot({bool refresh = false}) async {
    if (teacherCode.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingCards = false;
        _isRefreshing = false;
        _loadError = 'Teacher code is missing.';
        _snapshot = TeacherHomeSnapshot.empty();
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoadingCards = true;
      }
      _loadError = null;
    });

    try {
      // ✅ removed teacherCode parameter
      final List<dynamic> assignments = await TeacherDataService.fetchAssignmentsSummary();

      final TeacherHomeSnapshot snapshot = await TeacherHomeService.buildSnapshot(
        teacherCode: teacherCode,
        assignments: assignments,
      );

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoadingCards = false;
        _isRefreshing = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCards = false;
        _isRefreshing = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showLessonsSheet({
    required String title,
    required List<TeacherHomeLessonItem> lessons,
    required Color cardColor,
    required Color titleColor,
    required Color mutedColor,
    required Color iconBoxColor,
    required Color shadowColor,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _TeacherHomeLessonsSheet(
          title: title,
          lessons: lessons,
          cardColor: cardColor,
          titleColor: titleColor,
          mutedColor: mutedColor,
          iconBoxColor: iconBoxColor,
          shadowColor: shadowColor,
          onLessonTap: (lesson) {
            Navigator.of(ctx).pop();
            _handleLessonTap(lesson);
          },
        );
      },
    );
  }

  Future<void> _handleLessonTap(TeacherHomeLessonItem lesson) async {
    final l10n = AppLocalizations.of(context);

    if (!lesson.canOpenDirectly) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.thisLessonNotEnoughContext)),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonBuilderScreen(
          classKey: lesson.classKey,
          classTitle: lesson.classTitle,
          studentsCount: lesson.studentsCount,
          teacherCode: teacherCode, // still needed until LessonBuilderScreen is updated
          assignmentId: lesson.assignmentId!,
          classSectionId: lesson.classSectionId!,
          subjectId: lesson.subjectId!,
          existingLessonId: lesson.lessonId,
          moduleId: lesson.moduleId!,
          moduleTitle: lesson.moduleTitle,
        ),
      ),
    );

    if (!mounted) return;
    await _loadHomeSnapshot(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor = theme.textTheme.bodySmall?.color ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color borderColor = (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
        .withValues(alpha: isDarkMode ? 0.95 : 0.88);
    final Color iconBoxColor = isDarkMode
        ? EduTheme.darkSurfaceContainer
        : EduTheme.softPrimaryBackground;
    final Color softAccentColor = isDarkMode
        ? EduTheme.darkSurfaceContainerHigh
        : EduTheme.surfaceContainer;
    final Color shadowColor = Colors.black.withValues(alpha: isDarkMode ? 0.20 : 0.07);

    return Scaffold(
      backgroundColor: pageBackground,
      body: Container(
        decoration: BoxDecoration(gradient: EduTheme.pageGradient(isDarkMode)),
        child: SafeArea(
          child: RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => _loadHomeSnapshot(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _TeacherHomeHeaderCard(
                  fullName: fullName.isEmpty ? l10n.teacher : fullName,
                  firstName: _firstName.isEmpty ? l10n.teacher : _firstName,
                  imageUrl: imageUrl,
                  cardColor: cardColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                  iconBoxColor: iconBoxColor,
                  shadowColor: shadowColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 22),
                if (_loadError != null && _loadError!.trim().isNotEmpty) ...[
                  _TeacherHomeErrorCard(
                    message: _loadError!,
                    cardColor: cardColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    iconBoxColor: iconBoxColor,
                    shadowColor: shadowColor,
                    borderColor: borderColor,
                    onRetry: _loadHomeSnapshot,
                  ),
                  const SizedBox(height: 16),
                ],
                _TeacherHomeSectionHeader(
                  title: l10n.quickAccess,
                  subtitle: l10n.quickAccessSubtitle,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 12),
                if (_isLoadingCards)
                  _TeacherHomeCardsLoadingState(
                    cardColor: cardColor,
                    shadowColor: shadowColor,
                    borderColor: borderColor,
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _TeacherHomePrimaryStatCard(
                          title: l10n.publishedLessons,
                          value: _snapshot.publishedCount.toString(),
                          subtitle: _snapshot.hasPublishedLessons
                              ? l10n.recentLessonsReady
                              : l10n.noPublishedLessonsYet,
                          icon: Icons.menu_book_rounded,
                          cardColor: cardColor,
                          titleColor: titleColor,
                          mutedColor: mutedColor,
                          iconBoxColor: iconBoxColor,
                          shadowColor: shadowColor,
                          borderColor: borderColor,
                          onTap: _snapshot.hasPublishedLessons
                              ? () => _showLessonsSheet(
                                    title: l10n.publishedLessons,
                                    lessons: _snapshot.publishedLessons,
                                    cardColor: cardColor,
                                    titleColor: titleColor,
                                    mutedColor: mutedColor,
                                    iconBoxColor: iconBoxColor,
                                    shadowColor: shadowColor,
                                  )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TeacherHomePrimaryStatCard(
                          title: l10n.savedDrafts,
                          value: _snapshot.serverDraftCount.toString(),
                          subtitle: _snapshot.hasServerDraftLessons
                              ? l10n.draftsSavedOnServer
                              : l10n.noSavedDraftsRightNow,
                          icon: Icons.cloud_outlined,
                          cardColor: cardColor,
                          titleColor: titleColor,
                          mutedColor: mutedColor,
                          iconBoxColor: iconBoxColor,
                          shadowColor: shadowColor,
                          borderColor: borderColor,
                          onTap: _snapshot.hasServerDraftLessons
                              ? () => _showLessonsSheet(
                                    title: l10n.savedDrafts,
                                    lessons: _snapshot.serverDraftLessons,
                                    cardColor: cardColor,
                                    titleColor: titleColor,
                                    mutedColor: mutedColor,
                                    iconBoxColor: iconBoxColor,
                                    shadowColor: shadowColor,
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TeacherHomePrimaryStatCard(
                    title: l10n.continueEditing,
                    value: _snapshot.localContinuationCount.toString(),
                    subtitle: _snapshot.hasLocalContinuationLessons
                        ? l10n.localLessonEditsOnDevice
                        : l10n.noLocalContinuationFound,
                    icon: Icons.edit_note_rounded,
                    cardColor: cardColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    iconBoxColor: iconBoxColor,
                    shadowColor: shadowColor,
                    borderColor: borderColor,
                    onTap: _snapshot.hasLocalContinuationLessons
                        ? () => _showLessonsSheet(
                              title: l10n.continueEditing,
                              lessons: _snapshot.localContinuationLessons,
                              cardColor: cardColor,
                              titleColor: titleColor,
                              mutedColor: mutedColor,
                              iconBoxColor: iconBoxColor,
                              shadowColor: shadowColor,
                            )
                        : null,
                    isWide: true,
                  ),
                ],
                const SizedBox(height: 24),
                _TeacherHomeSectionHeader(
                  title: l10n.whatsNew,
                  subtitle: l10n.whatsNewSubtitle,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 12),
                _TeacherHomeActivityFeedCard(
                  items: _activityItems(l10n),
                  cardColor: cardColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                  iconBoxColor: iconBoxColor,
                  shadowColor: shadowColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 22),
                _TeacherHomeFocusCard(
                  cardColor: cardColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                  shadowColor: shadowColor,
                  borderColor: borderColor,
                  softAccentColor: softAccentColor,
                  hasLocalContinuationLessons: _snapshot.hasLocalContinuationLessons,
                  hasServerDraftLessons: _snapshot.hasServerDraftLessons,
                ),
                if (_isRefreshing) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}