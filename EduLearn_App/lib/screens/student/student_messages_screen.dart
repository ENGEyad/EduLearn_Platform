import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
<<<<<<< HEAD

import '../../theme.dart';
import '../../services/api_service.dart';
=======

import '../../theme.dart';

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

<<<<<<< HEAD
=======
/// ✅ Helper: فلترة مرنة لأسماء أحداث Reverb/Pusher
bool _isMessageSentEvent(String name) {
  final n = name.trim();
  return n == 'message.sent' ||
      n == '.message.sent' ||
      n.endsWith('MessageSent') ||
      n.contains('MessageSent');
}

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

<<<<<<< HEAD
/// ✅ نستخدم هذا المتغيّر لمعرفة المحادثة المفتوحة حالياً للطالب
/// (نضبطه قبل الدخول للشات مباشرة، وليس فقط داخل StudentChatScreen)
int? _currentStudentConversationId;
=======
/// ======================================================================
///  ✅ نفس فكرة Teacher: نعرف المحادثة المفتوحة حالياً
/// ======================================================================
class _StudentChatState {
  static int? currentConversationId;
}
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

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

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  late List<_ChatTeacher> _chatTeachers;
  bool _loadingConversations = false;

  /// محادثات لكل أستاذ حسب teacher_code
  final Map<String, _ConversationMeta> _metaByTeacherCode = {};

<<<<<<< HEAD
  /// خريطة تربط conversationId بـ teacher_code (مهمّة للـ WebSocket)
  final Map<int, String> _teacherCodeByConversationId = {};

  /// Laravel Reverb لقائمة المحادثات
  ReverbClient? _reverbClient;
=======
  /// conversationId -> teacherCode
  final Map<int, String> _teacherCodeByConversationId = {};

  /// Reverb
  ReverbClient? _reverbClient;

  /// القنوات المشترك بها (private-conversation.{id})
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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
    _chatTeachers = [];
<<<<<<< HEAD
    debugPrint('StudentMessagesScreen -> student map: ${widget.student}');
    debugPrint('StudentMessagesScreen -> academicId = $_academicId');
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    _loadStudentConversations();
  }

  @override
  void dispose() {
<<<<<<< HEAD
    // إلغاء الاشتراك من كل القنوات
    try {
      for (final ch in _conversationChannels.values) {
        ch.unsubscribe();
      }
    } catch (_) {}
    _conversationChannels.clear();

    try {
      _reverbClient?.disconnect();
    } catch (_) {}

=======
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    super.dispose();
  }

  Future<void> _loadStudentConversations() async {
<<<<<<< HEAD
    if (_academicId.isEmpty) {
      debugPrint(
          'StudentMessagesScreen: academicId is EMPTY, لن يتم طلب المحادثات من الـ API');
      return;
    }

    setState(() {
      _loadingConversations = true;
    });

    try {
      final convos = await ApiService.fetchStudentConversations(
        academicId: _academicId,
      );

      debugPrint(
          'StudentMessagesScreen: fetchStudentConversations returned ${convos.length} conversations');

=======
    if (_academicId.isEmpty) return;

    setState(() => _loadingConversations = true);

    try {
      final convos = await ChatService.fetchStudentConversations(
        academicId: _academicId,
      );

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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
<<<<<<< HEAD
        final String rawTime =
            (c['last_message_at'] ?? '').toString(); // ISO من الـ API
=======
        final String rawTime = (c['last_message_at'] ?? '').toString();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        final int unread =
            int.tryParse((c['unread_count'] ?? '0').toString()) ?? 0;

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
        );

        _teacherCodeByConversationId[conversationId] = teacherCode;
      }

      final list = teachers.values.toList()
<<<<<<< HEAD
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
=======
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

      setState(() {
        _chatTeachers = list;
        _metaByTeacherCode
          ..clear()
          ..addAll(meta);
      });

<<<<<<< HEAD
      // بعد تحميل المحادثات نشترك في كل قنواتها
      await _resubscribeToConversationChannels();
    } catch (e) {
      debugPrint('Failed to load student conversations: $e');
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

=======
      await _ensureReverbClient();
      await _resubscribeToConversationChannels();
    } catch (e) {
      debugPrint('Failed to load student conversations: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load conversations: $e',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingConversations = false);
    }
  }

  /// ===================== Reverb (Private Channels) =====================

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  Future<void> _ensureReverbClient() async {
    if (_reverbClient != null) return;

    try {
<<<<<<< HEAD
      final backendUri = Uri.parse(ApiService.rootUrl);
      final host = backendUri.host;

      _reverbClient = ReverbClient.instance(
        host: host,
        port: 8080,
        appKey: ApiService.pusherApiKey,
      );

      await _reverbClient!.connect();
=======
      // ✅ عميل واحد عبر ReverbService
      _reverbClient = await ReverbService.getStudentClient(
        academicId: _academicId,
        port: 8080,
      );
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    } catch (e) {
      debugPrint('StudentMessagesScreen: Failed to init ReverbClient: $e');
    }
  }

  Future<void> _subscribeToConversationChannel(int conversationId) async {
    await _ensureReverbClient();
    if (_reverbClient == null) return;

<<<<<<< HEAD
    if (_conversationChannels.containsKey(conversationId)) {
      return; // مشترك مسبقاً
    }

    try {
      final channelName = 'conversation.$conversationId';
      final ch = _reverbClient!.subscribeToChannel(channelName);
      await ch.subscribe();

      ch.stream.listen(
        (ChannelEvent event) {
=======
    if (_conversationChannels.containsKey(conversationId)) return;

    try {
      final channelName = 'private-conversation.$conversationId';
      final ch = _reverbClient!.subscribeToChannel(channelName);

      // ✅ listen قبل subscribe (نفس تعديل الأستاذ)
      ch.stream.listen(
        (ChannelEvent event) {
          // debugPrint('StudentMessagesScreen EVENT($conversationId): ${event.eventName}');
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
          _handleConversationChannelEvent(conversationId, event);
        },
        onError: (e) {
          debugPrint(
              'StudentMessagesScreen: error on channel $conversationId: $e');
        },
      );

<<<<<<< HEAD
=======
      ch.subscribe();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      _conversationChannels[conversationId] = ch;
    } catch (e) {
      debugPrint(
          'StudentMessagesScreen: failed to subscribe to conv $conversationId: $e');
    }
  }

  Future<void> _resubscribeToConversationChannels() async {
<<<<<<< HEAD
    // المحادثات المطلوبة بناءً على الميتا الحالية
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    final neededConversationIds = <int>{};
    for (final meta in _metaByTeacherCode.values) {
      neededConversationIds.add(meta.conversationId);
    }

<<<<<<< HEAD
    // إلغاء الاشتراك من القنوات غير المطلوبة
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    final toRemove = _conversationChannels.keys
        .where((id) => !neededConversationIds.contains(id))
        .toList();

    for (final id in toRemove) {
      try {
        _conversationChannels[id]?.unsubscribe();
      } catch (_) {}
      _conversationChannels.remove(id);
    }

<<<<<<< HEAD
    // الاشتراك في القنوات الجديدة
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    for (final id in neededConversationIds) {
      if (!_conversationChannels.containsKey(id)) {
        await _subscribeToConversationChannel(id);
      }
    }
  }

  void _handleConversationChannelEvent(int conversationId, ChannelEvent event) {
<<<<<<< HEAD
    if (event.eventName != 'message.sent') return;
=======
    // ✅ فلترة مرنة بدل شرط صارم
    if (!_isMessageSentEvent(event.eventName)) return;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

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

<<<<<<< HEAD
      final dynamic messageRaw = payload['message'] ?? payload['msg'];
=======
      final dynamic messageRaw = payload['message'] ?? payload['msg'] ?? payload;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      final dynamic convoRaw = payload['conversation'] ?? payload['conv'];

      if (messageRaw is! Map) return;

<<<<<<< HEAD
      final msg = Map<String, dynamic>.from(messageRaw as Map<dynamic, dynamic>);

      final conv = (convoRaw is Map)
          ? Map<String, dynamic>.from(convoRaw as Map<dynamic, dynamic>)
=======
      final msg = Map<String, dynamic>.from(messageRaw as Map);

      final conv = (convoRaw is Map)
          ? Map<String, dynamic>.from(convoRaw as Map)
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
          : <String, dynamic>{};

      final senderType = (msg['sender_type'] ?? '').toString();

<<<<<<< HEAD
      // نحدد الأستاذ (teacher_code) لهذه المحادثة
      final String? teacherCode = _teacherCodeByConversationId[conversationId];
      if (teacherCode == null || teacherCode.isEmpty) {
        return;
      }

      // آخر رسالة
=======
      final String? teacherCode = _teacherCodeByConversationId[conversationId];
      if (teacherCode == null || teacherCode.isEmpty) return;

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      final String lastPreview =
          (conv['last_message'] ?? msg['body'] ?? '').toString();

      final String lastTimeRaw =
          (conv['last_message_at'] ?? msg['sent_at'] ?? '').toString();

      final DateTime? lastAt = _parseUtcDate(lastTimeRaw);
<<<<<<< HEAD

=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      final String timeLabel = lastTimeRaw.isEmpty
          ? ''
          : _formatTimeLabel(lastTimeRaw, forConversation: true);

<<<<<<< HEAD
      // unread من السيرفر (للـ Student)
      // ✅ الأفضل: نعتمد unread_count إن توفر، وإلا unread_for_student
      int unreadFromServer = 0;
      if (conv.isNotEmpty) {
        unreadFromServer = int.tryParse(
              (conv['unread_count'] ??
                      conv['unread_for_student'] ??
                      '0')
                  .toString(),
            ) ??
            0;
      }

      // منطق واتساب:
      // - لو الطالب داخل نفس المحادثة حالياً -> unread = 0
      // - لو الرسالة من الطالب نفسه -> unread = 0
      // - غير ذلك -> unread = unreadFromServer
      int unreadClient;
      if (_currentStudentConversationId == conversationId) {
=======
      // ✅ unread: إذا السيرفر رجّع unread_for_student ناخذه
      // وإلا نعمل fallback زي الأستاذ (+1) بدل ما يظل 0
      int unreadClient;
      final isOpen = _StudentChatState.currentConversationId == conversationId;

      if (isOpen) {
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        unreadClient = 0;
      } else if (senderType == 'student') {
        unreadClient = 0;
      } else {
<<<<<<< HEAD
        unreadClient = unreadFromServer;
      }

=======
        final serverUnread = int.tryParse(
              (conv['unread_for_student'] ?? conv['unread_count'] ?? '')
                  .toString(),
            ) ??
            0;

        final prev = _metaByTeacherCode[teacherCode]?.unreadCount ?? 0;
        unreadClient = serverUnread > 0 ? serverUnread : (prev + 1);
      }

      if (!mounted) return;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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
          'StudentMessagesScreen: failed to handle conversation event: $e');
    }
  }

  Future<void> _openChatForTeacher(_ChatTeacher t) async {
    int? conversationId = _metaByTeacherCode[t.teacherCode]?.conversationId;

<<<<<<< HEAD
    // لو ما في محادثة موجودة نفتح/ننشيء من الـ API
    if (conversationId == null) {
      try {
        final conv = await ApiService.openStudentConversation(
=======
    if (conversationId == null) {
      try {
        final conv = await ChatService.openStudentConversation(
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

        setState(() {
          _metaByTeacherCode[t.teacherCode] = _ConversationMeta(
            conversationId: conversationId!,
            lastMessagePreview: lastPreview,
            lastMessageTimeLabel: timeLabel,
            lastMessageAt: lastAt,
            unreadCount:
                int.tryParse((conv['unread_count'] ?? '0').toString()) ?? 0,
          );
          _teacherCodeByConversationId[conversationId!] = t.teacherCode;
        });

<<<<<<< HEAD
        // نشترك في قناة هذه المحادثة الجديدة
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

<<<<<<< HEAD
    // ✅ مهم جداً: نثبت المحادثة المفتوحة قبل الدخول للشات مباشرة
    // حتى لا تزيد unread بالخطأ إذا وصل Event أثناء الانتقال
    _currentStudentConversationId = conversationId;

    // بمجرد دخول الطالب للمحادثة نعتبر رسائل الأستاذ مقروءة (من ناحية UI)
=======
    _StudentChatState.currentConversationId = conversationId;

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    final meta = _metaByTeacherCode[t.teacherCode];
    if (meta != null && (meta.unreadCount ?? 0) > 0) {
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
        ),
      ),
    );

<<<<<<< HEAD
    // ✅ بعد الرجوع من شاشة الشات، نلغي تحديد المحادثة المفتوحة
    if (_currentStudentConversationId == conversationId) {
      _currentStudentConversationId = null;
    }

    // بعد الرجوع من شاشة الشات نعيد تحميل المحادثات
=======
    if (_StudentChatState.currentConversationId == conversationId) {
      _StudentChatState.currentConversationId = null;
    }

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    await _loadStudentConversations();
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // نرتب الأساتذة حسب آخر رسالة (الأحدث أولاً)
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    final List<_ChatTeacher> orderedTeachers =
        List<_ChatTeacher>.from(_chatTeachers);

    orderedTeachers.sort((a, b) {
      final ma = _metaByTeacherCode[a.teacherCode];
      final mb = _metaByTeacherCode[b.teacherCode];

      final da = ma?.lastMessageAt;
      final db = mb?.lastMessageAt;

<<<<<<< HEAD
      if (da != null && db != null) {
        return db.compareTo(da); // الأحدث أولاً
      }
      if (da != null) return -1;
      if (db != null) return 1;

      // لو ما في رسائل من الطرفين نرتبهم بالاسم
=======
      if (da != null && db != null) return db.compareTo(da);
      if (da != null) return -1;
      if (db != null) return 1;

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                color: EduTheme.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _studentFullName,
              style: const TextStyle(
                color: EduTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: EduTheme.primaryDark,
              ),
<<<<<<< HEAD
              onPressed: () {
                // لاحقاً: بحث في الأساتذة / المحادثات
              },
=======
              onPressed: () {},
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
            ),
        ],
      ),
      body: orderedTeachers.isEmpty
          ? const Center(
              child: Text(
                'No chats yet. Start a conversation with your teachers.',
                style: TextStyle(
                  color: EduTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              itemCount: orderedTeachers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final t = orderedTeachers[index];

                final avatarText =
                    t.name.isNotEmpty ? t.name[0].toUpperCase() : '?';

                final meta = _metaByTeacherCode[t.teacherCode];

                final subtitle = 'Code: ${t.teacherCode}';

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
                    (t.imageUrl != null && t.imageUrl!.isNotEmpty)
<<<<<<< HEAD
                        ? ApiService.buildFullMediaUrl(t.imageUrl!)
=======
                        ? ApiHelpers.buildFullMediaUrl(t.imageUrl!)
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                        : null;

                return _MessageItem(
                  avatarText: avatarText,
                  avatarImageUrl: avatarImageUrl,
                  name: t.name.isNotEmpty ? t.name : t.teacherCode,
                  preview: displayPreview,
                  metaLine: subtitle,
                  time: displayTime,
                  unreadCount: unreadCount,
                  onTap: () => _openChatForTeacher(t),
                );
              },
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
<<<<<<< HEAD
                backgroundColor:
                    hasUnread ? EduTheme.primary.withOpacity(0.14) : Colors.white,
=======
                backgroundColor: hasUnread
                    ? EduTheme.primary.withOpacity(0.14)
                    : Colors.white,
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

/// ==================== شاشة محادثة الطالب مع أستاذ معيّن ====================

class StudentChatScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> teacher;
  final int conversationId;

  const StudentChatScreen({
    super.key,
    required this.student,
    required this.teacher,
    required this.conversationId,
  });

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = {};

  bool _loading = false;
  bool _initialLoaded = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

<<<<<<< HEAD
  // ========= Laravel Reverb (WebSocket) =========
  late ReverbClient _reverbClient;
  Channel? _channel;

  String get _academicId => (widget.student['academic_id'] ?? '').toString();
=======
  ReverbClient? _reverbClient;
  Channel? _channel;

  String get _academicId => (widget.student['academic_id'] ??
          widget.student['academicId'] ??
          widget.student['student_id'] ??
          widget.student['id'] ??
          '')
      .toString();

>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  String get _studentName => (widget.student['full_name'] ?? '').toString();

  String get _teacherName => (widget.teacher['full_name'] ?? '').toString();
  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString();
  String? get _teacherImage =>
      (widget.teacher['image'] as String?)?.toString();

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD

    // هذه هي المحادثة المفتوحة حالياً للطالب
    _currentStudentConversationId = widget.conversationId;

=======
    _StudentChatState.currentConversationId = widget.conversationId;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    _loadMessages();
    _initReverb();
  }

  Future<void> _loadMessages() async {
    if (_academicId.isEmpty) return;

<<<<<<< HEAD
    setState(() {
      _loading = true;
    });

    try {
      final msgs = await ApiService.fetchConversationMessagesAsStudent(
=======
    setState(() => _loading = true);

    try {
      final msgs = await ChatService.fetchConversationMessagesAsStudent(
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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

  /// تهيئة Reverb متوافقة مع Laravel Event:
  /// Channel: conversation.{id}
  /// Event:   message.sent
  Future<void> _initReverb() async {
    try {
      final backendUri = Uri.parse(ApiService.rootUrl);
      final host = backendUri.host;

      _reverbClient = ReverbClient.instance(
        host: host,
        port: 8080,
        appKey: ApiService.pusherApiKey,
      );

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

          final msg = Map<String, dynamic>.from(maybeMessage);

          final idStr = (msg['id'] ?? '').toString();
          if (idStr.isNotEmpty && _messageIds.contains(idStr)) {
            return; // الرسالة موجودة مسبقاً (من الـ API)
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
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initReverb() async {
    try {
      _reverbClient = await ReverbService.getStudentClient(
        academicId: _academicId,
        port: 8080,
      );

      final channelName = 'private-conversation.${widget.conversationId}';
      _channel = _reverbClient!.subscribeToChannel(channelName);

      // ✅ listen قبل subscribe (نفس تعديل الأستاذ)
      _channel!.stream.listen(
        (ChannelEvent event) {
          // debugPrint('StudentChatScreen EVENT: ${event.eventName}');
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    } catch (e) {
      debugPrint('Failed to init ReverbClient: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
<<<<<<< HEAD
      final sent = await ApiService.sendMessageAsStudent(
=======
      final sent = await ChatService.sendMessageAsStudent(
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        conversationId: widget.conversationId,
        academicId: _academicId,
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
<<<<<<< HEAD
    if (_currentStudentConversationId == widget.conversationId) {
      _currentStudentConversationId = null;
=======
    if (_StudentChatState.currentConversationId == widget.conversationId) {
      _StudentChatState.currentConversationId = null;
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
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
    // ✅ لا نعمل disconnect — فقط unsubscribe لقناة المحادثة
    try {
      _channel?.unsubscribe();
    } catch (_) {}
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
<<<<<<< HEAD
    if (_teacherCode.isNotEmpty) {
      subtitleParts.add('Code: $_teacherCode');
    }
    if (_studentName.isNotEmpty) {
      subtitleParts.add(_studentName);
    }
    final subtitle = subtitleParts.join(' • ');

    final avatarUrl = _teacherImage != null && _teacherImage!.isNotEmpty
        ? ApiService.buildFullMediaUrl(_teacherImage!)
=======
    if (_teacherCode.isNotEmpty) subtitleParts.add('Code: $_teacherCode');
    if (_studentName.isNotEmpty) subtitleParts.add(_studentName);
    final subtitle = subtitleParts.join(' • ');

    final avatarUrl = _teacherImage != null && _teacherImage!.isNotEmpty
        ? ApiHelpers.buildFullMediaUrl(_teacherImage!)
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
                Text(
                  _teacherName.isNotEmpty ? _teacherName : _teacherCode,
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
                          final senderType = (m['sender_type'] ?? '').toString();
=======
                          final senderType =
                              (m['sender_type'] ?? '').toString();
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                          final isStudent = senderType == 'student';

                          final body = (m['body'] ?? '').toString();
                          final createdAtRaw = (m['sent_at'] ?? '').toString();
                          final createdTimeLabel = createdAtRaw.isEmpty
                              ? ''
                              : _formatTimeLabel(createdAtRaw);

<<<<<<< HEAD
                          // ===== شريحة اليوم / أمس / التاريخ =====
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                          String? dateHeader;
                          final dt = _parseUtcDate(createdAtRaw)?.toLocal();
                          if (dt != null) {
                            bool showHeader = false;
                            if (index == 0) {
                              showHeader = true;
                            } else {
                              final prevRaw =
                                  (_messages[index - 1]['sent_at'] ?? '')
                                      .toString();
                              final prevDt = _parseUtcDate(prevRaw)?.toLocal();
                              if (prevDt == null ||
                                  !_isSameCalendarDate(prevDt, dt)) {
                                showHeader = true;
                              }
                            }

                            if (showHeader) {
                              final now = DateTime.now();
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final date =
                                  DateTime(dt.year, dt.month, dt.day);
                              final diffDays = today.difference(date).inDays;
                              if (diffDays == 0) {
                                dateHeader = 'Today';
                              } else if (diffDays == 1) {
                                dateHeader = 'Yesterday';
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
                                dateHeader =
                                    '${monthNames[dt.month - 1]} ${dt.day}';
                              }
                            }
                          }

                          return Column(
                            children: [
                              if (dateHeader != null)
                                _DateChip(label: dateHeader),
                              _ChatBubble(
                                isMe: isStudent,
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
                        color: Colors.black.withOpacity(0.05),
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
                    color: EduTheme.primary.withOpacity(0.9),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
