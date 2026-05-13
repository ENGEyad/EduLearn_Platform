import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:edulearn/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../theme.dart';
import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_lesson_viewer_l10n.dart';
import '../student_lesson_exercises/student_lesson_exercises_screen.dart';

part 'student_lesson_viewer_widgets.dart';

class StudentLessonViewerScreen extends StatefulWidget {
  final int lessonId;
  final String academicId; // used only to pass to exercises screen (will be removed later)

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
  static const Duration _silentSaveInterval = Duration(seconds: 20);
  static const double _estimatedBlockHeight = 210;

  bool _isLoading = true;
  String? _error;

  late String _title;
  String _durationLabel = '';

  String _statusForStudent = 'not_started';
  bool _isCompleting = false;
  bool _isSavingProgress = false;
  bool _pendingSaveAfterCurrent = false;
  bool _hasRestoredScroll = false;

  List<Map<String, dynamic>> _blocks = [];

  final ScrollController _scrollController = ScrollController();

  final Map<int, GlobalKey<_LessonAudioPlayerState>> _audioKeysByIndex = {};

  final Stopwatch _studyStopwatch = Stopwatch();
  DateTime? _lastSilentSaveAt;

  int _lastBlockIndex = 0;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScrollTracking);

    _title = widget.initialTitle;
    _durationLabel = widget.initialDurationLabel ?? '';
    _statusForStudent = _normalizeStatus(widget.initialStatus);

    _loadLessonDetail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScrollTracking);
    _studyStopwatch.stop();
    unawaited(_saveProgressSilently(isCompleted: _statusForStudent == 'completed'));
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_studyStopwatch.isRunning && _statusForStudent != 'completed') {
        _studyStopwatch.start();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_studyStopwatch.isRunning) {
        _studyStopwatch.stop();
      }
      unawaited(_saveProgressSilently(isCompleted: _statusForStudent == 'completed'));
    }
  }

  void _handleScrollTracking() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    ).toDouble();

    _lastScrollOffset = offset;
    _lastBlockIndex = _estimateCurrentBlockIndex(offset);

    final now = DateTime.now();
    if (_statusForStudent != 'completed' &&
        (_lastSilentSaveAt == null ||
            now.difference(_lastSilentSaveAt!) >= _silentSaveInterval)) {
      _lastSilentSaveAt = now;
      unawaited(_saveProgressSilently());
    }
  }

  int _estimateCurrentBlockIndex(double offset) {
    if (_blocks.isEmpty) return 0;

    final estimated = (offset / _estimatedBlockHeight).floor();
    return estimated.clamp(0, _blocks.length - 1).toInt();
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _markLessonOpenedSilently() async {
    if (_statusForStudent == 'completed') return;

    try {
      // ✅ removed academicId
      final data = await StudentService.saveStudentLessonProgress(
        lessonId: widget.lessonId,
        timeSpentSeconds: 0,
        status: 'draft',
        lastBlockIndex: _lastBlockIndex,
        lastScrollOffset: _lastScrollOffset,
        markOpened: true,
      );

      _statusForStudent = _normalizeStatus(
        (data['status'] ?? _statusForStudent).toString(),
      );
    } catch (_) {}
  }

  Future<void> _saveProgressSilently({bool isCompleted = false}) async {
    if (_isSavingProgress) {
      _pendingSaveAfterCurrent = true;
      return;
    }

    final elapsedSecs = _studyStopwatch.elapsed.inSeconds;
    if (elapsedSecs <= 0 && !isCompleted) return;

    _isSavingProgress = true;

    try {
      // ✅ removed academicId
      final data = await StudentService.saveStudentLessonProgress(
        lessonId: widget.lessonId,
        timeSpentSeconds: elapsedSecs,
        status: isCompleted ? 'completed' : 'draft',
        lastBlockIndex: _lastBlockIndex,
        lastScrollOffset: _lastScrollOffset,
      );

      final serverStatus = _normalizeStatus(
        (data['status'] ?? _statusForStudent).toString(),
      );
      _statusForStudent = serverStatus;

      _studyStopwatch.reset();
      if (!isCompleted && _statusForStudent != 'completed') {
        _studyStopwatch.start();
      }
    } catch (_) {
      if (!_studyStopwatch.isRunning && !isCompleted) {
        _studyStopwatch.start();
      }
    } finally {
      _isSavingProgress = false;

      if (_pendingSaveAfterCurrent) {
        _pendingSaveAfterCurrent = false;
        unawaited(_saveProgressSilently(isCompleted: _statusForStudent == 'completed'));
      }
    }
  }

  String _normalizeStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'completed') return 'completed';
    if (s == 'draft') return 'draft';
    return 'not_started';
  }

  String _mediaValueFromBlock(Map<String, dynamic> block) {
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
    if (_isAudioByMimeOrExt(url, mime)) return false;

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
        u.endsWith('.ogg') ||
        u.endsWith('.opus') ||
        u.endsWith('.weba') ||
        u.endsWith('.m4b') ||
        u.contains('.mp3?') ||
        u.contains('.m4a?') ||
        u.contains('.wav?') ||
        u.contains('.aac?') ||
        u.contains('.ogg?') ||
        u.contains('.opus?');
  }

  Future<void> _loadLessonDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _audioKeysByIndex.clear();
      _hasRestoredScroll = false;
    });

    try {
      // ✅ removed academicId
      final lesson = await StudentService.fetchStudentLessonDetail(
        lessonId: widget.lessonId,
      );

      _title = (lesson['title'] ?? _title).toString();
      _statusForStudent = _normalizeStatus(
        (lesson['status'] ?? _statusForStudent).toString(),
      );
      _lastBlockIndex = _readInt(lesson['last_block_index']);
      _lastScrollOffset = _readDouble(lesson['last_scroll_offset']);

      final dl = (lesson['duration_label'] ?? '').toString().trim();
      if (dl.isNotEmpty) {
        _durationLabel = dl;
      }

      final rawBlocks = lesson['blocks'];
      if (rawBlocks is List) {
        _blocks = rawBlocks
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _blocks.sort((a, b) {
          final sa = _readInt(a['sort_order']);
          final sb = _readInt(b['sort_order']);
          if (sa != sb) return sa.compareTo(sb);

          final pa = _readInt(a['position']);
          final pb = _readInt(b['position']);
          if (pa != pb) return pa.compareTo(pb);

          final ia = _readInt(a['id']);
          final ib = _readInt(b['id']);
          return ia.compareTo(ib);
        });
      } else {
        _blocks = [];
      }

      if (_statusForStudent == 'not_started') {
        _statusForStudent = 'draft';
      }

      unawaited(_markLessonOpenedSilently());
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreLastScrollPosition();
        if (_statusForStudent != 'completed' && !_studyStopwatch.isRunning) {
          _studyStopwatch.start();
        }
      });
    }
  }

  void _restoreLastScrollPosition() {
    if (_hasRestoredScroll || !_scrollController.hasClients) return;
    if (_lastScrollOffset <= 0) {
      _hasRestoredScroll = true;
      return;
    }

    final target = _lastScrollOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    ).toDouble();

    _scrollController.jumpTo(target);
    _hasRestoredScroll = true;
  }

  Future<void> _onMarkCompleted() async {
    setState(() => _isCompleting = true);

    try {
      _studyStopwatch.stop();

      if (_scrollController.hasClients) {
        _lastScrollOffset = _scrollController.offset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ).toDouble();
        _lastBlockIndex = _blocks.isEmpty ? 0 : _blocks.length - 1;
      }

      final elapsedSecs = _studyStopwatch.elapsed.inSeconds;

      // ✅ removed academicId
      final data = await StudentService.saveStudentLessonProgress(
        lessonId: widget.lessonId,
        timeSpentSeconds: elapsedSecs,
        status: 'completed',
        lastBlockIndex: _lastBlockIndex,
        lastScrollOffset: _lastScrollOffset,
      );

      _statusForStudent = _normalizeStatus(
        (data['status'] ?? 'completed').toString(),
      );
      _studyStopwatch.reset();

      if (!mounted) return;
      Navigator.of(context).pop('completed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      if (!_studyStopwatch.isRunning) {
        _studyStopwatch.start();
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _openExercisesScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentLessonExercisesScreen(
          lessonId: widget.lessonId,
          academicId: widget.academicId, // will be removed later
          lessonTitle: _title,
        ),
      ),
    );
  }

  Future<bool> _handleBackNavigation() async {
    _studyStopwatch.stop();
    await _saveProgressSilently(isCompleted: _statusForStudent == 'completed');

    if (!mounted) return false;

    if (_statusForStudent != 'completed') {
      Navigator.of(context).pop('draft');
      return false;
    }

    Navigator.of(context).pop('completed');
    return false;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onListenPressed() async {
    if (_blocks.isEmpty) {
      final l10n = AppLocalizations.of(context);
      _showSnack(l10n.studentLessonViewerNoAudioContent);
      return;
    }

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
      final l10n = AppLocalizations.of(context);
      _showSnack(l10n.studentLessonViewerNoAudioClip);
      return;
    }

    if (!_scrollController.hasClients) return;

    final targetOffset = (audioIndex * _estimatedBlockHeight).toDouble();
    await _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
    );

    _lastBlockIndex = audioIndex;
    _lastScrollOffset = _scrollController.offset;
    unawaited(_saveProgressSilently());

    final key = _audioKeysByIndex[audioIndex];
    if (key?.currentState != null) {
      await key!.currentState!.play();
    }
  }

  Widget _buildError() {
    return StudentLessonViewerErrorState(
      error: _error ?? '',
      onRetry: _loadLessonDetail,
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadLessonDetail,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 116),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentLessonViewerHeader(
              title: _title,
              durationLabel: _durationLabel,
              status: _statusForStudent,
              blocksCount: _blocks.length,
            ),
            const SizedBox(height: 16),
            StudentLessonContentCard(
              child: _blocks.isEmpty
                  ? const StudentLessonViewerEmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < _blocks.length; i++) ...[
                          _buildBlock(_blocks[i], index: i),
                          if (i != _blocks.length - 1)
                            StudentLessonSectionDivider(index: i + 1),
                        ],
                      ],
                    ),
            ),
          ],
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

    final isImage = type == 'image';
    final isFile = (type == 'file') || (type == 'pdf') || mime.contains('pdf');
    final isAudio = (type == 'audio') || _isAudioByMimeOrExt(url, mime);
    final isVideo = (type == 'video') || _isVideoByMimeOrExt(url, mime);

    if (isImage) {
      return StudentLessonInlineSection(
        child: _ImageBlock(url: url, caption: caption),
      );
    }

    if (isFile) {
      return StudentLessonInlineSection(
        child: _FileBlock(url: url, caption: caption),
      );
    }

    if (isAudio) {
      final key = GlobalKey<_LessonAudioPlayerState>();
      _audioKeysByIndex[index] = key;

      return StudentLessonInlineSection(
        child: LessonAudioPlayer(
          key: key,
          url: url,
          title: caption.isNotEmpty
              ? caption
              : AppLocalizations.of(context).studentLessonViewerAudio,
        ),
      );
    }

    if (isVideo) {
      return StudentLessonInlineSection(
        child: _VideoBlock(url: url, caption: caption),
      );
    }

    final body = (block['body'] ?? '').toString();
    final meta = (block['meta'] is Map)
        ? (block['meta'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final fontSize = (meta['font_size'] is num)
        ? (meta['font_size'] as num).toDouble()
        : 14.5;

    return _TextBlock(body: body, fontSize: fontSize);
  }

  Widget _buildBottomBar() {
    return StudentLessonViewerActionDock(
      isCompleted: _statusForStudent == 'completed',
      isLoading: _isCompleting,
      onListenTap: _onListenPressed,
      onExercisesTap: _openExercisesScreen,
      onCompleteTap: _onMarkCompleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
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
            onPressed: () async {
              await _handleBackNavigation();
            },
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
              tooltip: AppLocalizations.of(context).studentLessonViewerRefresh,
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
        body: Container(
          decoration: BoxDecoration(
            gradient: EduTheme.pageGradient(theme.brightness == Brightness.dark),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }
}