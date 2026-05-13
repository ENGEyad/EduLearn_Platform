import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'teacher_progress_models.dart';
import 'teacher_progress_service.dart';

class StudentSubjectProgressScreen extends StatefulWidget {
  final String studentName;
  final String? studentImageUrl;
  final String subjectName;
  final String grade;
  final String section;

  /// Required for live API loading.
  /// Kept optional so older navigation calls do not break immediately.
  final String? teacherCode;
  final int? studentId;
  final String? academicId;
  final int? subjectId;
  final int? assignmentId; // ✅ جديد

  const StudentSubjectProgressScreen({
    super.key,
    required this.studentName,
    this.studentImageUrl,
    required this.subjectName,
    required this.grade,
    required this.section,
    this.teacherCode,
    this.studentId,
    this.academicId,
    this.subjectId,
    this.assignmentId,
  });

  @override
  State<StudentSubjectProgressScreen> createState() =>
      _StudentSubjectProgressScreenState();
}

class _StudentSubjectProgressScreenState
    extends State<StudentSubjectProgressScreen> {
  bool _isLoading = false;
  String? _error;
  TeacherStudentSubjectProgress? _progress;

  bool get _hasApiContext {
    final hasTeacher = widget.teacherCode != null && widget.teacherCode!.trim().isNotEmpty;
    final hasSubject = widget.subjectId != null && widget.subjectId! > 0;
    final hasStudent = (widget.studentId != null && widget.studentId! > 0) ||
        (widget.academicId != null && widget.academicId!.trim().isNotEmpty);
    return hasTeacher && hasSubject && hasStudent;
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (!_hasApiContext) {
      setState(() {
        _isLoading = false;
        _error = 'Progress context is missing. Pass teacherCode, subjectId, and studentId or academicId.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await TeacherProgressService.fetchStudentSubjectProgress(
        studentId: widget.studentId,
        academicId: widget.academicId,
        subjectId: widget.subjectId!,
        assignmentId: widget.assignmentId,
      );

      if (!mounted) return;
      setState(() {
        _progress = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  String _scoreText(TeacherStudentSubjectProgress progress) {
    final score = progress.exercises.score;
    final total = progress.exercises.totalPoints;
    if (total <= 0) return '${progress.exercises.accuracyRate}%';

    String fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${fmt(score)} / ${fmt(total)}';
  }

  String _progressNote(TeacherStudentSubjectProgress progress) {
    final value = progress.overallProgress;
    if (value >= 85) return 'Excellent progress. The student is performing strongly in this subject.';
    if (value >= 65) return 'Good progress. The student is moving steadily and can improve with continued practice.';
    if (value >= 35) return 'Moderate progress. The student needs follow-up on lessons and exercises.';
    return 'Early progress. The student needs more engagement with lessons and exercises.';
  }

  String _resolvedStudentName() {
    final fromApi = (_progress?.studentName ?? '').trim();
    if (fromApi.isNotEmpty) return fromApi;

    final fromWidget = widget.studentName.trim();
    return fromWidget.isEmpty ? 'Student' : fromWidget;
  }

  String? _resolvedStudentImageUrl() {
    final fromWidget = widget.studentImageUrl?.trim() ?? '';
    if (fromWidget.isNotEmpty) return fromWidget;

    final student = _progress?.student ?? const <String, dynamic>{};
    final candidates = <dynamic>[
      student['image'],
      student['photo_url'],
      student['image_url'],
      student['avatar'],
      student['photo_path'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: titleColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _resolvedStudentName(),
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadProgress,
            icon: Icon(Icons.refresh_rounded, color: titleColor),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ProgressErrorView(
                    error: _error!,
                    onRetry: _loadProgress,
                  )
                : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final progress = _progress;

    final overallProgress = progress?.overallProgress ?? 0;
    final overallValue = progress?.overallProgressValue ?? 0;
    final averageScore = progress == null ? '0%' : _scoreText(progress);
    final learningTime = _formatTime(progress?.totalStudyTimeSeconds ?? 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _StudentSubjectHeaderCard(
          studentName: _resolvedStudentName(),
          studentImageUrl: _resolvedStudentImageUrl(),
          subjectName: widget.subjectName,
          grade: widget.grade,
          section: widget.section,
        ),
        const SizedBox(height: 16),
        _SubjectCompletionCard(
          title: '${widget.subjectName} Progress',
          progress: overallValue,
          progressText: '$overallProgress%',
          note: progress == null
              ? 'No progress data is available yet.'
              : _progressNote(progress),
        ),
        const SizedBox(height: 14),
        _InfoMetricCard(
          icon: Icons.workspace_premium_rounded,
          title: 'Average Score',
          value: averageScore,
        ),
        const SizedBox(height: 14),
        _InfoMetricCard(
          icon: Icons.timer_outlined,
          title: 'Learning Time',
          value: learningTime,
        ),
        const SizedBox(height: 14),
        if (progress != null) ...[
          _ProgressBreakdownCard(progress: progress),
          const SizedBox(height: 14),
          _ExercisePerformanceCard(progress: progress),
          const SizedBox(height: 22),
        ],
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF36A9F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Detailed Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressErrorView extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ProgressErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load progress',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentSubjectHeaderCard extends StatelessWidget {
  final String studentName;
  final String? studentImageUrl;
  final String subjectName;
  final String grade;
  final String section;

  const _StudentSubjectHeaderCard({
    required this.studentName,
    required this.studentImageUrl,
    required this.subjectName,
    required this.grade,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final initial =
        studentName.trim().isNotEmpty ? studentName.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                isDark ? EduTheme.darkSurface : const Color(0xFFEAF4FF),
            backgroundImage: (studentImageUrl != null && studentImageUrl!.isNotEmpty)
                ? NetworkImage(studentImageUrl!)
                : null,
            child: (studentImageUrl == null || studentImageUrl!.isEmpty)
                ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.school_rounded,
                      label: 'Grade $grade',
                    ),
                    _MetaChip(
                      icon: Icons.groups_2_rounded,
                      label: 'Section $section',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF223246) : const Color(0xFFF2F7FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCompletionCard extends StatelessWidget {
  final String title;
  final double progress;
  final String progressText;
  final String note;

  const _SubjectCompletionCard({
    required this.title,
    required this.progress,
    required this.progressText,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = const Color(0xFF36A9F1);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 18,
                    backgroundColor: const Color(0xFFE6EAF0),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              note,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoMetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: _cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF0FF),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF36A9F1),
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBreakdownCard extends StatelessWidget {
  final TeacherStudentSubjectProgress progress;

  const _ProgressBreakdownCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Breakdown',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _ProgressLine(
            title: 'Lessons completed',
            value: progress.lessonCompletionValue,
            valueText:
                '${progress.lessons.completedLessons}/${progress.lessons.totalLessons} lessons',
          ),
          const SizedBox(height: 14),
          _ProgressLine(
            title: 'Exercises completed',
            value: progress.exerciseCompletionValue,
            valueText:
                '${progress.exercises.completedExerciseSets}/${progress.exercises.totalExerciseSets} sets',
          ),
          const SizedBox(height: 14),
          _ProgressLine(
            title: 'Exercise accuracy',
            value: progress.accuracyValue,
            valueText: '${progress.exercises.accuracyRate}%',
          ),
        ],
      ),
    );
  }
}

class _ExercisePerformanceCard extends StatelessWidget {
  final TeacherStudentSubjectProgress progress;

  const _ExercisePerformanceCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise Performance',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetricBox(
                  title: 'Correct',
                  value: progress.exercises.correctCount.toString(),
                  color: const Color(0xFF12B980),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetricBox(
                  title: 'Wrong',
                  value: progress.exercises.wrongCount.toString(),
                  color: const Color(0xFFE55353),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetricBox(
                  title: 'Answered',
                  value:
                      '${progress.exercises.answeredCount}/${progress.exercises.questionCount}',
                  color: const Color(0xFF36A9F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String title;
  final double value;
  final String valueText;

  const _ProgressLine({
    required this.title,
    required this.value,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF36A9F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFE6EAF0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF36A9F1)),
          ),
        ),
      ],
    );
  }
}

class _MiniMetricBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MiniMetricBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return BoxDecoration(
    color: theme.cardColor,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.55),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}