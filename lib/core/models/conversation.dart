class ConversationSummary {
  final String id;
  final String userId;
  final String? scenario;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationSummary({
    required this.id,
    required this.userId,
    required this.scenario,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationSummary.fromMap(Map<String, dynamic> map) =>
      ConversationSummary(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        scenario: map['scenario'] as String?,
        title: map['title'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt:
            DateTime.parse((map['updated_at'] ?? map['created_at']) as String),
      );
}

class StoredMessage {
  final String id;
  final String conversationId;
  final String role; // 'user' | 'assistant'
  final String content;
  final int? evalScore;
  final String? evalSuggestion;
  final String? evalExplanation;
  final DateTime createdAt;

  const StoredMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.evalScore,
    this.evalSuggestion,
    this.evalExplanation,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory StoredMessage.fromMap(Map<String, dynamic> map) => StoredMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        evalScore: map['eval_score'] as int?,
        evalSuggestion: map['eval_suggestion'] as String?,
        evalExplanation: map['eval_explanation'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
