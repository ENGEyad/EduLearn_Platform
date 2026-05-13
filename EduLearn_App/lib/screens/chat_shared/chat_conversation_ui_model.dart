class ChatConversationUiModel {
  final int conversationId;
  final String primaryId;
  final String title;
  final String avatarText;
  final String? avatarImageUrl;
  final String preview;
  final String metaLine;
  final String timeLabel;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final Map<String, dynamic> raw;

  const ChatConversationUiModel({
    required this.conversationId,
    required this.primaryId,
    required this.title,
    required this.avatarText,
    required this.avatarImageUrl,
    required this.preview,
    required this.metaLine,
    required this.timeLabel,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.raw,
  });

  bool get hasUnread => unreadCount > 0;
}
