import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../theme.dart';
<<<<<<< HEAD
import '../../services/api_service.dart';
=======

// ✅ بدل api_service.dart
import '../../services/lesson_service.dart';
import '../../services/api_helpers.dart';
import '../../services/auth_service.dart';
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

class LessonBuilderScreen extends StatefulWidget {
  final String classKey;
  final String classTitle;
  final int studentsCount;

  // 🔹 Data needed to bind the lesson to the real assignment
  final String teacherCode;
  final int assignmentId;
  final int classSectionId;
  final int subjectId;

  // If editing an existing lesson
  final int? existingLessonId;

  // 🔹 Link the lesson to the outer module (ClassModule) it came from
  final int moduleId; // this is class_module_id
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
<<<<<<< HEAD
  final TextEditingController _contentController = TextEditingController();
=======

  // ✅ Block editor (بدل content + tokens + preview + pendingMedia)
  final List<_LessonBlock> _blocks = [];
  int? _activeTextBlockIndex;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

  // 🔹 داخلياً: نحتفظ بموديول واحد فقط (للتوافق مع شاشتك الحالية)
  final List<_ModuleData> _modules = [];
  _ModuleData? _selectedModule;

  bool _isSaving = false;

  // 🔹 Font size
  double _fontSize = 16;

  // 🔹 Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordingStartedAt;
  Duration _recordingElapsed = Duration.zero;
  late final Ticker _ticker;

<<<<<<< HEAD
  // 🔹 Uploaded media objects (معاينة حقيقية)
  final List<_PendingMedia> _pendingMedia = [];

  // ✅ معاينة محتوى الطالب (blocks)
  List<Map<String, dynamic>> _previewBlocks = [];

=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  // 🔹 Editing state
  bool get _isEditingExisting => widget.existingLessonId != null;
  bool _hasUnsavedChanges = false;
  bool _initializing = true;

  // ========= Draft autosave debounce =========
  DateTime? _lastDraftSaveAt;

  @override
  void initState() {
    super.initState();

    _ticker = Ticker(_onTick);

    _titleController.addListener(_onAnyFieldChanged);
<<<<<<< HEAD
    _contentController.addListener(_onAnyFieldChanged);
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

    if (_isEditingExisting) {
      _loadExistingLesson();
    } else {
      _addInitialStructure();
<<<<<<< HEAD
      _initializing = false;
      _previewBlocks = _buildBlocksFromContent(_contentController.text);
=======
      _ensureAtLeastOneTextBlock();
      _initializing = false;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopRecordingIfNeededOnDispose();
<<<<<<< HEAD
    _titleController.dispose();
    _contentController.dispose();
=======

    for (final b in _blocks) {
      b.dispose();
    }

    _titleController.dispose();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    _recorder.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (!_isRecording || _recordingStartedAt == null) return;
    final elapsed = DateTime.now().difference(_recordingStartedAt!);
    if (!mounted) return;
    setState(() => _recordingElapsed = elapsed);
  }

  void _onAnyFieldChanged() {
    if (_initializing) return;

<<<<<<< HEAD
    setState(() {
      _hasUnsavedChanges = true;
      _previewBlocks = _buildBlocksFromContent(_contentController.text);
    });

    // autosave draft كل ~5 ثواني (بسيط وعملي)
    final now = DateTime.now();
    if (_lastDraftSaveAt == null || now.difference(_lastDraftSaveAt!).inSeconds >= 5) {
=======
    setState(() => _hasUnsavedChanges = true);

    final now = DateTime.now();
    if (_lastDraftSaveAt == null ||
        now.difference(_lastDraftSaveAt!).inSeconds >= 5) {
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      _lastDraftSaveAt = now;
      _saveLocalDraft(); // لا ننتظر
    }
  }

<<<<<<< HEAD
=======
  void _markDirtyAndMaybeAutosave() {
    if (_initializing) return;

    setState(() => _hasUnsavedChanges = true);

    final now = DateTime.now();
    if (_lastDraftSaveAt == null ||
        now.difference(_lastDraftSaveAt!).inSeconds >= 5) {
      _lastDraftSaveAt = now;
      _saveLocalDraft();
    }
  }

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  // ======== Load existing lesson from local draft or API ========

  Future<void> _loadExistingLesson() async {
    try {
      // 1) Try local draft
      final draft = await _loadLocalDraft();
      if (draft != null) {
        _titleController.text = (draft['title'] ?? '').toString();
<<<<<<< HEAD
        _contentController.text = (draft['content'] ?? '').toString();
        final fs = draft['font_size'];
        if (fs is num) _fontSize = fs.toDouble();
        _addInitialStructure();

        // draft لا يشمل ميديا (حسب تصميمك) — نعيد المعاينة
        _pendingMedia.clear();
=======

        final fs = draft['font_size'];
        if (fs is num) _fontSize = fs.toDouble();

        _addInitialStructure();

        _blocks.clear();
        final rawBlocks = (draft['blocks'] as List?) ?? [];
        for (final raw in rawBlocks) {
          if (raw is! Map) continue;
          final m = raw.cast<String, dynamic>();
          final type = (m['type'] ?? '').toString();
          if (type == 'text') {
            _blocks.add(_LessonBlock.text(
              id: (m['id'] ?? _id()).toString(),
              controller: TextEditingController(text: (m['body'] ?? '').toString()),
            )..attachChangeListener(_onAnyFieldChanged));
          } else {
            final kind = _inferKindFromBlockType(type);
            _blocks.add(_LessonBlock.media(
              id: (m['id'] ?? _id()).toString(),
              media: _PendingMedia(
                id: (m['id'] ?? _id()).toString(),
                kind: kind,
                localPath: null,
                mediaPath: (m['media_path'] ?? '').toString(),
                remoteUrl: '',
                mime: m['media_mime']?.toString(),
                size: m['media_size'] is int
                    ? m['media_size'] as int
                    : (m['media_size'] is num ? (m['media_size'] as num).toInt() : null),
                status: _MediaStatus.ready,
              ),
            ));
          }
        }

        _ensureAtLeastOneTextBlock();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        return;
      }

      // 2) Load from API
<<<<<<< HEAD
      final lesson = await ApiService.fetchLessonDetail(
=======
      final lesson = await LessonService.fetchLessonDetail(
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        lessonId: widget.existingLessonId!,
        teacherCode: widget.teacherCode,
      );

      _titleController.text = (lesson['title'] ?? '').toString();

      _modules.clear();
      _modules.add(
        _ModuleData(
          tempId: 'm1',
          title: widget.moduleTitle,
          position: 1,
        ),
      );
      _selectedModule = _modules.first;

<<<<<<< HEAD
      _pendingMedia.clear();

      final blocks = (lesson['blocks'] as List?) ?? [];
      final buffer = StringBuffer();
      final restoredMedia = <_PendingMedia>[];

      for (final raw in blocks) {
        final block = (raw as Map).cast<String, dynamic>();
        final type = (block['type'] ?? '').toString();
        final body = (block['body'] ?? '').toString();

        if (type == 'text') {
          if (body.trim().isNotEmpty) {
            buffer.writeln(body.trim());
            buffer.writeln();
          }
          continue;
        }

        final mediaValue = ApiService.pickMediaValueFromBlock(block);
        if (mediaValue.isEmpty) continue;

        final mediaPath = ApiService.extractMediaPath(mediaValue);
        final mediaUrl = ApiService.buildMediaUrl(mediaPath.isNotEmpty ? mediaPath : mediaValue);

=======
      _blocks.clear();

      final blocks = (lesson['blocks'] as List?) ?? [];
      for (final raw in blocks) {
        if (raw is! Map) continue;
        final block = raw.cast<String, dynamic>();
        final type = (block['type'] ?? '').toString();

        if (type == 'text') {
          final body = (block['body'] ?? '').toString();
          _blocks.add(
            _LessonBlock.text(
              id: _id(),
              controller: TextEditingController(text: body),
            )..attachChangeListener(_onAnyFieldChanged),
          );
          continue;
        }

        final mediaValue = ApiHelpers.pickMediaValueFromBlock(block);
        final mediaPath = ApiHelpers.extractMediaPath(mediaValue);
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        final mime = block['media_mime']?.toString();
        final size = block['media_size'] is int
            ? block['media_size'] as int
            : (block['media_size'] is num ? (block['media_size'] as num).toInt() : null);

<<<<<<< HEAD
        // ✅ نعيد إدراجها داخل النص كـ token ثابت
        final id = _id();
        buffer.writeln(_MediaToken.encode(id));
        buffer.writeln();

        restoredMedia.add(
          _PendingMedia(
            id: id,
            kind: _inferKindFromBlockType(type),
            localPath: null,
            mediaPath: mediaPath,
            remoteUrl: mediaUrl,
            mime: mime,
            size: size,
            status: _MediaStatus.ready,
=======
        final id = _id();
        _blocks.add(
          _LessonBlock.media(
            id: id,
            media: _PendingMedia(
              id: id,
              kind: _inferKindFromBlockType(type),
              localPath: null,
              mediaPath: mediaPath,
              remoteUrl: '', // نبني URL وقت العرض
              mime: mime,
              size: size,
              status: _MediaStatus.ready,
            ),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
          ),
        );
      }

<<<<<<< HEAD
      _contentController.text = buffer.toString().trim();
      _pendingMedia.addAll(restoredMedia);

      // Restore font size from first block meta if exists
      if (blocks.isNotEmpty) {
        final firstBlock = (blocks.first as Map).cast<String, dynamic>();
        final meta = firstBlock['meta'] is Map ? (firstBlock['meta'] as Map).cast<String, dynamic>() : null;
        if (meta != null && meta['font_size'] is num) {
          _fontSize = (meta['font_size'] as num).toDouble();
=======
      // font size from first block meta (مثل كودك السابق)
      if (blocks.isNotEmpty) {
        final first = blocks.first;
        if (first is Map) {
          final firstBlock = first.cast<String, dynamic>();
          final meta = firstBlock['meta'] is Map
              ? (firstBlock['meta'] as Map).cast<String, dynamic>()
              : null;
          if (meta != null && meta['font_size'] is num) {
            _fontSize = (meta['font_size'] as num).toDouble();
          }
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        }
      }

      _addInitialStructure();
<<<<<<< HEAD
=======
      _ensureAtLeastOneTextBlock();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    } catch (e) {
      _showSnack(
        'Failed to load lesson: ${e.toString().replaceFirst('Exception: ', '')}',
      );
      _addInitialStructure();
<<<<<<< HEAD
=======
      _ensureAtLeastOneTextBlock();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    } finally {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _hasUnsavedChanges = false;
<<<<<<< HEAD
        _previewBlocks = _buildBlocksFromContent(_contentController.text);
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      });
    }
  }

  _MediaKind _inferKindFromBlockType(String type) {
    switch (type) {
      case 'image':
        return _MediaKind.image;
      case 'video':
        return _MediaKind.video;
      case 'audio':
        return _MediaKind.audio;
      default:
        return _MediaKind.audio;
    }
  }

  // ======== Local Draft Handling ========

  String get _draftKey {
    final id = widget.existingLessonId;
    if (id != null) return 'lesson_draft_$id';
    return 'lesson_draft_new_${widget.classSectionId}_${widget.subjectId}_${widget.moduleId}';
  }

  Future<void> _saveLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
      final draft = {
        'title': _titleController.text,
        'content': _contentController.text,
        'font_size': _fontSize,
      };
      await prefs.setString(_draftKey, jsonEncode(draft));
    } catch (_) {
      // تجاهل — لا نريد إزعاج المستخدم
    }
=======

      final blocksJson = _blocks.map((b) => b.toDraftJson()).toList();

      final draft = {
        'title': _titleController.text,
        'font_size': _fontSize,
        'blocks': blocksJson,
      };
      await prefs.setString(_draftKey, jsonEncode(draft));
    } catch (_) {}
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  }

  Future<Map<String, dynamic>?> _loadLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  // ======== Helpers for initial structure ========

  void _addInitialStructure() {
    if (_modules.isEmpty) {
      _modules.add(
        _ModuleData(
          tempId: 'm1',
          title: widget.moduleTitle,
          position: 1,
        ),
      );
    }
    _selectedModule ??= _modules.first;
  }

<<<<<<< HEAD
=======
  void _ensureAtLeastOneTextBlock() {
    if (_blocks.isEmpty) {
      final b = _LessonBlock.text(
        id: _id(),
        controller: TextEditingController(),
      )..attachChangeListener(_onAnyFieldChanged);
      _blocks.add(b);
      _activeTextBlockIndex = 0;
      return;
    }

    // لو آخر بلوك ميديا، أضف Text بعده عشان المعلم يكمّل كتابة
    if (_blocks.isNotEmpty && _blocks.last.type == _LessonBlockType.media) {
      final b = _LessonBlock.text(
        id: _id(),
        controller: TextEditingController(),
      )..attachChangeListener(_onAnyFieldChanged);
      _blocks.add(b);
    }
  }

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

<<<<<<< HEAD
  // ======== TEXT HELPER: bold/italic ========

  void _insertAroundSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;
=======
  // ======== TEXT HELPER: bold/italic (على بلوك النص النشط) ========

  void _insertAroundSelection(String prefix, String suffix) {
    final idx = _activeTextBlockIndex;
    if (idx == null || idx < 0 || idx >= _blocks.length) return;

    final block = _blocks[idx];
    if (block.type != _LessonBlockType.text || block.controller == null) return;

    final c = block.controller!;
    final text = c.text;
    final selection = c.selection;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    if (!selection.isValid) return;

    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end < 0 || start > end) return;

    final selectedText = text.substring(start, end);
    if (selectedText.isEmpty) return;

    final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');

<<<<<<< HEAD
    _contentController.value = _contentController.value.copyWith(
=======
    c.value = c.value.copyWith(
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      text: newText,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + prefix.length + selectedText.length + suffix.length,
      ),
    );
<<<<<<< HEAD
=======

    _markDirtyAndMaybeAutosave();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  }

  // =================== Media Picking (Unified UX) ===================

  Future<void> _openMediaPickerSheet() async {
    if (_isRecording) {
      _showSnack('Please stop recording first.');
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetItem(
                  icon: Icons.image_rounded,
                  title: 'Image (Gallery)',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickImage(fromCamera: false);
                  },
                ),
                _sheetItem(
                  icon: Icons.photo_camera_rounded,
                  title: 'Image (Camera)',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickImage(fromCamera: true);
                  },
                ),
                _sheetItem(
                  icon: Icons.videocam_rounded,
                  title: 'Video (Gallery)',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickVideo(fromCamera: false);
                  },
                ),
                _sheetItem(
                  icon: Icons.video_camera_back_rounded,
                  title: 'Video (Camera)',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickVideo(fromCamera: true);
                  },
                ),
                _sheetItem(
                  icon: Icons.library_music_rounded,
                  title: 'Audio file',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickAudioFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    required Future<void> Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: EduTheme.primaryDark),
      title: Text(title),
      onTap: onTap,
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _attachAndUploadMedia(kind: _MediaKind.image, localPath: picked.path);
  }

  Future<void> _pickVideo({required bool fromCamera}) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (picked == null) return;
    await _attachAndUploadMedia(kind: _MediaKind.video, localPath: picked.path);
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await _attachAndUploadMedia(kind: _MediaKind.audio, localPath: path);
  }

  // =================== Media Attachment + Upload ===================
<<<<<<< HEAD
=======
  // ✅ الآن: الميديا تظهر كبـ "Block" داخل المحرر نفسه (بدون Tokens)

  int _insertIndexForNewMediaBlock() {
    final idx = _activeTextBlockIndex;
    if (idx == null || idx < 0 || idx >= _blocks.length) {
      return _blocks.length; // آخر شي
    }
    return idx + 1; // تحت بلوك النص النشط مباشرة
  }
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

  Future<void> _attachAndUploadMedia({
    required _MediaKind kind,
    required String localPath,
  }) async {
    final id = _id();

<<<<<<< HEAD
    // 1) إدراج token داخل النص عند موضع المؤشر (ثابت ومضمون)
    _insertMediaTokenAtCursor(id);

    // 2) إضافة عنصر pending محلي للمعاينة الفورية
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    final pending = _PendingMedia(
      id: id,
      kind: kind,
      localPath: localPath,
      mediaPath: '',
      remoteUrl: '',
      mime: null,
      size: null,
      status: _MediaStatus.uploading,
    );

<<<<<<< HEAD
    setState(() {
      _pendingMedia.add(pending);
      _hasUnsavedChanges = true;
      _previewBlocks = _buildBlocksFromContent(_contentController.text);
    });

    // 3) رفع وتحديث العنصر (بدون تكرار logic)
    await _uploadMedia(id: id, localPath: localPath);
  }

  void _insertMediaTokenAtCursor(String id) {
    final token = '${_MediaToken.encode(id)}\n';
    final text = _contentController.text;
    final selection = _contentController.selection;

    final start = selection.isValid && selection.start >= 0 ? selection.start : text.length;
    final end = selection.isValid && selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, token);

    _contentController.value = _contentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  Future<void> _uploadMedia({required String id, required String localPath}) async {
    try {
      final uploadRes = await ApiService.uploadLessonMedia(filePath: localPath);
=======
    final insertAt = _insertIndexForNewMediaBlock();

    setState(() {
      _blocks.insert(insertAt, _LessonBlock.media(id: id, media: pending));
      // لو كان آخر بلوك ميديا، أضف Text بعده عشان يكمّل كتابة
      if (insertAt == _blocks.length - 1) {
        _ensureAtLeastOneTextBlock();
      } else {
        // لو البلوك اللي بعده ميديا/نهاية، أضف نص بينهما
        final nextIndex = insertAt + 1;
        if (nextIndex >= _blocks.length ||
            _blocks[nextIndex].type == _LessonBlockType.media) {
          final t = _LessonBlock.text(
            id: _id(),
            controller: TextEditingController(),
          )..attachChangeListener(_onAnyFieldChanged);
          _blocks.insert(nextIndex, t);
        }
      }

      _hasUnsavedChanges = true;
    });

    _markDirtyAndMaybeAutosave();

    await _uploadMedia(blockId: id, localPath: localPath);
  }

  Future<void> _uploadMedia({
    required String blockId,
    required String localPath,
  }) async {
    try {
      final uploadRes = await LessonService.uploadLessonMedia(
        filePath: localPath,
      );
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

      final mediaPath = (uploadRes['media_path'] ?? '').toString().trim();
      final mediaUrl = (uploadRes['media_url'] ?? '').toString().trim();
      final mime = uploadRes['media_mime']?.toString();
      final size = uploadRes['media_size'] is int
          ? uploadRes['media_size'] as int
<<<<<<< HEAD
          : (uploadRes['media_size'] is num ? (uploadRes['media_size'] as num).toInt() : null);
=======
          : (uploadRes['media_size'] is num
              ? (uploadRes['media_size'] as num).toInt()
              : null);
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

      if (!mounted) return;

      setState(() {
<<<<<<< HEAD
        final idx = _pendingMedia.indexWhere((m) => m.id == id);
        if (idx != -1) {
          final old = _pendingMedia[idx];
          _pendingMedia[idx] = old.copyWith(
            mediaPath: mediaPath,
            remoteUrl: mediaUrl.isNotEmpty ? mediaUrl : (mediaPath.isNotEmpty ? ApiService.buildMediaUrl(mediaPath) : ''),
            mime: mime,
            size: size,
            status: _MediaStatus.ready,
          );
        }
        _previewBlocks = _buildBlocksFromContent(_contentController.text);
        _hasUnsavedChanges = true;
      });
=======
        final idx = _blocks.indexWhere((b) => b.id == blockId);
        if (idx != -1 && _blocks[idx].type == _LessonBlockType.media) {
          final old = _blocks[idx].media!;
          _blocks[idx] = _blocks[idx].copyWithMedia(
            old.copyWith(
              mediaPath: mediaPath,
              remoteUrl: mediaUrl.isNotEmpty
                  ? mediaUrl
                  : (mediaPath.isNotEmpty ? ApiHelpers.buildMediaUrl(mediaPath) : ''),
              mime: mime,
              size: size,
              status: _MediaStatus.ready,
            ),
          );
        }
        _hasUnsavedChanges = true;
      });

      _markDirtyAndMaybeAutosave();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    } catch (e) {
      if (!mounted) return;

      setState(() {
<<<<<<< HEAD
        final idx = _pendingMedia.indexWhere((m) => m.id == id);
        if (idx != -1) {
          _pendingMedia[idx] = _pendingMedia[idx].copyWith(status: _MediaStatus.failed);
        }
      });

      _showSnack('Failed to upload media: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // =================== Voice Recording (WhatsApp-like practical) ===================
=======
        final idx = _blocks.indexWhere((b) => b.id == blockId);
        if (idx != -1 && _blocks[idx].type == _LessonBlockType.media) {
          final old = _blocks[idx].media!;
          _blocks[idx] = _blocks[idx].copyWithMedia(
            old.copyWith(status: _MediaStatus.failed),
          );
        }
      });

      _showSnack(
        'Failed to upload media: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // =================== Voice Recording ===================
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      await _stopRecordingAndAttach();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        _showSnack('Microphone permission is required.');
        return;
      }

      final tempDir = Directory.systemTemp;
<<<<<<< HEAD
      final filePath = '${tempDir.path}/lesson_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
=======
      final filePath =
          '${tempDir.path}/lesson_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _recordingStartedAt = DateTime.now();
      _recordingElapsed = Duration.zero;
      _ticker.start();

      setState(() => _isRecording = true);
    } catch (e) {
<<<<<<< HEAD
      _showSnack('Failed to start recording: ${e.toString().replaceFirst('Exception: ', '')}');
=======
      _showSnack(
        'Failed to start recording: ${e.toString().replaceFirst('Exception: ', '')}',
      );
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    }
  }

  Future<void> _stopRecordingAndAttach() async {
    try {
      final path = await _recorder.stop();
      _ticker.stop();

      setState(() => _isRecording = false);
      _recordingStartedAt = null;

      if (path == null) return;

<<<<<<< HEAD
      // نضيف كتسجيل صوتي (audio) — نفس مسار الصوت
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      await _attachAndUploadMedia(kind: _MediaKind.voice, localPath: path);
    } catch (e) {
      _ticker.stop();
      setState(() => _isRecording = false);
      _recordingStartedAt = null;
<<<<<<< HEAD
      _showSnack('Failed to stop recording: ${e.toString().replaceFirst('Exception: ', '')}');
=======
      _showSnack(
        'Failed to stop recording: ${e.toString().replaceFirst('Exception: ', '')}',
      );
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    }
  }

  Future<void> _cancelRecording() async {
    try {
<<<<<<< HEAD
      await _recorder.stop(); // stop بدون attach
=======
      await _recorder.stop();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    } catch (_) {}
    _ticker.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _recordingElapsed = Duration.zero;
    });
    _showSnack('Recording canceled.');
  }

  void _stopRecordingIfNeededOnDispose() {
    if (_isRecording) {
<<<<<<< HEAD
      // best-effort
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      _recorder.stop();
      _ticker.stop();
    }
  }

  // =================== SAVE LESSON ===================

<<<<<<< HEAD
=======
  bool _hasAnyMeaningfulContent() {
    for (final b in _blocks) {
      if (b.type == _LessonBlockType.text) {
        final t = b.controller?.text.trim() ?? '';
        if (t.isNotEmpty) return true;
      } else {
        return true; // أي ميديا تعتبر محتوى
      }
    }
    return false;
  }

  bool _hasUploadingMedia() {
    return _blocks.any((b) =>
        b.type == _LessonBlockType.media &&
        b.media != null &&
        b.media!.status == _MediaStatus.uploading);
  }

  bool _hasFailedMedia() {
    return _blocks.any((b) =>
        b.type == _LessonBlockType.media &&
        b.media != null &&
        b.media!.status == _MediaStatus.failed);
  }

  List<Map<String, dynamic>> _buildBlocksPayload() {
    final blocks = <Map<String, dynamic>>[];
    int position = 1;

    for (final b in _blocks) {
      if (b.type == _LessonBlockType.text) {
        final t = (b.controller?.text ?? '').trim();
        if (t.isEmpty) continue;

        blocks.add({
          'id': null,
          'type': 'text',
          'body': t,
          'caption': null,
          'media_url': null,
          'media_path': null,
          'media_mime': null,
          'media_size': null,
          'media_duration': null,
          'module_id': _selectedModule?.tempId,
          'topic_id': null,
          'position': position++,
          'meta': {'font_size': _fontSize},
        });
        continue;
      }

      final media = b.media;
      if (media == null) continue;

      final type = media.kind == _MediaKind.image
          ? 'image'
          : media.kind == _MediaKind.video
              ? 'video'
              : 'audio'; // audio + voice

      blocks.add({
        'id': null,
        'type': type,
        'body': null,
        'caption': null,
        'media_url': null,
        'media_path': media.mediaPath.isNotEmpty ? media.mediaPath : null,
        'media_mime': media.mime,
        'media_size': media.size,
        'media_duration': null,
        'module_id': _selectedModule?.tempId,
        'topic_id': null,
        'position': position++,
        'meta': {'font_size': _fontSize},
      });
    }

    return blocks;
  }

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  Future<void> _saveLesson({required bool publish}) async {
    try {
      FocusScope.of(context).unfocus();
      final title = _titleController.text.trim();
<<<<<<< HEAD
      final content = _contentController.text;
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

      if (title.isEmpty) {
        _showSnack('Please enter a lesson title.');
        return;
      }

<<<<<<< HEAD
      // منع حفظ ميديا تحت الرفع أو فاشلة
      final uploading = _pendingMedia.any((m) => m.status == _MediaStatus.uploading);
      if (uploading) {
        _showSnack('Please wait until media upload finishes.');
        return;
      }
      final failed = _pendingMedia.any((m) => m.status == _MediaStatus.failed);
      if (failed) {
=======
      if (_hasUploadingMedia()) {
        _showSnack('Please wait until media upload finishes.');
        return;
      }

      if (_hasFailedMedia()) {
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        _showSnack('Some media failed to upload. Remove or retry before saving.');
        return;
      }

<<<<<<< HEAD
      if (content.trim().isEmpty && _pendingMedia.isEmpty) {
=======
      if (!_hasAnyMeaningfulContent()) {
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        _showSnack('Please add some content or media to the lesson.');
        return;
      }

      setState(() => _isSaving = true);

<<<<<<< HEAD
      // ✅ الآن: لا نرسل modules/topics (حل نهائي) — نحافظ فقط للـ API إن كانت تتطلب وجودها
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      final modulesPayload = _modules
          .map((m) => {'id': m.tempId, 'title': m.title, 'position': m.position})
          .toList();

      final topicsPayload = <Map<String, dynamic>>[];

<<<<<<< HEAD
      // ✅ بناء blocks يعتمد على tokens + pending media (ثابت)
      final blocksPayload = _buildBlocksFromContent(content);

      await ApiService.saveLesson(
        teacherCode: widget.teacherCode,
        assignmentId: widget.assignmentId,
        classModuleId: widget.moduleId, // ✅ هذا هو class_module_id
=======
      final blocksPayload = _buildBlocksPayload();

      await LessonService.saveLesson(
        teacherCode: widget.teacherCode,
        assignmentId: widget.assignmentId,
        classModuleId: widget.moduleId,
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        classSectionId: widget.classSectionId,
        subjectId: widget.subjectId,
        lessonId: widget.existingLessonId,
        title: title,
        publish: publish,
        modules: modulesPayload,
        topics: topicsPayload,
        blocks: blocksPayload,
      );

      _showSnack(publish ? 'Lesson published.' : 'Lesson saved as draft.');

<<<<<<< HEAD
      _pendingMedia.clear();
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      await _clearLocalDraft();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  // =================== Back Handling ===================

  Future<void> _handleBack() async {
    if (_isRecording) {
      _showSnack('Stop recording before leaving.');
      return;
    }
    if (_isEditingExisting && _hasUnsavedChanges) {
      await _saveLocalDraft();
      _showSnack('Changes saved locally as draft. Not published yet.');
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  // =================== UI ===================

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: EduTheme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Lesson Builder'),
        leading: IconButton(
<<<<<<< HEAD
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: EduTheme.primaryDark),
=======
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: EduTheme.primaryDark),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
          onPressed: _handleBack,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: Text(
<<<<<<< HEAD
              _isEditingExisting ? (_hasUnsavedChanges ? 'Editing...' : 'Loaded') : 'New Lesson',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _hasUnsavedChanges ? Colors.orange : EduTheme.primaryDark,
=======
              _isEditingExisting
                  ? (_hasUnsavedChanges ? 'Editing...' : 'Loaded')
                  : 'New Lesson',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _hasUnsavedChanges
                        ? Colors.orange
                        : EduTheme.primaryDark,
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.classTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EduTheme.primaryDark,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Class: ${widget.classKey} • Students: ${widget.studentsCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
<<<<<<< HEAD
                          color: EduTheme.primaryDark.withValues(alpha: 0.6),
=======
                          color: EduTheme.primaryDark.withOpacity(0.6),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Module: ${widget.moduleTitle}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
<<<<<<< HEAD
                          color: EduTheme.primaryDark.withValues(alpha: 0.6),
=======
                          color: EduTheme.primaryDark.withOpacity(0.6),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Lesson Title',
<<<<<<< HEAD
                      hintText: 'e.g. Introduction to Photosynthesis',
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lesson Content',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: EduTheme.primaryDark,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: bottomInset + 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildToolbar(),
                        const SizedBox(height: 10),

<<<<<<< HEAD
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(fontSize: _fontSize),
                          decoration: const InputDecoration(
                            hintText:
                                'Write your lesson content here...\nUse the toolbar to attach media.',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Student View Preview',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: EduTheme.primaryDark,
                              ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
=======
                        // ✅ المحرر نفسه صار يعرض النص + الميديا بنفس شكل معاينة الطالب
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
<<<<<<< HEAD
                              for (final block in _previewBlocks) ...[
                                _buildPreviewBlock(block),
                                const SizedBox(height: 18),
=======
                              for (int i = 0; i < _blocks.length; i++) ...[
                                _buildEditorBlock(i, _blocks[i]),
                                if (i != _blocks.length - 1)
                                  const SizedBox(height: 16),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                              ],
                            ],
                          ),
                        ),

<<<<<<< HEAD
                        if (_pendingMedia.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Attached Media (Teacher Preview)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: EduTheme.primaryDark,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: _pendingMedia.map((m) => _buildMediaCard(m)).toList(),
                          ),
                        ],

                        const SizedBox(height: 12),

=======
                        const SizedBox(height: 12),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F6FF),
                              foregroundColor: EduTheme.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              _showSnack('Knowledge Check will be configured later.');
                            },
                            icon: const Icon(Icons.quiz_outlined),
                            label: const Text('Add Knowledge Check (coming soon)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomButtons(bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
<<<<<<< HEAD
            color: Colors.black.withValues(alpha: 0.04),
=======
            color: Colors.black.withOpacity(0.04),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Attach Media',
              icon: const Icon(Icons.attach_file_rounded),
              onPressed: _openMediaPickerSheet,
            ),
<<<<<<< HEAD

            const SizedBox(width: 8),

            // ✅ تسجيل صوت محسّن + مؤقت + إلغاء سريع
=======
            const SizedBox(width: 8),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleVoiceRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : EduTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
<<<<<<< HEAD
                  icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, size: 18),
=======
                  icon: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 18,
                  ),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                  label: Text(_isRecording ? 'Stop' : 'Voice'),
                ),
                if (_isRecording) ...[
                  const SizedBox(width: 10),
                  Text(
                    _formatTimer(_recordingElapsed),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _cancelRecording,
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
<<<<<<< HEAD

            const SizedBox(width: 12),

=======
            const SizedBox(width: 12),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
            IconButton(
              tooltip: 'Bold',
              icon: const Icon(Icons.format_bold_rounded),
              onPressed: () => _insertAroundSelection('**', '**'),
            ),
            IconButton(
              tooltip: 'Italic',
              icon: const Icon(Icons.format_italic_rounded),
              onPressed: () => _insertAroundSelection('_', '_'),
            ),
<<<<<<< HEAD

            const SizedBox(width: 12),

=======
            const SizedBox(width: 12),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
            Row(
              children: [
                const Text('A'),
                Slider(
                  value: _fontSize,
                  min: 12,
                  max: 24,
                  divisions: 6,
                  label: _fontSize.toStringAsFixed(0),
<<<<<<< HEAD
                  onChanged: (v) => setState(() => _fontSize = v),
=======
                  onChanged: (v) {
                    setState(() => _fontSize = v);
                    _markDirtyAndMaybeAutosave();
                  },
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimer(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

<<<<<<< HEAD
  // ========= Preview rendering =========

  TextSpan _buildStyledTextSpan(String body, double fontSize) {
    final defaultStyle = TextStyle(
      fontSize: fontSize,
      height: 1.4,
      color: EduTheme.primaryDark,
    );

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|_(.+?)_', dotAll: true);
    int lastIndex = 0;

    for (final match in regex.allMatches(body)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: body.substring(lastIndex, match.start), style: defaultStyle));
      }

      final boldText = match.group(1);
      final italicText = match.group(2);

      if (boldText != null) {
        spans.add(TextSpan(text: boldText, style: defaultStyle.copyWith(fontWeight: FontWeight.bold)));
      } else if (italicText != null) {
        spans.add(TextSpan(text: italicText, style: defaultStyle.copyWith(fontStyle: FontStyle.italic)));
      }

      lastIndex = match.end;
    }

    if (lastIndex < body.length) {
      spans.add(TextSpan(text: body.substring(lastIndex), style: defaultStyle));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: body, style: defaultStyle));
    }

    return TextSpan(children: spans, style: defaultStyle);
  }

  Widget _buildPreviewBlock(Map<String, dynamic> block) {
    final type = (block['type'] ?? '').toString();
    switch (type) {
      case 'image':
        return _buildPreviewImageBlock(block);
      case 'audio':
        return _buildPreviewAudioBlock(block);
      case 'video':
        return _buildPreviewVideoBlock(block);
      default:
        return _buildPreviewTextBlock(block);
    }
  }

  Widget _buildPreviewTextBlock(Map<String, dynamic> block) {
    final body = (block['body'] ?? '').toString();
    if (body.trim().isEmpty) return const SizedBox.shrink();

    final meta = block['meta'] is Map ? (block['meta'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final fontSize = (meta['font_size'] is num) ? (meta['font_size'] as num).toDouble() : _fontSize;

    return RichText(text: _buildStyledTextSpan(body, fontSize));
  }

  Widget _buildPreviewImageBlock(Map<String, dynamic> block) {
    final value = ApiService.pickMediaValueFromBlock(block);
    final path = ApiService.extractMediaPath(value);
    final url = ApiService.buildMediaUrl(path.isNotEmpty ? path : value);
    if (url.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Text('Failed to load image'),
      ),
    );
  }

  Widget _buildPreviewVideoBlock(Map<String, dynamic> block) {
    final value = ApiService.pickMediaValueFromBlock(block);
    final path = ApiService.extractMediaPath(value);
    final url = ApiService.buildMediaUrl(path.isNotEmpty ? path : value);
    if (url.isEmpty) return const SizedBox.shrink();

    final caption = (block['caption'] ?? '').toString();
=======
  // ========= Editor rendering =========

  Widget _buildEditorBlock(int index, _LessonBlock block) {
    if (block.type == _LessonBlockType.text) {
      final c = block.controller!;
      return TextField(
        controller: c,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: TextStyle(fontSize: _fontSize, height: 1.4),
        decoration: const InputDecoration(
          hintText: 'Write here...',
          border: OutlineInputBorder(),
        ),
        onTap: () => _activeTextBlockIndex = index,
        onChanged: (_) => _markDirtyAndMaybeAutosave(),
      );
    }

    // Media block
    final media = block.media!;
    final isUploading = media.status == _MediaStatus.uploading;
    final isFailed = media.status == _MediaStatus.failed;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
<<<<<<< HEAD
        LessonVideoPlayer(url: url),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EduTheme.primaryDark.withValues(alpha: 0.7),
                ),
          ),
        ],
=======
        Row(
          children: [
            Icon(_iconForKind(media.kind), color: EduTheme.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _labelForKind(media.kind),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: EduTheme.primaryDark,
                    ),
              ),
            ),
            if (isUploading)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (isFailed) ...[
              const SizedBox(width: 8),
              const Icon(Icons.error_outline_rounded, color: Colors.red),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () async {
                  final lp = media.localPath;
                  if (lp == null || lp.isEmpty) return;
                  setState(() {
                    final idx = _blocks.indexWhere((b) => b.id == block.id);
                    if (idx != -1) {
                      final old = _blocks[idx].media!;
                      _blocks[idx] = _blocks[idx].copyWithMedia(
                        old.copyWith(status: _MediaStatus.uploading),
                      );
                    }
                  });
                  await _uploadMedia(blockId: block.id, localPath: lp);
                },
                child: const Text('Retry'),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _removeBlockAt(index),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMediaPreview(media),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildPreviewAudioBlock(Map<String, dynamic> block) {
    final value = ApiService.pickMediaValueFromBlock(block);
    final path = ApiService.extractMediaPath(value);
    final url = ApiService.buildMediaUrl(path.isNotEmpty ? path : value);
    if (url.isEmpty) return const SizedBox.shrink();
    return LessonAudioPlayer(url: url);
  }

  // ======== Build blocks from content + tokens ========

  List<Map<String, dynamic>> _buildBlocksFromContent(String content) {
    final raw = content.trim();
    if (raw.isEmpty && _pendingMedia.isEmpty) return [];

    // نقسم النص بناءً على tokens [[MEDIA:id]]
    final tokens = _MediaToken.regex.allMatches(raw).toList();

    final blocks = <Map<String, dynamic>>[];
    int position = 1;
    int cursor = 0;

    void addTextBlock(String text) {
      final t = text.trim();
      if (t.isEmpty) return;
      blocks.add({
        'id': null,
        'type': 'text',
        'body': t,
        'caption': null,
        'media_url': null,
        'media_path': null,
        'media_mime': null,
        'media_size': null,
        'media_duration': null,
        'module_id': _selectedModule?.tempId,
        'topic_id': null,
        'position': position++,
        'meta': {'font_size': _fontSize},
      });
    }

    void addMediaBlock(String id) {
      final media = _pendingMedia.firstWhere(
        (m) => m.id == id,
        orElse: () => _PendingMedia.missing(id),
      );

      if (media.isMissing) {
        // token بدون ميديا — نعتبره نصاً حتى لا نكسر المحتوى
        addTextBlock(_MediaToken.encode(id));
        return;
      }

      final type = media.kind == _MediaKind.image
          ? 'image'
          : media.kind == _MediaKind.video
              ? 'video'
              : 'audio';

      blocks.add({
        'id': null,
        'type': type,
        'body': null,
        'caption': null,
        'media_url': null,
        'media_path': media.mediaPath.isNotEmpty ? media.mediaPath : null,
        'media_mime': media.mime,
        'media_size': media.size,
        'media_duration': null,
        'module_id': _selectedModule?.tempId,
        'topic_id': null,
        'position': position++,
        'meta': {'font_size': _fontSize},
      });
    }

    for (final m in tokens) {
      final before = raw.substring(cursor, m.start);
      addTextBlock(before);

      final id = _MediaToken.decode(m.group(0) ?? '');
      if (id != null && id.isNotEmpty) {
        addMediaBlock(id);
      }

      cursor = m.end;
    }

    if (cursor < raw.length) {
      addTextBlock(raw.substring(cursor));
    }

    // إذا لا يوجد tokens لكن هناك ميديا (حالة نادرة) — نضيفهم بالآخر
    if (tokens.isEmpty && _pendingMedia.isNotEmpty) {
      for (final media in _pendingMedia) {
        if (media.status != _MediaStatus.ready) continue;
        addMediaBlock(media.id);
      }
    }

    return blocks;
=======
  void _removeBlockAt(int index) {
    setState(() {
      final removed = _blocks.removeAt(index);
      removed.dispose();

      if (_activeTextBlockIndex != null) {
        if (_activeTextBlockIndex == index) {
          _activeTextBlockIndex = null;
        } else if (_activeTextBlockIndex! > index) {
          _activeTextBlockIndex = _activeTextBlockIndex! - 1;
        }
      }

      _ensureAtLeastOneTextBlock();
      _hasUnsavedChanges = true;
    });

    _markDirtyAndMaybeAutosave();
  }

  Widget _buildMediaPreview(_PendingMedia media) {
    final localPath = media.localPath;
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      final f = File(localPath);

      if (media.kind == _MediaKind.image) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            f,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text('Failed to preview image'),
          ),
        );
      }

      if (media.kind == _MediaKind.video) {
        return LessonVideoPlayer(url: 'file://$localPath');
      }

      return LessonAudioPlayer(url: 'file://$localPath');
    }

    // remote
    final url = media.remoteUrl.isNotEmpty
        ? media.remoteUrl
        : (media.mediaPath.isNotEmpty ? ApiHelpers.buildMediaUrl(media.mediaPath) : '');

    if (url.isEmpty) {
      return Text(
        media.status == _MediaStatus.failed ? 'Upload failed.' : 'Waiting for upload...',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: EduTheme.primaryDark.withOpacity(0.6),
            ),
      );
    }

    if (media.kind == _MediaKind.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Text('Failed to load image'),
        ),
      );
    }

    if (media.kind == _MediaKind.video) {
      return LessonVideoPlayer(url: url);
    }

    return LessonAudioPlayer(url: url);
  }

  IconData _iconForKind(_MediaKind k) {
    switch (k) {
      case _MediaKind.image:
        return Icons.image_rounded;
      case _MediaKind.video:
        return Icons.videocam_rounded;
      case _MediaKind.audio:
      case _MediaKind.voice:
        return Icons.audiotrack_rounded;
    }
  }

  String _labelForKind(_MediaKind k) {
    switch (k) {
      case _MediaKind.image:
        return 'Image';
      case _MediaKind.video:
        return 'Video';
      case _MediaKind.audio:
        return 'Audio';
      case _MediaKind.voice:
        return 'Voice';
    }
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  }

  Widget _buildBottomButtons(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => _saveLesson(publish: false),
              child: const Text('Save as Draft'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveLesson(publish: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publish'),
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD

  // ===== Teacher preview cards =====

  Widget _buildMediaCard(_PendingMedia media) {
    final isUploading = media.status == _MediaStatus.uploading;
    final isFailed = media.status == _MediaStatus.failed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(_iconForKind(media.kind), color: EduTheme.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _labelForKind(media.kind),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: EduTheme.primaryDark,
                        ),
                  ),
                ),
                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (isFailed)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.error_outline_rounded, color: Colors.red),
                  ),
                if (isFailed)
                  TextButton(
                    onPressed: () async {
                      if (media.localPath == null || media.localPath!.isEmpty) return;
                      setState(() {
                        final idx = _pendingMedia.indexWhere((m) => m.id == media.id);
                        if (idx != -1) {
                          _pendingMedia[idx] = _pendingMedia[idx].copyWith(status: _MediaStatus.uploading);
                        }
                      });
                      await _uploadMedia(id: media.id, localPath: media.localPath!);
                    },
                    child: const Text('Retry'),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _removeMedia(media.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildTeacherMediaPreview(media),
          ),
        ],
      ),
    );
  }

  void _removeMedia(String id) {
    setState(() {
      _pendingMedia.removeWhere((m) => m.id == id);

      // ✅ إزالة token من المحتوى أيضًا (حل نهائي)
      final token = _MediaToken.encode(id);
      final txt = _contentController.text;
      _contentController.text = txt.replaceAll(token, '').replaceAll('\n\n\n', '\n\n').trim();

      _previewBlocks = _buildBlocksFromContent(_contentController.text);
      _hasUnsavedChanges = true;
    });
  }

  IconData _iconForKind(_MediaKind k) {
    switch (k) {
      case _MediaKind.image:
        return Icons.image_rounded;
      case _MediaKind.video:
        return Icons.videocam_rounded;
      case _MediaKind.audio:
      case _MediaKind.voice:
        return Icons.audiotrack_rounded;
    }
  }

  String _labelForKind(_MediaKind k) {
    switch (k) {
      case _MediaKind.image:
        return 'Image';
      case _MediaKind.video:
        return 'Video';
      case _MediaKind.audio:
        return 'Audio';
      case _MediaKind.voice:
        return 'Voice';
    }
  }

  Widget _buildTeacherMediaPreview(_PendingMedia media) {
    // ✅ local preview (instant)
    final localPath = media.localPath;
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      final f = File(localPath);

      if (media.kind == _MediaKind.image) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            f,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text('Failed to preview image'),
          ),
        );
      }

      if (media.kind == _MediaKind.video) {
        return LessonVideoPlayer(url: 'file://$localPath');
      }

      return LessonAudioPlayer(url: 'file://$localPath');
    }

    // ✅ remote preview
    final url = media.remoteUrl.isNotEmpty
        ? media.remoteUrl
        : (media.mediaPath.isNotEmpty ? ApiService.buildMediaUrl(media.mediaPath) : '');

    if (url.isEmpty) {
      return Text(
        media.status == _MediaStatus.failed ? 'Upload failed.' : 'Waiting for upload...',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: EduTheme.primaryDark.withValues(alpha: 0.6),
            ),
      );
    }

    if (media.kind == _MediaKind.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Text('Failed to load image'),
        ),
      );
    }

    if (media.kind == _MediaKind.video) {
      return LessonVideoPlayer(url: url);
    }

    return LessonAudioPlayer(url: url);
  }
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
}

// ======== Helper internal models ========

class _ModuleData {
  final String tempId;
  final String title;
  final int position;

  _ModuleData({
    required this.tempId,
    required this.title,
    required this.position,
  });
}

enum _MediaKind { image, video, audio, voice }
enum _MediaStatus { uploading, ready, failed, missing }

class _PendingMedia {
  final String id;
  final _MediaKind kind;

<<<<<<< HEAD
  final String? localPath; // local preview (optional)
  final String mediaPath; // lessons/...
  final String remoteUrl; // full url if provided
=======
  final String? localPath;
  final String mediaPath;
  final String remoteUrl;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  final String? mime;
  final int? size;
  final _MediaStatus status;

  const _PendingMedia({
    required this.id,
    required this.kind,
    required this.localPath,
    required this.mediaPath,
    required this.remoteUrl,
    required this.mime,
    required this.size,
    required this.status,
  });

  factory _PendingMedia.missing(String id) {
    return _PendingMedia(
      id: id,
      kind: _MediaKind.audio,
      localPath: null,
      mediaPath: '',
      remoteUrl: '',
      mime: null,
      size: null,
      status: _MediaStatus.missing,
    );
  }

  bool get isMissing => status == _MediaStatus.missing;

  _PendingMedia copyWith({
    String? mediaPath,
    String? remoteUrl,
    String? mime,
    int? size,
    _MediaStatus? status,
  }) {
    return _PendingMedia(
      id: id,
      kind: kind,
      localPath: localPath,
      mediaPath: mediaPath ?? this.mediaPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      mime: mime ?? this.mime,
      size: size ?? this.size,
      status: status ?? this.status,
    );
  }
}

<<<<<<< HEAD
// ======== Token helper (replaces old placeholders) ========

class _MediaToken {
  // token example: [[MEDIA:123456]]
  static final RegExp regex = RegExp(r'\[\[MEDIA:([0-9]+)\]\]');

  static String encode(String id) => '[[MEDIA:$id]]';

  static String? decode(String token) {
    final m = regex.firstMatch(token);
    if (m == null) return null;
    return m.group(1);
=======
enum _LessonBlockType { text, media }

class _LessonBlock {
  final String id;
  final _LessonBlockType type;
  final TextEditingController? controller;
  final _PendingMedia? media;

  _LessonBlock._({
    required this.id,
    required this.type,
    required this.controller,
    required this.media,
  });

  factory _LessonBlock.text({
    required String id,
    required TextEditingController controller,
  }) {
    return _LessonBlock._(
      id: id,
      type: _LessonBlockType.text,
      controller: controller,
      media: null,
    );
  }

  factory _LessonBlock.media({
    required String id,
    required _PendingMedia media,
  }) {
    return _LessonBlock._(
      id: id,
      type: _LessonBlockType.media,
      controller: null,
      media: media,
    );
  }

  void attachChangeListener(VoidCallback listener) {
    if (controller == null) return;
    controller!.addListener(listener);
  }

  void dispose() {
    controller?.dispose();
  }

  _LessonBlock copyWithMedia(_PendingMedia newMedia) {
    return _LessonBlock._(
      id: id,
      type: type,
      controller: controller,
      media: newMedia,
    );
  }

  Map<String, dynamic> toDraftJson() {
    if (type == _LessonBlockType.text) {
      return {
        'id': id,
        'type': 'text',
        'body': controller?.text ?? '',
      };
    }
    final m = media!;
    final typeStr = m.kind == _MediaKind.image
        ? 'image'
        : m.kind == _MediaKind.video
            ? 'video'
            : 'audio';
    return {
      'id': id,
      'type': typeStr,
      'media_path': m.mediaPath,
      'media_mime': m.mime,
      'media_size': m.size,
    };
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  }
}

// ======== Simple Video/Audio Players for Preview ========

class LessonVideoPlayer extends StatefulWidget {
  final String url;

  const LessonVideoPlayer({super.key, required this.url});

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final uri = Uri.parse(widget.url);

      final c = (uri.scheme == 'file')
          ? VideoPlayerController.file(File(uri.toFilePath()))
          : VideoPlayerController.networkUrl(uri);

      _controller = c;

      await c.initialize();
      if (!mounted) return;

      setState(() => _initialized = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.pause();
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    if (_error || c == null) return const Text('Failed to load video');
    if (!_initialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return AspectRatio(
      aspectRatio: c.value.aspectRatio <= 0 ? (16 / 9) : c.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(c),
          Align(
            alignment: Alignment.bottomCenter,
            child: VideoProgressIndicator(c, allowScrubbing: true),
          ),
          Center(
            child: IconButton(
              iconSize: 48,
              icon: Icon(
<<<<<<< HEAD
                c.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white.withValues(alpha: 0.9),
=======
                c.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white.withOpacity(0.9),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
              ),
              onPressed: () {
                setState(() {
                  if (c.value.isPlaying) {
                    c.pause();
                  } else {
                    c.play();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LessonAudioPlayer extends StatefulWidget {
  final String url;

  const LessonAudioPlayer({super.key, required this.url});

  @override
  State<LessonAudioPlayer> createState() => _LessonAudioPlayerState();
}

class _LessonAudioPlayerState extends State<LessonAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
<<<<<<< HEAD
      // listeners أولاً
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      _player.onDurationChanged.listen((d) {
        if (!mounted) return;
        setState(() {
          _duration = d;
          _ready = true;
        });
      });

      _player.onPositionChanged.listen((p) {
        if (!mounted) return;
        setState(() => _position = p);
      });

      _player.onPlayerComplete.listen((event) {
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
      setState(() {
        _error = true;
        _ready = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_error) return const Text('Failed to load audio');
    if (!_ready) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final maxMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds.clamp(0, maxMs == 0 ? 0 : maxMs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: posMs.toDouble(),
          min: 0,
          max: (maxMs <= 0 ? 1 : maxMs).toDouble(),
          onChanged: (v) {
            final ms = v.toInt().clamp(0, maxMs <= 0 ? 0 : maxMs);
            _player.seek(Duration(milliseconds: ms));
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_format(_position)),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (_isPlaying) {
                  await _player.pause();
                } else {
                  await _player.resume();
                }
                if (!mounted) return;
                setState(() => _isPlaying = !_isPlaying);
              },
            ),
            Text(_format(_duration)),
          ],
        ),
      ],
    );
  }
}

<<<<<<< HEAD
// ======== Minimal ticker (بدون إضافة package) ========
=======
// ======== Minimal ticker ========
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

class Ticker {
  Ticker(this.onTick);

  final void Function(Duration elapsed) onTick;
  bool _running = false;
  DateTime? _start;

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
      final elapsed = DateTime.now().difference(_start!);
      onTick(elapsed);
    }
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
