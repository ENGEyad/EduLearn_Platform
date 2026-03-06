import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../theme.dart';
<<<<<<< HEAD
import '../../services/api_service.dart';
=======

// ✅ APIs
import '../../services/chat_service.dart';
import '../../services/api_helpers.dart';

// ✅ Reverb service (مشترك)
import '../../services/reverb_service.dart';
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

/// ========= Helpers عامة للتواريخ/الأوقات =========

DateTime? _parseUtcDate(String value) {
  try {
    if (value.trim().isEmpty) return null;
    var v = value.trim();

<<<<<<< HEAD
    // مثلاً لو جاك "2025-12-06 18:20:00" نحولها لصيغة ISO
=======
    // مثل: "2025-12-06 18:20:00" -> ISO
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

<<<<<<< HEAD
/// تنسيق وقت على شكل 09:30 AM
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

<<<<<<< HEAD
/// تنسيق وقت شاشة قائمة المحادثات
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

<<<<<<< HEAD
/// دالة عامة لتنسيق الوقت:
/// - forConversation = true  -> تستخدم لقائمة المحادثات
/// - forConversation = false -> تستخدم داخل شاشة الشات
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

<<<<<<< HEAD
/// ======================================================================
///  ✅ بديل آمن عن ApiService.currentTeacherConversationId
///  نخزّن المحادثة المفتوحة حالياً للأستاذ داخل هذا الملف فقط.
=======
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen> {
  late List<_ChatStudent> _chatStudents;
  bool _loadingConversations = false;

  /// محادثات لكل طالب حسب الـ academic_id
  final Map<String, _ConversationMeta> _metaByAcademicId = {};

<<<<<<< HEAD
  /// خريطة تربط رقم المحادثة بالـ academic_id (مهمة مع الـ WebSocket)
  final Map<int, String> _academicIdByConversationId = {};

  /// عميل Laravel Reverb لقائمة المحادثات نفسها
  ReverbClient? _reverbClient;

  /// القنوات المشترك بها (conversation.{id})
=======
  /// conversationId -> academicId
  final Map<int, String> _academicIdByConversationId = {};

  /// Reverb (مشترك)
  ReverbClient? _reverbClient;

  /// القنوات المشترك بها
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  final Map<int, Channel> _conversationChannels = {};

  String get _teacherFullName => (widget.teacher['full_name'] ?? '').toString();
  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString();
  String? get _teacherImage => (widget.teacher['image'] as String?)?.toString();

  @override
  void initState() {
    super.initState();
    _chatStudents = _extractChatStudents();
    _loadTeacherConversations();
  }

  @override
  void dispose() {
<<<<<<< HEAD
    // إغلاق قنوات Reverb الخاصة بالقائمة
    try {
      for (final ch in _conversationChannels.values) {
        ch.unsubscribe();
      }
    } catch (_) {}

    _conversationChannels.clear();

    try {
      _reverbClient?.disconnect();
    } catch (_) {}

    super.dispose();
  }

  // نجمّع الطلاب من جميع الإسنادات (لكل صف/شعبة)
=======
    // ✅ مهم: لا تفصل ReverbService هنا حتى لا تقطع الاتصال عن شاشة الشات/شاشات أخرى
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

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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
<<<<<<< HEAD

=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

  Future<void> _loadTeacherConversations() async {
    if (_teacherCode.isEmpty) return;

<<<<<<< HEAD
    setState(() {
      _loadingConversations = true;
    });

    try {
      final convos =
          await ApiService.fetchTeacherConversations(teacherCode: _teacherCode);
=======
    setState(() => _loadingConversations = true);

    try {
      final convos =
          await ChatService.fetchTeacherConversations(teacherCode: _teacherCode);
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

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
<<<<<<< HEAD

=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        if (conversationId == null) continue;

        final String lastPreview = (c['last_message'] ?? '').toString();
        final String lastTimeRaw = (c['last_message_at'] ?? '').toString();
        final int unread =
            int.tryParse((c['unread_count'] ?? '0').toString()) ?? 0;

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

      setState(() {
        _metaByAcademicId
          ..clear()
          ..addAll(map);
      });

<<<<<<< HEAD
      // بعد تحميل المحادثات نضبط الاشتراك في قنوات Reverb
      await _resubscribeToConversationChannels();
    } catch (e) {
      debugPrint('Failed to load teacher conversations: $e');
      if (mounted) {
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
      if (mounted) {
        setState(() {
          _loadingConversations = false;
        });
      }
    }
  }

  Future<void> _ensureReverbClient() async {
    if (_reverbClient != null) return;

    try {
      final backendUri = Uri.parse(ApiService.rootUrl);
      final host = backendUri.host;

      _reverbClient = ReverbClient.instance(
        host: host,
        port: 8080, // REVERB_PORT
        appKey: ApiService.pusherApiKey,
      );

      await _reverbClient!.connect();
    } catch (e) {
      debugPrint('TeacherMessagesScreen: Failed to init ReverbClient: $e');
    }
  }

  Future<void> _subscribeToConversationChannel(int conversationId) async {
    await _ensureReverbClient();
    if (_reverbClient == null) return;

    if (_conversationChannels.containsKey(conversationId)) {
      return; // مشترك مسبقاً
    }

    try {
      final channelName = 'conversation.$conversationId';
      final ch = _reverbClient!.subscribeToChannel(channelName);
      await ch.subscribe();

      ch.stream.listen(
        (ChannelEvent event) {
          _handleConversationChannelEvent(conversationId, event);
        },
        onError: (e) {
          debugPrint(
              'TeacherMessagesScreen: error on channel $conversationId: $e');
        },
      );

      _conversationChannels[conversationId] = ch;
    } catch (e) {
      debugPrint(
          'TeacherMessagesScreen: failed to subscribe to conv $conversationId: $e');
    }
  }

  Future<void> _resubscribeToConversationChannels() async {
    // نحدد المحادثات المطلوبة بناءً على الميتا الحالية
    final neededConversationIds = <int>{};
    for (final meta in _metaByAcademicId.values) {
      neededConversationIds.add(meta.conversationId);
    }

    // إلغاء الاشتراك من أي قناة لم تعد مطلوبة
    final toRemove = _conversationChannels.keys
        .where((id) => !neededConversationIds.contains(id))
        .toList();

    for (final id in toRemove) {
      try {
        _conversationChannels[id]?.unsubscribe();
      } catch (_) {}
      _conversationChannels.remove(id);
    }

    // الاشتراك في القنوات الجديدة
    for (final id in neededConversationIds) {
      if (!_conversationChannels.containsKey(id)) {
        await _subscribeToConversationChannel(id);
      }
    }
  }

  void _handleConversationChannelEvent(int conversationId, ChannelEvent event) {
    if (event.eventName != 'message.sent') return;

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

      final dynamic messageRaw = payload['message'] ?? payload['msg'];
      final dynamic convoRaw = payload['conversation'] ?? payload['conv'];

      if (messageRaw is! Map) return;

      final msg = Map<String, dynamic>.from(messageRaw as Map<dynamic, dynamic>);

      final conv = (convoRaw is Map)
          ? Map<String, dynamic>.from(convoRaw as Map<dynamic, dynamic>)
          : <String, dynamic>{};

      final senderType = (msg['sender_type'] ?? '').toString();

      // نحدد الطالب (academic_id) لهذه المحادثة
      final String? academicId = _academicIdByConversationId[conversationId];
      if (academicId == null || academicId.isEmpty) {
        return;
      }

      // نقرأ آخر رسالة من الـ conversation أو من msg
      final String lastPreview =
          (conv['last_message'] ?? msg['body'] ?? '').toString();

      final String lastTimeRaw =
          (conv['last_message_at'] ?? msg['sent_at'] ?? '').toString();

      final DateTime? lastAt = _parseUtcDate(lastTimeRaw);

      final String timeLabel = lastTimeRaw.isEmpty
          ? ''
          : _formatTimeLabel(lastTimeRaw, forConversation: true);

      // ✅ الأفضل: نعتمد unread_count أولاً، ثم unread_for_teacher
      int unreadFromServer = 0;
      if (conv.isNotEmpty) {
        unreadFromServer = int.tryParse(
              (conv['unread_count'] ?? conv['unread_for_teacher'] ?? '0')
                  .toString(),
            ) ??
            0;
      }

      // منطق واتساب:
      // - لو الأستاذ داخل نفس المحادثة حالياً -> unread = 0
      // - لو الرسالة من الأستاذ نفسه -> unread = 0
      // - غير ذلك -> unread = unreadFromServer
      int unreadClient;
      if (_TeacherChatState.currentConversationId == conversationId) {
        unreadClient = 0;
      } else if (senderType == 'teacher') {
        unreadClient = 0;
      } else {
        unreadClient = unreadFromServer;
      }

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
      debugPrint(
          'TeacherMessagesScreen: failed to handle conversation event: $e');
    }
  }

  Future<void> _openChatForStudent(_ChatStudent s) async {
    int? conversationId = _metaByAcademicId[s.academicId]?.conversationId;

    // لو ما في محادثة موجودة نفتح/ننشيء من الـ API
    if (conversationId == null) {
      try {
        final conv = await ApiService.openTeacherConversation(
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

        if (conversationId == null) {
          throw Exception('Invalid conversation id');
        }

        final String lastPreview = (conv['last_message'] ?? '').toString();
        final String lastTimeRaw = (conv['last_message_at'] ?? '').toString();
        final DateTime? lastAt = _parseUtcDate(lastTimeRaw);
        final String timeLabel = lastTimeRaw.isNotEmpty
            ? _formatTimeLabel(lastTimeRaw, forConversation: true)
            : '';

        setState(() {
          _metaByAcademicId[s.academicId] = _ConversationMeta(
            conversationId: conversationId!,
            lastMessagePreview: lastPreview,
            lastMessageTimeLabel: timeLabel,
            lastMessageAt: lastAt,
            unreadCount:
                int.tryParse((conv['unread_count'] ?? '0').toString()) ?? 0,
          );
          _academicIdByConversationId[conversationId!] = s.academicId;
        });

        // نشترك في قناة هذه المحادثة الجديدة
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

    // ✅ مهم جداً: نثبت المحادثة المفتوحة قبل الدخول للشات مباشرة
    // حتى لا تزيد unread بالخطأ إذا وصل Event أثناء الانتقال
    _TeacherChatState.currentConversationId = conversationId;

    // بمجرد دخول الأستاذ للمحادثة نعتبر رسائل الطالب مقروءة (من ناحية UI)
    final meta = _metaByAcademicId[s.academicId];
    if (meta != null && (meta.unreadCount ?? 0) > 0) {
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

    // ✅ بعد الرجوع من شاشة الشات، نلغي تحديد المحادثة المفتوحة
    if (_TeacherChatState.currentConversationId == conversationId) {
      _TeacherChatState.currentConversationId = null;
    }

    // بعد الرجوع من شاشة الشات نعيد تحميل محادثات الأستاذ
    await _loadTeacherConversations();
  }

  @override
  Widget build(BuildContext context) {
    final chatStudents = _chatStudents;

    // نرتب الطلاب حسب آخر رسالة (الأحدث أولاً)
    final List<_ChatStudent> orderedStudents = List<_ChatStudent>.from(chatStudents);

    orderedStudents.sort((a, b) {
      final ma = _metaByAcademicId[a.academicId];
      final mb = _metaByAcademicId[b.academicId];

      final da = ma?.lastMessageAt;
      final db = mb?.lastMessageAt;

      if (da != null && db != null) {
        return db.compareTo(da); // الأحدث أولاً
      }
      if (da != null) return -1;
      if (db != null) return 1;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final avatarUrl = _teacherImage != null && _teacherImage!.isNotEmpty
        ? ApiService.buildFullMediaUrl(_teacherImage!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(
                      Icons.person,
                      color: EduTheme.primaryDark,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: EduTheme.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _teacherFullName,
                  style: const TextStyle(
                    color: EduTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: EduTheme.primaryDark,
              ),
              onPressed: () {
                // لاحقاً: بحث في الطلاب / المحادثات
              },
            ),
        ],
      ),
      body: orderedStudents.isEmpty
          ? const Center(
              child: Text(
                'No students found for your classes yet.',
                style: TextStyle(
                  color: EduTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              itemCount: orderedStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
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
                        ? ApiService.buildFullMediaUrl(s.imageUrl!)
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
    final bool hasUnread = unreadCount != null && unreadCount! > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasUnread ? const Color(0xFFEFF4FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? EduTheme.primary.withValues(alpha: 0.25)
                  : const Color(0xFFE2E6F0),
            ),
            boxShadow: [
              BoxShadow(
               color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    hasUnread ? EduTheme.primary.withValues(alpha: 0.14) : Colors.white,
                backgroundImage:
                    avatarImageUrl != null ? NetworkImage(avatarImageUrl!) : null,
                child: avatarImageUrl == null
                    ? Text(
                        avatarText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: EduTheme.primaryDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
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
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 15.5,
                              color: EduTheme.primaryDark,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread
                                  ? EduTheme.primary
                                  : EduTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: EduTheme.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread ? EduTheme.primaryDark : EduTheme.textMuted,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 4),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: EduTheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
=======
      await _ensureReverbClient();
      await _resubscribeToConversationChannels();
    } catch (e) {
      debugPrint('Failed to load teacher conversations: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load conversations: $e',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = {};

  bool _loading = false;
  bool _initialLoaded = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ========= Laravel Reverb (WebSocket) =========
  late ReverbClient _reverbClient;
  Channel? _channel;

  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString();

  String get _studentName => (widget.student['full_name'] ?? '').toString();
  String get _academicId => (widget.student['academic_id'] ?? '').toString();
  String? get _studentImage => (widget.student['image'] as String?)?.toString();

  @override
  void initState() {
    super.initState();

    // ✅ نخبر "حالة الملف" أن هذه هي المحادثة المفتوحة حالياً للأستاذ
    _TeacherChatState.currentConversationId = widget.conversationId;

    _loadMessages();
    _initReverb();
  }

  Future<void> _loadMessages() async {
    if (_teacherCode.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final msgs = await ApiService.fetchConversationMessagesAsTeacher(
        conversationId: widget.conversationId,
        teacherCode: _teacherCode,
      );
<<<<<<< HEAD
=======
    } finally {
      if (mounted) setState(() => _loadingConversations = false);
    }
  }

  /// ===================== Reverb (Private Channels) =====================

  Future<void> _ensureReverbClient() async {
    if (_reverbClient != null) return;

    try {
      _reverbClient =
          await ReverbService.getTeacherClient(teacherCode: _teacherCode);
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

      // ✅ مهم: listen قبل subscribe حتى لا نفوّت أول events
      ch.stream.listen(
        (ChannelEvent event) {
          // debugPrint('TeacherMessagesScreen EVENT(${conversationId}): ${event.eventName}');
          _handleConversationChannelEvent(conversationId, event);
        },
        onError: (e) {
          debugPrint(
              'TeacherMessagesScreen: error on channel $conversationId: $e');
        },
      );

      ch.subscribe();
      _conversationChannels[conversationId] = ch;
    } catch (e) {
      debugPrint(
          'TeacherMessagesScreen: failed to subscribe to conv $conversationId: $e');
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
    // ✅ فلترة مرنة بدل شرط صارم
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

      // unread logic (عميل)
      int unreadClient;
      final isOpen = _TeacherChatState.currentConversationId == conversationId;

      if (isOpen) {
        unreadClient = 0;
      } else if (senderType == 'teacher') {
        unreadClient = 0;
      } else {
        // ✅ لو السيرفر رجّع unread_for_teacher ناخذه، وإلا نزود محلياً +1
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

        setState(() {
          _metaByAcademicId[s.academicId] = _ConversationMeta(
            conversationId: conversationId!,
            lastMessagePreview: lastPreview,
            lastMessageTimeLabel: timeLabel,
            lastMessageAt: lastAt,
            unreadCount:
                int.tryParse((conv['unread_count'] ?? '0').toString()) ?? 0,
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

    // ✅ اختياري: إعادة تحميل للتأكد من unread من السيرفر
    await _loadTeacherConversations();
  }

  @override
  Widget build(BuildContext context) {
    final List<_ChatStudent> orderedStudents =
        List<_ChatStudent>.from(_chatStudents);

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

    final avatarUrl = _teacherImage != null && _teacherImage!.isNotEmpty
        ? ApiHelpers.buildFullMediaUrl(_teacherImage!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: EduTheme.primaryDark)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: EduTheme.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _teacherFullName,
                  style: const TextStyle(
                    color: EduTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded, color: EduTheme.primaryDark),
              onPressed: () {},
            ),
        ],
      ),
      body: orderedStudents.isEmpty
          ? const Center(
              child: Text(
                'No students found for your classes yet.',
                style: TextStyle(color: EduTheme.textMuted, fontSize: 13),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              itemCount: orderedStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
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
    final bool hasUnread = unreadCount != null && unreadCount! > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasUnread ? const Color(0xFFEFF4FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? EduTheme.primary.withOpacity(0.25)
                  : const Color(0xFFE2E6F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: hasUnread
                    ? EduTheme.primary.withOpacity(0.14)
                    : Colors.white,
                backgroundImage: avatarImageUrl != null
                    ? NetworkImage(avatarImageUrl!)
                    : null,
                child: avatarImageUrl == null
                    ? Text(
                        avatarText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: EduTheme.primaryDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
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
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 15.5,
                              color: EduTheme.primaryDark,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread
                                  ? EduTheme.primary
                                  : EduTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: EduTheme.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread
                            ? EduTheme.primaryDark
                            : EduTheme.textMuted,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 4),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: EduTheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
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

class _TeacherChatScreenState extends State<TeacherChatScreen> {
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
    _TeacherChatState.currentConversationId = widget.conversationId;
    _loadMessages();
    _initReverb();
  }

  Future<void> _loadMessages() async {
    if (_teacherCode.isEmpty) return;

    setState(() => _loading = true);

    try {
      final msgs = await ChatService.fetchConversationMessagesAsTeacher(
        conversationId: widget.conversationId,
        teacherCode: _teacherCode,
      );
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

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

<<<<<<< HEAD
      setState(() {
        _initialLoaded = true;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
=======
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// تهيئة Reverb متوافقة مع Laravel:
  /// Channel: conversation.{id}
  /// Event:   message.sent
  Future<void> _initReverb() async {
    try {
      final backendUri = Uri.parse(ApiService.rootUrl);
      final host = backendUri.host;

      _reverbClient = ReverbClient.instance(
        host: host,
        port: 8080, // REVERB_PORT
        appKey: ApiService.pusherApiKey,
      );
<<<<<<< HEAD

      await _reverbClient.connect();

      final channelName = 'conversation.${widget.conversationId}';

      _channel = _reverbClient.subscribeToChannel(channelName);
      await _channel!.subscribe();

      _channel!.stream.listen((ChannelEvent event) {
        if (event.eventName != 'message.sent') {
          return;
        }

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

          if (idStr.isNotEmpty && _messageIds.contains(idStr)) {
            return; // الرسالة موجودة مسبقاً
          }

          setState(() {
            if (idStr.isNotEmpty) {
              _messageIds.add(idStr);
            }
            _messages.add(msg);
          });

          _scrollToBottom();
        } catch (e) {
          debugPrint('Failed to handle websocket message: $e');
        }
      });
    } catch (e) {
      debugPrint('Failed to init ReverbClient: $e');
=======
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initReverb() async {
    try {
      _reverbClient =
          await ReverbService.getTeacherClient(teacherCode: _teacherCode);

      final channelName = 'private-conversation.${widget.conversationId}';
      _channel = _reverbClient!.subscribeToChannel(channelName);

      // ✅ listen قبل subscribe
      _channel!.stream.listen(
        (ChannelEvent event) {
          // debugPrint('TeacherChatScreen EVENT: ${event.eventName}');
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
<<<<<<< HEAD
      final sent = await ApiService.sendMessageAsTeacher(
=======
      final sent = await ChatService.sendMessageAsTeacher(
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        conversationId: widget.conversationId,
        teacherCode: _teacherCode,
        messageBody: text,
      );

      final idStr = (sent['id'] ?? '').toString();

      setState(() {
<<<<<<< HEAD
        if (idStr.isNotEmpty) {
          _messageIds.add(idStr);
        }
=======
        if (idStr.isNotEmpty) _messageIds.add(idStr);
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        _messages.add(sent);
      });

      _textController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to send message: $e');
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
    if (_TeacherChatState.currentConversationId == widget.conversationId) {
      _TeacherChatState.currentConversationId = null;
    }

    _textController.dispose();
    _scrollController.dispose();

<<<<<<< HEAD
    try {
      _channel?.unsubscribe();
    } catch (_) {}
    try {
      _reverbClient.disconnect();
    } catch (_) {}
=======
    // ✅ نفصل القناة فقط، ولا نفصل الاتصال العام
    try {
      _channel?.unsubscribe();
    } catch (_) {}
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
<<<<<<< HEAD
        ? ApiService.buildFullMediaUrl(_studentImage!)
=======
        ? ApiHelpers.buildFullMediaUrl(_studentImage!)
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        : null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.4,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
<<<<<<< HEAD
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
=======
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: EduTheme.primaryDark)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName.isNotEmpty ? _studentName : _academicId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: EduTheme.primaryDark,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
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
      backgroundColor: const Color(0xFFECEFF3),
      body: Column(
        children: [
          Expanded(
            child: _loading && !_initialLoaded
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation.',
                          style: TextStyle(color: EduTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
<<<<<<< HEAD
                          final senderType =
                              (m['sender_type'] ?? '').toString();
=======
                          final senderType = (m['sender_type'] ?? '').toString();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                          final isTeacher = senderType == 'teacher';

                          final body = (m['body'] ?? '').toString();
                          final createdAtRaw = (m['sent_at'] ?? '').toString();
<<<<<<< HEAD
                          final createdTimeLabel = createdAtRaw.isEmpty
                              ? ''
                              : _formatTimeLabel(createdAtRaw);

                          // ===== شريحة اليوم / أمس / التاريخ =====
=======
                          final createdTimeLabel =
                              createdAtRaw.isEmpty ? '' : _formatTimeLabel(createdAtRaw);

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                          String? dateHeader;
                          final dt = _parseUtcDate(createdAtRaw)?.toLocal();
                          if (dt != null) {
                            bool showHeader = false;
                            if (index == 0) {
                              showHeader = true;
                            } else {
                              final prevRaw =
<<<<<<< HEAD
                                  (_messages[index - 1]['sent_at'] ?? '')
                                      .toString();
                              final prevDt =
                                  _parseUtcDate(prevRaw)?.toLocal();
                              if (prevDt == null ||
                                  !_isSameCalendarDate(prevDt, dt)) {
=======
                                  (_messages[index - 1]['sent_at'] ?? '').toString();
                              final prevDt = _parseUtcDate(prevRaw)?.toLocal();
                              if (prevDt == null || !_isSameCalendarDate(prevDt, dt)) {
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                                showHeader = true;
                              }
                            }

                            if (showHeader) {
                              final now = DateTime.now();
<<<<<<< HEAD
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final date =
                                  DateTime(dt.year, dt.month, dt.day);
=======
                              final today = DateTime(now.year, now.month, now.day);
                              final date = DateTime(dt.year, dt.month, dt.day);
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                              final diffDays = today.difference(date).inDays;
                              if (diffDays == 0) {
                                dateHeader = 'Today';
                              } else if (diffDays == 1) {
                                dateHeader = 'Yesterday';
                              } else {
                                const monthNames = [
                                  'Jan','Feb','Mar','Apr','May','Jun',
                                  'Jul','Aug','Sep','Oct','Nov','Dec',
                                ];
                                dateHeader =
                                    '${monthNames[dt.month - 1]} ${dt.day}';
                              }
                            }
                          }

                          return Column(
                            children: [
<<<<<<< HEAD
                              if (dateHeader != null)
                                _DateChip(label: dateHeader),
=======
                              if (dateHeader != null) _DateChip(label: dateHeader),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                              _ChatBubble(
                                isMe: isTeacher,
                                text: body,
                                timeLabel: createdTimeLabel,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: EduTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;

  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD9E1F2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: EduTheme.primaryDark,
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

  const _ChatBubble({
    required this.isMe,
    required this.text,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? EduTheme.primary : Colors.white;
    final textColor = isMe ? Colors.white : EduTheme.primaryDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
<<<<<<< HEAD
                        color: Colors.black.withValues(alpha: 0.05),
=======
                        color: Colors.black.withOpacity(0.05),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          if (timeLabel.isNotEmpty)
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: EduTheme.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 14,
<<<<<<< HEAD
                    color: EduTheme.primary.withValues(alpha: 0.9)
=======
                    color: EduTheme.primary.withOpacity(0.9),
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}