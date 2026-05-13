part of 'student_subject_detail_screen.dart';

class _SubjectOverviewCard extends StatelessWidget {
  final IconData subjectIcon;
  final String subjectName;
  final String teacherName;
  final Color cardColor;
  final Color borderColor;
  final Color titleColor;
  final Color mutedColor;
  final Color softBoxColor;
  final Color progressBackground;
  final Color shadowColor;
  final double progressValue;
  final String progressText;

  const _SubjectOverviewCard({
    required this.subjectIcon,
    required this.subjectName,
    required this.teacherName,
    required this.cardColor,
    required this.borderColor,
    required this.titleColor,
    required this.mutedColor,
    required this.softBoxColor,
    required this.progressBackground,
    required this.shadowColor,
    required this.progressValue,
    required this.progressText,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: softBoxColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              subjectIcon,
              color: EduTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  teacherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressValue.clamp(0.0, 1.0).toDouble(),
                          minHeight: 7,
                          backgroundColor: progressBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            EduTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      progressText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: EduTheme.primary,
                      ),
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

class _CenteredLoadingView extends StatelessWidget {
  const _CenteredLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _LessonsErrorView extends StatelessWidget {
  final Color titleColor;
  final Color mutedColor;
  final String errorText;
  final String errorTitle;
  final String retryLabel;
  final Future<void> Function() onRetry;

  const _LessonsErrorView({
    required this.titleColor,
    required this.mutedColor,
    required this.errorText,
    required this.errorTitle,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonsEmptyView extends StatelessWidget {
  final Color mutedColor;
  final String message;
  final double topSpacing;

  const _LessonsEmptyView({
    required this.mutedColor,
    required this.message,
    this.topSpacing = 90,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: topSpacing),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _StudentLessonModule module;
  final Color cardColor;
  final Color borderColor;
  final Color titleColor;
  final Color mutedColor;
  final Color softBoxColor;
  final Color shadowColor;
  final String lessonCountLabel;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.cardColor,
    required this.borderColor,
    required this.titleColor,
    required this.mutedColor,
    required this.softBoxColor,
    required this.shadowColor,
    required this.lessonCountLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: softBoxColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: EduTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lessonCountLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleLessonsHeader extends StatelessWidget {
  final Color titleColor;
  final Color mutedColor;
  final String moduleTitle;
  final bool isLoadingLessons;
  final VoidCallback onBack;

  const _ModuleLessonsHeader({
    required this.titleColor,
    required this.mutedColor,
    required this.moduleTitle,
    required this.isLoadingLessons,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: titleColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              moduleTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLoadingLessons)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Icon(
              Icons.menu_book_rounded,
              color: mutedColor,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _LessonItemCard extends StatelessWidget {
  final int number;
  final String title;
  final String duration;
  final String status;
  final Color cardColor;
  final Color borderColor;
  final Color titleColor;
  final Color mutedColor;
  final Color shadowColor;

  const _LessonItemCard({
    required this.number,
    required this.title,
    required this.duration,
    required this.status,
    required this.cardColor,
    required this.borderColor,
    required this.titleColor,
    required this.mutedColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    IconData trailingIcon;

    if (status == 'completed') {
      circleColor = const Color(0xFF4CAF50);
      trailingIcon = Icons.check_circle_rounded;
    } else if (status == 'draft') {
      circleColor = EduTheme.primary;
      trailingIcon = Icons.play_circle_fill_rounded;
    } else {
      circleColor = titleColor.withValues(alpha: 0.35);
      trailingIcon = Icons.play_circle_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: circleColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: circleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            trailingIcon,
            color: circleColor,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTabView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlaceholderTabView({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentHeight;
  final double maxExtentHeight;
  final Widget child;

  _OverviewHeaderDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.child,
  });

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double delta = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final double progress = (shrinkOffset / delta).clamp(0.0, 1.0);
    final double opacity = (1 - (progress * 1.15)).clamp(0.0, 1.0);
    final double translateY = -20 * progress;
    final double scale = 1 - (0.04 * progress);

    return SizedBox.expand(
      child: IgnorePointer(
        ignoring: opacity <= 0.02,
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: Align(
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _OverviewHeaderDelegate oldDelegate) {
    return oldDelegate.minExtentHeight != minExtentHeight ||
        oldDelegate.maxExtentHeight != maxExtentHeight ||
        oldDelegate.child != child;
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color borderColor;

  _TabBarHeaderDelegate({
    required this.tabBar,
    required this.borderColor,
  });

  @override
  double get minExtent => tabBar.preferredSize.height + 8;

  @override
  double get maxExtent => tabBar.preferredSize.height + 8;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final ThemeData theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) {
    return oldDelegate.borderColor != borderColor || oldDelegate.tabBar != tabBar;
  }
}