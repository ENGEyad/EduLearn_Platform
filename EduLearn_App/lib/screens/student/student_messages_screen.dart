import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../theme.dart';

// ✅ APIs
import '../../services/chat_service.dart';
import '../../services/api_helpers.dart';

// ✅ Reverb service (مشترك)
import '../../services/reverb_service.dart';

/// ========= Helpers عامة للتواريخ/الأوقات =========

DateTime? _parseUtcDate(String value) {
  try {
    if (value.trim().isEmpty) return null;
    var v = value.trim();

    // مثلاً لو جاك "2025-12-06 18:20:00" نحولها لصيغة ISO
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

/// دالة عامة لتنسيق الوقت:
/// - forConversation = true  -> تستخدم لشاشة قائمة المحادثات
/// - forConversation = false -> تستخدم لفقاعات الشات داخل المحادثة
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

  /// Reverb
  ReverbClient? _reverbClient;

  /// القنوات المشترك بها (private-conversation.{id})
  final Map<int, Channel> _conversationChannels = {};

  String get _studentFullName => (widget.student['full_name'] ?? '').toString();

  /// نحاول نجيب رقم الطالب من أكثر من key احتياطاً
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
    // ✅ عند الرجوع للتطبيق (أو بعد قطع الشبكة) أعد تثبيت الاشتراكات
    if (state == AppLifecycleState.resumed) {
      _ensureReverbClient().then((_) => _resubscribeToConversationChannels());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // ✅ لا نعمل disconnect هنا (لأننا نستخدم ReverbService كعميل واحد للتطبيق)
    // فقط نفك الاشتراكات.
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

  /// ✅ showLoading=false لتجنب “الدائرة الصغيرة” اللي تشوفها عند الرجوع من المحادثة
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

        // ✅ عادات الطالب: نفضل unread_for_student إن توفر، وإلا fallback على unread_count
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

      // ✅ إذا showLoading=false (بعد الرجوع من المحادثة) لا نزعج المستخدم بسناك بار
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
      if (showLoading && mounted) setState(() => _loadingConversations = false);
    }
  }

  /// ===================== Reverb (Private Channels) =====================

  Future<void> _ensureReverbClient() async {
    if (_reverbClient != null) return;

    try {
      // ✅ عميل واحد عبر ReverbService (الآن فيه await connect داخليًا)
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

      // ✅ listen قبل subscribe
      ch.stream.listen(
        (ChannelEvent event) {
          _handleConversationChannelEvent(conversationId, event);
        },
        onError: (e) {
          debugPrint('StudentMessagesScreen: error on channel $conversationId: $e');
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

      // ✅ unread للطالب:
      // - لو المحادثة مفتوحة -> 0
      // - لو الرسالة من الطالب نفسه -> 0
      // - غير ذلك -> unread_for_student إن وصل من السيرفر، وإلا +1 محلي
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

    // ✅ بدل “reload دائري مزعج” بعد الرجوع:
    // تحديث صامت فقط لضمان الالتقاط لو فاتنا شيء أثناء قطع الشبكة
    await _loadStudentConversations(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final List<_ChatTeacher> orderedTeachers =
        List<_ChatTeacher>.from(_chatTeachers);

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
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MESSAGES',
              style: GoogleFonts.orbitron(
                color: const Color(0xFF00E5FF),
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: 2,
                shadows: [
                  const Shadow(color: Color(0xFF00E5FF), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _studentFullName.toUpperCase(),
              style: GoogleFonts.orbitron(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          if (_loadingConversations)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF00E5FF),
              ),
              onPressed: () => _loadStudentConversations(showLoading: true),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E1A),
              const Color(0xFF161B22),
            ],
          ),
        ),
        child: orderedTeachers.isEmpty
            ? Center(
                child: Text(
                  'NO ACTIVE CHANNELS',
                  style: GoogleFonts.orbitron(
                    color: Colors.white24,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
                itemCount: orderedTeachers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = orderedTeachers[index];
                  final meta = _metaByTeacherCode[t.teacherCode];
                  
                  final isGroup = meta?.isGroup ?? false;
                  final displayName = isGroup ? (meta?.groupName ?? 'Class Group') : t.name;

                  final avatarText = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

                  final subtitle = isGroup ? 'Teacher: ${t.name}' : 'Personal Chat';

                  final displayPreview = (meta?.lastMessagePreview?.isNotEmpty ?? false)
                      ? meta!.lastMessagePreview!
                      : subtitle;

                  final displayTime = meta?.lastMessageTimeLabel ?? '';

                  final unreadCount = (meta?.unreadCount != null && meta!.unreadCount! > 0)
                      ? meta.unreadCount
                      : null;

                  final avatarImageUrl = (!isGroup && t.imageUrl != null && t.imageUrl!.isNotEmpty)
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
    );
  }
}

/// موديل بسيط للأستاذ في شاشة الدردشات
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
    final bool hasUnread = unreadCount != null && unreadCount! > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnread
                ? const Color(0xFF00E5FF).withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isGroup ? const Color(0xFF9C27B0).withOpacity(0.2) : const Color(0xFF00E5FF).withOpacity(0.1),
                  backgroundImage: avatarImageUrl != null ? NetworkImage(avatarImageUrl!) : null,
                  child: avatarImageUrl == null
                      ? Text(
                          avatarText,
                          style: GoogleFonts.orbitron(
                            color: isGroup ? const Color(0xFF9C27B0) : const Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                if (isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF9C27B0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.group, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: GoogleFonts.nunito(
                            color: hasUnread ? const Color(0xFF00E5FF) : Colors.white38,
                            fontSize: 10,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: hasUnread ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 6),
                  ],
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Color(0xFF0A0E1A), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
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

  String get _studentName => (widget.student['full_name'] ?? '').toString();

  String get _teacherName => (widget.teacher['full_name'] ?? '').toString();
  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString();
  String? get _teacherImage =>
      (widget.teacher['image'] as String?)?.toString();

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
    // ✅ عند الرجوع للتطبيق: أعد الاشتراك (في حال انقطع الاتصال)
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

      setState(() => _initialLoaded = true);
      _scrollToBottom();
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

      // ✅ لو كنا مشتركين سابقاً، افصل القديم قبل إعادة الاشتراك (مهم مع reconnect/resume)
      try {
        _channel?.unsubscribe();
      } catch (_) {}
      _channel = null;

      _channel = _reverbClient!.subscribeToChannel(channelName);

      // ✅ listen قبل subscribe
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
        // حذف الرسالة المؤقتة واستبدالها بالرسالة الحقيقية من السيرفر
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

      // في حال الفشل، نحذف الرسالة المؤقتة وننبه المستخدم
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
        _messageIds.remove(tempId);
        _textController.text = text; // إعادة النص للتحكم
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
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

    // ✅ لا نعمل disconnect — فقط unsubscribe لقناة المحادثة
    try {
      _channel?.unsubscribe();
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _teacherImage != null && _teacherImage!.isNotEmpty
        ? ApiHelpers.buildFullMediaUrl(_teacherImage!)
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white10,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Color(0xFF00E5FF), size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _teacherName,
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'SECURE CHANNEL',
                    style: GoogleFonts.orbitron(
                      fontSize: 8,
                      color: const Color(0xFF00E5FF),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF00E5FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF0F172A)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _loading && !_initialLoaded
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 100, left: 12, right: 12, bottom: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        final senderType = (m['sender_type'] ?? '').toString();
                        final isMe = senderType == 'student';

                        final body = (m['body'] ?? '').toString();
                        final time = (m['sent_at'] ?? '').toString();
                        final timeLabel = time.isEmpty ? '' : _formatTimeLabel(time);

                        return _ChatBubble(
                          isMe: isMe,
                          text: body,
                          timeLabel: timeLabel,
                          senderName: widget.isGroup ? (m['sender_name'] ?? (isMe ? null : 'Teacher')) : null,
                          isTemp: m['is_temp'] == true,
                        );
                      },
                    ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Encrypt data...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)]),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: isTemp ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF00E5FF).withOpacity(0.8) : Colors.white10,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (senderName != null && !isMe) ...[
                Text(
                  senderName!,
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                text,
                style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(color: isMe ? Colors.black54 : Colors.white30, fontSize: 9),
                  ),
                  if (isTemp && isMe) ...[
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(strokeWidth: 1, color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
