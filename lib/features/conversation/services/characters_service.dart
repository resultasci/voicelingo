import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ai/ai_character.dart';
import '../../../core/ai/characters.dart';

/// Kullanıcının seçili karakterini Supabase'de saklar + okur.
///
/// `profiles.selected_character_id` text alanı; sadece string ID saklanır.
/// Karakter detayları (system prompt, TTS, bio) [AICharacters]'tan çözülür.
class CharactersService {
  CharactersService(this._db);
  final SupabaseClient _db;

  /// Profile'dan seçili karakteri oku. Yoksa varsayılan.
  Future<AICharacter> getSelected() async {
    final user = _db.auth.currentUser;
    if (user == null) return AICharacters.defaultCharacter;
    try {
      final row = await _db
          .from('profiles')
          .select('selected_character_id')
          .eq('id', user.id)
          .maybeSingle();
      final id = row?['selected_character_id'] as String?;
      return AICharacters.byId(id);
    } catch (_) {
      return AICharacters.defaultCharacter;
    }
  }

  /// Seçimi kaydet. Sonraki konuşmalar bu karakteri kullanır.
  Future<void> setSelected(String characterId) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    await _db.from('profiles').update({
      'selected_character_id': characterId,
    }).eq('id', user.id);
  }
}

final charactersServiceProvider = Provider<CharactersService>((ref) {
  return CharactersService(Supabase.instance.client);
});

/// Reactive: o anki seçili karakter. Karakter değişince invalidate edilir.
final selectedCharacterProvider =
    FutureProvider.autoDispose<AICharacter>((ref) async {
  final svc = ref.watch(charactersServiceProvider);
  return svc.getSelected();
});
