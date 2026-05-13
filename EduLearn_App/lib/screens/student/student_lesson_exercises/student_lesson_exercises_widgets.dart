part of 'student_lesson_exercises_screen.dart';

class StudentLessonExercisesErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const StudentLessonExercisesErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.studentLessonExercisesUnableToLoad,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.studentLessonExercisesTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentLessonExercisesNoPublishedState extends StatelessWidget {
  const StudentLessonExercisesNoPublishedState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.studentLessonExercisesNoPublished,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.studentLessonExercisesNoPublishedMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentLessonExercisesEmptyQuestionsCard extends StatelessWidget {
  const StudentLessonExercisesEmptyQuestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.studentLessonExercisesNoVisibleQuestions,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.studentLessonExercisesNoVisibleQuestionsMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentLessonExercisesTopSummaryCard extends StatelessWidget {
  final String lessonTitle;
  final Color statusColor;
  final String statusLabel;
  final bool attemptLocked;
  final bool hasPendingChanges;
  final double score;
  final double totalPoints;
  final int correctCount;
  final int wrongCount;

  const StudentLessonExercisesTopSummaryCard({
    super.key,
    required this.lessonTitle,
    required this.statusColor,
    required this.statusLabel,
    required this.attemptLocked,
    required this.hasPendingChanges,
    required this.score,
    required this.totalPoints,
    required this.correctCount,
    required this.wrongCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.16 : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          text: statusLabel,
                          color: statusColor,
                        ),
                        if (attemptLocked)
                          _StatusChip(
                            text: l10n.studentLessonExercisesScore(
                              score.toStringAsFixed(score % 1 == 0 ? 0 : 1),
                              totalPoints.toStringAsFixed(totalPoints % 1 == 0 ? 0 : 1),
                            ),
                            color: Colors.green,
                          ),
                        if (hasPendingChanges)
                          _StatusChip(
                            text: l10n.studentLessonExercisesNewChangesAvailable,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (attemptLocked) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ScoreTile(
                    label: l10n.studentLessonExercisesCorrectCount,
                    value: correctCount.toString(),
                    color: Colors.green,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreTile(
                    label: l10n.studentLessonExercisesWrongCount,
                    value: wrongCount.toString(),
                    color: Colors.red,
                    icon: Icons.highlight_off_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreTile(
                    label: l10n.studentLessonExercisesTotal,
                    value: totalPoints.toStringAsFixed(
                      totalPoints % 1 == 0 ? 0 : 1,
                    ),
                    color: EduTheme.primary,
                    icon: Icons.star_border_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class StudentLessonExercisesSyncSummaryCard extends StatelessWidget {
  final Map<String, dynamic> syncSummary;

  const StudentLessonExercisesSyncSummaryCard({
    super.key,
    required this.syncSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final versionChanged = (syncSummary['version_changed'] ?? false) == true;
    final newCount = LessonExerciseService.readInt(syncSummary['new_count']);
    final needsReanswerCount =
        LessonExerciseService.readInt(syncSummary['needs_reanswer_count']);
    final deletedCount =
        LessonExerciseService.readInt(syncSummary['deleted_count']);
    final carriedForwardCount =
        LessonExerciseService.readInt(syncSummary['carried_forward_count']);

    if (!versionChanged &&
        newCount == 0 &&
        needsReanswerCount == 0 &&
        deletedCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.studentLessonExercisesUpdatedSetTitle,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.studentLessonExercisesUpdatedSetMessage,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (newCount > 0)
                _MiniCountChip(
                  label: l10n.studentLessonExercisesNewCount(newCount),
                  color: Colors.blue,
                ),
              if (needsReanswerCount > 0)
                _MiniCountChip(
                  label: l10n.studentLessonExercisesUpdatedCount(needsReanswerCount),
                  color: Colors.orange,
                ),
              if (deletedCount > 0)
                _MiniCountChip(
                  label: l10n.studentLessonExercisesRemovedCount(deletedCount),
                  color: Colors.red,
                ),
              if (carriedForwardCount > 0)
                _MiniCountChip(
                  label: l10n.studentLessonExercisesKeptCount(carriedForwardCount),
                  color: Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionVisualState {
  final String label;
  final Color color;

  const _QuestionVisualState({
    required this.label,
    required this.color,
  });
}

class StudentLessonExerciseQuestionCard extends StatelessWidget {
  final int index;
  final String questionText;
  final double points;
  final String questionTypeLabel;
  final String statusLabel;
  final Color statusColor;
  final bool readonly;
  final bool needsReanswer;
  final bool? isCorrect;
  final Color borderColor;
  final Widget content;
  final Widget? feedback;

  const StudentLessonExerciseQuestionCard({
    super.key,
    required this.index,
    required this.questionText,
    required this.points,
    required this.questionTypeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.readonly,
    required this.needsReanswer,
    required this.isCorrect,
    required this.borderColor,
    required this.content,
    this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.14 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                foregroundColor: theme.colorScheme.primary,
                child: Text('${index + 1}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _QuestionMetaChip(
                text: points % 1 == 0
                    ? l10n.studentLessonExercisesPoints(points.toInt().toString())
                    : l10n.studentLessonExercisesPoints(points.toStringAsFixed(1)),
                color: EduTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuestionMetaChip(
                text: questionTypeLabel,
                color: Colors.grey,
              ),
              _QuestionMetaChip(
                text: statusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
          if (feedback != null) feedback!,
        ],
      ),
    );
  }
}

class StudentLessonExerciseOptionTile extends StatelessWidget {
  final String optionText;
  final bool selected;
  final bool readOnly;
  final Color? backgroundColor;
  final Color borderColor;
  final bool showCorrectIcon;
  final bool showWrongIcon;
  final VoidCallback? onTap;

  const StudentLessonExerciseOptionTile({
    super.key,
    required this.optionText,
    required this.selected,
    required this.readOnly,
    required this.backgroundColor,
    required this.borderColor,
    required this.showCorrectIcon,
    required this.showWrongIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: selected || readOnly ? 1.25 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: showCorrectIcon
                  ? Colors.green
                  : showWrongIcon
                      ? Colors.red
                      : selected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (readOnly) ...[
              if (showCorrectIcon)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                )
              else if (showWrongIcon)
                const Icon(
                  Icons.cancel_rounded,
                  color: Colors.red,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class StudentLessonExerciseShortAnswerField extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;
  final ValueChanged<String> onChanged;

  const StudentLessonExerciseShortAnswerField({
    super.key,
    required this.controller,
    required this.editable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: controller,
      readOnly: !editable,
      minLines: 3,
      maxLines: 5,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: l10n.studentLessonExercisesWriteYourAnswer,
        alignLabelWithHint: true,
        hintText: editable ? l10n.studentLessonExercisesTypeAnswerHere : null,
        filled: true,
        fillColor: !editable
            ? theme.scaffoldBackgroundColor
            : theme.cardColor,
      ),
      onChanged: onChanged,
    );
  }
}

class StudentLessonExerciseFeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final double awardedPoints;
  final String? correctTextAnswer;
  final String? explanation;

  const StudentLessonExerciseFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.awardedPoints,
    this.correctTextAnswer,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = isCorrect ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect
                      ? l10n.studentLessonExercisesCorrectAnswer
                      : l10n.studentLessonExercisesIncorrectAnswer,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                awardedPoints % 1 == 0
                    ? l10n.studentLessonExercisesPoints(awardedPoints.toInt().toString())
                    : l10n.studentLessonExercisesPoints(awardedPoints.toStringAsFixed(1)),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (correctTextAnswer != null && correctTextAnswer!.trim().isNotEmpty)
            ...[
              const SizedBox(height: 10),
              Text(
                l10n.studentLessonExercisesCorrectAnswerLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                correctTextAnswer!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          if (explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.studentLessonExercisesExplanationLabel,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation!,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StudentLessonExercisesBottomBar extends StatelessWidget {
  final bool attemptLocked;
  final bool isSaving;
  final bool isSubmitting;
  final bool canSaveOrSubmit;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  const StudentLessonExercisesBottomBar({
    super.key,
    required this.attemptLocked,
    required this.isSaving,
    required this.isSubmitting,
    required this.canSaveOrSubmit,
    required this.onSave,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: attemptLocked
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(l10n.studentLessonExercisesAttemptLocked),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canSaveOrSubmit ? onSave : null,
                    icon: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(l10n.studentLessonExercisesSave),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canSaveOrSubmit ? onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(l10n.studentLessonExercisesSubmit),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ScoreTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionMetaChip extends StatelessWidget {
  final String text;
  final Color color;

  const _QuestionMetaChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MiniCountChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniCountChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}