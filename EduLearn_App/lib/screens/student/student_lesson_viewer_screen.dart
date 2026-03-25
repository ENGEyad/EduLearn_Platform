import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:edulearn/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../theme.dart';
import 'ai_tutor_screen.dart';
import 'lesson_completion_screen.dart';
// import '../../services/student_service.dart';

class StudentLessonViewerScreen extends StatefulWidget {
  final int lessonId;
  final String academicId;

  final String initialTitle;
  final String? initialDurationLabel;
  final String initialStatus; // not_started | draft | completed

  const StudentLessonViewerScreen({
    super.key,
    required this.lessonId,
    required this.academicId,
    required this.initialTitle,
    this.initialDurationLabel,
    this.initialStatus = 'not_started',
  });

  @override
  State<StudentLessonViewerScreen> createState() =>
      _StudentLessonViewerScreenState();
}

class _StudentLessonViewerScreenState extends State<StudentLessonViewerScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _error;

  late String _title;
  String _durationLabel = '';

  String _statusForStudent = 'not_started';
  bool _isCompleting = false;

  List<Map<String, dynamic>> _blocks = [];
  Map<String, dynamic>? _quizData;

  // ===== UX helpers =====
  final ScrollController _scrollController = ScrollController();

  // Audio auto-play support (Listen button)
  final Map<int, GlobalKey<_LessonAudioPlayerState>> _audioKeysByIndex = {};

  final Stopwatch _studyStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();

    _title = widget.initialTitle;
    _durationLabel = widget.initialDurationLabel ?? '';
    _statusForStudent = _normalizeStatus(widget.initialStatus);

    // ✅ أول مرة فقط: نحول not_started -> draft عند أول فتح (مثل الاتفاق)
    if (_statusForStudent == 'not_started') {
      _setDraftStatusSilently();
    }

    _loadLessonDetail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studyStopwatch.stop();
    _saveProgressSilently(isCompleted: _statusForStudent == 'completed');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_studyStopwatch.isRunning) {
        _studyStopwatch.start();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_studyStopwatch.isRunning) {
        _studyStopwatch.stop();
      }
    }
  }

  Future<void> _saveProgressSilently({bool isCompleted = false}) async {
    final elapsedSecs = _studyStopwatch.elapsed.inSeconds;
    if (elapsedSecs <= 0 && !isCompleted) return;

    try {
      await StudentService.saveStudentLessonProgress(
        academicId: widget.academicId,
        lessonId: widget.lessonId,
        timeSpentSeconds: elapsedSecs,
        status: isCompleted ? 'completed' : 'draft',
      );
      // Reset stopwatch to avoid counting twice if not disposed
      if (!isCompleted) _studyStopwatch.reset();
    } catch (_) {}
  }

  // =========================
  // Status normalization
  // =========================
  String _normalizeStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'completed') return 'completed';
    if (s == 'draft') return 'draft';
    return 'not_started';
  }

  Future<void> _setDraftStatusSilently() async {
    try {
      await StudentService.updateStudentLessonStatus(
        academicId: widget.academicId,
        lessonId: widget.lessonId,
        status: 'draft',
      );
      _statusForStudent = 'draft';
    } catch (_) {
      // تجاهل لتجنب إزعاج المستخدم
    }
  }

  // =========================
  // Media helpers (unified)
  // =========================
  String _mediaValueFromBlock(Map<String, dynamic> block) {
    // prefer backend helper if exists
    try {
      final v = ApiHelpers.pickMediaValueFromBlock(block);
      if (v is String) return v;
    } catch (_) {}

    final rawPath = (block['media_path'] ?? '').toString().trim();
    final rawUrl = (block['media_url'] ?? '').toString().trim();

    if (rawPath.isNotEmpty) return rawPath;
    if (rawUrl.isNotEmpty) return rawUrl;
    return '';
  }

  String _buildMediaUrl(String rawOrPath) {
    if (rawOrPath.isEmpty) return '';
    try {
      return ApiHelpers.buildMediaUrl(rawOrPath);
    } catch (_) {
      return ApiHelpers.buildFullMediaUrl(rawOrPath);
    }
  }

  bool _isVideoByMimeOrExt(String url, String mime) {
    final u = url.toLowerCase();
    final m = mime.toLowerCase();
    if (m.startsWith('video/')) return true;
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.mkv') ||
        u.endsWith('.webm') ||
        u.contains('.mp4?') ||
        u.contains('.mov?');
  }

  bool _isAudioByMimeOrExt(String url, String mime) {
    final u = url.toLowerCase();
    final m = mime.toLowerCase();
    if (m.startsWith('audio/')) return true;
    return u.endsWith('.mp3') ||
        u.endsWith('.wav') ||
        u.endsWith('.m4a') ||
        u.endsWith('.aac') ||
        u.contains('.mp3?') ||
        u.contains('.m4a?');
  }

  int _sortValue(Map<String, dynamic> b, String key) {
    final v = b[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // =========================
  // Load lesson
  // =========================
  Future<void> _loadLessonDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _audioKeysByIndex.clear();
    });

    try {
      // ✅ واجهة الطالب فقط (لا نستخدم fetchLessonDetail للأستاذ لأنه يتطلب teacherCode)
      final lesson = await StudentService.fetchStudentLessonDetail(
        academicId: widget.academicId,
        lessonId: widget.lessonId,
      );

      // title
      _title = (lesson['title'] ?? _title).toString();

      // duration_label (لو رجع من السيرفر)
      final dl = (lesson['duration_label'] ?? '').toString().trim();
      if (dl.isNotEmpty) {
        _durationLabel = dl;
      }

      // blocks
      final rawBlocks = lesson['blocks'];
      if (rawBlocks is List) {
        _blocks = rawBlocks
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // ✅ ترتيب ثابت: sort_order ثم position ثم id (حسب ما عندكم في Laravel normalize)
        _blocks.sort((a, b) {
          int readInt(dynamic v) {
            if (v is int) return v;
            if (v is num) return v.toInt();
            return int.tryParse(v?.toString() ?? '') ?? 0;
          }

          final sa = readInt(a['sort_order']);
          final sb = readInt(b['sort_order']);
          if (sa != sb) return sa.compareTo(sb);

          final pa = readInt(a['position']);
          final pb = readInt(b['position']);
          if (pa != pb) return pa.compareTo(pb);

          final ia = readInt(a['id']);
          final ib = readInt(b['id']);
          return ia.compareTo(ib);
        });
      } else {
        _blocks = [];
      }

      // quiz (اختياري)
      final q = lesson['quiz'];
      if (q is Map) {
        _quizData = Map<String, dynamic>.from(q);
      } else {
        _quizData = null;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================
  // Actions
  // =========================
  Future<void> _onMarkCompleted() async {
    setState(() => _isCompleting = true);

    try {
      _studyStopwatch.stop();
      final elapsedSecs = _studyStopwatch.elapsed.inSeconds;

      await StudentService.saveStudentLessonProgress(
        academicId: widget.academicId,
        lessonId: widget.lessonId,
        timeSpentSeconds: elapsedSecs,
        status: 'completed',
      );
      _statusForStudent = 'completed';

      if (!mounted) return;

      // Reset the stopwatch to 0 so dispose doesn't add more time if they somehow go back.
      _studyStopwatch.reset();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LessonCompletionScreen(
            title: _title,
            timeSpentSeconds: elapsedSecs,
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop('completed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_statusForStudent != 'completed') {
      Navigator.of(context).pop('draft');
      return false;
    }
    return true;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onListenPressed() async {
    if (_blocks.isEmpty) {
      _showSnack('لا يوجد محتوى صوتي في هذا الدرس.');
      return;
    }

    // find first audio block index
    int? audioIndex;
    for (int i = 0; i < _blocks.length; i++) {
      final b = _blocks[i];
      final type = (b['type'] ?? 'text').toString().toLowerCase();
      final raw = _mediaValueFromBlock(b);
      final url = _buildMediaUrl(raw);
      final mime = (b['mime'] ?? b['media_mime'] ?? '').toString();
      final isAudio = type == 'audio' || _isAudioByMimeOrExt(url, mime);

      if (isAudio && url.isNotEmpty) {
        audioIndex = i;
        break;
      }
    }

    if (audioIndex == null) {
      _showSnack('لا يوجد مقطع صوتي داخل هذا الدرس.');
      return;
    }

    // scroll close to that item (approx)
    final targetOffset = (audioIndex * 210).toDouble();
    await _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
    );

    // try auto-play
    final key = _audioKeysByIndex[audioIndex];
    if (key?.currentState != null) {
      await key!.currentState!.play();
    }
  }

  // =========================
  // Build UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: titleColor,
            ),
            onPressed: () => _onWillPop(),
          ),
          centerTitle: true,
          title: Text(
            _title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _loadLessonDetail,
              icon: Icon(
                Icons.refresh_rounded,
                color: titleColor,
              ),
              tooltip: 'Refresh',
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error loading lesson',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadLessonDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return RefreshIndicator(
      onRefresh: _loadLessonDetail,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              _title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            if (_durationLabel.isNotEmpty)
              Text(
                _durationLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
            const SizedBox(height: 12),

            if (_blocks.isEmpty) ...[
              _buildEmptyState(),
              const SizedBox(height: 16),
            ],

            // Blocks
            for (int i = 0; i < _blocks.length; i++) ...[
              _buildBlock(_blocks[i], index: i),
              const SizedBox(height: 16),
            ],

            // Quiz placeholder if present
            if (_quizData != null) ...[
              const SizedBox(height: 8),
              _buildKnowledgeCheckFromData(_quizData!),
            ],

            const SizedBox(height: 18),
            _buildMarkAsCompletedButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final boxColor =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFF3F7FF);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        'لا يوجد محتوى داخل هذا الدرس بعد.',
        style: TextStyle(
          color: mutedColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBlock(Map<String, dynamic> block, {required int index}) {
    final type = (block['type'] ?? 'text').toString().toLowerCase();
    final mime = (block['mime'] ?? block['media_mime'] ?? '').toString();

    final raw = _mediaValueFromBlock(block);
    final url = _buildMediaUrl(raw);

    final caption = (block['caption'] ?? '').toString().trim();

    final isVideo = (type == 'video') || _isVideoByMimeOrExt(url, mime);
    final isAudio = (type == 'audio') || _isAudioByMimeOrExt(url, mime);
    final isImage = (type == 'image');
    final isFile = (type == 'file') || (type == 'pdf') || mime.contains('pdf');

    if (isImage) {
      return _CardShell(
        child: _ImageBlock(url: url, caption: caption),
      );
    }

    if (isFile) {
      return _CardShell(
        child: _FileBlock(url: url, caption: caption),
      );
    }

    if (isVideo) {
      return _CardShell(
        child: _VideoBlock(url: url, caption: caption),
      );
    }

    if (isAudio) {
      final key = GlobalKey<_LessonAudioPlayerState>();
      _audioKeysByIndex[index] = key;

      return _CardShell(
        child: LessonAudioPlayer(
          key: key,
          url: url,
          title: caption.isNotEmpty ? caption : 'Audio',
        ),
      );
    }

    // text
    final body = (block['body'] ?? '').toString();
    final meta = (block['meta'] is Map)
        ? (block['meta'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final fontSize = (meta['font_size'] is num)
        ? (meta['font_size'] as num).toDouble()
        : 14.5;

    return _CardShell(
      child: _TextBlock(body: body, fontSize: fontSize),
    );
  }

  Widget _buildMarkAsCompletedButton() {
    final isCompleted = _statusForStudent == 'completed';

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isCompleting || isCompleted ? null : _onMarkCompleted,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isCompleted ? const Color(0xFF4CAF50) : EduTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isCompleting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompleted ? 'Completed' : 'Mark as Completed',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.check_rounded,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildKnowledgeCheckFromData(Map<String, dynamic> quiz) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    final title = (quiz['title'] ?? 'Knowledge Check').toString();
    final question = (quiz['question'] ?? '').toString();
    final options =
        (quiz['options'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),
        if (question.isNotEmpty) ...[
          Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (options.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final opt in options) _quizOption(opt),
              ],
            ),
          ),
      ],
    );
  }

  Widget _quizOption(String text) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final borderColor =
        isDarkMode ? EduTheme.darkInputBorder : const Color(0xFFE0E4F0);
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.radio_button_unchecked,
            size: 18,
            color: mutedColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? EduTheme.darkInputBorder : const Color(0xFFE0E4F0);

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.headphones_rounded,
            label: 'Listen',
            onTap: _onListenPressed,
          ),
          _BottomNavItem(
            icon: Icons.style_rounded,
            label: 'Flashcards',
            onTap: () => _showSnack('Flashcards سيتم تفعيلها لاحقاً.'),
          ),
          _BottomNavItem(
            icon: Icons.help_outline_rounded,
            label: 'AI Tutor',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AITutorScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ====================== UI building blocks ======================

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String body;
  final double fontSize;

  const _TextBlock({required this.body, required this.fontSize});

  TextSpan _buildStyledTextSpan(BuildContext context, String text) {
    final theme = Theme.of(context);
    final defaultStyle = TextStyle(
      fontSize: fontSize,
      height: 1.45,
      color: theme.colorScheme.onSurface,
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
          style: defaultStyle.copyWith(fontWeight: FontWeight.w800),
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

  const _ImageBlock({required this.url, required this.caption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            EduTheme.textMuted;

    if (url.isEmpty) {
      return Text(
        'Image not available',
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
                height: 120,
                color: theme.brightness == Brightness.dark
                    ? EduTheme.darkSurface
                    : Colors.grey.withValues(alpha: 0.1),
                child: const Center(child: Icon(Icons.broken_image_rounded)),
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
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

  const _FileBlock({required this.url, required this.caption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return InkWell(
      onTap: () {
        // In a real app, use url_launcher or a PDF viewer package.
        // For now, we'll just show a snackbar with the URL.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening document: $url')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDarkMode ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        caption.isNotEmpty ? caption : 'PDF Documentation',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        'Tap to open document',
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
          ],
        ),
      ),
    );
  }
}

class _VideoBlock extends StatelessWidget {
  final String url;
  final String caption;

  const _VideoBlock({required this.url, required this.caption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    if (url.isEmpty) {
      return Text(
        'Video not available',
        style: TextStyle(color: mutedColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonVideoPlayer(url: url),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: mutedColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== Audio Player (improved & reusable) ===================

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
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final softBoxColor =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFF3F7FF);

    if (widget.url.isEmpty) {
      return Text(
        'Audio not available',
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
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: _loadingSource ? null : toggle,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
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
            'تعذر تشغيل الصوت. تأكد من الرابط أو الاتصال.',
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
        ],
      ],
    );
  }
}

// =================== Video Player (improved) ===================

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
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          'Video not available',
          style: TextStyle(color: mutedColor),
        ),
      );
    }

    if (_initError) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: softBoxColor,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load video',
              style: TextStyle(color: mutedColor),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _initVideo,
              child: const Text('Retry'),
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
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final c = _controller!;
    final total = c.value.duration;
    final pos = c.value.position;

    final isPlaying = c.value.isPlaying;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio == 0 ? (16 / 9) : c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),

            // overlay
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

            // bottom progress
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