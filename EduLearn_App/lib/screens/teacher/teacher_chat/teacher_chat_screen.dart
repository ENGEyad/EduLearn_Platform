import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_chat_l10n.dart';
import '../../../services/api_helpers.dart';
import '../../../services/chat_service.dart';
import '../../../services/reverb_service.dart';
import '../../../theme.dart';
import '../../chat_shared/chat_message_ui_model.dart';
import '../../chat_shared/chat_shared_formatters.dart';
import '../../chat_shared/chat_session_state.dart';

part 'teacher_chat_models.dart';
part 'teacher_chat_widgets.dart';

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
  static const int _pageSize = 30;
  static const double _nearBottomThreshold = 140;

  final List<ChatMessageUiModel> _messages = [];
  final Set<String> _messageIds = {};

  bool _loading = false;
  bool _initialLoaded = false;
  bool _loadingMore = false;
  bool _sending = false;
  bool _showScrollToLatest = false;
  bool _studentTyping = false;
  int? _nextCursor;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _typingDebounce;
  Timer? _typingHideTimer;
  bool _typingSent = false;

  ReverbClient? _reverbClient;
  Channel? _channel;

  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString(); // kept for ReverbService only
  String get _studentName => (widget.student['full_name'] ?? '').toString();
  String get _academicId => (widget.student['academic_id'] ?? '').toString();
  String? get _studentImage => (widget.student['image'] as String?)?.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TeacherChatSessionState.currentConversationId = widget.conversationId;
    _scrollController.addListener(_onScroll);
    _loadInitialMessages();
    _initReverb();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initReverb();
      _markConversationDelivered();
      _markConversationRead();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _sendTypingStop();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels <= 120) {
      _loadOlderMessages();
    }

    final isNearBottom = _isNearBottom();
    if (_showScrollToLatest == !isNearBottom) return;

    setState(() {
      _showScrollToLatest = !isNearBottom;
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final remaining =
        _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    return remaining <= _nearBottomThreshold;
  }

  ChatMessageUiModel _mapMessage(Map<String, dynamic> message) {
    return ChatMessageUiModel.fromMap(
      message,
      dateParser: chatParseUtcDate,
    );
  }

  void _appendMessages(Iterable<Map<String, dynamic>> rawMessages) {
    for (final message in rawMessages) {
      final model = _mapMessage(message);
      if (model.id.isEmpty || _messageIds.contains(model.id)) continue;
      _messageIds.add(model.id);
      _messages.add(model);
    }
  }

  Future<void> _loadInitialMessages() async {
    if (_teacherCode.isEmpty) return;

    setState(() => _loading = true);

    try {
      // ✅ removed teacherCode
      final page = await ChatService.fetchConversationMessagesAsTeacher(
        conversationId: widget.conversationId,
        limit: _pageSize,
      );

      _messages.clear();
      _messageIds.clear();
      _appendMessages(page.messages);
      _nextCursor = page.nextCursor;

      if (!mounted) return;
      setState(() => _initialLoaded = true);
      _scrollToBottom(jump: true);
      await _markConversationDelivered();
      await _markConversationRead();
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_teacherCode.isEmpty || _loading || _loadingMore || _nextCursor == null) {
      return;
    }

    _loadingMore = true;
    final previousOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final previousMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    try {
      // ✅ removed teacherCode
      final page = await ChatService.fetchConversationMessagesAsTeacher(
        conversationId: widget.conversationId,
        limit: _pageSize,
        beforeId: _nextCursor,
      );

      final olderMessages = <ChatMessageUiModel>[];
      for (final raw in page.messages) {
        final model = _mapMessage(raw);
        if (model.id.isEmpty || _messageIds.contains(model.id)) continue;
        _messageIds.add(model.id);
        olderMessages.add(model);
      }

      _nextCursor = page.nextCursor;

      if (!mounted || olderMessages.isEmpty) return;

      setState(() {
        _messages.insertAll(0, olderMessages);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final newMaxExtent = _scrollController.position.maxScrollExtent;
        final delta = newMaxExtent - previousMaxExtent;
        final target = previousOffset + delta;

        _scrollController.jumpTo(
          target.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
        );
      });
    } catch (e) {
      debugPrint('Failed to load older messages: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).teacherChatFailedLoadOlderMessages,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } finally {
      _loadingMore = false;
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
        _handleChannelEvent,
        onError: (e) {
          debugPrint('TeacherChatScreen: channel error: $e');
        },
      );

      _channel!.subscribe();
    } catch (e) {
      debugPrint('TeacherChatScreen: Failed to init reverb: $e');
    }
  }

  void _handleChannelEvent(ChannelEvent event) {
    try {
      final payload = _normalizeEventPayload(event.data);
      if (payload == null) return;

      if (chatIsMessageSentEvent(event.eventName)) {
        final maybeMessage = payload['message'] ?? payload;
        if (maybeMessage is! Map) return;

        final model = _mapMessage(Map<String, dynamic>.from(maybeMessage));
        if (model.id.isEmpty || _messageIds.contains(model.id)) return;

        final shouldAutoScroll = _isNearBottom();

        if (!mounted) return;
        setState(() {
          _messageIds.add(model.id);
          _messages.add(model);
          _showScrollToLatest = !shouldAutoScroll;
        });

        if (shouldAutoScroll) {
          _scrollToBottom();
        }

        if (model.isStudent) {
          _markConversationRead();
        }
        return;
      }

      if (chatIsMessageStatusUpdatedEvent(event.eventName)) {
        final rawMessages = payload['messages'];
        if (rawMessages is List) {
          for (final item in rawMessages) {
            if (item is Map) {
              _applyStatusUpdate(Map<String, dynamic>.from(item));
            }
          }
          return;
        }

        final messageRaw = payload['message'];
        if (messageRaw is! Map) return;
        _applyStatusUpdate(Map<String, dynamic>.from(messageRaw));
        return;
      }

      if (chatIsTypingStatusEvent(event.eventName)) {
        final actorType = (payload['actor_type'] ?? '').toString();
        final isTyping = payload['is_typing'] == true;
        if (actorType == 'student') {
          _typingHideTimer?.cancel();
          if (!mounted) return;
          setState(() => _studentTyping = isTyping);
          if (isTyping) {
            _typingHideTimer = Timer(const Duration(seconds: 4), () {
              if (mounted) setState(() => _studentTyping = false);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('TeacherChatScreen: Failed to handle websocket msg: $e');
    }
  }

  void _applyStatusUpdate(Map<String, dynamic> messageMap) {
    final messageId = (messageMap['id'] ?? '').toString();
    if (messageId.isEmpty) return;

    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1 || !mounted) return;

    final current = _messages[index];
    final deliveredAtRaw = (messageMap['delivered_at'] ?? '').toString();
    final readAtRaw = (messageMap['read_at'] ?? '').toString();

    final deliveredAt = deliveredAtRaw.trim().isEmpty
        ? current.deliveredAt
        : chatParseUtcDate(deliveredAtRaw);
    final readAt = readAtRaw.trim().isEmpty
        ? current.readAt
        : chatParseUtcDate(readAtRaw);

    final ChatMessageDeliveryState state;
    if (readAt != null) {
      state = ChatMessageDeliveryState.read;
    } else if (deliveredAt != null) {
      state = ChatMessageDeliveryState.delivered;
    } else if (current.sentAt != null) {
      state = ChatMessageDeliveryState.sent;
    } else {
      state = current.deliveryState;
    }

    setState(() {
      _messages[index] = current.copyWith(
        deliveredAt: deliveredAt,
        readAt: readAt,
        deliveryState: state,
        raw: {
          ...current.raw,
          ...messageMap,
        },
      );
    });
  }

  Map<String, dynamic>? _normalizeEventPayload(dynamic raw) {
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

  Future<void> _markConversationDelivered() async {
    if (_teacherCode.isEmpty) return;
    try {
      // ✅ removed teacherCode
      await ChatService.markConversationDeliveredAsTeacher(
        conversationId: widget.conversationId,
      );
    } catch (e) {
      debugPrint('TeacherChatScreen: mark delivered failed: $e');
    }
  }

  Future<void> _markConversationRead() async {
    if (_teacherCode.isEmpty) return;
    try {
      // ✅ removed teacherCode
      await ChatService.markConversationReadAsTeacher(
        conversationId: widget.conversationId,
      );
    } catch (e) {
      debugPrint('TeacherChatScreen: mark read failed: $e');
    }
  }

  void _onInputChanged(String value) {
    if (value.trim().isEmpty) {
      _sendTypingStop();
      return;
    }

    if (!_typingSent) {
      _typingSent = true;
      // ✅ removed teacherCode
      ChatService.sendTypingStartAsTeacher(
        conversationId: widget.conversationId,
      ).catchError((e) {
        debugPrint('TeacherChatScreen: typing start failed: $e');
      });
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 1200), _sendTypingStop);
  }

  void _sendTypingStop() {
    _typingDebounce?.cancel();
    if (!_typingSent || _teacherCode.isEmpty) return;
    _typingSent = false;
    // ✅ removed teacherCode
    ChatService.sendTypingStopAsTeacher(
      conversationId: widget.conversationId,
    ).catchError((e) {
      debugPrint('TeacherChatScreen: typing stop failed: $e');
    });
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final text = (overrideText ?? _textController.text).trim();
    if (text.isEmpty || _sending) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = _mapMessage({
      'id': tempId,
      'body': text,
      'sender_type': 'teacher',
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      'is_temp': true,
    });

    final shouldAutoScroll = _isNearBottom();
    _sendTypingStop();

    if (mounted) {
      setState(() {
        _sending = true;
        _messageIds.add(tempId);
        _messages.add(tempMsg);
        _showScrollToLatest = !shouldAutoScroll;
      });
      _textController.clear();
      if (shouldAutoScroll) {
        _scrollToBottom();
      }
    }

    try {
      // ✅ removed teacherCode
      final sent = await ChatService.sendMessageAsTeacher(
        conversationId: widget.conversationId,
        messageBody: text,
      );

      final sentModel = _mapMessage(sent);

      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.removeWhere((message) => message.id == tempId);
        _messageIds.remove(tempId);

        final existingIndex = _messages.indexWhere((message) => message.id == sentModel.id);
        if (existingIndex != -1) {
          _messages[existingIndex] = sentModel;
        } else if (sentModel.id.isNotEmpty) {
          _messageIds.add(sentModel.id);
          _messages.add(sentModel);
        }
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (!mounted) return;

      final failed = _mapMessage({
        'id': tempId,
        'body': text,
        'sender_type': 'teacher',
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        'is_failed': true,
      });

      setState(() {
        _sending = false;
        final index = _messages.indexWhere((message) => message.id == tempId);
        if (index != -1) {
          _messages[index] = failed;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).teacherChatFailedSendMessage(e.toString()),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  Future<void> _retryMessage(ChatMessageUiModel message) async {
    setState(() {
      _messages.removeWhere((item) => item.id == message.id);
      _messageIds.remove(message.id);
    });
    await _sendMessage(overrideText: message.text);
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
          target.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }

      if (mounted) {
        setState(() => _showScrollToLatest = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (TeacherChatSessionState.currentConversationId == widget.conversationId) {
      TeacherChatSessionState.currentConversationId = null;
    }

    _typingDebounce?.cancel();
    _typingHideTimer?.cancel();
    _sendTypingStop();
    _scrollController.removeListener(_onScroll);
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
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subtitleParts = <String>[];
    if (widget.grade != null && widget.grade!.isNotEmpty) {
      subtitleParts.add('${l10n.teacherChatGrade} ${widget.grade}');
    }
    if (widget.section != null && widget.section!.isNotEmpty) {
      subtitleParts.add('${l10n.teacherChatSection} ${widget.section}');
    }
    final subtitle = subtitleParts.join(' • ');

    final avatarUrl = _studentImage != null && _studentImage!.isNotEmpty
        ? ApiHelpers.buildFullMediaUrl(_studentImage!)
        : null;

    final titleColor = theme.colorScheme.onSurface;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final appBarSurface = isDark
        ? EduTheme.darkSurfaceContainerLow.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.88);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _studentTyping
                        ? l10n.teacherChatStudentTyping
                        : (subtitle.isNotEmpty ? subtitle : l10n.teacherChatDirectConversation),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _studentTyping
                          ? theme.colorScheme.primary
                          : mutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: appBarSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: EduTheme.pageGradient(isDark),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                if (_loadingMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: _loading && !_initialLoaded
                      ? const TeacherChatLoadingSkeleton()
                      : _messages.isEmpty
                          ? const TeacherChatEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final previous =
                                    index > 0 ? _messages[index - 1] : null;
                                final next = index < _messages.length - 1
                                    ? _messages[index + 1]
                                    : null;

                                final date = message.sentAt?.toLocal();
                                String? dateHeader;
                                if (date != null) {
                                  final previousDate = previous?.sentAt?.toLocal();
                                  if (previousDate == null ||
                                      !chatIsSameCalendarDate(previousDate, date)) {
                                    dateHeader = chatFormatDateDivider(date);
                                  }
                                }

                                final mergeWithPrevious = previous != null &&
                                    previous.senderType == message.senderType &&
                                    previous.sentAt != null &&
                                    message.sentAt != null &&
                                    chatIsSameCalendarDate(
                                      previous.sentAt!.toLocal(),
                                      message.sentAt!.toLocal(),
                                    );

                                final mergeWithNext = next != null &&
                                    next.senderType == message.senderType &&
                                    next.sentAt != null &&
                                    message.sentAt != null &&
                                    chatIsSameCalendarDate(
                                      next.sentAt!.toLocal(),
                                      message.sentAt!.toLocal(),
                                    );

                                final createdTimeLabel = message.sentAt == null
                                    ? ''
                                    : chatFormatTimeOfDay(
                                        message.sentAt!.toLocal(),
                                      );

                                return Column(
                                  children: [
                                    if (dateHeader != null)
                                      TeacherChatDateChip(label: dateHeader),
                                    TeacherChatBubble(
                                      isMe: message.isTeacher,
                                      text: message.text,
                                      timeLabel: createdTimeLabel,
                                      deliveryState: message.deliveryState,
                                      showTopSpacing: !mergeWithPrevious,
                                      mergeWithPrevious: mergeWithPrevious,
                                      mergeWithNext: mergeWithNext,
                                      onRetry: message.isTeacher && message.isFailed
                                          ? () => _retryMessage(message)
                                          : null,
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
                TeacherChatInputBar(
                  controller: _textController,
                  onSend: _sendMessage,
                  onChanged: _onInputChanged,
                  isSending: _sending,
                ),
              ],
            ),
            if (_showScrollToLatest)
              Positioned(
                right: 16,
                bottom: 92,
                child: TeacherChatScrollToLatestButton(
                  onTap: () => _scrollToBottom(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}