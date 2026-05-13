import '../../core/app_localizations.dart';

extension TeacherChatL10n on AppLocalizations {
  String get teacherChatGrade => getValue('teacher_chat_grade');
  String get teacherChatSection => getValue('teacher_chat_section');

  String get teacherChatDirectConversation {
    return getValue('teacher_chat_direct_conversation');
  }

  String get teacherChatStudentTyping {
    return getValue('teacher_chat_student_typing');
  }

  String get teacherChatFailedLoadOlderMessages {
    return getValue('teacher_chat_failed_load_older_messages');
  }

  String teacherChatFailedSendMessage(String error) {
    return formatValue(
      'teacher_chat_failed_send_message',
      {'error': error},
    );
  }

  String get teacherChatNoMessagesYet {
    return getValue('teacher_chat_no_messages_yet');
  }

  String get teacherChatEmptySubtitle {
    return getValue('teacher_chat_empty_subtitle');
  }

  String get teacherChatSending => getValue('teacher_chat_sending');
  String get teacherChatRetry => getValue('teacher_chat_retry');
  String get teacherChatNewMessages => getValue('teacher_chat_new_messages');

  String get teacherChatWriteMessageHint {
    return getValue('teacher_chat_write_message_hint');
  }
}
