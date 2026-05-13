import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_messages_l10n.dart';
import '../../../services/api_helpers.dart';
import '../../../services/chat_service.dart';
import '../../../services/teacher_data_service.dart';
import '../../../services/reverb_service.dart';
import '../../../theme.dart';
import '../../chat_shared/chat_conversation_ui_model.dart';
import '../../chat_shared/chat_message_ui_model.dart';
import '../../chat_shared/chat_session_state.dart';
import '../../chat_shared/chat_shared_formatters.dart';
import '../teacher_chat/teacher_chat_screen.dart';

part 'teacher_messages_models.dart';
part 'teacher_messages_widgets.dart';

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
  late final ScrollController _listScrollController;
  late List<TeacherMessagesStudent> _chatStudents;

  final Map<String, TeacherConversationMeta> _metaByAcademicId = {};
  final Map<int, String> _academicIdByConversationId = {};
  final Map<int, Channel> _conversationChannels = {};
  final TextEditingController _searchController = TextEditingController();

  ReverbClient? _reverbClient;

  bool _loadingConversations = false;
  bool _loadingStudents = false;
  String _searchQuery = '';
  TeacherMessagesFilterType _activeFilterType = TeacherMessagesFilterType.all;
  String? _activeGradeFilter;
  String? _activeSectionFilter;

  String get _teacherCode => (widget.teacher['teacher_code'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listScrollController = ScrollController();
    _chatStudents = _extractChatStudents();
    _loadChatStudents();
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

  List<TeacherMessagesStudent> _extractChatStudents([
    List<dynamic>? sourceAssignments,
  ]) {
    final byId = <String, TeacherMessagesStudent>{};
    final assignments = sourceAssignments ?? widget.assignments;

    for (final assignment in assignments) {
      if (assignment is! Map<String, dynamic>) continue;

      final grade = (assignment['class_grade'] ?? '').toString().trim();
      final section = (assignment['class_section'] ?? '').toString().trim();
      final students = assignment['students'];
      if (students is! List) continue;

      for (final student in students) {
        if (student is! Map<String, dynamic>) continue;

        final id =
            (student['id'] ?? student['student_id'] ?? student['academic_id'] ?? '')
                .toString()
                .trim();

        if (id.isEmpty || byId.containsKey(id)) continue;

        byId[id] = TeacherMessagesStudent(
          id: id,
          name: (student['full_name'] ?? '').toString().trim(),
          academicId: (student['academic_id'] ?? '').toString().trim(),
          imageUrl: student['image'] as String?,
          grade: grade,
          section: section,
          raw: student,
        );
      }
    }

    final list = byId.values.toList();
    list.sort(
      (a, b) => a.normalizedName.toLowerCase().compareTo(
            b.normalizedName.toLowerCase(),
          ),
    );
    return list;
  }

  Future<void> _loadChatStudents() async {
    if (_teacherCode.isEmpty || _loadingStudents) return;

    setState(() => _loadingStudents = true);

    try {
      final assignments = await TeacherDataService.fetchAssignmentsSummary();

      final enrichedAssignments = <Map<String, dynamic>>[];

      for (final item in assignments) {
        if (item is! Map) continue;
        final assignment = Map<String, dynamic>.from(item);
        final assignmentIdRaw = assignment['assignment_id'];
        final assignmentId = assignmentIdRaw is int
            ? assignmentIdRaw
            : int.tryParse(assignmentIdRaw?.toString() ?? '');

        if (assignmentId == null || assignmentId <= 0) continue;

        try {
          final students = await TeacherDataService.fetchAssignmentStudents(
            assignmentId: assignmentId,
          );
          assignment['students'] = students;
        } catch (_) {
          assignment['students'] = <dynamic>[];
        }

        enrichedAssignments.add(assignment);
      }

      final students = _extractChatStudents(enrichedAssignments);

      if (!mounted) return;
      setState(() {
        _chatStudents = students;
      });
    } catch (e) {
      debugPrint('Failed to load teacher chat students: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingStudents = false);
      } else {
        _loadingStudents = false;
      }
    }
  }

  ChatMessageDeliveryState? _statusFromRaw(Map<String, dynamic> raw) {
    final value = (raw['last_message_status'] ?? raw['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

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

  Future<void> _loadTeacherConversations({required bool showLoading}) async {
    if (_teacherCode.isEmpty) return;

    if (showLoading && mounted) {
      setState(() => _loadingConversations = true);
    }

    try {
      final conversations = await ChatService.fetchTeacherConversations();

      final map = <String, TeacherConversationMeta>{};
      _academicIdByConversationId.clear();

      for (final item in conversations) {
        if (item is! Map<String, dynamic>) continue;

        final student = item['student'];
        if (student is! Map<String, dynamic>) continue;

        final academicId = (student['academic_id'] ?? '').toString().trim();
        if (academicId.isEmpty) continue;

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
        final unreadCount = int.tryParse(
              (item['unread_for_teacher'] ?? item['unread_count'] ?? '0')
                  .toString(),
            ) ??
            0;

        _academicIdByConversationId[conversationId] = academicId;
        map[academicId] = TeacherConversationMeta(
          conversationId: conversationId,
          lastMessagePreview: lastPreview,
          lastMessageTimeLabel: lastTimeRaw.isEmpty
              ? ''
              : chatFormatTimeLabel(lastTimeRaw, forConversation: true),
          lastMessageAt: chatParseUtcDate(lastTimeRaw),
          unreadCount: unreadCount,
          lastMessageSenderType:
              (item['last_message_sender_type'] ?? '').toString().trim().isEmpty
                  ? null
                  : (item['last_message_sender_type'] ?? '').toString().trim(),
          lastMessageDeliveryState: _statusFromRaw(item),
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

      if (!mounted || !showLoading) return;

      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.teacherMessagesFailedLoadConversations(e.toString()),
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

    if (_reverbClient == null ||
        _conversationChannels.containsKey(conversationId)) {
      return;
    }

    try {
      final channelName = 'private-conversation.$conversationId';
      final channel = _reverbClient!.subscribeToChannel(channelName);

      channel.stream.listen(
        (ChannelEvent event) =>
            _handleConversationChannelEvent(conversationId, event),
        onError: (e) {
          debugPrint(
            'TeacherMessagesScreen: error on channel $conversationId: $e',
          );
        },
      );

      channel.subscribe();
      _conversationChannels[conversationId] = channel;
    } catch (e) {
      debugPrint(
        'TeacherMessagesScreen: failed to subscribe to conv $conversationId: $e',
      );
    }
  }

  Future<void> _resubscribeToConversationChannels() async {
    final neededConversationIds = <int>{
      for (final meta in _metaByAcademicId.values) meta.conversationId,
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

        final academicId = _academicIdByConversationId[conversationId];
        if (academicId == null || academicId.isEmpty) return;

        final previous = _metaByAcademicId[academicId];
        final lastTimeRaw =
            (conversation['last_message_at'] ?? latest['sent_at'] ?? '')
                .toString();
        final lastMessageAt = chatParseUtcDate(lastTimeRaw);
        final timeLabel = lastTimeRaw.isEmpty
            ? ''
            : chatFormatTimeLabel(lastTimeRaw, forConversation: true);
        final isOpen =
            TeacherChatSessionState.currentConversationId == conversationId;
        final unreadCount = isOpen
            ? 0
            : (int.tryParse(
                      (conversation['unread_for_teacher'] ?? '').toString(),
                    ) ??
                    previous?.unreadCount ??
                    0);

        if (!mounted) return;
        setState(() {
          if (previous == null) {
            _metaByAcademicId[academicId] = TeacherConversationMeta(
              conversationId: conversationId,
              lastMessagePreview: null,
              lastMessageTimeLabel: timeLabel,
              lastMessageAt: lastMessageAt,
              unreadCount: unreadCount,
              lastMessageSenderType:
                  (conversation['last_message_sender_type'] ?? '')
                          .toString()
                          .trim()
                          .isEmpty
                      ? null
                      : (conversation['last_message_sender_type'] ?? '')
                          .toString()
                          .trim(),
              lastMessageDeliveryState: _statusFromMessage(latest!),
            );
          } else {
            _metaByAcademicId[academicId] = previous.copyWith(
              lastMessageTimeLabel:
                  timeLabel.isNotEmpty ? timeLabel : previous.lastMessageTimeLabel,
              lastMessageAt: lastMessageAt ?? previous.lastMessageAt,
              unreadCount: unreadCount,
              lastMessageSenderType:
                  (conversation['last_message_sender_type'] ?? '')
                          .toString()
                          .trim()
                          .isEmpty
                      ? previous.lastMessageSenderType
                      : (conversation['last_message_sender_type'] ?? '')
                          .toString()
                          .trim(),
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
      final academicId = _academicIdByConversationId[conversationId];
      if (academicId == null || academicId.isEmpty) return;

      final lastPreview =
          (conversation['last_message'] ?? message['body'] ?? '').toString();
      final lastTimeRaw =
          (conversation['last_message_at'] ?? message['sent_at'] ?? '')
              .toString();
      final lastMessageAt = chatParseUtcDate(lastTimeRaw);
      final timeLabel = lastTimeRaw.isEmpty
          ? ''
          : chatFormatTimeLabel(lastTimeRaw, forConversation: true);

      final isOpen =
          TeacherChatSessionState.currentConversationId == conversationId;

      int unreadCount;
      if (isOpen || senderType == 'teacher') {
        unreadCount = 0;
      } else {
        final serverUnread = int.tryParse(
              (conversation['unread_for_teacher'] ??
                      conversation['unread_count'] ??
                      '')
                  .toString(),
            ) ??
            0;
        final previousUnread = _metaByAcademicId[academicId]?.unreadCount ?? 0;
        unreadCount = serverUnread > 0 ? serverUnread : previousUnread + 1;
      }

      if (!mounted) return;
      setState(() {
        final previous = _metaByAcademicId[academicId];
        _metaByAcademicId[academicId] = TeacherConversationMeta(
          conversationId: previous?.conversationId ?? conversationId,
          lastMessagePreview: lastPreview.isNotEmpty
              ? lastPreview
              : (previous?.lastMessagePreview ?? ''),
          lastMessageTimeLabel: timeLabel.isNotEmpty
              ? timeLabel
              : (previous?.lastMessageTimeLabel ?? ''),
          lastMessageAt: lastMessageAt ?? previous?.lastMessageAt,
          unreadCount: unreadCount,
          lastMessageSenderType:
              senderType.isNotEmpty ? senderType : previous?.lastMessageSenderType,
          lastMessageDeliveryState: _statusFromRaw(conversation) ??
              _statusFromRaw(message) ??
              _statusFromMessage(message),
        );
      });
    } catch (e) {
      debugPrint('TeacherMessagesScreen: failed to handle event: $e');
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

  Future<void> _openChatForStudent(TeacherMessagesStudent student) async {
    final l10n = AppLocalizations.of(context);
    int? conversationId = _metaByAcademicId[student.academicId]?.conversationId;

    if (conversationId == null) {
      try {
        final conversation = await ChatService.openTeacherConversation(
          academicId: student.academicId,
          classSectionId: student.raw['class_section_id'] is int
              ? student.raw['class_section_id'] as int
              : int.tryParse(
                  (student.raw['class_section_id'] ?? '').toString(),
                ),
          subjectId: null,
        );

        final idRaw = conversation['id'];
        if (idRaw is int) {
          conversationId = idRaw;
        } else if (idRaw is String) {
          conversationId = int.tryParse(idRaw);
        }

        if (conversationId == null) {
          throw Exception(l10n.teacherMessagesInvalidConversationId);
        }

        final lastTimeRaw = (conversation['last_message_at'] ?? '').toString();

        if (!mounted) return;
        setState(() {
          _metaByAcademicId[student.academicId] = TeacherConversationMeta(
            conversationId: conversationId!,
            lastMessagePreview: (conversation['last_message'] ?? '').toString(),
            lastMessageTimeLabel: lastTimeRaw.isEmpty
                ? ''
                : chatFormatTimeLabel(lastTimeRaw, forConversation: true),
            lastMessageAt: chatParseUtcDate(lastTimeRaw),
            unreadCount: int.tryParse(
                  (conversation['unread_for_teacher'] ??
                          conversation['unread_count'] ??
                          '0')
                      .toString(),
                ) ??
                0,
            lastMessageSenderType:
                (conversation['last_message_sender_type'] ?? '')
                        .toString()
                        .trim()
                        .isEmpty
                    ? null
                    : (conversation['last_message_sender_type'] ?? '')
                        .toString()
                        .trim(),
            lastMessageDeliveryState: _statusFromRaw(conversation),
          );
          _academicIdByConversationId[conversationId!] = student.academicId;
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

    TeacherChatSessionState.currentConversationId = conversationId;

    final meta = _metaByAcademicId[student.academicId];
    if (meta != null && meta.unreadCount > 0 && mounted) {
      setState(() {
        _metaByAcademicId[student.academicId] = meta.copyWith(unreadCount: 0);
      });
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherChatScreen(
          teacher: widget.teacher,
          student: student.raw,
          grade: student.grade,
          section: student.section,
          conversationId: conversationId!,
        ),
      ),
    );

    if (TeacherChatSessionState.currentConversationId == conversationId) {
      TeacherChatSessionState.currentConversationId = null;
    }

    await _loadTeacherConversations(showLoading: false);
  }

  List<String> _extractAvailableGrades() {
    final grades = <String>{};

    for (final student in _chatStudents) {
      if (student.normalizedGrade.isNotEmpty) {
        grades.add(student.normalizedGrade);
      }
    }

    final list = grades.toList()..sort();
    return list;
  }

  List<String> _extractAvailableSections() {
    final sections = <String>{};

    for (final student in _chatStudents) {
      if (student.normalizedSection.isNotEmpty) {
        sections.add(student.normalizedSection);
      }
    }

    final list = sections.toList()..sort();
    return list;
  }

  List<ChatConversationUiModel> _buildConversationItems() {
    final l10n = AppLocalizations.of(context);

    final orderedStudents = List<TeacherMessagesStudent>.from(_chatStudents)
      ..sort((a, b) {
        final metaA = _metaByAcademicId[a.academicId];
        final metaB = _metaByAcademicId[b.academicId];
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

    for (final student in orderedStudents) {
      final meta = _metaByAcademicId[student.academicId];
      final unreadCount = meta?.unreadCount ?? 0;

      if (_activeFilterType == TeacherMessagesFilterType.unread &&
          unreadCount <= 0) {
        continue;
      }

      if (_activeGradeFilter != null &&
          _activeGradeFilter!.isNotEmpty &&
          student.normalizedGrade != _activeGradeFilter) {
        continue;
      }

      if (_activeSectionFilter != null &&
          _activeSectionFilter!.isNotEmpty &&
          student.normalizedSection != _activeSectionFilter) {
        continue;
      }

      final title =
          student.normalizedName.isNotEmpty ? student.normalizedName : student.academicId;

      final metaLine = student.buildMetaLine(
        gradeLabel: l10n.teacherMessagesGrade,
        sectionLabel: l10n.teacherMessagesSection,
      );

      final preview = (meta?.lastMessagePreview?.trim().isNotEmpty ?? false)
          ? meta!.lastMessagePreview!.trim()
          : metaLine;

      final matchesSearch = query.isEmpty ||
          title.toLowerCase().contains(query) ||
          student.academicId.toLowerCase().contains(query) ||
          student.normalizedGrade.toLowerCase().contains(query) ||
          student.normalizedSection.toLowerCase().contains(query);

      if (!matchesSearch) continue;

      items.add(
        ChatConversationUiModel(
          conversationId: meta?.conversationId ?? -1,
          primaryId: student.academicId,
          title: title,
          avatarText: title.isNotEmpty ? title[0].toUpperCase() : '?',
          avatarImageUrl:
              student.imageUrl != null && student.imageUrl!.isNotEmpty
                  ? ApiHelpers.buildFullMediaUrl(student.imageUrl!)
                  : null,
          preview: preview,
          metaLine: metaLine,
          timeLabel: meta?.lastMessageTimeLabel ?? '',
          unreadCount: unreadCount,
          lastMessageAt: meta?.lastMessageAt,
          raw: student.raw,
        ),
      );
    }

    return items;
  }

  Future<void> _showAdvancedFilterSheet() async {
    final l10n = AppLocalizations.of(context);
    final grades = _extractAvailableGrades();
    final sections = _extractAvailableSections();

    String? selectedGrade = _activeGradeFilter;
    String? selectedSection = _activeSectionFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sheetColor = theme.cardColor;
        final mutedColor = theme.textTheme.bodySmall?.color ??
            (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildOptionChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => onTap(),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedColor:
                      theme.colorScheme.primary.withValues(alpha: 0.14),
                  backgroundColor: isDark
                      ? EduTheme.darkSurfaceContainerLow
                      : EduTheme.softSecondaryBackground,
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.28)
                        : theme.dividerColor.withValues(alpha: 0.28),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  visualDensity:
                      const VisualDensity(horizontal: -1, vertical: -1),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.dividerColor.withValues(
                        alpha: isDark ? 0.30 : 0.60,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.28 : 0.10,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.teacherMessagesFilterStudents,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.teacherMessagesFilterStudentsSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.teacherMessagesGrade,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          children: [
                            buildOptionChip(
                              label: l10n.teacherMessagesAny,
                              selected: selectedGrade == null,
                              onTap: () {
                                setModalState(() => selectedGrade = null);
                              },
                            ),
                            for (final grade in grades)
                              buildOptionChip(
                                label: '${l10n.teacherMessagesGrade} $grade',
                                selected: selectedGrade == grade,
                                onTap: () {
                                  setModalState(() => selectedGrade = grade);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.teacherMessagesSection,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          children: [
                            buildOptionChip(
                              label: l10n.teacherMessagesAny,
                              selected: selectedSection == null,
                              onTap: () {
                                setModalState(() => selectedSection = null);
                              },
                            ),
                            for (final section in sections)
                              buildOptionChip(
                                label:
                                    '${l10n.teacherMessagesSection} $section',
                                selected: selectedSection == section,
                                onTap: () {
                                  setModalState(() => selectedSection = section);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _activeGradeFilter = null;
                                    _activeSectionFilter = null;
                                    _activeFilterType =
                                        TeacherMessagesFilterType.all;
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: Text(l10n.teacherMessagesClear),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _activeGradeFilter = selectedGrade;
                                    _activeSectionFilter = selectedSection;
                                    _activeFilterType =
                                        TeacherMessagesFilterType.all;
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: Text(l10n.teacherMessagesApply),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchField(ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context);

    final fillColor =
        isDark ? EduTheme.darkSurfaceContainerLow : EduTheme.surface;
    final hintColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62);

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
          hintText: l10n.teacherMessagesSearchHint,
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

  Widget _buildTopSummaryCard(
    ThemeData theme, {
    required int totalItems,
    required bool showLoadingSkeleton,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final activeCount = itemsCountLabel(totalItems);
    final unreadTotal = _metaByAcademicId.values.fold<int>(
      0,
      (sum, meta) => sum + meta.unreadCount,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.055),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.teacherMessagesRecentConversations,
                      style: GoogleFonts.nunito(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.teacherMessagesRecentConversationsSubtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loadingConversations && !showLoadingSkeleton)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadTotal > 0
                        ? l10n.teacherMessagesUnreadCount(unreadTotal)
                        : l10n.teacherMessagesAllCaughtUp,
                    style: GoogleFonts.nunito(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TeacherMessagesMetricTile(
                  label: l10n.teacherMessagesStudents,
                  value: activeCount,
                  icon: Icons.people_alt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeacherMessagesMetricTile(
                  label: l10n.teacherMessagesUnread,
                  value: unreadTotal.toString(),
                  icon: Icons.mark_chat_unread_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String itemsCountLabel(int totalItems) => totalItems.toString();

  void _setAllFilter() {
    setState(() {
      _activeFilterType = TeacherMessagesFilterType.all;
      _activeGradeFilter = null;
      _activeSectionFilter = null;
    });
  }

  void _setUnreadFilter() {
    setState(() {
      _activeFilterType = TeacherMessagesFilterType.unread;
      _activeGradeFilter = null;
      _activeSectionFilter = null;
    });
  }

  void _clearAdvancedFilter() {
    setState(() {
      _activeGradeFilter = null;
      _activeSectionFilter = null;
      _activeFilterType = TeacherMessagesFilterType.all;
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
        _loadingConversations && _metaByAcademicId.isEmpty;
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
              isDark
                  ? EduTheme.darkBackground
                  : theme.scaffoldBackgroundColor,
              isDark
                  ? EduTheme.darkSurface.withValues(alpha: 0.35)
                  : EduTheme.softSecondaryBackground.withValues(alpha: 0.42),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => _loadTeacherConversations(showLoading: false),
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
                          l10n.teacherMessagesTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.teacherMessagesSubtitle,
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
                          child: TeacherMessagesFilterBar(
                            activeType: _activeFilterType,
                            activeGrade: _activeGradeFilter,
                            activeSection: _activeSectionFilter,
                            onTapAll: _setAllFilter,
                            onTapUnread: _setUnreadFilter,
                            onTapAdvancedFilter: _showAdvancedFilterSheet,
                            onClearAdvancedFilter: _clearAdvancedFilter,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (showLoadingSkeleton)
                  const SliverToBoxAdapter(
                    child: TeacherMessagesLoadingList(),
                  )
                else if (showSearchEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: TeacherMessagesSearchEmptyState(),
                  )
                else if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: TeacherMessagesEmptyState(),
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
                          final meta = _metaByAcademicId[item.primaryId];

                          return TeacherMessageItem(
                            avatarText: item.avatarText,
                            avatarImageUrl: item.avatarImageUrl,
                            name: item.title,
                            preview: item.preview,
                            metaLine: item.metaLine,
                            time: item.timeLabel,
                            unreadCount: item.unreadCount,
                            showOutgoingStatus:
                                meta?.lastMessageSenderType == 'teacher',
                            deliveryState: meta?.lastMessageDeliveryState,
                            onTap: () {
                              final student = _chatStudents.firstWhere(
                                (entry) => entry.academicId == item.primaryId,
                                orElse: () => TeacherMessagesStudent(
                                  id: item.primaryId,
                                  name: item.title,
                                  academicId: item.primaryId,
                                  imageUrl: null,
                                  grade: null,
                                  section: null,
                                  raw: item.raw,
                                ),
                              );
                              _openChatForStudent(student);
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