import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ai/gemini_service.dart';

/// Konuşma persistence katmanı — conversations/messages tabloları ve XP RPC'si.
///
/// Tüm metodlar best-effort: persistence başarısız olsa da kullanıcı bellekte
/// sohbete devam edebilmeli, bu yüzden hatalar yutulur ve null dönülür.
class ConversationRepository {
  ConversationRepository(this._db);
  final SupabaseClient _db;

  /// Yeni conversation row'u açar; id döner. Oturum yoksa veya insert
  /// başarısızsa null.
  Future<String?> createConversation({
    String? scenarioId,
    String? title,
    required String characterId,
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _db
          .from('conversations')
          .insert({
            'user_id': userId,
            'scenario': scenarioId,
            'title': title,
            // Karakter snapshot — sohbet history'sinde immutable kalır.
            'character_id': characterId,
          })
          .select()
          .single();
      return row['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Mesajı tek round-trip'te ekler (insert + conversations.updated_at bump,
  /// `append_message` RPC). Eklenen satırın id'si döner.
  Future<String?> appendMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    if (_db.auth.currentUser == null) return null;
    try {
      final id = await _db.rpc('append_message', params: {
        'p_conversation_id': conversationId,
        'p_role': role,
        'p_content': content,
      });
      return id as String?;
    } catch (_) {
      return null;
    }
  }

  /// Persist edilmiş mesaj satırına değerlendirme alanlarını geri yazar.
  Future<void> patchEvaluation(String remoteId, SpeechEvaluation eval) async {
    try {
      await _db.from('messages').update({
        'eval_score': eval.score,
        'eval_suggestion': eval.correct,
        'eval_explanation': eval.explanation,
        'grammar_errors': eval.grammarErrors,
      }).eq('id', remoteId);
    } catch (_) {}
  }

  /// Konuşma turu için XP/streak kaydı. Başarıda true döner ki çağıran
  /// profil cache'ini düşürebilsin.
  Future<bool> logConversationTurn() async {
    try {
      final tzo = DateTime.now().timeZoneOffset.inHours;
      final sign = tzo >= 0 ? '+' : '-';
      final tzStr = '$sign${tzo.abs().toString().padLeft(2, '0')}:00';
      await _db.rpc('log_practice_session', params: {
        'p_mode': 'conversation',
        'p_words_practiced': 0,
        'p_avg_score': 5.0,
        'p_xp_earned': 5,
        'p_timezone_offset': tzStr,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(Supabase.instance.client),
);
