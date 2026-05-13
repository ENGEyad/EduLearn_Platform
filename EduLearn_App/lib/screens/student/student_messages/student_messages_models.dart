
part of 'student_messages_screen.dart';

enum StudentMessagesFilterType {
  all,
  unread,
}

class StudentMessagesTeacher {
  final String teacherCode;
  final String name;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  StudentMessagesTeacher({
    required this.teacherCode,
    required this.name,
    required this.imageUrl,
    required this.raw,
  });

  String get normalizedName => name.trim();

  String buildMetaLine() {
    return '';
  }
}

class StudentConversationMeta {
  final int conversationId;
  final String? lastMessagePreview;
  final String? lastMessageTimeLabel;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? lastMessageSenderType;
  final ChatMessageDeliveryState? lastMessageDeliveryState;

  StudentConversationMeta({
    required this.conversationId,
    this.lastMessagePreview,
    this.lastMessageTimeLabel,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.lastMessageSenderType,
    this.lastMessageDeliveryState,
  });

  StudentConversationMeta copyWith({
    int? conversationId,
    String? lastMessagePreview,
    String? lastMessageTimeLabel,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? lastMessageSenderType,
    ChatMessageDeliveryState? lastMessageDeliveryState,
  }) {
    return StudentConversationMeta(
      conversationId: conversationId ?? this.conversationId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageTimeLabel: lastMessageTimeLabel ?? this.lastMessageTimeLabel,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageSenderType: lastMessageSenderType ?? this.lastMessageSenderType,
      lastMessageDeliveryState:
          lastMessageDeliveryState ?? this.lastMessageDeliveryState,
    );
  }
}
