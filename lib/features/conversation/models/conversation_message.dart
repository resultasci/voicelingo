import '../../../core/ai/gemini_service.dart';

/// Konuşma ekranının durum makinesi.
enum ConvStatus {
  idle,
  connecting,
  ready,
  listening,
  thinking,
  playing,
  error,
}

/// Tek bir sohbet balonu. Transcript/evaluation geç geldiğinde yerinde
/// mutate edilir (optimistic UI), bu yüzden alanlar bilinçli olarak mutable.
class ConversationMessage {
  final bool isUser;
  String text;
  SpeechEvaluation? evaluation;
  bool isError;
  bool persisted = false;
  String? remoteId;

  /// Used to run the entrance animation only for freshly added bubbles —
  /// items re-entering the viewport on scroll render statically.
  final DateTime createdAt = DateTime.now();

  ConversationMessage({
    required this.isUser,
    required this.text,
    this.isError = false,
  });
}
