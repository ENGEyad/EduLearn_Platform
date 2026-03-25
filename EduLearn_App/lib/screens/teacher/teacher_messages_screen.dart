import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../theme.dart';
import '../../services/chat_service.dart';
import '../../services/api_helpers.dart';
import '../../services/reverb_service.dart';

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

/// ✅ Helper: فلترة مرنة لأسماء أحداث Reverb/Pusher
bool _isMessageSentEvent(String name) {
  final n = name.trim();
  return n == 'message.sent' ||
      n == '.message.sent' ||
      n.endsWith('MessageSent') ||
      n.contains('MessageSent');
}

/// ======================================================================
///  ✅ State عام: المحادثة المفتوحة حالياً (للأستاذ)
/// ======================================================================
class _TeacherChatState {
  static int? currentConversationId;
}

/// ==================== شاشة قائمة محادثات الأستاذ ====================

class TeacherMessagesScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final List<dynamic> assignments;
  final int totalAssignedStudents;

  const TeacherMessagesScreen({
    super.key,
    required this.teacher,
    required this.assignments,
    required this.totalAssignedStudents,
  });

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen>
    with WidgetsBindingObserver {
  late List<_ChatStudent> _chatStudents;
  bool _loadingConversations = false;

  final Map<String, _ConversationMeta> _metaByAcademicId = {};
  final Map<int, String> _academicIdByConversationId = {};

  ReverbClient? _reverbClient;
  final Map<int, Channel> _conversationChannels = {};

  String get _teacherFullName => (widget.teacher['full_name'] ?? '').toString();
  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString();
  String? get _teacherImage => (widget.teacher['image'] as String?)?.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatStudents = _extractChatStudents();
    _loadTeacherConversations(showLoading: true);
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

  List<_ChatStudent> _extractChatStudents() {
    final Map<String, _ChatStudent> byId = {};

    for (final a in widget.assignments) {
      if (a is! Map<String, dynamic>) continue;

      final String grade = (a['class_grade'] ?? '').toString();
      final String section = (a['class_section'] ?? '').toString();

      final students = a['students'];
      if (students is! List) continue;

      for (final s in students) {
        if (s is! Map<String, dynamic>) continue;

        final String id =
            (s['id'] ?? s['student_id'] ?? s['academic_id'] ?? '').toString();
        if (id.isEmpty) continue;
        if (byId.containsKey(id)) continue;

        final String name = (s['full_name'] ?? '').toString();
        final String academicId = (s['academic_id'] ?? '').toString();
        final String? imageUrl = s['image'] as String?;

        byId[id] = _ChatStudent(
          id: id,
          name: name,
          academicId: academicId,
          imageUrl: imageUrl,
          grade: grade,
          section: section,
          raw: s,
        );
      }
    }

    final list = byId.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> _loadTeacherConversations({required bool showLoading}) async {
    if (_teacherCode.isEmpty) return;

    if (showLoading && mounted) {
      setState(() => _loadingConversations = true);
    }

    try {
      final convos =
          await ChatService.fetchTeacherConversations(teacherCode: _teacherCode);

      final map = <String, _ConversationMeta>{};
      _academicIdByConversationId.clear();

      for (final c in convos) {
        if (c is! Map<String, dynamic>) continue;

        final student = c['student'];
        if (student is! Map<String, dynamic>) continue;

        final String academicId =
            (student['academic_id'] ?? '').toString().trim();
        if (academicId.isEmpty) continue;

        final dynamic idRaw = c['id'];
        int? conversationId;
        if (idRaw is int) {
          conversationId = idRaw;
        } else if (idRaw is String) {
          conversationId = int.tryParse(idRaw);
        }
        if (conversationId == null) continue;

        final String lastPreview = (c['last_message'] ?? '').toString();
        final String lastTimeRaw = (c['last_message_at'] ?? '').toString();

        final int unread = int.tryParse(
              (c['unread_for_teacher'] ?? c['unread_count'] ?? '0').toString(),
            ) ??
            0;

        final DateTime? lastAt = _parseUtcDate(lastTimeRaw);
        final String timeLabel = lastTimeRaw.isEmpty
            ? ''
            : _formatTimeLabel(lastTimeRaw, forConversation: true);

        _academicIdByConversationId[conversationId] = academicId;

        map[academicId] = _ConversationMeta(
          conversationId: conversationId,
          lastMessagePreview: lastPreview,
          lastMessageTimeLabel: timeLabel,
          lastMessageAt: lastAt,
          unreadCount: unread,
        );
      }

      if (!mounted) return;
      setState(() {
        _metaByAcademicId
          ..clear()
          ..addAll(map);
      });

      await _ensureReverbClient();
      await _resubscribeToConversationChannels();
    } catch (e) {
      debugPrint('Failed to load teacher conversations: $e');
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
      _reverbClient = await ReverbService.getTeacherClient(
        teacherCode: _teacherCode,
        port: 8080,
      );
    } catch (e) {
      debugPrint('TeacherMessagesScreen: Failed to init Reverb client: $e');
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
            'TeacherMessagesScreen: error on channel $conversationId: $e',
          );
        },
      );

      ch.subscribe();
      _conversationChannels[conversationId] = ch;
    } catch (e) {
      debugPrint(
        'TeacherMessagesScreen: failed to subscribe to conv $conversationId: $e',
      );
    }
  }

  Future<void> _resubscribeToConversationChannels() async {
    final neededConversationIds = <int>{};
    for (final meta in _metaByAcademicId.values) {
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

      final String? academicId = _academicIdByConversationId[conversationId];
      if (academicId == null || academicId.isEmpty) return;

      final String lastPreview =
          (conv['last_message'] ?? msg['body'] ?? '').toString();

      final String lastTimeRaw =
          (conv['last_message_at'] ?? msg['sent_at'] ?? '').toString();

      final DateTime? lastAt = _parseUtcDate(lastTimeRaw);
      final String timeLabel = lastTimeRaw.isEmpty
          ? ''
          : _formatTimeLabel(lastTimeRaw, forConversation: true);

      final isOpen = _TeacherChatState.currentConversationId == conversationId;

      int unreadClient;
      if (isOpen) {
        unreadClient = 0;
      } else if (senderType == 'teacher') {
        unreadClient = 0;
      } else {
        final serverUnread = int.tryParse(
              (conv['unread_for_teacher'] ?? conv['unread_count'] ?? '')
                  .toString(),
            ) ??
            0;

        final prev = _metaByAcademicId[academicId]?.unreadCount ?? 0;
        unreadClient = serverUnread > 0 ? serverUnread : (prev + 1);
      }

      if (!mounted) return;
      setState(() {
        final old = _metaByAcademicId[academicId];

        _metaByAcademicId[academicId] = _ConversationMeta(
          conversationId: old?.conversationId ?? conversationId,
          lastMessagePreview: lastPreview.isNotEmpty
              ? lastPreview
              : (old?.lastMessagePreview ?? ''),
          lastMessageTimeLabel: timeLabel.isNotEmpty
              ? timeLabel
              : (old?.lastMessageTimeLabel ?? ''),
          lastMessageAt: lastAt ?? old?.lastMessageAt,
          unreadCount: unreadClient,
        );
      });
    } catch (e) {
      debugPrint('TeacherMessagesScreen: failed to handle event: $e');
    }
  }

  Future<void> _openChatForStudent(_ChatStudent s) async {
    int? conversationId = _metaByAcademicId[s.academicId]?.conversationId;

    if (conversationId == null) {
      try {
        final conv = await ChatService.openTeacherConversation(
          teacherCode: _teacherCode,
          academicId: s.academicId,
          classSectionId: s.raw['class_section_id'] is int
              ? s.raw['class_section_id'] as int
              : int.tryParse((s.raw['class_section_id'] ?? '').toString()),
          subjectId: null,
        );

        final dynamic idRaw = conv['id'];
        if (idRaw is int) {
          conversationId = idRaw;
        } else if (idRaw is String) {
          conversationId = int.tryParse(idRaw);
        }
        if (conversationId == null) throw Exception('Invalid conversation id');

        final String lastPreview = (conv['last_message'] ?? '').toString();
        final String lastTimeRaw = (conv['last_message_at'] ?? '').toString();
        final DateTime? lastAt = _parseUtcDate(lastTimeRaw);
        final String timeLabel = lastTimeRaw.isNotEmpty
            ? _formatTimeLabel(lastTimeRaw, forConversation: true)
            : '';

        if (!mounted) return;
        setState(() {
          _metaByAcademicId[s.academicId] = _ConversationMeta(
            conversationId: conversationId!,
            lastMessagePreview: lastPreview,
            lastMessageTimeLabel: timeLabel,
            lastMessageAt: lastAt,
            unreadCount: int.tryParse(
                  (conv['unread_for_teacher'] ?? conv['unread_count'] ?? '0')
                      .toString(),
                ) ??
                0,
          );
          _academicIdByConversationId[conversationId!] = s.academicId;
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

    _TeacherChatState.currentConversationId = conversationId;

    final meta = _metaByAcademicId[s.academicId];
    if (meta != null && (meta.unreadCount ?? 0) > 0) {
      if (!mounted) return;
      setState(() {
        _metaByAcademicId[s.academicId] = _ConversationMeta(
          conversationId: meta.conversationId,
          lastMessagePreview: meta.lastMessagePreview,
          lastMessageTimeLabel: meta.lastMessageTimeLabel,
          lastMessageAt: meta.lastMessageAt,
          unreadCount: 0,
        );
      });
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherChatScreen(
          teacher: widget.teacher,
          student: s.raw,
          grade: s.grade,
          section: s.section,
          conversationId: conversationId!,
        ),
      ),
    );

    if (_TeacherChatState.currentConversationId == conversationId) {
      _TeacherChatState.currentConversationId = null;
    }

    await _loadTeacherConversations(showLoading: false);
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

    final List<_ChatStudent> orderedStudents = List<_ChatStudent>.from(
      _chatStudents,
    );

    orderedStudents.sort((a, b) {
      final ma = _metaByAcademicId[a.academicId];
      final mb = _metaByAcademicId[b.academicId];

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
              onPressed: () => _loadTeacherConversations(showLoading: true),
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
                      _teacherFullName.trim().isNotEmpty
                          ? _teacherFullName.trim()[0].toUpperCase()
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
                          _teacherFullName,
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
                          'Your conversations with students',
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
            child: orderedStudents.isEmpty
                ? const _EmptyConversationsState()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: orderedStudents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final s = orderedStudents[index];

                      final avatarText =
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : '?';

                      final subtitleParts = <String>[];
                      if (s.grade != null && s.grade!.isNotEmpty) {
                        subtitleParts.add('Grade ${s.grade}');
                      }
                      if (s.section != null && s.section!.isNotEmpty) {
                        subtitleParts.add('Section ${s.section}');
                      }
                      if (s.academicId.isNotEmpty) {
                        subtitleParts.add('#${s.academicId}');
                      }
                      final fallbackSubtitle = subtitleParts.join(' • ');

                      final meta = _metaByAcademicId[s.academicId];

                      final displayPreview =
                          (meta?.lastMessagePreview?.isNotEmpty ?? false)
                          ? meta!.lastMessagePreview!
                          : fallbackSubtitle;

                      final displayTime = meta?.lastMessageTimeLabel ?? '';

                      final unreadCount =
                          (meta?.unreadCount != null && meta!.unreadCount! > 0)
                          ? meta.unreadCount
                          : null;

                      final avatarImageUrl =
                          (s.imageUrl != null && s.imageUrl!.isNotEmpty)
                          ? ApiHelpers.buildFullMediaUrl(s.imageUrl!)
                          : null;

                      return _MessageItem(
                        avatarText: avatarText,
                        avatarImageUrl: avatarImageUrl,
                        name: s.name.isNotEmpty ? s.name : s.academicId,
                        preview: displayPreview,
                        metaLine: fallbackSubtitle,
                        time: displayTime,
                        unreadCount: unreadCount,
                        onTap: () => _openChatForStudent(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// موديل بسيط للطالب في شاشة الدردشات
class _ChatStudent {
  final String id;
  final String name;
  final String academicId;
  final String? imageUrl;
  final String? grade;
  final String? section;
  final Map<String, dynamic> raw;

  _ChatStudent({
    required this.id,
    required this.name,
    required this.academicId,
    required this.imageUrl,
    required this.grade,
    required this.section,
    required this.raw,
  });
}

class _ConversationMeta {
  final int conversationId;
  final String? lastMessagePreview;
  final String? lastMessageTimeLabel;
  final DateTime? lastMessageAt;
  final int? unreadCount;

  _ConversationMeta({
    required this.conversationId,
    this.lastMessagePreview,
    this.lastMessageTimeLabel,
    this.lastMessageAt,
    this.unreadCount,
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
                'Student conversations will appear here once available.',
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
  final VoidCallback? onTap;

  const _MessageItem({
    required this.avatarText,
    required this.name,
    required this.preview,
    required this.metaLine,
    required this.time,
    this.avatarImageUrl,
    this.unreadCount,
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
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                backgroundImage: avatarImageUrl != null
                    ? NetworkImage(avatarImageUrl!)
                    : null,
                child: avatarImageUrl == null
                    ? Text(
                        avatarText,
                        style: GoogleFonts.nunito(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      )
                    : null,
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
                    if (metaLine.isNotEmpty) ...[
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
                    ],
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

/// ==================== شاشة محادثة الأستاذ مع طالب معيّن ====================

class TeacherChatScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final Map<String, dynamic> student;
  final String? grade;
  final String? section;
  final int conversationId;

  const TeacherChatScreen({
    super.key,
    required this.teacher,
    required this.student,
    this.grade,
    this.section,
    required this.conversationId,
  });

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen>
    with WidgetsBindingObserver {
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = {};

  bool _loading = false;
  bool _initialLoaded = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ReverbClient? _reverbClient;
  Channel? _channel;

  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString();

  String get _studentName => (widget.student['full_name'] ?? '').toString();
  String get _academicId => (widget.student['academic_id'] ?? '').toString();
  String? get _studentImage => (widget.student['image'] as String?)?.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _TeacherChatState.currentConversationId = widget.conversationId;
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
    if (_teacherCode.isEmpty) return;

    setState(() => _loading = true);

    try {
      final msgs = await ChatService.fetchConversationMessagesAsTeacher(
        conversationId: widget.conversationId,
        teacherCode: _teacherCode,
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
    if (_teacherCode.isEmpty) return;

    try {
      _reverbClient = await ReverbService.getTeacherClient(
        teacherCode: _teacherCode,
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
            debugPrint('TeacherChatScreen: Failed to handle websocket msg: $e');
          }
        },
        onError: (e) {
          debugPrint('TeacherChatScreen: channel error: $e');
        },
      );

      _channel!.subscribe();
    } catch (e) {
      debugPrint('TeacherChatScreen: Failed to init reverb: $e');
    }
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final text = (overrideText ?? _textController.text).trim();
    if (text.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'body': text,
      'sender_type': 'teacher',
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
      final sent = await ChatService.sendMessageAsTeacher(
        conversationId: widget.conversationId,
        teacherCode: _teacherCode,
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
            'فشل الإرسال: $e',
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

    if (_TeacherChatState.currentConversationId == widget.conversationId) {
      _TeacherChatState.currentConversationId = null;
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

    final subtitleParts = <String>[];
    if (widget.grade != null && widget.grade!.isNotEmpty) {
      subtitleParts.add('Grade: ${widget.grade}');
    }
    if (widget.section != null && widget.section!.isNotEmpty) {
      subtitleParts.add('Section: ${widget.section}');
    }
    if (_academicId.isNotEmpty) {
      subtitleParts.add('ID: $_academicId');
    }
    final subtitle = subtitleParts.join(' • ');

    final avatarUrl = _studentImage != null && _studentImage!.isNotEmpty
        ? ApiHelpers.buildFullMediaUrl(_studentImage!)
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
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _studentName.isNotEmpty ? _studentName : _academicId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      final isTeacher = senderType == 'teacher';

                      final body = (m['body'] ?? '').toString();
                      final createdAtRaw = (m['sent_at'] ?? '').toString();
                      final createdTimeLabel = createdAtRaw.isEmpty
                          ? ''
                          : _formatTimeLabel(createdAtRaw);

                      String? dateHeader;
                      final dt = _parseUtcDate(createdAtRaw)?.toLocal();
                      if (dt != null) {
                        bool showHeader = false;
                        if (index == 0) {
                          showHeader = true;
                        } else {
                          final prevRaw =
                              (_messages[index - 1]['sent_at'] ?? '').toString();
                          final prevDt = _parseUtcDate(prevRaw)?.toLocal();
                          if (prevDt == null ||
                              !_isSameCalendarDate(prevDt, dt)) {
                            showHeader = true;
                          }
                        }

                        if (showHeader) {
                          dateHeader = _formatDateDivider(dt);
                        }
                      }

                      return Column(
                        children: [
                          if (dateHeader != null) _DateChip(label: dateHeader),
                          _ChatBubble(
                            isMe: isTeacher,
                            text: body,
                            timeLabel: createdTimeLabel,
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
                    hintText: 'Type a message...',
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

class _DateChip extends StatelessWidget {
  final String label;

  const _DateChip({required this.label});

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
  final bool isTemp;

  const _ChatBubble({
    required this.isMe,
    required this.text,
    required this.timeLabel,
    this.isTemp = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe ? theme.colorScheme.primary : theme.cardColor;
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
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
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