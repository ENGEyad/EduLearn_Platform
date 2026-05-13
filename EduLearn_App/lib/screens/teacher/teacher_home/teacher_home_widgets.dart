part of 'teacher_home_screen.dart';

class _StudentActivityItemData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StudentActivityItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _PerformanceMetricData {
  final String label;
  final double value;
  final String valueText;

  const _PerformanceMetricData({
    required this.label,
    required this.value,
    required this.valueText,
  });
}

class _TeacherHomeSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color mutedColor;

  const _TeacherHomeSectionHeader({
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _TeacherHomeHeaderCard extends StatelessWidget {
  final String fullName;
  final String firstName;
  final String? imageUrl;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;

  const _TeacherHomeHeaderCard({
    required this.fullName,
    required this.firstName,
    required this.imageUrl,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final ImageProvider? avatarProvider =
        imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusXL,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.cardShadow(theme.brightness == Brightness.dark),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBoxColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor.withValues(alpha: 0.85)),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.transparent,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeBack(firstName),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  fullName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: EduTheme.radiusMedium,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: theme.colorScheme.primary,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherHomeHeroSummaryCard extends StatelessWidget {
  final Color titleColor;
  final Color mutedColor;
  final Color cardColor;
  final Color iconBoxColor;
  final Color softAccentColor;
  final Color shadowColor;
  final Color borderColor;
  final bool hasLocalContinuationLessons;
  final bool hasServerDraftLessons;
  final int publishedCount;
  final int totalStudents;

  const _TeacherHomeHeroSummaryCard({
    required this.titleColor,
    required this.mutedColor,
    required this.cardColor,
    required this.iconBoxColor,
    required this.softAccentColor,
    required this.shadowColor,
    required this.borderColor,
    required this.hasLocalContinuationLessons,
    required this.hasServerDraftLessons,
    required this.publishedCount,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String summaryText = hasLocalContinuationLessons
        ? l10n.heroSummaryLocal
        : hasServerDraftLessons
            ? l10n.heroSummaryServer
            : l10n.heroSummaryDefault;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusXL,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.teacherDashboard,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summaryText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: softAccentColor,
                  borderRadius: EduTheme.radiusLarge,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TeacherHomeMiniMetric(
                  label: l10n.students,
                  value: totalStudents.toString(),
                  icon: Icons.group_rounded,
                  cardColor: iconBoxColor.withValues(alpha: isDark ? 0.70 : 0.88),
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TeacherHomeMiniMetric(
                  label: l10n.published,
                  value: publishedCount.toString(),
                  icon: Icons.menu_book_rounded,
                  cardColor: softAccentColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherHomeMiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;

  const _TeacherHomeMiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusLarge,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: EduTheme.radiusMedium,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
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

class _TeacherHomePrimaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool isWide;

  const _TeacherHomePrimaryStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
    required this.borderColor,
    this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: isWide ? 16 : 15,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusLarge,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.subtleShadow(theme.brightness == Brightness.dark),
      ),
      child: isWide
          ? Row(
              children: [
                _TeacherHomeIconTile(
                  icon: icon,
                  iconBoxColor: iconBoxColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _TeacherHomeStatTextGroup(
                    title: title,
                    value: value,
                    subtitle: subtitle,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: mutedColor,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeacherHomeIconTile(
                  icon: icon,
                  iconBoxColor: iconBoxColor,
                  compact: true,
                ),
                const SizedBox(height: 14),
                _TeacherHomeStatTextGroup(
                  title: title,
                  value: value,
                  subtitle: subtitle,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
              ],
            ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: EduTheme.radiusLarge,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _TeacherHomeIconTile extends StatelessWidget {
  final IconData icon;
  final Color iconBoxColor;
  final bool compact;

  const _TeacherHomeIconTile({
    required this.icon,
    required this.iconBoxColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: compact ? 42 : 46,
      height: compact ? 42 : 46,
      decoration: BoxDecoration(
        color: iconBoxColor,
        borderRadius: EduTheme.radiusMedium,
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _TeacherHomeStatTextGroup extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color titleColor;
  final Color mutedColor;

  const _TeacherHomeStatTextGroup({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.titleColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TeacherHomeLessonCard extends StatelessWidget {
  final TeacherHomeLessonItem lesson;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _TeacherHomeLessonCard({
    required this.lesson,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
    required this.borderColor,
    required this.onTap,
  });

  String _statusText(AppLocalizations l10n) {
    if (lesson.isPublished) return l10n.publishedStatus;

    switch (lesson.draftSource) {
      case TeacherHomeDraftSource.server:
        return l10n.serverDraftStatus;
      case TeacherHomeDraftSource.local:
        return l10n.localEditStatus;
      case null:
        return l10n.draftStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: EduTheme.radiusLarge,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: EduTheme.radiusLarge,
            border: Border.all(color: borderColor),
            boxShadow: EduTheme.subtleShadow(isDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: EduTheme.radiusMedium,
                ),
                child: Icon(
                  lesson.isPublished
                      ? Icons.menu_book_rounded
                      : lesson.draftSource == TeacherHomeDraftSource.server
                          ? Icons.cloud_outlined
                          : Icons.edit_note_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.safeTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.locationLabel.trim().isNotEmpty
                          ? lesson.locationLabel
                          : l10n.lessonContextNotAvailable,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TeacherHomeStatusChip(
                          label: _statusText(l10n),
                          textColor: titleColor,
                          backgroundColor: iconBoxColor,
                        ),
                        if (lesson.localLessonState != null &&
                            lesson.localLessonState!.trim().isNotEmpty)
                          _TeacherHomeStatusChip(
                            label: lesson.localLessonState!,
                            textColor: mutedColor,
                            backgroundColor: iconBoxColor,
                          ),
                        if (!lesson.canOpenDirectly)
                          Text(
                            l10n.contextIncomplete,
                            style: TextStyle(
                              color: mutedColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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

class _TeacherHomeStatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _TeacherHomeStatusChip({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: EduTheme.radiusPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TeacherHomeActivityFeedCard extends StatelessWidget {
  final List<_StudentActivityItemData> items;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;

  const _TeacherHomeActivityFeedCard({
    required this.items,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusXL,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.subtleShadow(isDark),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _TeacherHomeActivityItem(
              data: items[i],
              titleColor: titleColor,
              mutedColor: mutedColor,
              iconBoxColor: iconBoxColor,
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _TeacherHomeActivityItem extends StatelessWidget {
  final _StudentActivityItemData data;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;

  const _TeacherHomeActivityItem({
    required this.data,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: iconBoxColor.withValues(alpha: 0.62),
        borderRadius: EduTheme.radiusMedium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: EduTheme.radiusSmall,
            ),
            child: Icon(
              data.icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
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

class _TeacherHomePerformanceChartCard extends StatelessWidget {
  final List<_PerformanceMetricData> metrics;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color softAccentColor;
  final Color shadowColor;
  final Color borderColor;

  const _TeacherHomePerformanceChartCard({
    required this.metrics,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.softAccentColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusXL,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.subtleShadow(isDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: softAccentColor,
                  borderRadius: EduTheme.radiusMedium,
                ),
                child: Icon(
                  Icons.stacked_bar_chart_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.performanceOverview,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.performanceOverviewSubtitle,
                      style: TextStyle(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < metrics.length; i++) ...[
            _TeacherHomeMetricBar(
              metric: metrics[i],
              titleColor: titleColor,
              mutedColor: mutedColor,
              trackColor: iconBoxColor,
            ),
            if (i != metrics.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _TeacherHomeMetricBar extends StatelessWidget {
  final _PerformanceMetricData metric;
  final Color titleColor;
  final Color mutedColor;
  final Color trackColor;

  const _TeacherHomeMetricBar({
    required this.metric,
    required this.titleColor,
    required this.mutedColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final double safeValue = metric.value.clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                metric.label,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              metric.valueText,
              style: TextStyle(
                color: mutedColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: EduTheme.radiusPill,
          child: Container(
            height: 10,
            color: trackColor.withValues(alpha: 0.78),
            child: FractionallySizedBox(
              widthFactor: safeValue,
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherHomeFocusCard extends StatelessWidget {
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color shadowColor;
  final Color borderColor;
  final Color softAccentColor;
  final bool hasLocalContinuationLessons;
  final bool hasServerDraftLessons;

  const _TeacherHomeFocusCard({
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.shadowColor,
    required this.borderColor,
    required this.softAccentColor,
    required this.hasLocalContinuationLessons,
    required this.hasServerDraftLessons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusXL,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.subtleShadow(isDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: softAccentColor,
              borderRadius: EduTheme.radiusLarge,
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              color: theme.colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todaysFocus,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasLocalContinuationLessons
                      ? l10n.focusLocal
                      : hasServerDraftLessons
                          ? l10n.focusServer
                          : l10n.focusDefault,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.35,
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

class _TeacherHomeLessonsSheet extends StatelessWidget {
  final String title;
  final List<TeacherHomeLessonItem> lessons;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final ValueChanged<TeacherHomeLessonItem> onLessonTap;

  const _TeacherHomeLessonsSheet({
    required this.title,
    required this.lessons,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        (isDark ? EduTheme.darkInputBorder : EduTheme.inputBorder).withValues(alpha: 0.88);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: mutedColor.withValues(alpha: 0.35),
                    borderRadius: EduTheme.radiusPill,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.lessonsCount(lessons.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: lessons.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noLessonsAvailable,
                          style: TextStyle(
                            color: mutedColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: lessons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final TeacherHomeLessonItem lesson = lessons[index];
                          return _TeacherHomeLessonCard(
                            lesson: lesson,
                            cardColor: cardColor,
                            titleColor: titleColor,
                            mutedColor: mutedColor,
                            iconBoxColor: iconBoxColor,
                            shadowColor: shadowColor,
                            borderColor: borderColor,
                            onTap: () => onLessonTap(lesson),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherHomeErrorCard extends StatelessWidget {
  final String message;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;
  final Future<void> Function({bool refresh}) onRetry;

  const _TeacherHomeErrorCard({
    required this.message,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
    required this.borderColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: EduTheme.radiusLarge,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.subtleShadow(theme.brightness == Brightness.dark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: EduTheme.radiusMedium,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.couldNotLoadAllHomeData,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => onRetry(refresh: true),
                  child: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherHomeCardsLoadingState extends StatelessWidget {
  final Color cardColor;
  final Color shadowColor;
  final Color borderColor;

  const _TeacherHomeCardsLoadingState({
    required this.cardColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget box({required double height}) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: EduTheme.radiusLarge,
          border: Border.all(color: borderColor),
          boxShadow: EduTheme.subtleShadow(isDark),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: box(height: 156)),
            const SizedBox(width: 12),
            Expanded(child: box(height: 156)),
          ],
        ),
        const SizedBox(height: 12),
        box(height: 112),
      ],
    );
  }
}