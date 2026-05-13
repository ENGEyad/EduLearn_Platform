import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/lesson_builder_l10n.dart';
import '../../../l10n/translations/teacher/lesson_builder_translations.dart';
import '../../../services/api_helpers.dart';
import '../../../services/lesson_service.dart';
import '../lesson_exercises/lesson_exercises_screen.dart';

part 'lesson_builder_models.dart';
part 'lesson_builder_widgets.dart';

class LessonBuilderScreen extends StatefulWidget {
  final String classKey;
  final String classTitle;
  final int studentsCount;

  final String teacherCode; // still passed but not used in services
  final int assignmentId;
  final int classSectionId;
  final int subjectId;

  final int? existingLessonId;

  final int moduleId;
  final String moduleTitle;

  const LessonBuilderScreen({
    super.key,
    required this.classKey,
    required this.classTitle,
    required this.studentsCount,
    required this.teacherCode,
    required this.assignmentId,
    required this.classSectionId,
    required this.subjectId,
    this.existingLessonId,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  State<LessonBuilderScreen> createState() => _LessonBuilderScreenState();
}

class _LessonBuilderScreenState extends State<LessonBuilderScreen> {
  final TextEditingController _titleController = TextEditingController();
  final List<_LessonBlock> _blocks = [];

  final AudioRecorder _recorder = AudioRecorder();
  late final _ElapsedTicker _ticker;

  bool _isInitializing = true;
  bool _isSaving = false;
  bool _isRecording = false;
  bool _hasUnsavedChanges = false;

  DateTime? _recordingStartedAt;
  Duration _recordingElapsed = Duration.zero;
  DateTime? _lastDraftSaveAt;

  int? _resolvedLessonId;
  String _lessonStateLabel = 'Draft';
  String? _activeTextBlockId;
  bool _isAiWorking = false;
  int? _activeAiSourceId;

  bool get _isEditingExisting => widget.existingLessonId != null;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Map<String, String> get _aiGenerateInstructions => {
        'structured_explanation': _l10n.lessonBuilderAiStructuredExplanation,
        'simplify_for_students': _l10n.lessonBuilderAiSimplifyForStudents,
        'short_explanation': _l10n.lessonBuilderAiShortExplanation,
        'clarify_and_organize': _l10n.lessonBuilderAiClarifyAndOrganize,
        'focus_key_points': _l10n.lessonBuilderAiFocusKeyPoints,
        'focus_definitions': _l10n.lessonBuilderAiFocusDefinitions,
        'focus_steps': _l10n.lessonBuilderAiFocusSteps,
        'add_examples': _l10n.lessonBuilderAiAddExamples,
      };

  Map<String, String> get _aiRewriteInstructions => {
        'rewrite': _l10n.lessonBuilderAiRewrite,
        'simplify': _l10n.lessonBuilderAiSimplify,
        'shorten': _l10n.lessonBuilderAiShorten,
        'expand': _l10n.lessonBuilderAiExpand,
        'clarify': _l10n.lessonBuilderAiClarify,
      };

  String _localizedStatusLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('published')) return _l10n.lessonBuilderStatusPublished;
    if (normalized.contains('saved')) return _l10n.lessonBuilderStatusSaved;
    if (normalized.contains('unsaved')) return _l10n.lessonBuilderStatusUnsaved;
    if (normalized.contains('draft')) return _l10n.lessonBuilderStatusDraft;
    return value;
  }

  String _stableKey() =>
      'blk_${DateTime.now().microsecondsSinceEpoch}_${(_blocks.length + 1)}';

  _LessonBlock _newManualTextBlock({String text = ''}) {
    return _LessonBlock.text(
      id: _id(),
      stableKey: _stableKey(),
      text: text,
      createdOrigin: 'manual',
      lastEditOrigin: 'manual',
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  Future<void> _openAiGeneratePanel() async {
    if (_resolvedLessonId == null) {
      _showSnack(_l10n.lessonBuilderSaveFirstBeforeAi);
      return;
    }

    final sourceStatus = await LessonService.getActiveLessonAiSource(
      lessonId: _resolvedLessonId!,
    ).catchError((_) => <String, dynamic>{'has_active_source': false});

    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) => _LessonAiGenerateSheet(
        hasActiveSource: sourceStatus['has_active_source'] == true,
        instructionItems: _aiGenerateInstructions,
      ),
    );

    if (result == null || result.isEmpty) return;

    final instructionKey = (result['instruction_key'] ?? '').toString().trim();
    if (instructionKey.isEmpty) return;

    try {
      setState(() => _isAiWorking = true);

      Map<String, dynamic> response;
      final mode = (result['mode'] ?? '').toString();

      if (mode == 'existing') {
        response = await LessonService.generateAiLessonBlocksFromExistingSource(
          lessonId: _resolvedLessonId!,
          instructionKey: instructionKey,
        );
      } else if (mode == 'text') {
        response = await LessonService.generateAiLessonBlocksFromText(
          lessonId: _resolvedLessonId!,
          instructionKey: instructionKey,
          sourceText: (result['source_text'] ?? '').toString(),
        );
      } else if (mode == 'pdf') {
        response = await LessonService.generateAiLessonBlocksFromPdf(
          lessonId: _resolvedLessonId!,
          instructionKey: instructionKey,
          filePath: (result['file_path'] ?? '').toString(),
        );
      } else {
        return;
      }

      _appendAiBlocksFromResponse(response);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _isAiWorking = false);
    }
  }

  void _appendAiBlocksFromResponse(Map<String, dynamic> response) {
    final rawBlocks = (response['blocks'] as List?) ?? const [];
    if (rawBlocks.isEmpty) {
      _showSnack(_l10n.lessonBuilderNoAiBlocksGenerated);
      return;
    }

    final aiSourceId = _asInt(response['ai_source_id']);
    final aiRunId = _asInt(response['ai_run_id']);

    final appended = <_LessonBlock>[];
    for (final raw in rawBlocks) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
      final body = (map['body'] ?? '').toString().trim();
      if (body.isEmpty) continue;

      final meta = map['meta'] is Map
          ? Map<String, dynamic>.from(map['meta'] as Map)
          : <String, dynamic>{};

      appended.add(
        _LessonBlock.text(
          id: _id(),
          stableKey: (map['stable_key'] ?? _stableKey()).toString(),
          text: body,
          style: _TextBlockStyle.fromJson(meta),
          createdOrigin: (map['created_origin'] ?? 'ai').toString(),
          lastEditOrigin: (map['last_edit_origin'] ?? 'ai').toString(),
          aiSourceId: _asInt(map['ai_source_id']) ?? aiSourceId,
          aiLastRunId: _asInt(map['ai_last_run_id']) ?? aiRunId,
        ),
      );
    }

    if (appended.isEmpty) {
      _showSnack(_l10n.lessonBuilderNoValidAiBlocksReturned);
      return;
    }

    setState(() {
      _activeAiSourceId = aiSourceId ?? _activeAiSourceId;
      if (_blocks.isNotEmpty &&
          _blocks.last.type == _LessonBlockType.text &&
          (_blocks.last.controller?.text.trim() ?? '').isEmpty) {
        _blocks.removeLast();
      }
      _blocks.addAll(appended);
      _ensureTrailingTextBlock();
      _activeTextBlockId = appended.last.id;
      _lessonStateLabel = 'Unsaved';
      _hasUnsavedChanges = true;
    });
    _onAnyFieldChanged();
    _showSnack(_l10n.lessonBuilderAiBlocksAdded);
  }

  Future<void> _rewriteBlockWithAi(
    _LessonBlock block,
    String instructionKey,
  ) async {
    if (_resolvedLessonId == null) {
      _showSnack(_l10n.lessonBuilderSaveFirstBeforeAi);
      return;
    }
    if (block.type != _LessonBlockType.text || block.controller == null) return;

    final currentBody = block.controller!.text.trim();
    if (currentBody.isEmpty) {
      _showSnack(_l10n.lessonBuilderBlockEmpty);
      return;
    }

    try {
      setState(() => _isAiWorking = true);
      final response = await LessonService.rewriteAiLessonBlock(
        lessonId: _resolvedLessonId!,
        stableKey: block.stableKey,
        currentBody: currentBody,
        instructionKey: instructionKey,
      );

      final newBody = (response['body'] ?? '').toString().trim();
      if (newBody.isEmpty) {
        _showSnack(_l10n.lessonBuilderAiReturnedEmpty);
        return;
      }

      final oldBody = block.controller!.text;
      setState(() {
        block.controller!.text = newBody;
        block.lastEditOrigin =
            (response['last_edit_origin'] ?? 'ai').toString();
        block.aiLastRunId = _asInt(response['ai_run_id']);
        if (_asInt(response['ai_source_id']) != null) {
          block.aiSourceId = _asInt(response['ai_source_id']);
          _activeAiSourceId = block.aiSourceId;
        }
        _lessonStateLabel = 'Unsaved';
        _hasUnsavedChanges = true;
      });
      _onAnyFieldChanged();
      _showSnack(
        _l10n.lessonBuilderBlockUpdatedWithAi,
        action: SnackBarAction(
          label: _l10n.lessonBuilderUndo,
          onPressed: () {
            setState(() {
              block.controller!.text = oldBody;
              _lessonStateLabel = 'Unsaved';
              _hasUnsavedChanges = true;
            });
            _onAnyFieldChanged();
          },
        ),
      );
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _isAiWorking = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _ticker = _ElapsedTicker(_handleRecordingTick);
    _titleController.addListener(_onAnyFieldChanged);
    _resolvedLessonId = widget.existingLessonId;

    if (_isEditingExisting) {
      _loadExistingLesson();
    } else {
      _titleController.text = '';
      _blocks.add(_newManualTextBlock());
      _activeTextBlockId = _blocks.first.id;
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (_isRecording) {
      _recorder.stop();
    }
    _recorder.dispose();
    _titleController.dispose();
    for (final block in _blocks) {
      block.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingLesson() async {
    try {
      final draft = await _loadLocalDraft();
      if (draft != null) {
        _restoreFromDraft(draft);
        return;
      }

      final lesson = await LessonService.fetchLessonDetail(
        teacherCode: widget.teacherCode,
        lessonId: widget.existingLessonId!,
      );
      _restoreFromLessonDetail(lesson);
    } catch (e) {
      _showSnack(
        _l10n.lessonBuilderFailedToLoadLesson(e.toString().replaceFirst('Exception: ', '')),
      );
      if (_blocks.isEmpty) {
        _blocks.add(_newManualTextBlock());
      }
      _activeTextBlockId = _firstTextBlockId();
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasUnsavedChanges = false;
      });
    }
  }

  void _restoreFromDraft(Map<String, dynamic> draft) {
    _titleController.text = (draft['title'] ?? '').toString();
    _lessonStateLabel = (draft['lesson_state'] ?? 'Draft').toString();
    _resolvedLessonId = draft['lesson_id'] is int
        ? draft['lesson_id'] as int
        : (draft['lesson_id'] is num)
            ? (draft['lesson_id'] as num).toInt()
            : widget.existingLessonId;

    _blocks.clear();
    final rawBlocks = (draft['blocks'] as List?) ?? [];
    for (final raw in rawBlocks) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
      final type = (map['type'] ?? '').toString();
      if (type == 'text') {
        _blocks.add(
          _LessonBlock.text(
            id: (map['id'] ?? _id()).toString(),
            stableKey: (map['stable_key'] ?? _stableKey()).toString(),
            text: (map['body'] ?? '').toString(),
            style: _TextBlockStyle.fromJson(
              map['style'] is Map
                  ? Map<String, dynamic>.from(map['style'])
                  : {},
            ),
            createdOrigin: (map['created_origin'] ?? 'manual').toString(),
            lastEditOrigin:
                (map['last_edit_origin'] ??
                        map['created_origin'] ??
                        'manual')
                    .toString(),
            aiSourceId: _asInt(map['ai_source_id']),
            aiLastRunId: _asInt(map['ai_last_run_id']),
          ),
        );
      } else {
        final blockId = (map['id'] ?? _id()).toString();
        final kind = _mediaKindFromSavedValue(
          map['kind']?.toString(),
          blockType: type,
          mime: map['media_mime']?.toString(),
        );
        _blocks.add(
          _LessonBlock.media(
            id: blockId,
            stableKey: (map['stable_key'] ?? _stableKey()).toString(),
            createdOrigin: (map['created_origin'] ?? 'manual').toString(),
            lastEditOrigin:
                (map['last_edit_origin'] ??
                        map['created_origin'] ??
                        'manual')
                    .toString(),
            aiSourceId: _asInt(map['ai_source_id']),
            aiLastRunId: _asInt(map['ai_last_run_id']),
            media: _MediaBlockData(
              id: blockId,
              kind: kind,
              localPath: map['local_path']?.toString(),
              mediaPath: (map['media_path'] ?? '').toString(),
              remoteUrl: (map['remote_url'] ?? '').toString(),
              mime: map['media_mime']?.toString(),
              size: map['media_size'] is num
                  ? (map['media_size'] as num).toInt()
                  : null,
              captionController: TextEditingController(
                text: (map['caption'] ?? '').toString(),
              ),
              status: _mediaStatusFromValue(map['status']?.toString()),
            ),
          ),
        );
      }
    }

    if (_blocks.isEmpty) {
      _blocks.add(_newManualTextBlock());
    }
    _ensureTrailingTextBlock();
    _activeTextBlockId = _firstTextBlockId();
  }

  void _restoreFromLessonDetail(Map<String, dynamic> lesson) {
    _titleController.text = (lesson['title'] ?? '').toString();
    _resolvedLessonId = lesson['id'] is int
        ? lesson['id'] as int
        : (lesson['id'] is num)
            ? (lesson['id'] as num).toInt()
            : widget.existingLessonId;
    _lessonStateLabel = (lesson['status'] ?? '').toString().trim().isNotEmpty
        ? (lesson['status'] ?? '').toString()
        : ((lesson['published_at'] != null) ? 'Published' : 'Draft');

    _blocks.clear();
    final blocks = (lesson['blocks'] as List?) ?? [];
    for (final raw in blocks) {
      if (raw is! Map) continue;
      final block = Map<String, dynamic>.from(raw.cast<String, dynamic>());
      final type = (block['type'] ?? '').toString();
      final meta = block['meta'] is Map
          ? Map<String, dynamic>.from(block['meta'] as Map)
          : <String, dynamic>{};

      if (type == 'text') {
        _blocks.add(
          _LessonBlock.text(
            id: _id(),
            stableKey: (block['stable_key'] ?? _stableKey()).toString(),
            text: (block['body'] ?? '').toString(),
            style: _TextBlockStyle(
              fontSize: (meta['font_size'] is num)
                  ? (meta['font_size'] as num).toDouble()
                  : 18,
              isBold: meta['is_bold'] == true,
              isItalic: meta['is_italic'] == true,
            ),
            createdOrigin: (block['created_origin'] ?? 'manual').toString(),
            lastEditOrigin:
                (block['last_edit_origin'] ??
                        block['created_origin'] ??
                        'manual')
                    .toString(),
            aiSourceId: _asInt(block['ai_source_id']),
            aiLastRunId: _asInt(block['ai_last_run_id']),
          ),
        );
        continue;
      }

      final mediaValue = ApiHelpers.pickMediaValueFromBlock(block);
      final mediaPath = ApiHelpers.extractMediaPath(mediaValue);
      final mime = block['media_mime']?.toString();
      final savedKind = meta['input_kind']?.toString();
      final mediaId = _id();

      _blocks.add(
        _LessonBlock.media(
          id: mediaId,
          stableKey: (block['stable_key'] ?? _stableKey()).toString(),
          createdOrigin: (block['created_origin'] ?? 'manual').toString(),
          lastEditOrigin:
              (block['last_edit_origin'] ??
                      block['created_origin'] ??
                      'manual')
                  .toString(),
          aiSourceId: _asInt(block['ai_source_id']),
          aiLastRunId: _asInt(block['ai_last_run_id']),
          media: _MediaBlockData(
            id: mediaId,
            kind: _mediaKindFromSavedValue(
              savedKind,
              blockType: type,
              mime: mime,
            ),
            localPath: null,
            mediaPath: mediaPath,
            remoteUrl: mediaValue.startsWith('http')
                ? mediaValue
                : (mediaPath.isNotEmpty
                    ? ApiHelpers.buildMediaUrl(mediaPath)
                    : ''),
            mime: mime,
            size: block['media_size'] is num
                ? (block['media_size'] as num).toInt()
                : null,
            captionController: TextEditingController(
              text: (block['caption'] ?? '').toString(),
            ),
            status: _MediaStatus.ready,
          ),
        ),
      );
    }

    if (_blocks.isEmpty) {
      _blocks.add(_newManualTextBlock());
    }
    _ensureTrailingTextBlock();
    _activeTextBlockId = _firstTextBlockId();
  }

  void _handleRecordingTick(Duration elapsed) {
    if (!mounted || !_isRecording) return;
    setState(() {
      _recordingElapsed = elapsed;
    });
  }

  void _onAnyFieldChanged() {
    if (_isInitializing) return;
    _lessonStateLabel = 'Unsaved';
    if (mounted) {
      setState(() => _hasUnsavedChanges = true);
    }
    final now = DateTime.now();
    if (_lastDraftSaveAt == null ||
        now.difference(_lastDraftSaveAt!).inSeconds >= 5) {
      _lastDraftSaveAt = now;
      _saveLocalDraft();
    }
  }

  Future<void> _saveLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _draftKey,
        jsonEncode({
          'title': _titleController.text,
          'lesson_state': _lessonStateLabel,
          'lesson_id': _resolvedLessonId,
          'blocks': _blocks.map((e) => e.toDraftJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  String get _draftKey {
    if (widget.existingLessonId != null) {
      return 'lesson_draft_${widget.existingLessonId}';
    }
    return 'lesson_draft_new_${widget.classSectionId}_${widget.subjectId}_${widget.moduleId}';
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  void _showSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  int _insertIndexForNewBlock() {
    if (_activeTextBlockId == null) return _blocks.length;
    final currentIndex = _blocks.indexWhere((b) => b.id == _activeTextBlockId);
    if (currentIndex == -1) return _blocks.length;
    return currentIndex + 1;
  }

  String? _firstTextBlockId() {
    for (final block in _blocks) {
      if (block.type == _LessonBlockType.text) return block.id;
    }
    return null;
  }

  void _ensureTrailingTextBlock() {
    if (_blocks.isEmpty) {
      _blocks.add(_newManualTextBlock());
      return;
    }
    if (_blocks.last.type != _LessonBlockType.text) {
      _blocks.add(_newManualTextBlock());
    }
  }

  void _focusTextBlock(String blockId, {bool requestKeyboard = false}) {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;
    final block = _blocks[index];
    if (block.type != _LessonBlockType.text || block.focusNode == null) return;
    setState(() {
      _activeTextBlockId = blockId;
    });
    if (requestKeyboard) {
      Future.microtask(() {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(block.focusNode);
      });
    }
  }

  void _insertTextBlock() {
    FocusScope.of(context).unfocus();
    final block = _newManualTextBlock();
    final insertAt = _insertIndexForNewBlock();
    setState(() {
      _blocks.insert(insertAt, block);
      _activeTextBlockId = block.id;
      _hasUnsavedChanges = true;
      _lessonStateLabel = 'Unsaved';
    });
    _onAnyFieldChanged();
    _focusTextBlock(block.id, requestKeyboard: true);
  }

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return;
    await _addMediaBlock(kind: _MediaKind.image, localPath: picked.path);
  }

  Future<void> _pickVideo() async {
    FocusScope.of(context).unfocus();
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (picked == null) return;
    await _addMediaBlock(kind: _MediaKind.video, localPath: picked.path);
  }

  Future<void> _pickAudioFile() async {
    FocusScope.of(context).unfocus();
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.trim().isEmpty) return;
    await _addMediaBlock(kind: _MediaKind.audio, localPath: path);
  }

  Future<void> _pickPdf() async {
    FocusScope.of(context).unfocus();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.trim().isEmpty) return;
    await _addMediaBlock(kind: _MediaKind.pdf, localPath: path);
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      await _stopRecordingAndAdd();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final allowed = await _recorder.hasPermission();
      if (!allowed) {
        _showSnack(_l10n.lessonBuilderMicPermissionRequired);
        return;
      }
      final tempDir = Directory.systemTemp;
      final path =
          '${tempDir.path}/lesson_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      _recordingStartedAt = DateTime.now();
      _recordingElapsed = Duration.zero;
      _ticker.start();
      if (!mounted) return;
      setState(() => _isRecording = true);
    } catch (e) {
      _showSnack(
        _l10n.lessonBuilderFailedToStartRecording(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  Future<void> _stopRecordingAndAdd() async {
    try {
      final path = await _recorder.stop();
      _ticker.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      _recordingStartedAt = null;
      _recordingElapsed = Duration.zero;
      if (path == null || path.trim().isEmpty) return;
      await _addMediaBlock(kind: _MediaKind.voice, localPath: path);
    } catch (e) {
      _ticker.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);
      _recordingStartedAt = null;
      _recordingElapsed = Duration.zero;
      _showSnack(
        _l10n.lessonBuilderFailedToStopRecording(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    _ticker.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _recordingElapsed = Duration.zero;
    });
  }

  Future<void> _addMediaBlock({
    required _MediaKind kind,
    required String localPath,
  }) async {
    final insertAt = _insertIndexForNewBlock();
    final blockId = _id();
    final block = _LessonBlock.media(
      id: blockId,
      stableKey: _stableKey(),
      createdOrigin: 'manual',
      lastEditOrigin: 'manual',
      media: _MediaBlockData(
        id: blockId,
        kind: kind,
        localPath: localPath,
        mediaPath: '',
        remoteUrl: '',
        mime: null,
        size: null,
        captionController: TextEditingController(),
        status: _MediaStatus.uploading,
      ),
    );

    setState(() {
      _blocks.insert(insertAt, block);
      if (insertAt == _blocks.length - 1 || _blocks.last.id == blockId) {
        _blocks.add(_newManualTextBlock());
      } else {
        final nextIndex = insertAt + 1;
        if (_blocks[nextIndex].type != _LessonBlockType.text) {
          _blocks.insert(nextIndex, _newManualTextBlock());
        }
      }
      _activeTextBlockId = null;
      _hasUnsavedChanges = true;
      _lessonStateLabel = 'Unsaved';
    });

    _onAnyFieldChanged();
    await _uploadMedia(block.id, localPath: localPath);
  }

  Future<void> _uploadMedia(String blockId, {required String localPath}) async {
    try {
      final response = await LessonService.uploadLessonMedia(filePath: localPath);
      if (!mounted) return;
      setState(() {
        final index = _blocks.indexWhere((b) => b.id == blockId);
        if (index == -1) return;
        final media = _blocks[index].media;
        if (media == null) return;
        _blocks[index] = _blocks[index].copyWithMedia(
          media.copyWith(
            mediaPath: (response['media_path'] ?? '').toString(),
            remoteUrl: (response['media_url'] ?? '').toString(),
            mime: response['media_mime']?.toString(),
            size: response['media_size'] is num
                ? (response['media_size'] as num).toInt()
                : null,
            status: _MediaStatus.ready,
          ),
        );
      });
      _onAnyFieldChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final index = _blocks.indexWhere((b) => b.id == blockId);
        if (index == -1) return;
        final media = _blocks[index].media;
        if (media == null) return;
        _blocks[index] = _blocks[index].copyWithMedia(
          media.copyWith(status: _MediaStatus.failed),
        );
      });
      _showSnack(
        _l10n.lessonBuilderFailedToUploadMedia(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  bool _hasAnyMeaningfulContent() {
    for (final block in _blocks) {
      if (block.type == _LessonBlockType.text) {
        if ((block.controller?.text.trim() ?? '').isNotEmpty) return true;
      } else {
        final media = block.media;
        if (media != null) return true;
      }
    }
    return false;
  }

  bool _hasUploadingMedia() => _blocks.any(
        (b) =>
            b.type == _LessonBlockType.media &&
            b.media?.status == _MediaStatus.uploading,
      );

  bool _hasFailedMedia() => _blocks.any(
        (b) =>
            b.type == _LessonBlockType.media &&
            b.media?.status == _MediaStatus.failed,
      );

  Future<void> _saveLesson({required bool publish}) async {
    try {
      FocusScope.of(context).unfocus();
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        _showSnack(_l10n.lessonBuilderPleaseEnterTitle);
        return;
      }
      if (_hasUploadingMedia()) {
        _showSnack(_l10n.lessonBuilderWaitMediaUpload);
        return;
      }
      if (_hasFailedMedia()) {
        _showSnack(_l10n.lessonBuilderSomeMediaFailed);
        return;
      }
      if (!_hasAnyMeaningfulContent()) {
        _showSnack(_l10n.lessonBuilderAddContentOrMedia);
        return;
      }

      setState(() => _isSaving = true);
      final response = await LessonService.saveLesson(
        teacherCode: widget.teacherCode,
        assignmentId: widget.assignmentId,
        classModuleId: widget.moduleId,
        classSectionId: widget.classSectionId,
        subjectId: widget.subjectId,
        lessonId: _resolvedLessonId,
        title: title,
        publish: publish,
        blocks: _buildBlocksPayload(),
      );

      final lessonMap = response['lesson'] is Map
          ? Map<String, dynamic>.from(response['lesson'] as Map)
          : <String, dynamic>{};
      final lessonId = lessonMap['id'] ?? response['lesson_id'];
      if (lessonId is num) {
        _resolvedLessonId = lessonId.toInt();
      }
      _lessonStateLabel = publish ? 'Published' : 'Saved';
      _hasUnsavedChanges = false;
      await _clearLocalDraft();
      if (!mounted) return;
      setState(() {});
      _showSnack(publish ? _l10n.lessonBuilderLessonPublished : _l10n.lessonBuilderLessonSavedDraft);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  List<Map<String, dynamic>> _buildBlocksPayload() {
    final payload = <Map<String, dynamic>>[];
    int position = 1;
    for (final block in _blocks) {
      if (block.type == _LessonBlockType.text) {
        final body = (block.controller?.text ?? '').trim();
        if (body.isEmpty) continue;
        payload.add({
          'id': null,
          'stable_key': block.stableKey,
          'created_origin': block.createdOrigin,
          'last_edit_origin': block.lastEditOrigin,
          'ai_source_id': block.aiSourceId,
          'ai_last_run_id': block.aiLastRunId,
          'type': 'text',
          'body': body,
          'caption': null,
          'media_url': null,
          'media_path': null,
          'media_mime': null,
          'media_size': null,
          'media_duration': null,
          'module_id': null,
          'topic_id': null,
          'position': position++,
          'meta': block.textStyle?.toMetaJson(),
        });
      } else {
        final media = block.media;
        if (media == null) continue;
        payload.add({
          'id': null,
          'stable_key': block.stableKey,
          'created_origin': block.createdOrigin,
          'last_edit_origin': block.lastEditOrigin,
          'ai_source_id': block.aiSourceId,
          'ai_last_run_id': block.aiLastRunId,
          'type': media.apiType,
          'body': null,
          'caption': media.captionController.text.trim().isEmpty
              ? null
              : media.captionController.text.trim(),
          'media_url': media.remoteUrl.isNotEmpty ? media.remoteUrl : null,
          'media_path': media.mediaPath.isNotEmpty ? media.mediaPath : null,
          'media_mime': media.mime,
          'media_size': media.size,
          'media_duration': null,
          'module_id': null,
          'topic_id': null,
          'position': position++,
          'meta': {
            'input_kind': media.kind.name,
          },
        });
      }
    }
    return payload;
  }

  Future<void> _openLessonExercises() async {
    if (_resolvedLessonId == null) {
      _showSnack(_l10n.lessonBuilderSaveFirstForExercises);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonExercisesScreen(
          lessonId: _resolvedLessonId!,
          teacherCode: widget.teacherCode, // still passed, but service will be updated later
          lessonTitle: _titleController.text.trim().isEmpty
              ? widget.moduleTitle
              : _titleController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _handleBack() async {
    if (_isRecording) {
      _showSnack(_l10n.lessonBuilderStopRecordingBeforeLeaving);
      return;
    }
    if (_hasUnsavedChanges) {
      await _saveLocalDraft();
      _showSnack(_l10n.lessonBuilderChangesSavedLocally);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _deleteBlock(String blockId) {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;
    final removed = _blocks[index];
    setState(() {
      _blocks.removeAt(index);
      if (_blocks.isEmpty) {
        final newBlock = _newManualTextBlock();
        _blocks.add(newBlock);
        _activeTextBlockId = newBlock.id;
      } else {
        _ensureTrailingTextBlock();
        if (_activeTextBlockId == blockId) {
          _activeTextBlockId = _firstTextBlockId();
        }
      }
      _hasUnsavedChanges = true;
      _lessonStateLabel = 'Unsaved';
    });
    _onAnyFieldChanged();
    _showSnack(
      _l10n.lessonBuilderBlockDeleted,
      action: SnackBarAction(
        label: _l10n.lessonBuilderUndo,
        onPressed: () {
          setState(() {
            final restoreAt = index.clamp(0, _blocks.length);
            _blocks.insert(restoreAt, removed);
            _ensureTrailingTextBlock();
            _hasUnsavedChanges = true;
            _lessonStateLabel = 'Unsaved';
          });
          _onAnyFieldChanged();
        },
      ),
    );
  }

  void _retryUpload(_LessonBlock block) {
    final media = block.media;
    if (media == null || media.localPath == null || media.localPath!.isEmpty) {
      return;
    }
    setState(() {
      final index = _blocks.indexWhere((b) => b.id == block.id);
      if (index == -1) return;
      _blocks[index] = _blocks[index].copyWithMedia(
        media.copyWith(status: _MediaStatus.uploading),
      );
    });
    _uploadMedia(block.id, localPath: media.localPath!);
  }

  Future<void> _openPdf(_MediaBlockData media) async {
    try {
      if (media.localPath != null && File(media.localPath!).existsSync()) {
        final result = await OpenFile.open(media.localPath!);
        if (result.type != ResultType.done) {
          _showSnack(
            result.message.isNotEmpty ? result.message : _l10n.lessonBuilderCouldNotOpenFile,
          );
        }
        return;
      }
      final url = media.remoteUrl.isNotEmpty
          ? media.remoteUrl
          : (media.mediaPath.isNotEmpty
              ? ApiHelpers.buildMediaUrl(media.mediaPath)
              : '');
      if (url.isEmpty) {
        _showSnack(_l10n.lessonBuilderFileNotReady);
        return;
      }
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showSnack(_l10n.lessonBuilderCouldNotOpenFile);
      }
    } catch (_) {
      _showSnack(_l10n.lessonBuilderFailedToOpenFile);
    }
  }

  Color _statusColor(BuildContext context, String value) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = value.toLowerCase();
    if (normalized.contains('published')) return Colors.green;
    if (normalized.contains('saving')) return scheme.primary;
    if (normalized.contains('saved')) return Colors.teal;
    if (normalized.contains('unsaved')) return Colors.orange;
    return scheme.primary;
  }

  _MediaKind _mediaKindFromSavedValue(
    String? rawKind, {
    required String blockType,
    String? mime,
  }) {
    switch ((rawKind ?? '').toLowerCase()) {
      case 'voice':
        return _MediaKind.voice;
      case 'audio':
        return _MediaKind.audio;
      case 'video':
        return _MediaKind.video;
      case 'image':
        return _MediaKind.image;
      case 'pdf':
      case 'file':
        return _MediaKind.pdf;
    }
    switch (blockType) {
      case 'image':
        return _MediaKind.image;
      case 'video':
        return _MediaKind.video;
      case 'audio':
        return _MediaKind.audio;
      case 'file':
      case 'pdf':
        return _MediaKind.pdf;
    }
    final normalizedMime = (mime ?? '').toLowerCase();
    if (normalizedMime.contains('pdf')) return _MediaKind.pdf;
    if (normalizedMime.startsWith('image/')) return _MediaKind.image;
    if (normalizedMime.startsWith('video/')) return _MediaKind.video;
    return _MediaKind.audio;
  }

  _MediaStatus _mediaStatusFromValue(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'uploading':
        return _MediaStatus.uploading;
      case 'failed':
        return _MediaStatus.failed;
      default:
        return _MediaStatus.ready;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final statusColor = _statusColor(context, _lessonStateLabel);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _LessonBuilderTopBar(
              statusLabel: _localizedStatusLabel(_lessonStateLabel),
              isSaving: _isSaving,
              isAiWorking: _isAiWorking,
              statusColor: statusColor,
              onBack: _handleBack,
              onOpenAi: (_isSaving || _isAiWorking)
                  ? null
                  : _openAiGeneratePanel,
              onSaveDraft: (_isSaving || _isAiWorking)
                  ? null
                  : () => _saveLesson(publish: false),
              onPublish: (_isSaving || _isAiWorking)
                  ? null
                  : () => _saveLesson(publish: true),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 194),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LessonBuilderTitleSection(
                          controller: _titleController,
                        ),
                        const SizedBox(height: 18),
                        _LessonBuilderBlocksList(
                          blocks: _blocks,
                          activeTextBlockId: _activeTextBlockId,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = _blocks.removeAt(oldIndex);
                              _blocks.insert(newIndex, item);
                              _hasUnsavedChanges = true;
                              _lessonStateLabel = 'Unsaved';
                            });
                            _onAnyFieldChanged();
                          },
                          onDeleteBlock: _deleteBlock,
                          onFocusTextBlock: (blockId) => _focusTextBlock(blockId),
                          onTextChanged: (_) => _onAnyFieldChanged(),
                          onToggleBold: (block) {
                            final style = block.textStyle ?? const _TextBlockStyle();
                            setState(() {
                              block.textStyle = style.copyWith(
                                isBold: !style.isBold,
                              );
                              _lessonStateLabel = 'Unsaved';
                              _hasUnsavedChanges = true;
                            });
                            _onAnyFieldChanged();
                          },
                          onToggleItalic: (block) {
                            final style = block.textStyle ?? const _TextBlockStyle();
                            setState(() {
                              block.textStyle = style.copyWith(
                                isItalic: !style.isItalic,
                              );
                              _lessonStateLabel = 'Unsaved';
                              _hasUnsavedChanges = true;
                            });
                            _onAnyFieldChanged();
                          },
                          onFontSizeChanged: (block, value) {
                            final style = block.textStyle ?? const _TextBlockStyle();
                            setState(() {
                              block.textStyle = style.copyWith(fontSize: value);
                              _lessonStateLabel = 'Unsaved';
                              _hasUnsavedChanges = true;
                            });
                          },
                          onFontSizeChangeEnd: (_) => _onAnyFieldChanged(),
                          onRetryUpload: _retryUpload,
                          onOpenPdf: _openPdf,
                          onAiAction: (block, actionKey) =>
                              _rewriteBlockWithAi(block, actionKey),
                        ),
                        const SizedBox(height: 18),
                        _LessonBuilderExercisesFooter(
                          hasLessonId: _resolvedLessonId != null,
                          onOpenExercises: _openLessonExercises,
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.only(bottom: keyboardInset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRecording)
                            _LessonBuilderRecordingBar(
                              elapsed: _recordingElapsed,
                              onCancel: _cancelRecording,
                              onStop: _toggleVoiceRecording,
                            ),
                          _LessonBuilderBottomComposer(
                            isRecording: _isRecording,
                            onInsertText: _insertTextBlock,
                            onPickImage: _pickImage,
                            onPickVideo: _pickVideo,
                            onPickAudio: _pickAudioFile,
                            onToggleRecording: _toggleVoiceRecording,
                            onPickPdf: _pickPdf,
                          ),
                        ],
                      ),
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