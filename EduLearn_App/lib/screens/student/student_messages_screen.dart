import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../services/chat_service.dart';
import '../../services/api_helpers.dart';
import '../../services/reverb_service.dart';
import '../../theme.dart';

/// ========= Helpers عامة للتواريخ/الأوقات =========

DateTime? _parseUtcDate(String value) {
  try {
    if (value.trim().isEmpty) return null;
    var v = value.trim();

    if (!v.contains('T') && v.length >= 19) {
      v = v.substring(0, 19).replaceFirst(' ', 'T') + 'Z';
    }

    var dt = DateTime.parse(v);
    if (!dt.isUtc) {
      dt = DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      );
    }
    return dt;
  } catch (_) {
    return null;
  }
}

/// ✅ Helper: فلترة مرنة لأسماء أحداث Reverb/Pusher
bool _isMessageSentEvent(String name) {
  final n = name.trim();
  return n == 'message.sent' ||
      n == '.message.sent' ||
      n.endsWith('MessageSent') ||
      n.contains('MessageSent');
}

/// تنسيق وقت على شكل 09:30 AM
String _formatTimeOfDay(DateTime local) {
  int hour = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final isAm = hour < 12;
  final suffix = isAm ? 'AM' : 'PM';

  if (hour == 0) {
    hour = 12;
  } else if (hour > 12) {
    hour -= 12;
  }

  final hh = hour.toString();
  return '$hh:$minute $suffix';
}

/// تنسيق وقت شاشة قائمة المحادثات:
/// اليوم -> 09:30 AM
/// أمس -> Yesterday
/// غير ذلك -> Monday / Tuesday ... أو تاريخ مختصر
String _formatConversationTime(DateTime local) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(date).inDays;

  if (diffDays == 0) {
    return _formatTimeOfDay(local);
  } else if (diffDays == 1) {
    return 'Yesterday';
  } else if (diffDays > 1 && diffDays < 7) {
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdayNames[local.weekday - 1];
  } else {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[local.month - 1]} ${local.day}';
  }
}

String _formatTimeLabel(String raw, {bool forConversation = false}) {
  final dt = _parseUtcDate(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();

  if (forConversation) {
    return _formatConversationTime(local);
  }
  return _formatTimeOfDay(local);
}

bool _isSameCalendarDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDateDivider(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

/// ======================================================================
///  ✅ نفس فكرة Teacher: نعرف المحادثة المفتوحة حالياً
/// ======================================================================
class _StudentChatState {
  static int? currentConversationId;
}

/// ==================== شاشة قائمة محادثات الطالب ====================

class StudentMessagesScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentMessagesScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen>
    with WidgetsBindingObserver {
  late List<_ChatTeacher> _chatTeachers;
  bool _loadingConversations = false;

  /// محادثات لكل أستاذ حسب teacher_code
  final Map<String, _ConversationMeta> _metaByTeacherCode = {};

  /// conversationId -> teacherCode
  final Map<int, String> _teacherCodeByConversationId = {};

  ReverbClient? _reverbClient;
  final Map<int, Channel> _conversationChannels = {};

  String get _studentFullName => (widget.student['full_name'] ?? '').toString();

  String get _academicId {
    final dynamic raw = widget.student['academic_id'] ??
        widget.student['academicId'] ??
        widget.student['student_id'] ??
        widget.student['id'];
    return (raw ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatTeachers = [];
    _loadStudentConversations(showLoading: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureReverbClient().then((_) => _resubscribeToConversationChannels());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    try {
      for (final ch in _conversationChannels.values) {
        try {
          ch.unsubscribe();
        } catch (_) {}
      }
    } catch (_) {}

    _conversationChannels.clear();
    super.dispose();
  }

  Future<void> _loadStudentConversations({required bool showLoading}) async {
    if (_academicId.isEmpty) return;

    if (showLoading && mounted) {
      setState(() => _loadingConversations = true);
    }

    try {
      final convos = await ChatService.fetchStudentConversations(
        academicId: _academicId,
      );

      final teachers = <String, _ChatTeacher>{};
      final meta = <String, _ConversationMeta>{};
      _teacherCodeByConversationId.clear();

      for (final c in convos) {
        if (c is! Map<String, dynamic>) continue;

        final teacher = c['teacher'];
        if (teacher is! Map<String, dynamic>) continue;

        final String teacherCode =
            (teacher['teacher_code'] ?? '').toString().trim();
        if (teacherCode.isEmpty) continue;

        final String teacherName = (teacher['full_name'] ?? '').toString();
        final String? imageUrl = teacher['image'] as String?;

        final dynamic idRaw = c['id'];
        int? conversationId;
        if (idRaw is int) {
          conversationId = idRaw;
        } else if (idRaw is String) {
          conversationId = int.tryParse(idRaw);
        }
        if (conversationId == null) continue;

        final String lastPreview = (c['last_message'] ?? '').toString();
        final String rawTime = (c['last_message_at'] ?? '').toString();

        final bool isGroup = c['is_group'] == true;
        final String? groupName = c['group_name'];

        final int unread = int.tryParse(
              (c['unread_for_student'] ?? c['unread_count'] ?? '0').toString(),
            ) ??
            0;

        final DateTime? lastAt = _parseUtcDate(rawTime);
        final String timeLabel = rawTime.isEmpty
            ? ''
            : _formatTimeLabel(rawTime, forConversation: true);

        teachers[teacherCode] = _ChatTeacher(
          teacherCode: teacherCode,
          name: teacherName,
          imageUrl: imageUrl,
          raw: teacher,
        );

        meta[teacherCode] = _ConversationMeta(
          conversationId: conversationId,
          lastMessagePreview: lastPreview,
          lastMessageTimeLabel: timeLabel,
          lastMessageAt: lastAt,
          unreadCount: unread,
          isGroup: isGroup,
          groupName: groupName,
        );

        _teacherCodeByConversationId[conversationId] = teacherCode;
      }

      final list = teachers.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _chatTeachers = list;
        _metaByTeacherCode
          ..clear()
          ..addAll(meta);
      });

      await _ensureReverbClient();
      await _resubscribeToConversationChannels();
    } catch (e) {
      debugPrint('Failed to load student conversations: $e');

      if (showLoading && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load conversations: $e',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    } finally {
      if (showLoading && mounted) {
        setState(() => _loadingConversations = false);
      }
    }
  }

  Future<void> _ensureReverbClient() async {
    if (_reverbClient != null) return;

    try {
      _reverbClient = await ReverbService.getStudentClient(
        academicId: _academicId,
        port: 8080,
      );
    } catch (e) {
      debugPrint('StudentMessagesScreen: Failed to init ReverbClient: $e');
    }
  }

  Future<void> _subscribeToConversationChannel(int conversationId) async {
    await _ensureReverbClient();
    if (_reverbClient == null) return;

    if (_conversationChannels.containsKey(conversationId)) return;

    try {
      final channelName = 'private-conversation.$conversationId';
      final ch = _reverbClient!.subscribeToChannel(channelName);

      ch.stream.listen(
        (ChannelEvent event) {
          _handleConversationChannelEvent(conversationId, event);
        },
        onError: (e) {
          debugPrint(
            'StudentMessagesScreen: error on channel $conversationId: $e',
          );
        },
      );

      ch.subscribe();
      _conversationChannels[conversationId] = ch;
    } catch (e) {
      debugPrint(
        'StudentMessagesScreen: failed to subscribe to conv $conversationId: $e',
      );
    }
  }

  Future<void> _resubscribeToConversationChannels() async {
    final neededConversationIds = <int>{};
    for (final meta in _metaByTeacherCode.values) {
      neededConversationIds.add(meta.conversationId);
    }

    final toRemove = _conversationChannels.keys
        .where((id) => !neededConversationIds.contains(id))
        .toList();

    for (final id in toRemove) {
      try {
        _conversationChannels[id]?.unsubscribe();
      } catch (_) {}
      _conversationChannels.remove(id);
    }

    for (final id in neededConversationIds) {
      if (!_conversationChannels.containsKey(id)) {
        await _subscribeToConversationChannel(id);
      }
    }
  }

  void _handleConversationChannelEvent(int conversationId, ChannelEvent event) {
    if (!_isMessageSentEvent(event.eventName)) return;

    try {
      dynamic raw = event.data;
      Map<String, dynamic> payload;

      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        } else {
          return;
        }
      } else if (raw is Map<String, dynamic>) {
        payload = raw;
      } else if (raw is Map) {
        payload = Map<String, dynamic>.from(raw);
      } else {
        return;
      }

      final dynamic messageRaw = payload['message'] ?? payload['msg'] ?? payload;
      final dynamic convoRaw = payload['conversation'] ?? payload['conv'];

      if (messageRaw is! Map) return;

      final msg = Map<String, dynamic>.from(messageRaw as Map);

      final conv = (convoRaw is Map)
          ? Map<String, dynamic>.from(convoRaw as Map)
          : <String, dynamic>{};

      final senderType = (msg['sender_type'] ?? '').toString();

      final String? teacherCode = _teacherCodeByConversationId[conversationId];
      if (teacherCode == null || teacherCode.isEmpty) return;

      final String lastPreview =
          (conv['last_message'] ?? msg['body'] ?? '').toString();

      final String lastTimeRaw =
          (conv['last_message_at'] ?? msg['sent_at'] ?? '').toString();

      final DateTime? lastAt = _parseUtcDate(lastTimeRaw);
      final String timeLabel = lastTimeRaw.isEmpty
          ? ''
          : _formatTimeLabel(lastTimeRaw, forConversation: true);

      final isOpen = _StudentChatState.currentConversationId == conversationId;

      int unreadClient;
      if (isOpen) {
        unreadClient = 0;
      } else if (senderType == 'student') {
        unreadClient = 0;
      } else {
        final serverUnread = int.tryParse(
              (conv['unread_for_student'] ?? conv['unread_count'] ?? '')
                  .toString(),
            ) ??
            0;

        final prev = _metaByTeacherCode[teacherCode]?.unreadCount ?? 0;
        unreadClient = serverUnread > 0 ? serverUnread : (prev + 1);
      }

      if (!mounted) return;
      setState(() {
        final old = _metaByTeacherCode[teacherCode];

        _metaByTeacherCode[teacherCode] = _ConversationMeta(
          conversationId: old?.conversationId ?? conversationId,
          lastMessagePreview: lastPreview.isNotEmpty
              ? lastPreview
              : (old?.lastMessagePreview ?? ''),
          lastMessageTimeLabel: timeLabel.isNotEmpty
              ? timeLabel
              : (old?.lastMessageTimeLabel ?? ''),
          lastMessageAt: lastAt ?? old?.lastMessageAt,
          unreadCount: unreadClient,
          isGroup: old?.isGroup ?? false,
          groupName: old?.groupName,
        );
      });
    } catch (e) {
      debugPrint(
        'StudentMessagesScreen: failed to handle conversation event: $e',
      );
    }
  }

  Future<void> _openChatForTeacher(_ChatTeacher t) async {
    int? conversationId = _metaByTeacherCode[t.teacherCode]?.conversationId;

    if (conversationId == null) {
      try {
        final conv = await ChatService.openStudentConversation(
          academicId: _academicId,
          teacherCode: t.teacherCode,
          classSectionId: null,
          subjectId: null,
        );

        final dynamic idRaw = conv['id'];
        if (idRaw is int) {
          conversationId = idRaw;
        } else if (idRaw is String) {
          conversationId = int.tryParse(idRaw);
        }

        if (conversationId == null) {
          throw Exception('Invalid conversation id');
        }

        final String lastPreview = (conv['last_message'] ?? '').toString();
        final String rawTime = (conv['last_message_at'] ?? '').toString();
        final DateTime? lastAt = _parseUtcDate(rawTime);
        final String timeLabel = rawTime.isEmpty
            ? ''
            : _formatTimeLabel(rawTime, forConversation: true);

        if (!mounted) return;
        setState(() {
          _metaByTeacherCode[t.teacherCode] = _ConversationMeta(
            conversationId: conversationId!,
            lastMessagePreview: lastPreview,
            lastMessageTimeLabel: timeLabel,
            lastMessageAt: lastAt,
            unreadCount: int.tryParse(
                  (conv['unread_for_student'] ?? conv['unread_count'] ?? '0')
                      .toString(),
                ) ??
                0,
          );
          _teacherCodeByConversationId[conversationId!] = t.teacherCode;
        });

        await _subscribeToConversationChannel(conversationId!);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
        return;
      }
    }

    _StudentChatState.currentConversationId = conversationId;

    final meta = _metaByTeacherCode[t.teacherCode];
    if (meta != null && (meta.unreadCount ?? 0) > 0) {
      if (!mounted) return;
      setState(() {
        _metaByTeacherCode[t.teacherCode] = _ConversationMeta(
          conversationId: meta.conversationId,
          lastMessagePreview: meta.lastMessagePreview,
          lastMessageTimeLabel: meta.lastMessageTimeLabel,
          lastMessageAt: meta.lastMessageAt,
          unreadCount: 0,
          isGroup: meta.isGroup,
          groupName: meta.groupName,
        );
      });
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentChatScreen(
          student: widget.student,
          teacher: t.raw,
          conversationId: conversationId!,
          isGroup: meta?.isGroup ?? false,
        ),
      ),
    );

    if (_StudentChatState.currentConversationId == conversationId) {
      _StudentChatState.currentConversationId = null;
    }

    await _loadStudentConversations(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = theme.colorScheme.onSurface;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final headerBoxColor = theme.cardColor;
    final headerShadow = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x12000000);

    final List<_ChatTeacher> orderedTeachers = List<_ChatTeacher>.from(
      _chatTeachers,
    );

    orderedTeachers.sort((a, b) {
      final ma = _metaByTeacherCode[a.teacherCode];
      final mb = _metaByTeacherCode[b.teacherCode];

      final da = ma?.lastMessageAt;
      final db = mb?.lastMessageAt;

      if (da != null && db != null) return db.compareTo(da);
      if (da != null) return -1;
      if (db != null) return 1;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          'Messages',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        actions: [
          if (_loadingConversations)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: () => _loadStudentConversations(showLoading: true),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: headerBoxColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: headerShadow,
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDark
                        ? EduTheme.darkSurface
                        : const Color(0xFFE8F3FF),
                    child: Text(
                      _studentFullName.trim().isNotEmpty
                          ? _studentFullName.trim()[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentFullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Your conversations with teachers',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: orderedTeachers.isEmpty
                ? const _EmptyConversationsState()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: orderedTeachers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final t = orderedTeachers[index];
                      final meta = _metaByTeacherCode[t.teacherCode];

                      final isGroup = meta?.isGroup ?? false;
                      final displayName =
                          isGroup ? (meta?.groupName ?? 'Class Group') : t.name;

                      final avatarText = displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?';

                      final subtitle =
                          isGroup ? 'Teacher: ${t.name}' : 'Personal chat';

                      final displayPreview =
                          (meta?.lastMessagePreview?.isNotEmpty ?? false)
                          ? meta!.lastMessagePreview!
                          : subtitle;

                      final displayTime = meta?.lastMessageTimeLabel ?? '';

                      final unreadCount =
                          (meta?.unreadCount != null && meta!.unreadCount! > 0)
                          ? meta.unreadCount
                          : null;

                      final avatarImageUrl =
                          (!isGroup &&
                              t.imageUrl != null &&
                              t.imageUrl!.isNotEmpty)
                          ? ApiHelpers.buildFullMediaUrl(t.imageUrl!)
                          : null;

                      return _MessageItem(
                        avatarText: avatarText,
                        avatarImageUrl: avatarImageUrl,
                        name: displayName,
                        preview: displayPreview,
                        metaLine: subtitle,
                        time: displayTime,
                        unreadCount: unreadCount,
                        isGroup: isGroup,
                        onTap: () => _openChatForTeacher(t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatTeacher {
  final String teacherCode;
  final String name;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  _ChatTeacher({
    required this.teacherCode,
    required this.name,
    required this.imageUrl,
    required this.raw,
  });
}

class _ConversationMeta {
  final int conversationId;
  final String? lastMessagePreview;
  final String? lastMessageTimeLabel;
  final DateTime? lastMessageAt;
  final int? unreadCount;
  final bool isGroup;
  final String? groupName;

  _ConversationMeta({
    required this.conversationId,
    this.lastMessagePreview,
    this.lastMessageTimeLabel,
    this.lastMessageAt,
    this.unreadCount,
    this.isGroup = false,
    this.groupName,
  });
}

class _EmptyConversationsState extends StatelessWidget {
  const _EmptyConversationsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No conversations yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your conversations with teachers will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final String avatarText;
  final String? avatarImageUrl;
  final String name;
  final String preview;
  final String metaLine;
  final String time;
  final int? unreadCount;
  final bool isGroup;
  final VoidCallback? onTap;

  const _MessageItem({
    required this.avatarText,
    required this.name,
    required this.preview,
    required this.metaLine,
    required this.time,
    this.avatarImageUrl,
    this.unreadCount,
    this.isGroup = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool hasUnread = unreadCount != null && unreadCount! > 0;

    final titleColor = theme.colorScheme.onSurface;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.14)
        : const Color(0x10000000);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: hasUnread
                  ? theme.colorScheme.primary.withValues(alpha: 0.20)
                  : theme.dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isGroup
                        ? Colors.deepPurple.withValues(alpha: 0.12)
                        : theme.colorScheme.primary.withValues(alpha: 0.10),
                    backgroundImage: avatarImageUrl != null
                        ? NetworkImage(avatarImageUrl!)
                        : null,
                    child: avatarImageUrl == null
                        ? Text(
                            avatarText,
                            style: GoogleFonts.nunito(
                              color: isGroup
                                  ? Colors.deepPurple
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  if (isGroup)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.group,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: GoogleFonts.nunito(
                              color: hasUnread
                                  ? theme.colorScheme.primary
                                  : mutedColor,
                              fontSize: 11,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      metaLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: hasUnread ? titleColor : mutedColor,
                        fontSize: 13,
                        fontWeight:
                            hasUnread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 10),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount! > 99 ? '99+' : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ==================== شاشة محادثة الطالب مع أستاذ معيّن ====================

class StudentChatScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> teacher;
  final int conversationId;
  final bool isGroup;

  const StudentChatScreen({
    super.key,
    required this.student,
    required this.teacher,
    required this.conversationId,
    this.isGroup = false,
  });

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen>
    with WidgetsBindingObserver {
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = {};

  bool _loading = false;
  bool _initialLoaded = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ReverbClient? _reverbClient;
  Channel? _channel;

  String get _academicId => (widget.student['academic_id'] ??
          widget.student['academicId'] ??
          widget.student['student_id'] ??
          widget.student['id'] ??
          '')
      .toString();

  String get _teacherName => (widget.teacher['full_name'] ?? '').toString();
  String? get _teacherImage => (widget.teacher['image'] as String?)?.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _StudentChatState.currentConversationId = widget.conversationId;
    _loadMessages();
    _initReverb();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initReverb();
    }
  }

  Future<void> _loadMessages() async {
    if (_academicId.isEmpty) return;

    setState(() => _loading = true);

    try {
      final msgs = await ChatService.fetchConversationMessagesAsStudent(
        conversationId: widget.conversationId,
        academicId: _academicId,
      );

      _messages.clear();
      _messageIds.clear();

      for (final m in msgs) {
        if (m is! Map<String, dynamic>) continue;

        final idStr = (m['id'] ?? '').toString();
        if (idStr.isEmpty) continue;

        if (_messageIds.contains(idStr)) continue;

        _messageIds.add(idStr);
        _messages.add(m);
      }

      if (!mounted) return;
      setState(() => _initialLoaded = true);
      _scrollToBottom(jump: true);
    } catch (e) {
      debugPrint('Failed to load messages: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initReverb() async {
    if (_academicId.isEmpty) return;

    try {
      _reverbClient = await ReverbService.getStudentClient(
        academicId: _academicId,
        port: 8080,
      );

      final channelName = 'private-conversation.${widget.conversationId}';

      try {
        _channel?.unsubscribe();
      } catch (_) {}
      _channel = null;

      _channel = _reverbClient!.subscribeToChannel(channelName);

      _channel!.stream.listen(
        (ChannelEvent event) {
          if (!_isMessageSentEvent(event.eventName)) return;

          try {
            dynamic raw = event.data;
            Map<String, dynamic> payload;

            if (raw is String) {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) {
                payload = decoded;
              } else if (decoded is Map) {
                payload = Map<String, dynamic>.from(decoded);
              } else {
                return;
              }
            } else if (raw is Map<String, dynamic>) {
              payload = raw;
            } else if (raw is Map) {
              payload = Map<String, dynamic>.from(raw);
            } else {
              return;
            }

            final dynamic maybeMessage = payload['message'] ?? payload;
            if (maybeMessage is! Map) return;

            final msg = Map<String, dynamic>.from(maybeMessage as Map);
            final idStr = (msg['id'] ?? '').toString();

            if (idStr.isNotEmpty && _messageIds.contains(idStr)) return;

            if (!mounted) return;
            setState(() {
              if (idStr.isNotEmpty) _messageIds.add(idStr);
              _messages.add(msg);
            });

            _scrollToBottom();
          } catch (e) {
            debugPrint('Failed to handle websocket message: $e');
          }
        },
        onError: (e) {
          debugPrint('StudentChatScreen: channel error: $e');
        },
      );

      _channel!.subscribe();
    } catch (e) {
      debugPrint('Failed to init ReverbClient: $e');
    }
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final text = (overrideText ?? _textController.text).trim();
    if (text.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'body': text,
      'sender_type': 'student',
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      'is_temp': true,
    };

    if (mounted) {
      setState(() {
        _messageIds.add(tempId);
        _messages.add(tempMsg);
      });
      _textController.clear();
      _scrollToBottom();
    }

    try {
      final sent = await ChatService.sendMessageAsStudent(
        conversationId: widget.conversationId,
        academicId: _academicId,
        messageBody: text,
      );

      final idStr = (sent['id'] ?? '').toString();

      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
        _messageIds.remove(tempId);

        if (idStr.isNotEmpty && !_messageIds.contains(idStr)) {
          _messageIds.add(idStr);
          _messages.add(sent);
        }
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
        _messageIds.remove(tempId);
        _textController.text = text;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في إرسال الرسالة: $e',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent + 80;
      if (jump) {
        _scrollController.jumpTo(
          target.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
        );
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (_StudentChatState.currentConversationId == widget.conversationId) {
      _StudentChatState.currentConversationId = null;
    }

    _textController.dispose();
    _scrollController.dispose();

    try {
      _channel?.unsubscribe();
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final avatarUrl = _teacherImage != null && _teacherImage!.isNotEmpty
        ? ApiHelpers.buildFullMediaUrl(_teacherImage!)
        : null;

    final titleColor = theme.colorScheme.onSurface;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.isGroup
                      ? Colors.deepPurple.withValues(alpha: 0.12)
                      : theme.colorScheme.primary.withValues(alpha: 0.10),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Icon(
                          widget.isGroup ? Icons.group : Icons.person,
                          color: widget.isGroup
                              ? Colors.deepPurple
                              : theme.colorScheme.primary,
                          size: 20,
                        )
                      : null,
                ),
                if (widget.isGroup)
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _teacherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    widget.isGroup ? 'Group conversation' : 'Direct conversation',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && !_initialLoaded
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _messages.isEmpty
                ? const _EmptyChatState()
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final senderType = (m['sender_type'] ?? '').toString();
                      final isMe = senderType == 'student';

                      final body = (m['body'] ?? '').toString();
                      final time = (m['sent_at'] ?? '').toString();
                      final timeLabel = time.isEmpty ? '' : _formatTimeLabel(time);

                      final currentDate = _parseUtcDate(time)?.toLocal();
                      final previousTime = index > 0
                          ? (_messages[index - 1]['sent_at'] ?? '').toString()
                          : '';
                      final previousDate = _parseUtcDate(previousTime)?.toLocal();

                      final showDateDivider =
                          currentDate != null &&
                          (index == 0 ||
                              previousDate == null ||
                              !_isSameCalendarDate(currentDate, previousDate));

                      return Column(
                        children: [
                          if (showDateDivider)
                            _DateDivider(
                              label: _formatDateDivider(currentDate),
                            ),
                          _ChatBubble(
                            isMe: isMe,
                            text: body,
                            timeLabel: timeLabel,
                            senderName: widget.isGroup
                                ? (m['sender_name'] ?? (isMe ? null : 'Teacher'))
                                : null,
                            isTemp: m['is_temp'] == true,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inputFill = isDark ? EduTheme.darkSurface : Colors.white;
    final borderColor = theme.dividerColor.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
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
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  cursorColor: theme.colorScheme.primary,
                  style: GoogleFonts.nunito(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write a message...',
                    hintStyle: GoogleFonts.nunito(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: canSend ? 1 : 0.55,
                  child: GestureDetector(
                    onTap: canSend ? _sendMessage : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_chat_unread_rounded,
                color: theme.colorScheme.primary,
                size: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'No messages yet',
                style: GoogleFonts.nunito(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start the conversation by sending your first message.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String label;

  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String timeLabel;
  final String? senderName;
  final bool isTemp;

  const _ChatBubble({
    required this.isMe,
    required this.text,
    required this.timeLabel,
    this.senderName,
    this.isTemp = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : theme.cardColor;

    final textColor = isMe ? Colors.white : theme.colorScheme.onSurface;
    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.78)
        : theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: isTemp ? 0.72 : 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 18),
              ),
              border: Border.all(
                color: isMe
                    ? theme.colorScheme.primary.withValues(alpha: 0.20)
                    : theme.dividerColor.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (senderName != null && !isMe) ...[
                  Text(
                    senderName!,
                    style: GoogleFonts.nunito(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: GoogleFonts.nunito(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTemp ? 'Sending...' : timeLabel,
                      style: GoogleFonts.nunito(
                        color: timeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isTemp && isMe) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 9,
                        height: 9,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.2,
                          color: Colors.white.withValues(alpha: 0.8),
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
    );
  }
}