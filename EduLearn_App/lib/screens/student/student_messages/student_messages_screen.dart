import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_messages_l10n.dart';
import '../../../services/api_helpers.dart';
import '../../../services/chat_service.dart';
import '../../../services/student_service.dart';
import '../../../services/reverb_service.dart';
import '../../../theme.dart';
import '../../chat_shared/chat_conversation_ui_model.dart';
import '../../chat_shared/chat_message_ui_model.dart';
import '../../chat_shared/chat_session_state.dart';
import '../../chat_shared/chat_shared_formatters.dart';
import '../student_chat/student_chat_screen.dart';

part 'student_messages_models.dart';
part 'student_messages_widgets.dart';

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
  late final ScrollController _listScrollController;
  late List<StudentMessagesTeacher> _chatTeachers;

  final Map<String, StudentConversationMeta> _metaByTeacherCode = {};
  final Map<int, String> _teacherCodeByConversationId = {};
  final Map<int, Channel> _conversationChannels = {};
  final TextEditingController _searchController = TextEditingController();

  ReverbClient? _reverbClient;

  bool _loadingConversations = false;
  String _searchQuery = '';
  StudentMessagesFilterType _activeFilterType = StudentMessagesFilterType.all;

  String get _studentFullName => (widget.student['full_name'] ?? '').toString();

  String get _academicId {
    final raw = widget.student['academic_id'] ??
        widget.student['academicId'] ??
        widget.student['student_id'] ??
        widget.student['id'];
    return (raw ?? '').toString().trim();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listScrollController = ScrollController();
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
    _searchController.dispose();
    _listScrollController.dispose();

    for (final channel in _conversationChannels.values) {
      try {
        channel.unsubscribe();
      } catch (_) {}
    }
    _conversationChannels.clear();
    super.dispose();
  }

  ChatMessageDeliveryState? _statusFromRaw(Map<String, dynamic> raw) {
    final value = (raw['last_message_status'] ?? raw['status'] ?? '').toString().trim().toLowerCase();
    switch (value) {
      case 'sending':
        return ChatMessageDeliveryState.sending;
      case 'sent':
        return ChatMessageDeliveryState.sent;
      case 'delivered':
        return ChatMessageDeliveryState.delivered;
      case 'read':
        return ChatMessageDeliveryState.read;
      case 'failed':
        return ChatMessageDeliveryState.failed;
      default:
        return null;
    }
  }

  ChatMessageDeliveryState _statusFromMessage(Map<String, dynamic> rawMessage) {
    return ChatMessageUiModel.fromMap(
      rawMessage,
      dateParser: chatParseUtcDate,
    ).deliveryState;
  }

  bool _isMessageStatusUpdatedEvent(String name) {
    final normalized = name.trim();
    return normalized == 'message.status.updated' ||
        normalized == '.message.status.updated' ||
        normalized.endsWith('MessageStatusUpdated') ||
        normalized.contains('MessageStatusUpdated');
  }

  Future<void> _loadStudentConversations({required bool showLoading}) async {
    if (_academicId.isEmpty) return;

    if (showLoading && mounted) {
      setState(() => _loadingConversations = true);
    }

    try {
      // ✅ استخدام StudentService.fetchStudentTeachers() بدلاً من HTTP مباشر
      final teachersResponse = await StudentService.fetchStudentTeachers();

      // ✅ إزالة academicId من استدعاء جلب المحادثات
      final conversations = await ChatService.fetchStudentConversations();

      final teachers = <String, StudentMessagesTeacher>{};
      final meta = <String, StudentConversationMeta>{};
      _teacherCodeByConversationId.clear();

      for (final item in teachersResponse) {
        if (item is! Map) continue;
        final teacher = Map<String, dynamic>.from(item);
        final teacherCode = (teacher['teacher_code'] ?? '').toString().trim();
        if (teacherCode.isEmpty) continue;

        teachers[teacherCode] = StudentMessagesTeacher(
          teacherCode: teacherCode,
          name: (teacher['full_name'] ?? teacher['name'] ?? '').toString().trim(),
          imageUrl: (teacher['image'] ?? teacher['teacher_image'] ?? teacher['photo_url'] ?? teacher['image_url'])?.toString(),
          raw: teacher,
        );
      }

      for (final item in conversations) {
        if (item is! Map<String, dynamic>) continue;

        final teacher = item['teacher'];
        if (teacher is! Map<String, dynamic>) continue;

        final teacherCode = (teacher['teacher_code'] ?? '').toString().trim();
        if (teacherCode.isEmpty) continue;

        final idRaw = item['id'];
        int? conversationId;
        if (idRaw is int) {
          conversationId = idRaw;
        } else if (idRaw is String) {
          conversationId = int.tryParse(idRaw);
        }
        if (conversationId == null) continue;

        final lastPreview = (item['last_message'] ?? '').toString();
        final lastTimeRaw = (item['last_message_at'] ?? '').toString();
        final unreadCount =
            int.tryParse((item['unread_for_student'] ?? item['unread_count'] ?? '0')
                    .toString()) ??
                0;

        teachers.putIfAbsent(
          teacherCode,
          () => StudentMessagesTeacher(
            teacherCode: teacherCode,
            name: (teacher['full_name'] ?? teacher['name'] ?? '').toString().trim(),
            imageUrl: (teacher['image'] ?? teacher['teacher_image'] ?? teacher['photo_url'] ?? teacher['image_url'])?.toString(),
            raw: teacher,
          ),
        );

        meta[teacherCode] = StudentConversationMeta(
          conversationId: conversationId,
          lastMessagePreview: lastPreview,
          lastMessageTimeLabel: lastTimeRaw.isEmpty
              ? ''
              : chatFormatTimeLabel(lastTimeRaw, forConversation: true),
          lastMessageAt: chatParseUtcDate(lastTimeRaw),
          unreadCount: unreadCount,
          lastMessageSenderType: (item['last_message_sender_type'] ?? '').toString().trim().isEmpty
              ? null
              : (item['last_message_sender_type'] ?? '').toString().trim(),
          lastMessageDeliveryState: _statusFromRaw(item),
        );

        _teacherCodeByConversationId[conversationId] = teacherCode;
      }

      final list = teachers.values.toList()
        ..sort((a, b) => a.normalizedName.toLowerCase().compareTo(
              b.normalizedName.toLowerCase(),
            ));

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
      debugPrint('Failed to load student conversations/teachers: $e');
      if (!mounted || !showLoading) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.studentMessagesFailedLoadConversations(e.toString()),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } finally {
      if (showLoading && mounted) {
        setState(() => _loadingConversations = false);
      }
    }
  }

  Future<void> _ensureReverbClient() async {
    try {
      // ✅ إزالة academicId (الخدمة تستخدم التوكن)
      _reverbClient = await ReverbService.getStudentClient();
    } catch (e) {
      debugPrint('StudentMessagesScreen: Failed to init Reverb client: $e');
    }
  }

  Future<void> _subscribeToConversationChannel(int conversationId) async {
    await _ensureReverbClient();
    if (_reverbClient == null || _conversationChannels.containsKey(conversationId)) {
      return;
    }

    try {
      final channelName = 'private-conversation.$conversationId';
      final channel = _reverbClient!.subscribeToChannel(channelName);

      channel.stream.listen(
        (ChannelEvent event) => _handleConversationChannelEvent(conversationId, event),
        onError: (e) {
          debugPrint('StudentMessagesScreen: error on channel $conversationId: $e');
        },
      );

      channel.subscribe();
      _conversationChannels[conversationId] = channel;
    } catch (e) {
      debugPrint('StudentMessagesScreen: failed to subscribe to conv $conversationId: $e');
    }
  }

  Future<void> _resubscribeToConversationChannels() async {
    final neededConversationIds = <int>{
      for (final meta in _metaByTeacherCode.values) meta.conversationId,
    };

    final idsToRemove = _conversationChannels.keys
        .where((id) => !neededConversationIds.contains(id))
        .toList();

    for (final id in idsToRemove) {
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
    if (!chatIsMessageSentEvent(event.eventName) &&
        !_isMessageStatusUpdatedEvent(event.eventName)) {
      return;
    }

    try {
      final payload = _parseEventPayload(event.data);
      if (payload == null) return;

      final conversationRaw = payload['conversation'] ?? payload['conv'];
      final conversation = (conversationRaw is Map)
          ? Map<String, dynamic>.from(conversationRaw)
          : <String, dynamic>{};

      if (_isMessageStatusUpdatedEvent(event.eventName)) {
        final rawMessages = payload['messages'];
        if (rawMessages is! List || rawMessages.isEmpty) return;

        Map<String, dynamic>? latest;
        for (final item in rawMessages) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final currentId = int.tryParse((map['id'] ?? '').toString()) ?? 0;
          final latestId = int.tryParse((latest?['id'] ?? '').toString()) ?? 0;
          if (currentId > latestId) {
            latest = map;
          }
        }

        if (latest == null) return;

        final teacherCode = _teacherCodeByConversationId[conversationId];
        if (teacherCode == null || teacherCode.isEmpty) return;

        final previous = _metaByTeacherCode[teacherCode];
        final lastTimeRaw =
            (conversation['last_message_at'] ?? latest['sent_at'] ?? '').toString();
        final lastMessageAt = chatParseUtcDate(lastTimeRaw);
        final timeLabel = lastTimeRaw.isEmpty
            ? ''
            : chatFormatTimeLabel(lastTimeRaw, forConversation: true);
        final isOpen = StudentChatSessionState.currentConversationId == conversationId;
        final unreadCount = isOpen
            ? 0
            : (int.tryParse((conversation['unread_for_student'] ?? '').toString()) ??
                previous?.unreadCount ??
                0);

        if (!mounted) return;
        setState(() {
          if (previous == null) {
            _metaByTeacherCode[teacherCode] = StudentConversationMeta(
              conversationId: conversationId,
              lastMessagePreview: null,
              lastMessageTimeLabel: timeLabel,
              lastMessageAt: lastMessageAt,
              unreadCount: unreadCount,
              lastMessageSenderType:
                  (conversation['last_message_sender_type'] ?? '').toString().trim().isEmpty
                      ? null
                      : (conversation['last_message_sender_type'] ?? '').toString().trim(),
              lastMessageDeliveryState: _statusFromMessage(latest!),
            );
          } else {
            _metaByTeacherCode[teacherCode] = previous.copyWith(
              lastMessageTimeLabel:
                  timeLabel.isNotEmpty ? timeLabel : previous.lastMessageTimeLabel,
              lastMessageAt: lastMessageAt ?? previous.lastMessageAt,
              unreadCount: unreadCount,
              lastMessageSenderType:
                  (conversation['last_message_sender_type'] ?? '').toString().trim().isEmpty
                      ? previous.lastMessageSenderType
                      : (conversation['last_message_sender_type'] ?? '').toString().trim(),
              lastMessageDeliveryState: _statusFromMessage(latest!),
            );
          }
        });
        return;
      }

      final messageRaw = payload['message'] ?? payload['msg'] ?? payload;
      if (messageRaw is! Map) return;

      final message = Map<String, dynamic>.from(messageRaw);
      final senderType = (message['sender_type'] ?? '').toString();
      final teacherCode = _teacherCodeByConversationId[conversationId];
      if (teacherCode == null || teacherCode.isEmpty) return;

      final lastPreview =
          (conversation['last_message'] ?? message['body'] ?? '').toString();
      final lastTimeRaw =
          (conversation['last_message_at'] ?? message['sent_at'] ?? '').toString();
      final lastMessageAt = chatParseUtcDate(lastTimeRaw);
      final timeLabel = lastTimeRaw.isEmpty
          ? ''
          : chatFormatTimeLabel(lastTimeRaw, forConversation: true);

      final isOpen =
          StudentChatSessionState.currentConversationId == conversationId;

      int unreadCount;
      if (isOpen || senderType == 'student') {
        unreadCount = 0;
      } else {
        final serverUnread = int.tryParse(
              (conversation['unread_for_student'] ?? conversation['unread_count'] ?? '')
                  .toString(),
            ) ??
            0;
        final previousUnread = _metaByTeacherCode[teacherCode]?.unreadCount ?? 0;
        unreadCount = serverUnread > 0 ? serverUnread : previousUnread + 1;
      }

      if (!mounted) return;
      setState(() {
        final previous = _metaByTeacherCode[teacherCode];
        _metaByTeacherCode[teacherCode] = StudentConversationMeta(
          conversationId: previous?.conversationId ?? conversationId,
          lastMessagePreview: lastPreview.isNotEmpty
              ? lastPreview
              : (previous?.lastMessagePreview ?? ''),
          lastMessageTimeLabel: timeLabel.isNotEmpty
              ? timeLabel
              : (previous?.lastMessageTimeLabel ?? ''),
          lastMessageAt: lastMessageAt ?? previous?.lastMessageAt,
          unreadCount: unreadCount,
          lastMessageSenderType: senderType.isNotEmpty
              ? senderType
              : previous?.lastMessageSenderType,
          lastMessageDeliveryState: _statusFromRaw(conversation) ??
              _statusFromRaw(message) ??
              _statusFromMessage(message),
        );
      });
    } catch (e) {
      debugPrint('StudentMessagesScreen: failed to handle event: $e');
    }
  }

  Map<String, dynamic>? _parseEventPayload(dynamic raw) {
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    }
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  int? _readOptionalInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _openChatForTeacher(StudentMessagesTeacher teacher) async {
    int? conversationId = _metaByTeacherCode[teacher.teacherCode]?.conversationId;

    if (conversationId == null) {
      try {
        // ✅ إزالة academicId (الطالب معروف من التوكن)
        final conversation = await ChatService.openStudentConversation(
          teacherCode: teacher.teacherCode,
          classSectionId: _readOptionalInt(teacher.raw['class_section_id']),
          subjectId: _readOptionalInt(teacher.raw['subject_id']),
        );

        final idRaw = conversation['id'];
        if (idRaw is int) {
          conversationId = idRaw;
        } else if (idRaw is String) {
          conversationId = int.tryParse(idRaw);
        }
        if (conversationId == null) {
          throw Exception(AppLocalizations.of(context).studentMessagesInvalidConversationId);
        }

        final lastTimeRaw = (conversation['last_message_at'] ?? '').toString();

        if (!mounted) return;
        setState(() {
          _metaByTeacherCode[teacher.teacherCode] = StudentConversationMeta(
            conversationId: conversationId!,
            lastMessagePreview: (conversation['last_message'] ?? '').toString(),
            lastMessageTimeLabel: lastTimeRaw.isEmpty
                ? ''
                : chatFormatTimeLabel(lastTimeRaw, forConversation: true),
            lastMessageAt: chatParseUtcDate(lastTimeRaw),
            unreadCount: int.tryParse(
                  (conversation['unread_for_student'] ?? conversation['unread_count'] ?? '0')
                      .toString(),
                ) ??
                0,
            lastMessageSenderType:
                (conversation['last_message_sender_type'] ?? '').toString().trim().isEmpty
                    ? null
                    : (conversation['last_message_sender_type'] ?? '').toString().trim(),
            lastMessageDeliveryState: _statusFromRaw(conversation),
          );
          _teacherCodeByConversationId[conversationId] = teacher.teacherCode;
        });

        await _subscribeToConversationChannel(conversationId);
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

    StudentChatSessionState.currentConversationId = conversationId;

    final meta = _metaByTeacherCode[teacher.teacherCode];
    if (meta != null && meta.unreadCount > 0 && mounted) {
      setState(() {
        _metaByTeacherCode[teacher.teacherCode] = meta.copyWith(unreadCount: 0);
      });
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentChatScreen(
          student: widget.student,
          teacher: teacher.raw,
          conversationId: conversationId!,
        ),
      ),
    );

    if (StudentChatSessionState.currentConversationId == conversationId) {
      StudentChatSessionState.currentConversationId = null;
    }

    await _loadStudentConversations(showLoading: false);
  }

  List<ChatConversationUiModel> _buildConversationItems() {
    final orderedTeachers = List<StudentMessagesTeacher>.from(_chatTeachers)
      ..sort((a, b) {
        final metaA = _metaByTeacherCode[a.teacherCode];
        final metaB = _metaByTeacherCode[b.teacherCode];
        final dateA = metaA?.lastMessageAt;
        final dateB = metaB?.lastMessageAt;

        if (dateA != null && dateB != null) return dateB.compareTo(dateA);
        if (dateA != null) return -1;
        if (dateB != null) return 1;
        return a.normalizedName.toLowerCase().compareTo(
              b.normalizedName.toLowerCase(),
            );
      });

    final query = _searchQuery.trim().toLowerCase();
    final items = <ChatConversationUiModel>[];

    for (final teacher in orderedTeachers) {
      final meta = _metaByTeacherCode[teacher.teacherCode];
      final unreadCount = meta?.unreadCount ?? 0;

      if (_activeFilterType == StudentMessagesFilterType.unread && unreadCount <= 0) {
        continue;
      }

      final title = teacher.normalizedName.isNotEmpty
          ? teacher.normalizedName
          : teacher.teacherCode;
      final metaLine = teacher.buildMetaLine();
      final preview = (meta?.lastMessagePreview?.trim().isNotEmpty ?? false)
          ? meta!.lastMessagePreview!.trim()
          : metaLine;

      final matchesSearch = query.isEmpty ||
          title.toLowerCase().contains(query) ||
          teacher.teacherCode.toLowerCase().contains(query);
      if (!matchesSearch) continue;

      items.add(
        ChatConversationUiModel(
          conversationId: meta?.conversationId ?? -1,
          primaryId: teacher.teacherCode,
          title: title,
          avatarText: title.isNotEmpty ? title[0].toUpperCase() : '?',
          avatarImageUrl:
              teacher.imageUrl != null && teacher.imageUrl!.isNotEmpty
                  ? ApiHelpers.buildFullMediaUrl(teacher.imageUrl!)
                  : null,
          preview: preview,
          metaLine: metaLine,
          timeLabel: meta?.lastMessageTimeLabel ?? '',
          unreadCount: unreadCount,
          lastMessageAt: meta?.lastMessageAt,
          raw: teacher.raw,
        ),
      );
    }

    return items;
  }

  Widget _buildSearchField(ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final fillColor = isDark
        ? EduTheme.darkSurfaceContainerLow
        : EduTheme.surface;
    final hintColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62);

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.24 : 0.80),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.studentMessagesSearchHint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: hintColor,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          suffixIcon: _searchQuery.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
          filled: true,
          fillColor: fillColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.22),
              width: 1.15,
            ),
          ),
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  String itemsCountLabel(int totalItems) => totalItems.toString();

  void _setAllFilter() {
    setState(() {
      _activeFilterType = StudentMessagesFilterType.all;
    });
  }

  void _setUnreadFilter() {
    setState(() {
      _activeFilterType = StudentMessagesFilterType.unread;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = _buildConversationItems();
    final hasSearch = _searchQuery.trim().isNotEmpty;
    final showSearchEmpty = items.isEmpty && hasSearch;
    final showLoadingSkeleton =
        _loadingConversations && _metaByTeacherCode.isEmpty;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? EduTheme.darkBackground : theme.scaffoldBackgroundColor,
              isDark
                  ? EduTheme.darkSurface.withValues(alpha: 0.35)
                  : EduTheme.softSecondaryBackground.withValues(alpha: 0.42),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => _loadStudentConversations(showLoading: false),
            child: CustomScrollView(
              controller: _listScrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.studentMessagesTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.studentMessagesSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSearchField(theme, isDark),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StudentMessagesFilterBar(
                            activeType: _activeFilterType,
                            onTapAll: _setAllFilter,
                            onTapUnread: _setUnreadFilter,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showLoadingSkeleton)
                  const SliverToBoxAdapter(
                    child: StudentMessagesLoadingList(),
                  )
                else if (showSearchEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: StudentMessagesSearchEmptyState(),
                  )
                else if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: StudentMessagesEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index.isOdd) {
                            return const SizedBox(height: 12);
                          }

                          final itemIndex = index ~/ 2;
                          final item = items[itemIndex];
                          final meta = _metaByTeacherCode[item.primaryId];
                          return StudentMessageItem(
                            avatarText: item.avatarText,
                            avatarImageUrl: item.avatarImageUrl,
                            name: item.title,
                            preview: item.preview,
                            metaLine: item.metaLine,
                            time: item.timeLabel,
                            unreadCount: item.unreadCount,
                            showOutgoingStatus:
                                meta?.lastMessageSenderType == 'student',
                            deliveryState: meta?.lastMessageDeliveryState,
                            onTap: () {
                              final teacher = _chatTeachers.firstWhere(
                                (entry) => entry.teacherCode == item.primaryId,
                                orElse: () => StudentMessagesTeacher(
                                  teacherCode: item.primaryId,
                                  name: item.title,
                                  imageUrl: null,
                                  raw: item.raw,
                                ),
                              );
                              _openChatForTeacher(teacher);
                            },
                          );
                        },
                        childCount: items.isEmpty ? 0 : (items.length * 2) - 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}