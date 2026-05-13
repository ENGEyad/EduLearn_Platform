import '../../core/app_localizations.dart';

extension TeacherMessagesL10n on AppLocalizations {
  String get teacherMessagesTitle => getValue('teacher_messages_title');

  String get teacherMessagesSubtitle {
    return getValue('teacher_messages_subtitle');
  }

  String get teacherMessagesSearchHint {
    return getValue('teacher_messages_search_hint');
  }

  String get teacherMessagesRecentConversations {
    return getValue('teacher_messages_recent_conversations');
  }

  String get teacherMessagesRecentConversationsSubtitle {
    return getValue('teacher_messages_recent_conversations_subtitle');
  }

  String get teacherMessagesAllCaughtUp {
    return getValue('teacher_messages_all_caught_up');
  }

  String teacherMessagesUnreadCount(int count) {
    return formatValue(
      'teacher_messages_unread_count',
      {'count': count.toString()},
    );
  }

  String get teacherMessagesStudents => getValue('teacher_messages_students');
  String get teacherMessagesUnread => getValue('teacher_messages_unread');
  String get teacherMessagesAll => getValue('teacher_messages_all');

  String get teacherMessagesGradeSection {
    return getValue('teacher_messages_grade_section');
  }

  String get teacherMessagesFilterStudents {
    return getValue('teacher_messages_filter_students');
  }

  String get teacherMessagesFilterStudentsSubtitle {
    return getValue('teacher_messages_filter_students_subtitle');
  }

  String get teacherMessagesGrade => getValue('teacher_messages_grade');
  String get teacherMessagesSection => getValue('teacher_messages_section');
  String get teacherMessagesAny => getValue('teacher_messages_any');
  String get teacherMessagesClear => getValue('teacher_messages_clear');
  String get teacherMessagesApply => getValue('teacher_messages_apply');

  String get teacherMessagesEmptyTitle {
    return getValue('teacher_messages_empty_title');
  }

  String get teacherMessagesEmptySubtitle {
    return getValue('teacher_messages_empty_subtitle');
  }

  String get teacherMessagesSearchEmptyTitle {
    return getValue('teacher_messages_search_empty_title');
  }

  String get teacherMessagesSearchEmptySubtitle {
    return getValue('teacher_messages_search_empty_subtitle');
  }

  String teacherMessagesFailedLoadConversations(String error) {
    return formatValue(
      'teacher_messages_failed_load_conversations',
      {'error': error},
    );
  }

  String get teacherMessagesInvalidConversationId {
    return getValue('teacher_messages_invalid_conversation_id');
  }
}