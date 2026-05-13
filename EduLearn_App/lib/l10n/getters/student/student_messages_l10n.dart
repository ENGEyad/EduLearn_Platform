import '../../core/app_localizations.dart';

extension StudentMessagesL10n on AppLocalizations {
  String get studentMessagesTitle => getValue('student_messages_title');

  String get studentMessagesSubtitle {
    return getValue('student_messages_subtitle');
  }

  String get studentMessagesSearchHint {
    return getValue('student_messages_search_hint');
  }

  String get studentMessagesAll => getValue('student_messages_all');

  String get studentMessagesUnread => getValue('student_messages_unread');

  String get studentMessagesEmptyTitle {
    return getValue('student_messages_empty_title');
  }

  String get studentMessagesEmptySubtitle {
    return getValue('student_messages_empty_subtitle');
  }

  String get studentMessagesSearchEmptyTitle {
    return getValue('student_messages_search_empty_title');
  }

  String get studentMessagesSearchEmptySubtitle {
    return getValue('student_messages_search_empty_subtitle');
  }

  String studentMessagesFailedLoadConversations(String error) {
    return formatValue(
      'student_messages_failed_load_conversations',
      {'error': error},
    );
  }

  String get studentMessagesInvalidConversationId {
    return getValue('student_messages_invalid_conversation_id');
  }
}
