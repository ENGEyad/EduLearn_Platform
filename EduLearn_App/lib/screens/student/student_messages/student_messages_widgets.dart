part of 'student_messages_screen.dart';

class _StudentMessagesMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StudentMessagesMetricTile({
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

class StudentMessagesEmptyState extends StatelessWidget {
  const StudentMessagesEmptyState({super.key});

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
                l10n.studentMessagesEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.studentMessagesEmptySubtitle,
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

class StudentMessagesSearchEmptyState extends StatelessWidget {
  const StudentMessagesSearchEmptyState({super.key});

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
                l10n.studentMessagesSearchEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.studentMessagesSearchEmptySubtitle,
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

class StudentMessagesLoadingList extends StatelessWidget {
  const StudentMessagesLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const StudentMessageItemSkeleton(),
    );
  }
}

class StudentMessageItemSkeleton extends StatelessWidget {
  const StudentMessageItemSkeleton({super.key});

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

class StudentMessagesFilterBar extends StatelessWidget {
  final StudentMessagesFilterType activeType;
  final VoidCallback onTapAll;
  final VoidCallback onTapUnread;

  const StudentMessagesFilterBar({
    super.key,
    required this.activeType,
    required this.onTapAll,
    required this.onTapUnread,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          StudentMessagesFilterChip(
            label: l10n.studentMessagesAll,
            selected: activeType == StudentMessagesFilterType.all,
            onTap: onTapAll,
          ),
          const SizedBox(width: 8),
          StudentMessagesFilterChip(
            label: l10n.studentMessagesUnread,
            selected: activeType == StudentMessagesFilterType.unread,
            onTap: onTapUnread,
            icon: Icons.mark_email_unread_rounded,
          ),
        ],
      ),
    );
  }
}

class StudentMessagesFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const StudentMessagesFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : theme.cardColor;
    final borderColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.24)
        : theme.dividerColor.withValues(alpha: 0.14);
    final textColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentMessageItem extends StatelessWidget {
  final String avatarText;
  final String? avatarImageUrl;
  final String name;
  final String preview;
  final String metaLine;
  final String time;
  final int unreadCount;
  final bool showOutgoingStatus;
  final ChatMessageDeliveryState? deliveryState;
  final VoidCallback onTap;

  const StudentMessageItem({
    super.key,
    required this.avatarText,
    required this.avatarImageUrl,
    required this.name,
    required this.preview,
    required this.metaLine,
    required this.time,
    required this.unreadCount,
    required this.showOutgoingStatus,
    required this.deliveryState,
    required this.onTap,
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
      ChatMessageDeliveryState.failed => EduTheme.danger,
      ChatMessageDeliveryState.read => theme.colorScheme.primary,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasUnread
                  ? theme.colorScheme.primary.withValues(alpha: 0.10)
                  : theme.dividerColor.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
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
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          const SizedBox(width: 8),
                          Text(
                            time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: hasUnread
                                  ? theme.colorScheme.primary
                                  : mutedColor,
                              fontSize: 10,
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (showOutgoingStatus && statusIcon != null) ...[
                          Icon(statusIcon, size: 15, color: statusColor),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: hasUnread ? titleColor : mutedColor,
                              fontSize: 13,
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (metaLine.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 10),
                Container(
                  width: 22,
                  height: 22,
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
                      fontSize: unreadCount > 99 ? 8 : 10,
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
