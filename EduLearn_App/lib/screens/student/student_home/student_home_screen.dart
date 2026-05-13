import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_home_l10n.dart';
import '../../../theme.dart';
import '../../../services/student_service.dart';

part 'student_home_widgets.dart';

class StudentHomeScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentHomeScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  Map<String, dynamic>? _progressOverview;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoadingProgress = false;
  String? _progressError;

  @override
  void initState() {
    super.initState();
    _loadProgressOverview();
  }

  Future<void> _loadProgressOverview() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProgress = true;
      _progressError = null;
    });

    try {
      // ✅ removed academicId from both service calls
      final results = await Future.wait<dynamic>([
        StudentService.fetchStudentProgressOverview(),
        StudentService.fetchStudentActivities(limit: 6),
      ]);

      if (!mounted) return;

      final overview = Map<String, dynamic>.from(results[0] as Map);
      final activitiesPage = results[1];

      setState(() {
        _progressOverview = overview;

        if (activitiesPage is StudentActivitiesPage) {
          _activities = activitiesPage.activities;
        } else if (activitiesPage is List) {
          // توافق مؤقت
          _activities = activitiesPage
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          _activities = [];
        }

        _isLoadingProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progressError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingProgress = false;
      });
    }
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _readPercent(dynamic value) {
    if (value is int) return value.clamp(0, 100).toInt();
    if (value is num) return value.round().clamp(0, 100).toInt();
    final parsed = double.tryParse(value?.toString() ?? '');
    return parsed == null ? 0 : parsed.round().clamp(0, 100).toInt();
  }

  int _overviewProgressPercent() {
    final root = _progressOverview;
    if (root == null) return 0;

    final direct = _readPercent(
      root['overall_progress'] ??
          root['overall_subject_progress'] ??
          root['progress'] ??
          root['progress_percentage'] ??
          root['average_overall_progress'],
    );

    if (direct > 0) return direct;

    final subjects = root['subjects'];
    if (subjects is List && subjects.isNotEmpty) {
      final values = subjects
          .whereType<Map>()
          .map(
            (e) => _readPercent(
              e['overall_progress'] ??
                  e['progress'] ??
                  e['progress_percentage'],
            ),
          )
          .where((value) => value > 0)
          .toList();

      if (values.isNotEmpty) {
        return (values.reduce((a, b) => a + b) / values.length)
            .round()
            .clamp(0, 100)
            .toInt();
      }
    }

    return _readPercent(
      root['lesson_completion_rate'] ??
          root['exercise_completion_rate'] ??
          root['exercise_accuracy_rate'],
    );
  }

  String _activityTitle(Map<String, dynamic> activity) {
    final l10n = AppLocalizations.of(context);
    final title = (activity['title'] ?? '').toString().trim();
    if (title.isNotEmpty) return title;

    switch ((activity['event_type'] ?? '').toString()) {
      case 'teacher_published_lesson':
      case 'lesson_published':
        return l10n.studentHomeNewLessonPublished;
      case 'teacher_updated_lesson':
      case 'lesson_updated':
        return l10n.studentHomeLessonUpdated;
      case 'teacher_published_exercise':
      case 'exercise_published':
        return l10n.studentHomeNewExercisesPublished;
      case 'teacher_updated_exercise':
      case 'exercise_updated':
        return l10n.studentHomeExercisesUpdated;
      case 'lesson_completed':
      case 'student_completed_lesson':
        return l10n.studentHomeLessonCompleted;
      case 'exercise_submitted':
      case 'student_submitted_exercise':
      case 'exercise_graded':
        return l10n.studentHomeExerciseSubmitted;
      default:
        return l10n.studentHomeLearningUpdate;
    }
  }

  String _activitySubtitle(Map<String, dynamic> activity) {
    final body = (activity['body'] ?? activity['description'] ?? '').toString().trim();
    final time = _activityTimeLabel(activity['created_at']);

    if (body.isNotEmpty && time.isNotEmpty) return '$body • $time';
    if (body.isNotEmpty) return body;
    if (time.isNotEmpty) return time;
    return AppLocalizations.of(context).studentHomeCheckLatestUpdates;
  }

  IconData _activityIcon(Map<String, dynamic> activity) {
    switch ((activity['event_type'] ?? '').toString()) {
      case 'teacher_published_lesson':
      case 'teacher_updated_lesson':
      case 'lesson_published':
      case 'lesson_updated':
      case 'lesson_completed':
      case 'student_completed_lesson':
        return Icons.menu_book_rounded;
      case 'teacher_published_exercise':
      case 'teacher_updated_exercise':
      case 'exercise_published':
      case 'exercise_updated':
      case 'exercise_submitted':
      case 'student_submitted_exercise':
      case 'exercise_graded':
        return Icons.quiz_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _activityTimeLabel(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return '';

    final value = DateTime.tryParse(text);
    if (value == null) return '';

    final diff = DateTime.now().difference(value.toLocal());
    final l10n = AppLocalizations.of(context);
    if (diff.inMinutes < 1) return l10n.studentHomeJustNow;
    if (diff.inMinutes < 60) return l10n.studentHomeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.studentHomeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.studentHomeDaysAgo(diff.inDays);

    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  List<_StudentHomeActivityData> _activityItems() {
    return _activities.map((activity) {
      return _StudentHomeActivityData(
        title: _activityTitle(activity),
        subtitle: _activitySubtitle(activity),
        icon: _activityIcon(activity),
      );
    }).toList();
  }

  String _progressSubtitle() {
    final l10n = AppLocalizations.of(context);
    if (_isLoadingProgress) {
      return l10n.studentHomeLoadingProgress;
    }
    if (_progressError != null) {
      return l10n.studentHomeProgressRefreshConnection;
    }

    final subjectsCount = _readInt(_progressOverview?['subjects_count']);
    final lessonRate = _readInt(_progressOverview?['lesson_completion_rate']);
    final exerciseRate = _readInt(_progressOverview?['exercise_accuracy_rate']);

    if (subjectsCount <= 0) {
      return l10n.studentHomeStartLessonsBuildProgress;
    }

    return l10n.studentHomeProgressAcrossSubjects(
      subjectsCount,
      lessonRate,
      exerciseRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final String fullName = (widget.student['full_name'] ?? '').toString().trim();
    final String? imageUrl = widget.student['image'] as String?;

    final int progressPercent = _overviewProgressPercent();
    final double progressValue = progressPercent / 100.0;

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color borderColor = (isDarkMode
            ? EduTheme.darkInputBorder
            : EduTheme.inputBorder)
        .withValues(alpha: isDarkMode ? 0.95 : 0.86);
    final Color iconBoxColor = isDarkMode
        ? EduTheme.darkSurfaceContainer
        : EduTheme.softPrimaryBackground;
    final Color softAccentColor = isDarkMode
        ? EduTheme.darkSurfaceContainerHigh
        : EduTheme.softSecondaryBackground;
    final Color progressBackground = isDarkMode
        ? EduTheme.darkSurfaceContainerHigh
        : EduTheme.inputBorder.withValues(alpha: 0.88);
    final Color shadowColor = theme.shadowColor.withValues(
      alpha: isDarkMode ? 0.20 : 0.07,
    );

    return Scaffold(
      backgroundColor: pageBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: EduTheme.pageGradient(isDarkMode),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadProgressOverview,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StudentHeaderCard(
                    fullName: fullName.isEmpty ? l10n.studentHomeStudentFallback : fullName,
                    imageUrl: imageUrl,
                    cardColor: cardColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    iconBoxColor: iconBoxColor,
                    shadowColor: shadowColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 22),
                  _StudentSectionHeader(
                    title: l10n.studentHomeOverview,
                    subtitle: l10n.studentHomeOverviewSubtitle,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 12),
                  _StudentProgressCard(
                    cardColor: cardColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    borderColor: borderColor,
                    shadowColor: shadowColor,
                    progressBackground: progressBackground,
                    iconBoxColor: iconBoxColor,
                    value: progressValue,
                    valueText: '$progressPercent%',
                    title: l10n.studentHomeOverallProgress,
                    subtitle: _progressSubtitle(),
                  ),
                  const SizedBox(height: 18),
                  _OngoingLessonCard(
                    cardColor: cardColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    borderColor: borderColor,
                    shadowColor: shadowColor,
                    iconBoxColor: softAccentColor,
                  ),
                  const SizedBox(height: 24),
                  _StudentSectionHeader(
                    title: l10n.studentHomeLatestUpdates,
                    subtitle: l10n.studentHomeLatestUpdatesSubtitle,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 12),
                  _StudentActivityFeedCard(
                    items: _activityItems(),
                    cardColor: cardColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    iconBoxColor: iconBoxColor,
                    shadowColor: shadowColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 24),
                  _StudentSectionHeader(
                    title: l10n.studentHomeRecommendedForYou,
                    subtitle: l10n.studentHomeRecommendedSubtitle,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RecommendedCard(
                          title: l10n.studentHomeExploreRomanEmpire,
                          subtitle: l10n.studentHomeExpandHistoricalKnowledge,
                          imageUrl:
                              'https://images.unsplash.com/photo-1461360370896-922624d12aa1?auto=format&fit=crop&w=900&q=80',
                          cardColor: cardColor,
                          titleColor: titleColor,
                          mutedColor: mutedColor,
                          previewColor: softAccentColor,
                          shadowColor: shadowColor,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RecommendedCard(
                          title: l10n.studentHomePracticeAdvancedAlgebra,
                          subtitle: l10n.studentHomeAlgebraPracticeSubtitle,
                          imageUrl:
                              'https://images.unsplash.com/photo-1509228468518-180dd4864904?auto=format&fit=crop&w=900&q=80',
                          cardColor: cardColor,
                          titleColor: titleColor,
                          mutedColor: mutedColor,
                          previewColor: softAccentColor,
                          shadowColor: shadowColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}