enum ChatMessageDeliveryState {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessageUiModel {
  final String id;
  final String text;
  final String senderType;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isTemp;
  final ChatMessageDeliveryState deliveryState;
  final Map<String, dynamic> raw;

  const ChatMessageUiModel({
    required this.id,
    required this.text,
    required this.senderType,
    required this.sentAt,
    required this.deliveredAt,
    required this.readAt,
    required this.isTemp,
    required this.deliveryState,
    required this.raw,
  });

  bool get isTeacher => senderType == 'teacher';
  bool get isStudent => senderType == 'student';
  bool get isFailed => deliveryState == ChatMessageDeliveryState.failed;

  String get sentAtRaw => (raw['sent_at'] ?? '').toString();
  String get deliveredAtRaw => (raw['delivered_at'] ?? '').toString();
  String get readAtRaw => (raw['read_at'] ?? '').toString();

  ChatMessageUiModel copyWith({
    String? id,
    String? text,
    String? senderType,
    DateTime? sentAt,
    Object? deliveredAt = _sentinel,
    Object? readAt = _sentinel,
    bool? isTemp,
    ChatMessageDeliveryState? deliveryState,
    Map<String, dynamic>? raw,
  }) {
    return ChatMessageUiModel(
      id: id ?? this.id,
      text: text ?? this.text,
      senderType: senderType ?? this.senderType,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: identical(deliveredAt, _sentinel)
          ? this.deliveredAt
          : deliveredAt as DateTime?,
      readAt: identical(readAt, _sentinel) ? this.readAt : readAt as DateTime?,
      isTemp: isTemp ?? this.isTemp,
      deliveryState: deliveryState ?? this.deliveryState,
      raw: raw ?? this.raw,
    );
  }

  factory ChatMessageUiModel.fromMap(
    Map<String, dynamic> map, {
    DateTime? Function(String value)? dateParser,
  }) {
    final sentAtRaw = (map['sent_at'] ?? '').toString();
    final deliveredAtRaw = (map['delivered_at'] ?? '').toString();
    final readAtRaw = (map['read_at'] ?? '').toString();

    final parsedSentAt =
        dateParser != null && sentAtRaw.isNotEmpty ? dateParser(sentAtRaw) : null;
    final parsedDeliveredAt = dateParser != null && deliveredAtRaw.isNotEmpty
        ? dateParser(deliveredAtRaw)
        : null;
    final parsedReadAt =
        dateParser != null && readAtRaw.isNotEmpty ? dateParser(readAtRaw) : null;

    final isTemp = map['is_temp'] == true;
    final isFailed = map['is_failed'] == true;

    final ChatMessageDeliveryState state;
    if (isFailed) {
      state = ChatMessageDeliveryState.failed;
    } else if (isTemp) {
      state = ChatMessageDeliveryState.sending;
    } else if (parsedReadAt != null) {
      state = ChatMessageDeliveryState.read;
    } else if (parsedDeliveredAt != null) {
      state = ChatMessageDeliveryState.delivered;
    } else {
      state = ChatMessageDeliveryState.sent;
    }

    return ChatMessageUiModel(
      id: (map['id'] ?? '').toString(),
      text: (map['body'] ?? '').toString(),
      senderType: (map['sender_type'] ?? '').toString(),
      sentAt: parsedSentAt,
      deliveredAt: parsedDeliveredAt,
      readAt: parsedReadAt,
      isTemp: isTemp,
      deliveryState: state,
      raw: Map<String, dynamic>.from(map),
    );
  }
}

const _sentinel = Object();
