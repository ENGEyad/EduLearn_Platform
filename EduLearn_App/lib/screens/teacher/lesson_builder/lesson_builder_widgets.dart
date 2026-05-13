part of 'lesson_builder_screen.dart';

class _LessonBuilderTopBar extends StatelessWidget {
  final String statusLabel;
  final bool isSaving;
  final bool isAiWorking;
  final Color statusColor;
  final VoidCallback onBack;
  final VoidCallback? onOpenAi;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onPublish;

  const _LessonBuilderTopBar({
    required this.statusLabel,
    required this.isSaving,
    required this.isAiWorking,
    required this.statusColor,
    required this.onBack,
    required this.onOpenAi,
    required this.onSaveDraft,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.textTheme.bodySmall?.color?.withValues(
          alpha: isDark ? 0.82 : 0.78,
        ) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.colorScheme.onSurface,
                  minimumSize: const Size(46, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: isDark ? 0.52 : 0.78),
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
                      l10n.lessonBuilderTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.lessonBuilderSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  isSaving ? l10n.lessonBuilderSaving : statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: isDark ? 0.54 : 0.82),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 12,
                  child: _LessonBuilderTopActionButton(
                    onTap: onOpenAi,
                    icon: Icons.auto_awesome_rounded,
                    label: l10n.lessonBuilderAiStudio,
                    isPrimary: true,
                    trailing: isAiWorking
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 9,
                  child: _LessonBuilderTopActionButton(
                    onTap: onSaveDraft,
                    icon: Icons.save_rounded,
                    label: l10n.lessonBuilderSave,
                    trailing: isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onSurface,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: _LessonBuilderTopActionButton(
                    onTap: onPublish,
                    icon: Icons.publish_rounded,
                    label: l10n.lessonBuilderPublish,
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

class _LessonBuilderTopActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final Widget? trailing;

  const _LessonBuilderTopActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isPrimary
        ? theme.colorScheme.primary
        : theme.scaffoldBackgroundColor.withValues(alpha: isDark ? 0.24 : 0.88);
    final foregroundColor = isPrimary
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : backgroundColor,
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : theme.dividerColor.withValues(alpha: isDark ? 0.54 : 0.86),
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonBuilderTitleSection extends StatelessWidget {
  final TextEditingController controller;

  const _LessonBuilderTitleSection({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.58 : 0.90),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lessonBuilderLessonTitleLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.lessonBuilderEnterLessonTitle,
              filled: true,
              fillColor: theme.scaffoldBackgroundColor.withValues(
                alpha: isDark ? 0.18 : 0.55,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.92),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.92),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.88),
                  width: 1.4,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonBuilderMetaRow extends StatelessWidget {
  final String moduleTitle;
  final String classTitle;
  final String classKey;

  const _LessonBuilderMetaRow({
    required this.moduleTitle,
    required this.classTitle,
    required this.classKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lessonBuilderLessonContext,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.lessonBuilderLessonContextSubtitle,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(icon: Icons.menu_book_rounded, label: moduleTitle),
              _MetaPill(icon: Icons.class_rounded, label: classTitle),
              _MetaPill(icon: Icons.school_rounded, label: classKey),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonBuilderBlocksList extends StatelessWidget {
  final List<_LessonBlock> blocks;
  final String? activeTextBlockId;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<String> onDeleteBlock;
  final ValueChanged<String> onFocusTextBlock;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<_LessonBlock> onToggleBold;
  final ValueChanged<_LessonBlock> onToggleItalic;
  final void Function(_LessonBlock block, double value) onFontSizeChanged;
  final ValueChanged<double> onFontSizeChangeEnd;
  final ValueChanged<_LessonBlock> onRetryUpload;
  final ValueChanged<_MediaBlockData> onOpenPdf;
  final void Function(_LessonBlock block, String actionKey) onAiAction;

  const _LessonBuilderBlocksList({
    required this.blocks,
    required this.activeTextBlockId,
    required this.onReorder,
    required this.onDeleteBlock,
    required this.onFocusTextBlock,
    required this.onTextChanged,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onFontSizeChanged,
    required this.onFontSizeChangeEnd,
    required this.onRetryUpload,
    required this.onOpenPdf,
    required this.onAiAction,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      key: const PageStorageKey('lesson-builder-reorderable-list'),
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      physics: const ClampingScrollPhysics(),
      itemCount: blocks.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final value = Curves.easeOutCubic.transform(animation.value);
            return Transform.translate(
              offset: Offset(0, -6 * value),
              child: Transform.scale(
                scale: 1.0 + (0.05 * value),
                child: Opacity(
                  opacity: 0.98,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return Padding(
          key: ValueKey(block.id),
          padding: const EdgeInsets.only(bottom: 14),
          child: _LessonBuilderBlockCard(
            block: block,
            index: index,
            isActive: block.id == activeTextBlockId,
            onDelete: () => onDeleteBlock(block.id),
            onFocusTextBlock: () => onFocusTextBlock(block.id),
            onTextChanged: (value) => onTextChanged(value),
            onToggleBold: () => onToggleBold(block),
            onToggleItalic: () => onToggleItalic(block),
            onFontSizeChanged: (value) => onFontSizeChanged(block, value),
            onFontSizeChangeEnd: onFontSizeChangeEnd,
            onRetryUpload: () => onRetryUpload(block),
            onOpenPdf: block.media == null ? null : () => onOpenPdf(block.media!),
            onAiAction: (actionKey) => onAiAction(block, actionKey),
          ),
        );
      },
    );
  }
}

class _LessonBuilderBlockCard extends StatelessWidget {
  final _LessonBlock block;
  final int index;
  final bool isActive;
  final VoidCallback onDelete;
  final VoidCallback onFocusTextBlock;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onFontSizeChangeEnd;
  final VoidCallback onRetryUpload;
  final VoidCallback? onOpenPdf;
  final ValueChanged<String>? onAiAction;

  const _LessonBuilderBlockCard({
    required this.block,
    required this.index,
    required this.isActive,
    required this.onDelete,
    required this.onFocusTextBlock,
    required this.onTextChanged,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onFontSizeChanged,
    required this.onFontSizeChangeEnd,
    required this.onRetryUpload,
    required this.onOpenPdf,
    required this.onAiAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isText = block.type == _LessonBlockType.text;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.92)
              : theme.dividerColor.withValues(alpha: isDark ? 0.68 : 0.98),
          width: isActive ? 1.8 : 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? theme.colorScheme.primary : Colors.black)
                .withValues(alpha: isActive ? 0.12 : (isDark ? 0.18 : 0.055)),
            blurRadius: isActive ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDelayedDragStartListener(
            index: index,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                color: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.10)
                    : theme.scaffoldBackgroundColor.withValues(
                        alpha: isDark ? 0.34 : 0.82,
                      ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.92),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: theme.cardColor,
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: isDark ? 0.66 : 0.95),
                      ),
                    ),
                    child: Icon(
                      _iconForBlock(block),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleForBlock(context, block),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isText
                              ? l10n.lessonBuilderReorderTextHint
                              : l10n.lessonBuilderReorderMediaHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.86,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (block.isAiGenerated || block.isAiEdited) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (block.isAiGenerated)
                                _AiStateBadge(label: l10n.lessonBuilderAiGenerated),
                              if (block.isAiEdited)
                                _AiStateBadge(label: l10n.lessonBuilderAiEdited),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: l10n.lessonBuilderBlockActions,
                    color: theme.cardColor,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.black.withValues(alpha: 0.16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.48),
                      ),
                    ),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.52),
                        ),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    itemBuilder: (context) => [
                      if (isText) ...[
                        _buildPopupMenuItem(
                          context,
                          value: 'rewrite',
                          label: l10n.lessonBuilderRewriteWithAi,
                          icon: Icons.edit_note_rounded,
                        ),
                        _buildPopupMenuItem(
                          context,
                          value: 'simplify',
                          label: l10n.lessonBuilderSimplifyWithAi,
                          icon: Icons.lightbulb_outline_rounded,
                        ),
                        _buildPopupMenuItem(
                          context,
                          value: 'shorten',
                          label: l10n.lessonBuilderShortenWithAi,
                          icon: Icons.compress_rounded,
                        ),
                        _buildPopupMenuItem(
                          context,
                          value: 'expand',
                          label: l10n.lessonBuilderExpandWithAi,
                          icon: Icons.open_in_full_rounded,
                        ),
                        _buildPopupMenuItem(
                          context,
                          value: 'clarify',
                          label: l10n.lessonBuilderClarifyWithAi,
                          icon: Icons.tips_and_updates_outlined,
                        ),
                        const PopupMenuDivider(height: 8),
                      ],
                      _buildPopupMenuItem(
                        context,
                        value: 'delete',
                        label: l10n.lessonBuilderDeleteBlock,
                        icon: Icons.delete_outline_rounded,
                        isDestructive: true,
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                        return;
                      }
                      if (isText && onAiAction != null) {
                        onAiAction!(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: isText
                ? _LessonBuilderTextBlock(
                    block: block,
                    onFocus: onFocusTextBlock,
                    onTextChanged: onTextChanged,
                    onToggleBold: onToggleBold,
                    onToggleItalic: onToggleItalic,
                    onFontSizeChanged: onFontSizeChanged,
                    onFontSizeChangeEnd: onFontSizeChangeEnd,
                  )
                : _LessonBuilderMediaBlock(
                    block: block,
                    onRetryUpload: onRetryUpload,
                    onOpenPdf: onOpenPdf,
                    onCaptionChanged: onTextChanged,
                  ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonBuilderTextBlock extends StatelessWidget {
  final _LessonBlock block;
  final VoidCallback onFocus;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onFontSizeChangeEnd;

  const _LessonBuilderTextBlock({
    required this.block,
    required this.onFocus,
    required this.onTextChanged,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onFontSizeChanged,
    required this.onFontSizeChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final style = block.textStyle ?? const _TextBlockStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(
              alpha: isDark ? 0.18 : 0.52,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.92),
            ),
          ),
          child: TextField(
            controller: block.controller,
            focusNode: block.focusNode,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            onTap: onFocus,
            onChanged: onTextChanged,
            decoration: InputDecoration(
              hintText: l10n.lessonBuilderWriteContentHint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            style: TextStyle(
              fontSize: style.fontSize,
              height: 1.6,
              fontWeight: style.isBold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: style.isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(
              alpha: isDark ? 0.16 : 0.42,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.58 : 0.84),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InlineToolButton(
                  icon: Icons.format_bold_rounded,
                  selected: style.isBold,
                  onTap: onToggleBold,
                ),
                _InlineToolButton(
                  icon: Icons.format_italic_rounded,
                  selected: style.isItalic,
                  onTap: onToggleItalic,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.lessonBuilderSize,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Slider(
                    value: style.fontSize,
                    min: 14,
                    max: 30,
                    divisions: 8,
                    label: style.fontSize.toStringAsFixed(0),
                    onChanged: onFontSizeChanged,
                    onChangeEnd: onFontSizeChangeEnd,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.48),
                    ),
                  ),
                  child: Text(
                    '${style.fontSize.toStringAsFixed(0)} px',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonBuilderMediaBlock extends StatelessWidget {
  final _LessonBlock block;
  final VoidCallback onRetryUpload;
  final VoidCallback? onOpenPdf;
  final ValueChanged<String> onCaptionChanged;

  const _LessonBuilderMediaBlock({
    required this.block,
    required this.onRetryUpload,
    required this.onOpenPdf,
    required this.onCaptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final media = block.media!;
    final isUploading = media.status == _MediaStatus.uploading;
    final isFailed = media.status == _MediaStatus.failed;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUploading || isFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                if (isUploading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (isUploading) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUploading ? l10n.lessonBuilderUploading : l10n.lessonBuilderUploadFailed,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isFailed ? theme.colorScheme.error : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isFailed)
                  TextButton(
                    onPressed: onRetryUpload,
                    child: Text(l10n.lessonBuilderRetry),
                  ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(
              alpha: isDark ? 0.16 : 0.46,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.90),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: _buildMediaPreview(context, media),
          ),
        ),
        if (media.supportsCaption) ...[
          const SizedBox(height: 12),
          TextField(
            controller: media.captionController,
            onChanged: onCaptionChanged,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.lessonBuilderAddCaption,
              filled: true,
              fillColor: theme.scaffoldBackgroundColor.withValues(
                alpha: isDark ? 0.16 : 0.46,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.90),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.90),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.86),
                  width: 1.3,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context, _MediaBlockData media) {
    final l10n = AppLocalizations.of(context);
    if (media.kind == _MediaKind.pdf) {
      return _PdfPreviewTile(
        media: media,
        onOpen: onOpenPdf,
      );
    }

    if (media.kind == _MediaKind.audio || media.kind == _MediaKind.voice) {
      final url = _resolveMediaUrl(media);
      if (url == null) return const SizedBox.shrink();
      return _AudioPreviewCard(
        key: ValueKey('audio-${media.id}-${media.kind.name}-$url'),
        url: url,
        isVoice: media.kind == _MediaKind.voice,
      );
    }

    if (media.kind == _MediaKind.image) {
      final localPath = media.localPath;
      if (localPath != null &&
          localPath.isNotEmpty &&
          File(localPath).existsSync()) {
        return Image.file(
          File(localPath),
          fit: BoxFit.cover,
        );
      }

      final url = _resolveMediaUrl(media);
      if (url == null) return const SizedBox.shrink();

      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _FailedPreview(label: l10n.lessonBuilderFailedLoadImage),
      );
    }

    final url = _resolveMediaUrl(media);
    if (url == null) return const SizedBox.shrink();

    return _VideoPreviewCard(
      key: ValueKey('video-${media.id}-$url'),
      url: url,
    );
  }
}

class _PdfPreviewTile extends StatelessWidget {
  final _MediaBlockData media;
  final VoidCallback? onOpen;

  const _PdfPreviewTile({
    required this.media,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.scaffoldBackgroundColor.withOpacity(0.40),
          border: Border.all(color: theme.dividerColor.withOpacity(0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: theme.colorScheme.primary.withOpacity(0.10),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mediaDisplayName(context, media),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    media.sizeText(
                      pdfDocumentLabel: l10n.lessonBuilderPdfDocument,
                      fileLabel: l10n.lessonBuilderFile,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonBuilderExercisesFooter extends StatelessWidget {
  final bool hasLessonId;
  final VoidCallback onOpenExercises;

  const _LessonBuilderExercisesFooter({
    required this.hasLessonId,
    required this.onOpenExercises,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.60 : 0.90),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              Icons.assignment_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lessonBuilderLessonExercises,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasLessonId
                      ? l10n.lessonBuilderCreateQuestions
                      : l10n.lessonBuilderSaveFirstToContinue,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onOpenExercises,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.arrow_outward_rounded, size: 18),
            label: Text(l10n.lessonBuilderOpen),
          ),
        ],
      ),
    );
  }
}

class _LessonBuilderRecordingBar extends StatelessWidget {
  final Duration elapsed;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  const _LessonBuilderRecordingBar({
    required this.elapsed,
    required this.onCancel,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.lessonBuilderRecordingVoiceNote(_formatDurationMmSs(elapsed)),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text(l10n.lessonBuilderCancel),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: onStop,
            child: Text(l10n.lessonBuilderStop),
          ),
        ],
      ),
    );
  }
}

class _LessonBuilderBottomComposer extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onInsertText;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickAudio;
  final VoidCallback onToggleRecording;
  final VoidCallback onPickPdf;

  const _LessonBuilderBottomComposer({
    required this.isRecording,
    required this.onInsertText,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickAudio,
    required this.onToggleRecording,
    required this.onPickPdf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.92),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ComposerButton(
                icon: Icons.notes_rounded,
                label: l10n.lessonBuilderComposerText,
                onTap: onInsertText,
              ),
              _ComposerButton(
                icon: Icons.image_rounded,
                label: l10n.lessonBuilderComposerImage,
                onTap: onPickImage,
              ),
              _ComposerButton(
                icon: Icons.videocam_rounded,
                label: l10n.lessonBuilderComposerVideo,
                onTap: onPickVideo,
              ),
              _ComposerButton(
                icon: Icons.audio_file_rounded,
                label: l10n.lessonBuilderComposerAudio,
                onTap: onPickAudio,
              ),
              _ComposerButton(
                icon: isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                label: l10n.lessonBuilderComposerRecord,
                onTap: onToggleRecording,
                isPrimary: isRecording,
              ),
              _ComposerButton(
                icon: Icons.picture_as_pdf_rounded,
                label: l10n.lessonBuilderComposerPdf,
                onTap: onPickPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ComposerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 86,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isPrimary
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : theme.scaffoldBackgroundColor.withValues(alpha: isDark ? 0.24 : 0.60),
            border: Border.all(
              color: isPrimary
                  ? theme.colorScheme.primary.withValues(alpha: 0.28)
                  : theme.dividerColor.withValues(alpha: isDark ? 0.62 : 0.88),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? theme.colorScheme.primary.withValues(alpha: 0.14)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: isPrimary
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
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

class _AiStateBadge extends StatelessWidget {
  final String label;

  const _AiStateBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LessonAiGenerateSheet extends StatefulWidget {
  final bool hasActiveSource;
  final Map<String, String> instructionItems;

  const _LessonAiGenerateSheet({
    required this.hasActiveSource,
    required this.instructionItems,
  });

  @override
  State<_LessonAiGenerateSheet> createState() => _LessonAiGenerateSheetState();
}

class _LessonAiGenerateSheetState extends State<_LessonAiGenerateSheet> {
  final TextEditingController _textController = TextEditingController();
  String _instructionKey = 'structured_explanation';
  String _mode = 'existing';
  String? _pdfPath;
  String? _pdfName;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.hasActiveSource) {
      _mode = 'text';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.trim().isEmpty) return;
    setState(() {
      _pdfPath = path;
      _pdfName = result.files.single.name;
      _mode = 'pdf';
    });
  }

  void _submit() {
    if (_mode == 'text' && _textController.text.trim().isEmpty) return;
    if (_mode == 'pdf' && (_pdfPath == null || _pdfPath!.trim().isEmpty)) {
      return;
    }
    setState(() => _submitting = true);
    Navigator.of(context).pop({
      'mode': _mode,
      'instruction_key': _instructionKey,
      if (_mode == 'text') 'source_text': _textController.text.trim(),
      if (_mode == 'pdf') 'file_path': _pdfPath,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSubmit = _mode == 'existing'
        ? true
        : _mode == 'text'
            ? _textController.text.trim().isNotEmpty
            : (_pdfPath?.trim().isNotEmpty ?? false);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.24 : 0.40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF001A33), // Brand Deep Navy
                            const Color(0xFF003366), // Lighter Navy
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF001A33).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFFF6600), // Brand Vibrant Orange
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.lessonBuilderAiLessonAssistant,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.lessonBuilderAiSheetSubtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.layers_outlined, 
                            size: 16, 
                            color: theme.colorScheme.primary.withValues(alpha: 0.7)
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.lessonBuilderAiSource.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (widget.hasActiveSource)
                          _AiModeChip(
                            label: l10n.lessonBuilderAiSavedSource,
                            icon: Icons.history_edu_rounded,
                            selected: _mode == 'existing',
                            onTap: () => setState(() => _mode = 'existing'),
                          ),
                        _AiModeChip(
                          label: l10n.lessonBuilderComposerText,
                          icon: Icons.notes_rounded,
                          selected: _mode == 'text',
                          onTap: () => setState(() => _mode = 'text'),
                        ),
                        _AiModeChip(
                          label: l10n.lessonBuilderComposerPdf,
                          icon: Icons.picture_as_pdf_rounded,
                          selected: _mode == 'pdf',
                          onTap: () => setState(() => _mode = 'pdf'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.terminal_rounded, 
                            size: 16, 
                            color: theme.colorScheme.primary.withValues(alpha: 0.7)
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.lessonBuilderAiCommand.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        alignment: WrapAlignment.start,
                        children: widget.instructionItems.entries
                            .map(
                              (e) => _AiInstructionChip(
                                label: e.value,
                                selected: _instructionKey == e.key,
                                onTap: () => setState(() => _instructionKey = e.key),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _mode == 'text'
                          ? Padding(
                              key: const ValueKey('text-mode'),
                              padding: const EdgeInsets.only(top: 14),
                              child: TextField(
                                controller: _textController,
                                minLines: 7,
                                maxLines: 10,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: l10n.lessonBuilderPasteSourceText,
                                  alignLabelWithHint: true,
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor.withValues(alpha: isDark ? 0.25 : 0.45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: theme.dividerColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: theme.dividerColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: const Color(0xFFFF6600).withValues(alpha: 0.65),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : _mode == 'pdf'
                              ? Padding(
                                  key: const ValueKey('pdf-mode'),
                                  padding: const EdgeInsets.only(top: 14),
                                  child: InkWell(
                                    onTap: _pickPdf,
                                    borderRadius: BorderRadius.circular(24),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withValues(
                                            alpha: _pdfPath != null ? 0.5 : 0.15,
                                          ),
                                          width: _pdfPath != null ? 1.5 : 1,
                                        ),
                                        color: _pdfPath != null 
                                          ? theme.colorScheme.primary.withValues(alpha: 0.05)
                                          : theme.scaffoldBackgroundColor.withValues(alpha: 0.45),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _pdfPath != null ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
                                              color: theme.colorScheme.primary,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _pdfName ?? l10n.lessonBuilderChoosePdfFile,
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _pdfName == null
                                                ? l10n.lessonBuilderTapUploadPdf
                                                : l10n.lessonBuilderPdfSelectedReady,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  key: const ValueKey('existing-mode'),
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.34),
                                      border: Border.all(
                                        color: theme.dividerColor.withValues(alpha: 0.40),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.lessonBuilderAiReuseSavedSource,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: canSubmit ? [
                            BoxShadow(
                              color: const Color(0xFFFF6600).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ] : null,
                        ),
                        child: FilledButton(
                          onPressed: (_submitting || !canSubmit) ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: const Color(0xFFFF6600), // Brand Vibrant Orange
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_submitting)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                const Icon(Icons.auto_awesome_rounded, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                l10n.lessonBuilderGenerateLessonBlocks,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiInstructionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AiInstructionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: selected
                ? null
                : theme.scaffoldBackgroundColor.withValues(alpha: isDark ? 0.35 : 0.65),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: isDark ? 0.25 : 0.45),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AiModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AiModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? const Color(0xFF001A33).withValues(alpha: 0.08)
                : theme.scaffoldBackgroundColor.withValues(alpha: isDark ? 0.35 : 0.65),
            border: Border.all(
              color: selected
                  ? const Color(0xFF001A33).withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: isDark ? 0.25 : 0.45),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? const Color(0xFF001A33)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? const Color(0xFF001A33)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineToolButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _InlineToolButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.14)
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                selected ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
        ),
      ),
    );
  }
}

class _FailedPreview extends StatelessWidget {
  final String label;

  const _FailedPreview({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.42)),
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.32),
      ),
      alignment: Alignment.center,
      child: Text(label),
    );
  }
}

class _VideoPreviewCard extends StatefulWidget {
  final String url;

  const _VideoPreviewCard({super.key, required this.url});

  @override
  State<_VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<_VideoPreviewCard> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final uri = Uri.parse(widget.url);
      final controller = uri.scheme == 'file'
          ? VideoPlayerController.file(File(uri.toFilePath()))
          : VideoPlayerController.networkUrl(uri);
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _format(Duration value) {
    final mm = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _seekRelative(Duration delta) async {
    final controller = _controller;
    if (controller == null) return;
    final current = controller.value.position;
    final total = controller.value.duration;
    final next = current + delta;
    await controller.seekTo(
      next < Duration.zero
          ? Duration.zero
          : (next > total ? total : next),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (_error || _controller == null) {
      return _FailedPreview(label: l10n.lessonBuilderFailedLoadVideo);
    }
    if (!_ready) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final controller = _controller!;
    final aspectRatio = controller.value.aspectRatio <= 0
        ? 16 / 9
        : controller.value.aspectRatio;

    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VideoControlButton(
                    icon: Icons.replay_10_rounded,
                    onTap: () => _seekRelative(const Duration(seconds: -10)),
                  ),
                  const SizedBox(width: 12),
                  _VideoControlButton(
                    icon: controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 70,
                    onTap: () async {
                      if (controller.value.isPlaying) {
                        await controller.pause();
                      } else {
                        await controller.play();
                      }
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 12),
                  _VideoControlButton(
                    icon: Icons.forward_10_rounded,
                    onTap: () => _seekRelative(const Duration(seconds: 10)),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.44),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          _format(controller.value.position),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _format(controller.value.duration),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.only(top: 6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _VideoControlButton({
    required this.icon,
    required this.onTap,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _AudioPreviewCard extends StatefulWidget {
  final String url;
  final bool isVoice;

  const _AudioPreviewCard({
    super.key,
    required this.url,
    required this.isVoice,
  });

  @override
  State<_AudioPreviewCard> createState() => _AudioPreviewCardState();
}

class _AudioPreviewCardState extends State<_AudioPreviewCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _error = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      _player.onDurationChanged.listen((event) {
        if (!mounted) return;
        setState(() {
          _duration = event;
          _ready = true;
        });
      });
      _player.onPositionChanged.listen((event) {
        if (!mounted) return;
        setState(() => _position = event);
      });
      _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      });

      final uri = Uri.parse(widget.url);
      if (uri.scheme == 'file') {
        await _player.setSourceDeviceFile(uri.toFilePath());
      } else {
        await _player.setSourceUrl(widget.url);
      }
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration value) {
    final mm = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (_error) {
      return _FailedPreview(label: l10n.lessonBuilderFailedLoadAudio);
    }
    if (!_ready) {
      return Container(
        height: 96,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final maxMs = _duration.inMilliseconds <= 0 ? 1 : _duration.inMilliseconds;
    final currentMs = _position.inMilliseconds.clamp(0, maxMs);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.40),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _player.pause();
                    } else {
                      if (_duration > Duration.zero && _position >= _duration) {
                        await _player.seek(Duration.zero);
                      }
                      await _player.resume();
                    }
                    if (!mounted) return;
                    setState(() => _isPlaying = !_isPlaying);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isVoice ? l10n.lessonBuilderVoiceNote : l10n.lessonBuilderAudioFile,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_format(_position)} / ${_format(_duration)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Slider(
            value: currentMs.toDouble(),
            min: 0,
            max: maxMs.toDouble(),
            onChanged: (value) {
              _player.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ],
      ),
    );
  }
}

class _ElapsedTicker {
  final void Function(Duration elapsed) onTick;
  bool _running = false;
  DateTime? _start;

  _ElapsedTicker(this.onTick);

  void start() {
    if (_running) return;
    _running = true;
    _start = DateTime.now();
    _loop();
  }

  void stop() {
    _running = false;
    _start = null;
  }

  void dispose() {
    _running = false;
    _start = null;
  }

  Future<void> _loop() async {
    while (_running) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!_running || _start == null) return;
      onTick(DateTime.now().difference(_start!));
    }
  }
}

String? _resolveMediaUrl(_MediaBlockData media) {
  final localPath = media.localPath;
  if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
    return 'file://$localPath';
  }
  if (media.remoteUrl.isNotEmpty) return media.remoteUrl;
  if (media.mediaPath.isNotEmpty) return ApiHelpers.buildMediaUrl(media.mediaPath);
  return null;
}

String _mediaDisplayName(BuildContext context, _MediaBlockData media) {
  final l10n = AppLocalizations.of(context);
  if (media.localPath != null && media.localPath!.trim().isNotEmpty) {
    return media.localPath!.split(Platform.pathSeparator).last;
  }
  if (media.mediaPath.trim().isNotEmpty) {
    return media.mediaPath.split('/').last;
  }
  final url = media.remoteUrl.trim();
  if (url.isNotEmpty) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    } catch (_) {}
  }
  return media.kind == _MediaKind.pdf ? 'document.pdf' : l10n.lessonBuilderFile;
}

String _formatDurationMmSs(Duration duration) {
  final mm = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

IconData _iconForBlock(_LessonBlock block) {
  if (block.type == _LessonBlockType.text) return Icons.notes_rounded;
  final kind = block.media?.kind;
  switch (kind) {
    case _MediaKind.image:
      return Icons.image_rounded;
    case _MediaKind.video:
      return Icons.videocam_rounded;
    case _MediaKind.audio:
      return Icons.audio_file_rounded;
    case _MediaKind.voice:
      return Icons.mic_rounded;
    case _MediaKind.pdf:
      return Icons.picture_as_pdf_rounded;
    case null:
      return Icons.article_outlined;
  }
}

String _titleForBlock(BuildContext context, _LessonBlock block) {
  final l10n = AppLocalizations.of(context);
  if (block.type == _LessonBlockType.text) return l10n.lessonBuilderTextBlock;
  switch (block.media?.kind) {
    case _MediaKind.image:
      return l10n.lessonBuilderImageBlock;
    case _MediaKind.video:
      return l10n.lessonBuilderVideoBlock;
    case _MediaKind.audio:
      return l10n.lessonBuilderAudioBlock;
    case _MediaKind.voice:
      return l10n.lessonBuilderVoiceNote;
    case _MediaKind.pdf:
      return l10n.lessonBuilderPdfBlock;
    case null:
      return l10n.lessonBuilderMediaBlock;
  }
}