import '../../core/app_localizations.dart';

extension StudentChatL10n on AppLocalizations {
  String get studentChatFailedLoadOlderMessages {
    return getValue('student_chat_failed_load_older_messages');
  }

  String studentChatFailedSendMessage(String error) {
    return formatValue(
      'student_chat_failed_send_message',
      {'error': error},
    );
  }

  String get studentChatTeacherTyping {
    return getValue('student_chat_teacher_typing');
  }

  String get studentChatDirectConversation {
    return getValue('student_chat_direct_conversation');
  }

  String get studentChatNoMessagesYet {
    return getValue('student_chat_no_messages_yet');
  }

  String get studentChatStartConversation {
    return getValue('student_chat_start_conversation');
  }

  String get studentChatSending => getValue('student_chat_sending');
  String get studentChatRetry => getValue('student_chat_retry');
  String get studentChatNewMessages => getValue('student_chat_new_messages');
  String get studentChatWriteMessage => getValue('student_chat_write_message');
}
