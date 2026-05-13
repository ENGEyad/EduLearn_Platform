part of 'teacher_messages_screen.dart';

enum TeacherMessagesFilterType {
  all,
  unread,
}

class TeacherMessagesStudent {
  final String id;
  final String name;
  final String academicId;
  final String? imageUrl;
  final String? grade;
  final String? section;
  final Map<String, dynamic> raw;

  TeacherMessagesStudent({
    required this.id,
    required this.name,
    required this.academicId,
    required this.imageUrl,
    required this.grade,
    required this.section,
    required this.raw,
  });

  String get normalizedName => name.trim();
  String get normalizedGrade => (grade ?? '').trim();
  String get normalizedSection => (section ?? '').trim();

  String buildMetaLine({
    required String gradeLabel,
    required String sectionLabel,
  }) {
    final parts = <String>[];

    if (normalizedGrade.isNotEmpty) {
      parts.add('$gradeLabel $normalizedGrade');
    }

    if (normalizedSection.isNotEmpty) {
      parts.add('$sectionLabel $normalizedSection');
    }

    return parts.join(' • ');
  }
}

class TeacherConversationMeta {
  final int conversationId;
  final String? lastMessagePreview;
  final String? lastMessageTimeLabel;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? lastMessageSenderType;
  final ChatMessageDeliveryState? lastMessageDeliveryState;

  TeacherConversationMeta({
    required this.conversationId,
    this.lastMessagePreview,
    this.lastMessageTimeLabel,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.lastMessageSenderType,
    this.lastMessageDeliveryState,
  });

  TeacherConversationMeta copyWith({
    int? conversationId,
    String? lastMessagePreview,
    String? lastMessageTimeLabel,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? lastMessageSenderType,
    ChatMessageDeliveryState? lastMessageDeliveryState,
  }) {
    return TeacherConversationMeta(
      conversationId: conversationId ?? this.conversationId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageTimeLabel: lastMessageTimeLabel ?? this.lastMessageTimeLabel,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageSenderType:
          lastMessageSenderType ?? this.lastMessageSenderType,
      lastMessageDeliveryState:
          lastMessageDeliveryState ?? this.lastMessageDeliveryState,
    );
  }
}