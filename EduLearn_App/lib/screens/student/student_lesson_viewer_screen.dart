import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:edulearn/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../theme.dart';
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

class _StudentLessonViewerScreenState extends State<StudentLessonViewerScreen> {
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
    _scrollController.dispose();
    super.dispose();
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
      await StudentService.updateStudentLessonStatus(
        academicId: widget.academicId,
        lessonId: widget.lessonId,
        status: 'completed',
      );
      _statusForStudent = 'completed';

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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: EduTheme.primaryDark),
            onPressed: () => _onWillPop(),
          ),
          centerTitle: true,
          title: Text(
            _title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EduTheme.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _loadLessonDetail,
              icon: const Icon(Icons.refresh_rounded,
                  color: EduTheme.primaryDark),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Error loading lesson',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: EduTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EduTheme.textMuted,
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: EduTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            if (_durationLabel.isNotEmpty)
              Text(
                _durationLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: EduTheme.textMuted,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: const Text(
        'لا يوجد محتوى داخل هذا الدرس بعد.',
        style: TextStyle(
          color: EduTheme.textMuted,
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

    if (isImage) {
      return _CardShell(
        child: _ImageBlock(url: url, caption: caption),
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
    final meta =
        (block['meta'] is Map) ? (block['meta'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
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
    final title = (quiz['title'] ?? 'Knowledge Check').toString();
    final question = (quiz['question'] ?? '').toString();
    final options = (quiz['options'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: EduTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 10),
        if (question.isNotEmpty) ...[
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: EduTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (options.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E4F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked,
              size: 18, color: EduTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: EduTheme.primaryDark,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E4F0), width: 0.6),
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
            label: 'Ask',
            onTap: () => _showSnack('Ask سيتم تفعيلها لاحقاً.'),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
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

  TextSpan _buildStyledTextSpan(String text) {
    final defaultStyle = TextStyle(
      fontSize: fontSize,
      height: 1.45,
      color: EduTheme.primaryDark,
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
    return RichText(text: _buildStyledTextSpan(t));
  }
}

class _ImageBlock extends StatelessWidget {
  final String url;
  final String caption;

  const _ImageBlock({required this.url, required this.caption});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Text(
        'Image not available',
        style: TextStyle(color: EduTheme.textMuted),
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
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              );
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFEEF1F8),
                  alignment: Alignment.center,
                  child: const Text(
                    'Failed to load image',
                    style: TextStyle(color: EduTheme.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 12,
              color: EduTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _VideoBlock extends StatelessWidget {
  final String url;
  final String caption;

  const _VideoBlock({required this.url, required this.caption});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Text(
        'Video not available',
        style: TextStyle(color: EduTheme.textMuted),
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
            style: const TextStyle(
              fontSize: 12,
              color: EduTheme.textMuted,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: EduTheme.textMuted),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: EduTheme.textMuted,
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
    if (widget.url.isEmpty) {
      return const Text(
        'Audio not available',
        style: TextStyle(color: EduTheme.textMuted),
      );
    }

    final maxMs = (_duration.inMilliseconds <= 0) ? 1.0 : _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((widget.title ?? '').trim().isNotEmpty) ...[
          Text(
            widget.title!.trim(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: EduTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7FF),
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
                    color: !_ready
                        ? const Color(0xFFBFC7DA)
                        : EduTheme.primary,
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: EduTheme.textMuted,
                          ),
                        ),
                        Text(
                          _fmt(_duration),
                          style: const TextStyle(
                            fontSize: 11,
                            color: EduTheme.textMuted,
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
          const Text(
            'تعذر تشغيل الصوت. تأكد من الرابط أو الاتصال.',
            style: TextStyle(fontSize: 12, color: EduTheme.textMuted),
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
    if (widget.url.isEmpty) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F8),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Video not available',
          style: TextStyle(color: EduTheme.textMuted),
        ),
      );
    }

    if (_initError) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F8),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load video',
              style: TextStyle(color: EduTheme.textMuted),
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
          color: const Color(0xFFEEF1F8),
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
