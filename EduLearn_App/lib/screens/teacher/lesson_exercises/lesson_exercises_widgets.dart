part of 'lesson_exercises_screen.dart';

class _QuestionPill extends StatelessWidget {
  final String text;
  final Color color;
  final bool outlined;

  const _QuestionPill({
    required this.text,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: color.withValues(alpha: 0.35)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _EditorSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.86),
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _QuestionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final int minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const _QuestionTextField({
    required this.controller,
    required this.hintText,
    this.labelText,
    this.minLines = 2,
    this.maxLines = 4,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction ??
          (maxLines == 1 ? TextInputAction.done : TextInputAction.newline),
      scrollPadding: const EdgeInsets.only(bottom: 140),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        alignLabelWithHint: maxLines == null || (maxLines ?? 1) > 1,
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.45),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.3),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()..addRRect(rect);
    final dashed = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const double dash = 8;
      const double gap = 6;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}


class _MetaTinyPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaTinyPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? EduTheme.darkSurfaceContainer
        : EduTheme.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.iconTheme.color?.withValues(alpha: 0.82)),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionDragHandle extends StatelessWidget {
  final bool compact;

  const _QuestionDragHandle({
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: compact ? 42 : 46,
      height: compact ? 42 : 46,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? EduTheme.darkSurfaceContainer
            : EduTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.28),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.drag_indicator_rounded,
        color: theme.iconTheme.color?.withValues(alpha: 0.82),
      ),
    );
  }
}

class _QuestionMenuButton extends StatelessWidget {
  final bool isDeleted;
  final bool isArchived;
  final Color statusColor;
  final ValueChanged<String> onSelected;

  const _QuestionMenuButton({
    required this.isDeleted,
    required this.isArchived,
    required this.statusColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).lessonExercisesQuestionActions,
      onSelected: onSelected,
      color: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.36),
        ),
      ),
      itemBuilder: (ctx) => [
        if (!isDeleted)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 18),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).lessonExercisesDeleteQuestion),
              ],
            ),
          ),
        if (isDeleted)
          PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                Icon(Icons.restore_rounded, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).lessonExercisesRestoreQuestion),
              ],
            ),
          ),
        if (!isArchived)
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive_outlined, color: theme.colorScheme.secondary, size: 18),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).lessonExercisesArchiveQuestion),
              ],
            ),
          ),
        if (isArchived)
          PopupMenuItem(
            value: 'unarchive',
            child: Row(
              children: [
                Icon(Icons.unarchive_outlined, color: statusColor, size: 18),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).lessonExercisesUnarchiveQuestion),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? EduTheme.darkSurfaceContainer
              : EduTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.28),
          ),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: theme.iconTheme.color?.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}
