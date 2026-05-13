part of 'student_home_screen.dart';

BoxDecoration _studentCardDecoration({
  required Color cardColor,
  required Color shadowColor,
  required Color borderColor,
}) {
  return BoxDecoration(
    color: cardColor,
    borderRadius: EduTheme.radiusXL,
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _StudentSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color mutedColor;

  const _StudentSectionHeader({
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


class _StudentHomeActivityData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StudentHomeActivityData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _StudentActivityFeedCard extends StatelessWidget {
  final List<_StudentHomeActivityData> items;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;

  const _StudentActivityFeedCard({
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
    final visibleItems = items.take(4).toList();

    return Container(
      decoration: _studentCardDecoration(
        cardColor: cardColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      padding: const EdgeInsets.all(14),
      child: visibleItems.isEmpty
          ? _StudentEmptyActivityItem(
              titleColor: titleColor,
              mutedColor: mutedColor,
              iconBoxColor: iconBoxColor,
            )
          : Column(
              children: [
                for (int i = 0; i < visibleItems.length; i++) ...[
                  _StudentActivityItem(
                    data: visibleItems[i],
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    iconBoxColor: iconBoxColor,
                  ),
                  if (i != visibleItems.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _StudentActivityItem extends StatelessWidget {
  final _StudentHomeActivityData data;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;

  const _StudentActivityItem({
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
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

class _StudentEmptyActivityItem extends StatelessWidget {
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;

  const _StudentEmptyActivityItem({
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: iconBoxColor.withValues(alpha: 0.62),
        borderRadius: EduTheme.radiusMedium,
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.studentHomeNoNewUpdatesYet,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _StudentHeaderCard extends StatelessWidget {
  final String fullName;
  final String? imageUrl;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;

  const _StudentHeaderCard({
    required this.fullName,
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
    final ThemeData theme = Theme.of(context);
    final ImageProvider? avatarProvider =
        imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null;
    final String firstLetter =
        fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';

    return Container(
      decoration: _studentCardDecoration(
        cardColor: cardColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: iconBoxColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor.withValues(alpha: 0.9)),
            ),
            child: CircleAvatar(
              radius: 31,
              backgroundColor: Colors.transparent,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? Text(
                      firstLetter,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              fullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: EduTheme.radiusMedium,
            ),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications_none_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentProgressCard extends StatelessWidget {
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color borderColor;
  final Color shadowColor;
  final Color progressBackground;
  final Color iconBoxColor;
  final double value;
  final String valueText;
  final String title;
  final String subtitle;

  const _StudentProgressCard({
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.borderColor,
    required this.shadowColor,
    required this.progressBackground,
    required this.iconBoxColor,
    required this.value,
    required this.valueText,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: _studentCardDecoration(
        cardColor: cardColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      padding: const EdgeInsets.all(18),
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
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: EduTheme.radiusPill,
                ),
                child: Text(
                  valueText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: EduTheme.radiusPill,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: progressBackground,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.studentHomeKeepItUp,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _OngoingLessonCard extends StatelessWidget {
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color borderColor;
  final Color shadowColor;
  final Color iconBoxColor;

  const _OngoingLessonCard({
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.borderColor,
    required this.shadowColor,
    required this.iconBoxColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: _studentCardDecoration(
        cardColor: cardColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.studentHomeOngoingLesson,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.studentHomePhotosynthesisLesson,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.studentHomeLessonProgress75,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: EduTheme.radiusPill,
                  ),
                  child: Text(
                    l10n.studentHomeContinueLearning,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: EduTheme.radiusLarge,
            ),
            child: Icon(
              Icons.local_florist_rounded,
              color: theme.colorScheme.primary,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;
  final Color borderColor;

  const _AssessmentCard({
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  State<_AssessmentCard> createState() => _AssessmentCardState();
}

class _AssessmentCardState extends State<_AssessmentCard> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: _studentCardDecoration(
        cardColor: widget.cardColor,
        shadowColor: widget.shadowColor,
        borderColor: widget.borderColor,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.iconBoxColor,
              borderRadius: EduTheme.radiusMedium,
            ),
            child: Icon(
              Icons.assignment_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.mutedColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: widget.mutedColor,
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color previewColor;
  final Color shadowColor;
  final Color borderColor;

  const _RecommendedCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.previewColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: _studentCardDecoration(
        cardColor: cardColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: EduTheme.radiusLarge,
            child: Container(
              height: 122,
              width: double.infinity,
              color: previewColor,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.primary,
                      size: 34,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
