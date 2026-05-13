class ChatSessionState {
  static int? currentConversationId;
}

class TeacherChatSessionState {
  static int? get currentConversationId => ChatSessionState.currentConversationId;

  static set currentConversationId(int? value) {
    ChatSessionState.currentConversationId = value;
  }
}

class StudentChatSessionState {
  static int? get currentConversationId => ChatSessionState.currentConversationId;

  static set currentConversationId(int? value) {
    ChatSessionState.currentConversationId = value;
  }
}
