class Conversation {
  final String id;
  final String userId;
  final String? title;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final bool isUser;
  final String text;
  final String? feedback;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.isUser,
    required this.text,
    this.feedback,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      isUser: map['role'] == 'user',
      text: map['content'] as String,
      feedback: map['feedback'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': isUser ? 'user' : 'assistant',
      'content': text,
      if (feedback != null) 'feedback': feedback,
      // created_at is handled by supabase
    };
  }
}
