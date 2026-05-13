part of 'teacher_messages_screen.dart';

class _TeacherMessagesMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TeacherMessagesMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodySmall?.color ?? EduTheme.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
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

class TeacherMessagesEmptyState extends StatelessWidget {
  const TeacherMessagesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.mark_chat_unread_rounded,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.teacherMessagesEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.teacherMessagesEmptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherMessagesSearchEmptyState extends StatelessWidget {
  const TeacherMessagesSearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                color: theme.colorScheme.primary,
                size: 30,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.teacherMessagesSearchEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.teacherMessagesSearchEmptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherMessagesLoadingList extends StatelessWidget {
  const TeacherMessagesLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const TeacherMessageItemSkeleton(),
    );
  }
}

class TeacherMessageItemSkeleton extends StatelessWidget {
  const TeacherMessageItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? EduTheme.darkSurface.withValues(alpha: 0.92)
        : theme.cardColor;
    final lineColor = theme.dividerColor.withValues(alpha: 0.18);

    Widget line(double width, {double height = 10}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: lineColor,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lineColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: line(118, height: 12)),
                    const SizedBox(width: 12),
                    line(48, height: 10),
                  ],
                ),
                const SizedBox(height: 10),
                line(double.infinity, height: 10),
                const SizedBox(height: 8),
                line(126, height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherMessagesFilterBar extends StatelessWidget {
  final TeacherMessagesFilterType activeType;
  final String? activeGrade;
  final String? activeSection;
  final VoidCallback onTapAll;
  final VoidCallback onTapUnread;
  final VoidCallback onTapAdvancedFilter;
  final VoidCallback onClearAdvancedFilter;

  const TeacherMessagesFilterBar({
    super.key,
    required this.activeType,
    required this.activeGrade,
    required this.activeSection,
    required this.onTapAll,
    required this.onTapUnread,
    required this.onTapAdvancedFilter,
    required this.onClearAdvancedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final hasAdvanced =
        (activeGrade != null && activeGrade!.isNotEmpty) ||
        (activeSection != null && activeSection!.isNotEmpty);

    final advancedLabel = hasAdvanced
        ? [
            if (activeGrade != null && activeGrade!.isNotEmpty)
              '${l10n.teacherMessagesGrade} $activeGrade',
            if (activeSection != null && activeSection!.isNotEmpty)
              '${l10n.teacherMessagesSection} $activeSection',
          ].join(' • ')
        : l10n.teacherMessagesGradeSection;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          TeacherMessagesFilterChip(
            label: l10n.teacherMessagesAll,
            selected:
                activeType == TeacherMessagesFilterType.all && !hasAdvanced,
            onTap: onTapAll,
          ),
          const SizedBox(width: 8),
          TeacherMessagesFilterChip(
            label: l10n.teacherMessagesUnread,
            selected: activeType == TeacherMessagesFilterType.unread,
            onTap: onTapUnread,
            icon: Icons.mark_email_unread_rounded,
          ),
          const SizedBox(width: 8),
          TeacherMessagesFilterChip(
            label: advancedLabel,
            selected: hasAdvanced,
            onTap: onTapAdvancedFilter,
            icon: Icons.filter_list_rounded,
            trailing: hasAdvanced
                ? GestureDetector(
                    onTap: onClearAdvancedFilter,
                    child: const Icon(Icons.close_rounded, size: 16),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class TeacherMessagesFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? trailing;

  const TeacherMessagesFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : (theme.brightness == Brightness.dark
            ? EduTheme.darkSurfaceContainerLow
            : theme.cardColor);
    final borderColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.28)
        : theme.dividerColor.withValues(alpha: 0.18);
    final textColor =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: textColor),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TeacherMessageItem extends StatelessWidget {
  final String avatarText;
  final String? avatarImageUrl;
  final String name;
  final String preview;
  final String metaLine;
  final String time;
  final int unreadCount;
  final bool showOutgoingStatus;
  final ChatMessageDeliveryState? deliveryState;
  final VoidCallback? onTap;

  const TeacherMessageItem({
    super.key,
    required this.avatarText,
    required this.name,
    required this.preview,
    required this.metaLine,
    required this.time,
    required this.unreadCount,
    required this.showOutgoingStatus,
    required this.deliveryState,
    this.avatarImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = unreadCount > 0;

    final titleColor = theme.colorScheme.onSurface;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    final statusColor = switch (deliveryState) {
      ChatMessageDeliveryState.read => const Color(0xFF38BDF8),
      ChatMessageDeliveryState.failed => theme.colorScheme.error,
      _ => mutedColor,
    };

    final statusIcon = switch (deliveryState) {
      ChatMessageDeliveryState.sending => Icons.schedule_rounded,
      ChatMessageDeliveryState.sent => Icons.done_rounded,
      ChatMessageDeliveryState.delivered => Icons.done_all_rounded,
      ChatMessageDeliveryState.read => Icons.done_all_rounded,
      ChatMessageDeliveryState.failed => Icons.error_outline_rounded,
      null => null,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                backgroundImage:
                    avatarImageUrl != null ? NetworkImage(avatarImageUrl!) : null,
                child: avatarImageUrl == null
                    ? Text(
                        avatarText,
                        style: GoogleFonts.nunito(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: titleColor,
                              fontWeight:
                                  hasUnread ? FontWeight.w900 : FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: hasUnread
                                  ? theme.colorScheme.primary
                                  : mutedColor.withValues(alpha: 0.9),
                              fontSize: 10.5,
                              fontWeight:
                                  hasUnread ? FontWeight.w900 : FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: mutedColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (showOutgoingStatus && statusIcon != null) ...[
                          Icon(statusIcon, size: 15, color: statusColor),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: mutedColor.withValues(
                                alpha: hasUnread ? 0.95 : 0.88,
                              ),
                              fontSize: 13.4,
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 12),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: unreadCount > 99 ? 8.5 : 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}