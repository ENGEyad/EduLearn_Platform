DateTime? chatParseUtcDate(String value) {
  try {
    if (value.trim().isEmpty) return null;
    var normalized = value.trim();

    if (!normalized.contains('T') && normalized.length >= 19) {
      normalized = normalized.substring(0, 19).replaceFirst(' ', 'T') + 'Z';
    }

    var dateTime = DateTime.parse(normalized);
    if (!dateTime.isUtc) {
      dateTime = DateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );
    }

    return dateTime;
  } catch (_) {
    return null;
  }
}

String chatFormatTimeOfDay(DateTime local) {
  var hour = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final isAm = hour < 12;
  final suffix = isAm ? 'AM' : 'PM';

  if (hour == 0) {
    hour = 12;
  } else if (hour > 12) {
    hour -= 12;
  }

  return '$hour:$minute $suffix';
}

String chatFormatConversationTime(DateTime local) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(date).inDays;

  if (diffDays == 0) return chatFormatTimeOfDay(local);
  if (diffDays == 1) return 'Yesterday';
  if (diffDays > 1 && diffDays < 7) {
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
  }

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

String chatFormatDateDivider(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diffDays = today.difference(target).inDays;

  if (diffDays == 0) return 'Today';
  if (diffDays == 1) return 'Yesterday';

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
  return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String chatFormatTimeLabel(
  String raw, {
  bool forConversation = false,
}) {
  final parsed = chatParseUtcDate(raw);
  if (parsed == null) return raw;

  final local = parsed.toLocal();
  return forConversation
      ? chatFormatConversationTime(local)
      : chatFormatTimeOfDay(local);
}

bool chatIsSameCalendarDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool chatIsMessageSentEvent(String name) {
  final normalized = name.trim();
  return normalized == 'message.sent' ||
      normalized == '.message.sent' ||
      normalized.endsWith('MessageSent') ||
      normalized.contains('MessageSent');
}

bool chatIsMessageStatusUpdatedEvent(String name) {
  final normalized = name.trim();
  return normalized == 'message.status.updated' ||
      normalized == '.message.status.updated' ||
      normalized.endsWith('MessageStatusUpdated') ||
      normalized.contains('MessageStatusUpdated');
}

bool chatIsTypingStatusEvent(String name) {
  final normalized = name.trim();
  return normalized == 'typing.status.changed' ||
      normalized == '.typing.status.changed' ||
      normalized.endsWith('TypingStatusChanged') ||
      normalized.contains('TypingStatusChanged');
}
