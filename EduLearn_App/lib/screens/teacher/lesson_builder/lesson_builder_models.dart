part of 'lesson_builder_screen.dart';

enum _LessonBlockType { text, media }

enum _MediaKind { image, video, audio, voice, pdf }

enum _MediaStatus { uploading, ready, failed }

class _LessonBlock {
  final String id;
  final _LessonBlockType type;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  _TextBlockStyle? textStyle;
  final _MediaBlockData? media;

  final String stableKey;
  final String createdOrigin;
  String lastEditOrigin;
  int? aiSourceId;
  int? aiLastRunId;

  _LessonBlock._({
    required this.id,
    required this.type,
    required this.controller,
    required this.focusNode,
    required this.textStyle,
    required this.media,
    required this.stableKey,
    required this.createdOrigin,
    required this.lastEditOrigin,
    required this.aiSourceId,
    required this.aiLastRunId,
  });

  factory _LessonBlock.text({
    required String id,
    required String stableKey,
    String text = '',
    _TextBlockStyle style = const _TextBlockStyle(),
    String createdOrigin = 'manual',
    String lastEditOrigin = 'manual',
    int? aiSourceId,
    int? aiLastRunId,
  }) {
    return _LessonBlock._(
      id: id,
      type: _LessonBlockType.text,
      controller: TextEditingController(text: text),
      focusNode: FocusNode(),
      textStyle: style,
      media: null,
      stableKey: stableKey,
      createdOrigin: createdOrigin,
      lastEditOrigin: lastEditOrigin,
      aiSourceId: aiSourceId,
      aiLastRunId: aiLastRunId,
    );
  }

  factory _LessonBlock.media({
  required String id,
  String? stableKey,
  required _MediaBlockData media,
  String createdOrigin = 'manual',
  String lastEditOrigin = 'manual',
  int? aiSourceId,
  int? aiLastRunId,
}) {
    return _LessonBlock._(
      id: id,
      type: _LessonBlockType.media,
      controller: null,
      focusNode: null,
      textStyle: null,
      media: media,
      stableKey: stableKey ?? id,
      createdOrigin: createdOrigin,
      lastEditOrigin: lastEditOrigin,
      aiSourceId: aiSourceId,
      aiLastRunId: aiLastRunId,
    );
  }

  _LessonBlock copyWithMedia(_MediaBlockData newMedia) {
    return _LessonBlock._(
      id: id,
      type: type,
      controller: controller,
      focusNode: focusNode,
      textStyle: textStyle,
      media: newMedia,
      stableKey: stableKey,
      createdOrigin: createdOrigin,
      lastEditOrigin: lastEditOrigin,
      aiSourceId: aiSourceId,
      aiLastRunId: aiLastRunId,
    );
  }

  bool get isAiGenerated => createdOrigin == 'ai';
  bool get isAiEdited => createdOrigin != 'ai' && lastEditOrigin == 'ai';

  Map<String, dynamic> toDraftJson() {
    if (type == _LessonBlockType.text) {
      return {
        'id': id,
        'stable_key': stableKey,
        'created_origin': createdOrigin,
        'last_edit_origin': lastEditOrigin,
        'ai_source_id': aiSourceId,
        'ai_last_run_id': aiLastRunId,
        'type': 'text',
        'body': controller?.text ?? '',
        'style': textStyle?.toJson() ?? const _TextBlockStyle().toJson(),
      };
    }
    final m = media!;
    return {
      'id': id,
      'stable_key': stableKey,
      'created_origin': createdOrigin,
      'last_edit_origin': lastEditOrigin,
      'ai_source_id': aiSourceId,
      'ai_last_run_id': aiLastRunId,
      'type': m.apiType,
      'kind': m.kind.name,
      'local_path': m.localPath,
      'media_path': m.mediaPath,
      'remote_url': m.remoteUrl,
      'media_mime': m.mime,
      'media_size': m.size,
      'caption': m.captionController.text,
      'status': m.status.name,
    };
  }

  void dispose() {
    controller?.dispose();
    focusNode?.dispose();
    media?.dispose();
  }
}

class _MediaBlockData {
  final String id;
  final _MediaKind kind;
  final String? localPath;
  final String mediaPath;
  final String remoteUrl;
  final String? mime;
  final int? size;
  final TextEditingController captionController;
  final _MediaStatus status;

  const _MediaBlockData({
    required this.id,
    required this.kind,
    required this.localPath,
    required this.mediaPath,
    required this.remoteUrl,
    required this.mime,
    required this.size,
    required this.captionController,
    required this.status,
  });

  bool get supportsCaption =>
      kind == _MediaKind.image || kind == _MediaKind.video;

  String get apiType {
    switch (kind) {
      case _MediaKind.image:
        return 'image';
      case _MediaKind.video:
        return 'video';
      case _MediaKind.pdf:
        return 'file';
      case _MediaKind.audio:
      case _MediaKind.voice:
        return 'audio';
    }
  }

  String sizeText({
    required String pdfDocumentLabel,
    required String fileLabel,
  }) {
    if (size == null || size == 0) {
      return kind == _MediaKind.pdf ? pdfDocumentLabel : fileLabel;
    }
    final kb = size! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  _MediaBlockData copyWith({
    String? mediaPath,
    String? remoteUrl,
    String? mime,
    int? size,
    _MediaStatus? status,
  }) {
    return _MediaBlockData(
      id: id,
      kind: kind,
      localPath: localPath,
      mediaPath: mediaPath ?? this.mediaPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      mime: mime ?? this.mime,
      size: size ?? this.size,
      captionController: captionController,
      status: status ?? this.status,
    );
  }

  void dispose() {
    captionController.dispose();
  }
}

class _TextBlockStyle {
  final double fontSize;
  final bool isBold;
  final bool isItalic;

  const _TextBlockStyle({
    this.fontSize = 18,
    this.isBold = false,
    this.isItalic = false,
  });

  _TextBlockStyle copyWith({
    double? fontSize,
    bool? isBold,
    bool? isItalic,
  }) {
    return _TextBlockStyle(
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
    );
  }

  Map<String, dynamic> toJson() => {
        'font_size': fontSize,
        'is_bold': isBold,
        'is_italic': isItalic,
      };

  Map<String, dynamic> toMetaJson() => toJson();

  factory _TextBlockStyle.fromJson(Map<String, dynamic> json) {
    return _TextBlockStyle(
      fontSize: (json['font_size'] is num)
          ? (json['font_size'] as num).toDouble()
          : 18,
      isBold: json['is_bold'] == true,
      isItalic: json['is_italic'] == true,
    );
  }
}
