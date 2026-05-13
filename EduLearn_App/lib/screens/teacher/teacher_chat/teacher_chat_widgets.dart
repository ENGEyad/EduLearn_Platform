part of 'teacher_chat_screen.dart';

class TeacherChatEmptyState extends StatelessWidget {
  const TeacherChatEmptyState({super.key});

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
            color: isDark
                ? EduTheme.darkSurfaceContainerLow
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.16),
            ),
            boxShadow: EduTheme.cardShadow(isDark),
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
                l10n.teacherChatNoMessagesYet,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.teacherChatEmptySubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherChatLoadingSkeleton extends StatelessWidget {
  const TeacherChatLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = isDark
        ? EduTheme.darkSurfaceContainerLow
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: 7,
      itemBuilder: (context, index) {
        final isMe = index.isOdd;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * (isMe ? 0.52 : 0.68),
            height: index % 3 == 0 ? 64 : 48,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}

class TeacherChatDateChip extends StatelessWidget {
  final String label;

  const TeacherChatDateChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isDark
                ? EduTheme.darkSurfaceContainerLow.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String timeLabel;
  final ChatMessageDeliveryState deliveryState;
  final bool showTopSpacing;
  final bool mergeWithPrevious;
  final bool mergeWithNext;
  final VoidCallback? onRetry;

  const TeacherChatBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.timeLabel,
    required this.deliveryState,
    required this.showTopSpacing,
    required this.mergeWithPrevious,
    required this.mergeWithNext,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : (theme.brightness == Brightness.dark
            ? EduTheme.darkSurfaceContainerLow
            : Colors.white);
    final textColor = isMe ? Colors.white : theme.colorScheme.onSurface;
    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.84)
        : theme.textTheme.bodySmall?.color ?? Colors.grey;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(mergeWithPrevious && !isMe ? 10 : 22),
      topRight: Radius.circular(mergeWithPrevious && isMe ? 10 : 22),
      bottomLeft: Radius.circular(isMe ? 22 : (mergeWithNext ? 10 : 22)),
      bottomRight: Radius.circular(isMe ? (mergeWithNext ? 10 : 22) : 22),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: showTopSpacing ? 8 : 2,
          bottom: mergeWithNext ? 2 : 8,
        ),
        child: Opacity(
          opacity: deliveryState == ChatMessageDeliveryState.sending ? 0.80 : 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                border: isMe
                    ? null
                    : Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.16),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isMe ? 0.07 : 0.05),
                    blurRadius: isMe ? 14 : 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.nunito(
                      color: textColor,
                      fontSize: 14.2,
                      fontWeight: FontWeight.w700,
                      height: 1.38,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        deliveryState == ChatMessageDeliveryState.sending
                            ? l10n.teacherChatSending
                            : timeLabel,
                        style: GoogleFonts.nunito(
                          color: timeColor,
                          fontSize: 10.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        _TeacherDeliveryIndicator(state: deliveryState),
                      ],
                      if (deliveryState == ChatMessageDeliveryState.failed &&
                          onRetry != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onRetry,
                          child: Text(
                            l10n.teacherChatRetry,
                            style: GoogleFonts.nunito(
                              color: isMe
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              fontSize: 10.4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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

class _TeacherDeliveryIndicator extends StatelessWidget {
  final ChatMessageDeliveryState state;

  const _TeacherDeliveryIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (state) {
      case ChatMessageDeliveryState.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.2,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );
      case ChatMessageDeliveryState.sent:
        color = Colors.white.withValues(alpha: 0.85);
        icon = Icons.done_rounded;
        break;
      case ChatMessageDeliveryState.delivered:
        color = Colors.white.withValues(alpha: 0.90);
        icon = Icons.done_all_rounded;
        break;
      case ChatMessageDeliveryState.read:
        color = const Color(0xFF7DD3FC);
        icon = Icons.done_all_rounded;
        break;
      case ChatMessageDeliveryState.failed:
        color = Colors.white.withValues(alpha: 0.92);
        icon = Icons.error_outline_rounded;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }
}

class TeacherChatScrollToLatestButton extends StatelessWidget {
  final VoidCallback onTap;

  const TeacherChatScrollToLatestButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? EduTheme.darkSurfaceContainer.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.teacherChatNewMessages,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function({String? overrideText}) onSend;
  final ValueChanged<String> onChanged;
  final bool isSending;

  const TeacherChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onChanged,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill = isDark
        ? EduTheme.darkSurfaceContainerLow
        : Colors.white;
    final borderColor = theme.dividerColor.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? EduTheme.darkBackground.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.84),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  cursorColor: theme.colorScheme.primary,
                  onChanged: onChanged,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.teacherChatWriteMessageHint,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: isSending ? null : () => onSend(),
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: isSending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
