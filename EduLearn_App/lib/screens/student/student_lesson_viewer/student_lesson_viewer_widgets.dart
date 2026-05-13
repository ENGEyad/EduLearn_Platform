part of 'student_lesson_viewer_screen.dart';

class StudentLessonViewerHeader extends StatelessWidget {
  final String title;
  final String durationLabel;
  final String status;
  final int blocksCount;

  const StudentLessonViewerHeader({
    super.key,
    required this.title,
    required this.durationLabel,
    required this.status,
    required this.blocksCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final borderColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.92 : 0.72);
    final softBoxColor = isDarkMode
        ? EduTheme.darkSurfaceContainer
        : EduTheme.softPrimaryBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: EduTheme.radiusXL,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.cardShadow(isDarkMode),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: softBoxColor,
              borderRadius: EduTheme.radiusLarge,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_agenda_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$blocksCount',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.studentLessonViewerBlocks,
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _HeaderStatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _HeaderStatusBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: EduTheme.radiusLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color backgroundColor;

  const _HeaderStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: EduTheme.radiusLarge,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: EduTheme.radiusMedium,
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
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

class StudentLessonContentCard extends StatelessWidget {
  final Widget child;

  const StudentLessonContentCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.92 : 0.72);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: EduTheme.radiusXL,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.cardShadow(isDarkMode),
      ),
      child: child,
    );
  }
}

class StudentLessonInlineSection extends StatelessWidget {
  final Widget child;

  const StudentLessonInlineSection({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final fillColor = isDarkMode
        ? EduTheme.darkSurfaceContainerLow
        : EduTheme.surfaceContainerLow;
    final borderColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.75 : 0.62);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: EduTheme.radiusLarge,
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class StudentLessonSectionDivider extends StatelessWidget {
  final int index;

  const StudentLessonSectionDivider({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dividerColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.95 : 0.9);
    final fillColor = isDarkMode
        ? EduTheme.darkSurfaceContainerLow
        : EduTheme.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor, thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: EduTheme.radiusPill,
              border: Border.all(color: dividerColor),
            ),
            child: Text(
              l10n.studentLessonViewerSection(index + 1),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor, thickness: 1)),
        ],
      ),
    );
  }
}

class StudentLessonViewerErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const StudentLessonViewerErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: StudentLessonContentCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.studentLessonViewerErrorTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.studentLessonViewerRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentLessonViewerEmptyState extends StatelessWidget {
  const StudentLessonViewerEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final boxColor = isDarkMode
        ? EduTheme.darkSurfaceContainerLow
        : EduTheme.surfaceContainerLow;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: EduTheme.radiusLarge,
      ),
      padding: const EdgeInsets.all(18),
      child: Text(
        l10n.studentLessonViewerEmptyLessonContent,
        style: TextStyle(
          color: mutedColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StudentLessonViewerActionDock extends StatelessWidget {
  final bool isCompleted;
  final bool isLoading;
  final VoidCallback onListenTap;
  final VoidCallback onExercisesTap;
  final VoidCallback? onCompleteTap;

  const StudentLessonViewerActionDock({
    super.key,
    required this.isCompleted,
    required this.isLoading,
    required this.onListenTap,
    required this.onExercisesTap,
    required this.onCompleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.96 : 0.88);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.20 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _DockActionButton(
                    icon: Icons.headphones_rounded,
                    label: l10n.studentLessonViewerListen,
                    onTap: onListenTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DockActionButton(
                    icon: Icons.quiz_outlined,
                    label: l10n.studentLessonViewerExercises,
                    onTap: onExercisesTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading || isCompleted ? null : onCompleteTap,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.task_alt_rounded,
                      ),
                label: Text(
                  isCompleted
                      ? l10n.studentLessonViewerCompleted
                      : l10n.studentLessonViewerCompleteLesson,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCompleted ? const Color(0xFF4CAF50) : EduTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: EduTheme.radiusLarge,
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DockActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.78 : 0.72);
    final fillColor = isDarkMode
        ? EduTheme.darkSurfaceContainerLow
        : EduTheme.surfaceContainerLow;

    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          backgroundColor: fillColor,
          shape: RoundedRectangleBorder(
            borderRadius: EduTheme.radiusLarge,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String body;
  final double fontSize;

  const _TextBlock({
    required this.body,
    required this.fontSize,
  });

  TextSpan _buildStyledTextSpan(BuildContext context, String text) {
    final theme = Theme.of(context);
    final defaultStyle = TextStyle(
      fontSize: fontSize,
      height: 1.7,
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|_(.+?)_', dotAll: true);
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      final boldText = match.group(1);
      final italicText = match.group(2);

      if (boldText != null) {
        spans.add(TextSpan(
          text: boldText,
          style: defaultStyle.copyWith(fontWeight: FontWeight.w900),
        ));
      } else if (italicText != null) {
        spans.add(TextSpan(
          text: italicText,
          style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: defaultStyle));
    }

    return TextSpan(children: spans, style: defaultStyle);
  }

  @override
  Widget build(BuildContext context) {
    final t = body.trim();
    if (t.isEmpty) return const SizedBox.shrink();
    return RichText(text: _buildStyledTextSpan(context, t));
  }
}

class _ImageBlock extends StatelessWidget {
  final String url;
  final String caption;

  const _ImageBlock({
    required this.url,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            EduTheme.textMuted;

    if (url.isEmpty) {
      return Text(
        l10n.studentLessonViewerImageNotAvailable,
        style: TextStyle(color: mutedColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: InteractiveViewer(
                    child: Image.network(url),
                  ),
                ),
              );
            },
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: theme.brightness == Brightness.dark
                    ? EduTheme.darkSurface
                    : Colors.grey.withValues(alpha: 0.1),
                child: const Center(child: Icon(Icons.broken_image_rounded)),
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _FileBlock extends StatelessWidget {
  final String url;
  final String caption;

  const _FileBlock({
    required this.url,
    required this.caption,
  });

  Future<void> _openDocument(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentLessonViewerFileNotAvailable)),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.studentLessonViewerCouldNotOpenFile)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.studentLessonViewerCouldNotOpenFile)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return InkWell(
      onTap: () => _openDocument(context),
      borderRadius: EduTheme.radiusLarge,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDarkMode ? 0.12 : 0.05),
          borderRadius: EduTheme.radiusLarge,
          border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption.isNotEmpty
                      ? caption
                      : l10n.studentLessonViewerPdfDocumentation,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.studentLessonViewerTapToOpenDocument,
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoBlock extends StatelessWidget {
  final String url;
  final String caption;

  const _VideoBlock({
    required this.url,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    if (url.isEmpty) {
      return Text(
        l10n.studentLessonViewerVideoNotAvailable,
        style: TextStyle(color: mutedColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonVideoPlayer(url: url),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
        ],
      ],
    );
  }
}

class LessonAudioPlayer extends StatefulWidget {
  final String url;
  final String? title;

  const LessonAudioPlayer({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<LessonAudioPlayer> createState() => _LessonAudioPlayerState();
}

class _LessonAudioPlayerState extends State<LessonAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription? _durSub;
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  bool _ready = false;
  bool _isPlaying = false;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _loadingSource = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _bindStreams();

    try {
      _loadingSource = true;
      if (mounted) setState(() {});

      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setSourceUrl(widget.url);

      _ready = true;
    } catch (_) {
      _ready = false;
    } finally {
      _loadingSource = false;
      if (mounted) setState(() {});
    }
  }

  void _bindStreams() {
    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = (s == PlayerState.playing));
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  Future<void> play() async {
    if (!_ready) return;
    await _player.resume();
  }

  Future<void> pause() async {
    if (!_ready) return;
    await _player.pause();
  }

  Future<void> toggle() async {
    if (!_ready) return;
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration d) async {
    if (!_ready) return;
    await _player.seek(d);
  }

  @override
  void dispose() {
    _durSub?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final softBoxColor = isDarkMode
        ? EduTheme.darkSurfaceContainer
        : EduTheme.softSecondaryBackground;

    if (widget.url.isEmpty) {
      return Text(
        l10n.studentLessonViewerAudioNotAvailable,
        style: TextStyle(color: mutedColor),
      );
    }

    final maxMs = (_duration.inMilliseconds <= 0)
        ? 1.0
        : _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds
        .clamp(0, _duration.inMilliseconds)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((widget.title ?? '').trim().isNotEmpty) ...[
          Text(
            widget.title!.trim(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            color: softBoxColor,
            borderRadius: EduTheme.radiusLarge,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: _loadingSource ? null : toggle,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !_ready ? const Color(0xFFBFC7DA) : EduTheme.primary,
                  ),
                  child: _loadingSource
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Slider(
                      value: posMs,
                      max: maxMs,
                      onChanged: !_ready
                          ? null
                          : (v) => seek(Duration(milliseconds: v.toInt())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(_position),
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                        Text(
                          _fmt(_duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!_ready && !_loadingSource) ...[
          const SizedBox(height: 8),
          Text(
            l10n.studentLessonViewerAudioPlaybackFailed,
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
        ],
      ],
    );
  }
}

class LessonVideoPlayer extends StatefulWidget {
  final String url;

  const LessonVideoPlayer({
    super.key,
    required this.url,
  });

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _initError = false;
      _initialized = false;
      if (mounted) setState(() {});

      final uri = Uri.tryParse(widget.url);
      if (uri == null) {
        _initError = true;
        if (mounted) setState(() {});
        return;
      }

      final c = VideoPlayerController.networkUrl(uri);
      _controller = c;

      await c.initialize();
      await c.setLooping(false);

      _initialized = true;
      if (mounted) setState(() {});
    } catch (_) {
      _initError = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (!_initialized || _initError || c == null) return;

    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    if (mounted) setState(() {});
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final softBoxColor =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFEEF1F8);

    if (widget.url.isEmpty) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: softBoxColor,
          borderRadius: EduTheme.radiusLarge,
        ),
        alignment: Alignment.center,
        child: Text(
          l10n.studentLessonViewerVideoNotAvailable,
          style: TextStyle(color: mutedColor),
        ),
      );
    }

    if (_initError) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: softBoxColor,
          borderRadius: EduTheme.radiusLarge,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.studentLessonViewerUnableToLoadVideo,
              style: TextStyle(color: mutedColor),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _initVideo,
              child: Text(l10n.studentLessonViewerRetry),
            ),
          ],
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: softBoxColor,
          borderRadius: EduTheme.radiusLarge,
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final c = _controller!;
    final total = c.value.duration;
    final pos = c.value.position;
    final isPlaying = c.value.isPlaying;

    return ClipRRect(
      borderRadius: EduTheme.radiusLarge,
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio == 0 ? (16 / 9) : c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  opacity: isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Row(
                children: [
                  Text(
                    _fmt(pos),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _fmt(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
