import 'package:hive_flutter/hive_flutter.dart';

/// Tüm Hive box isimlerinin tek kaynağı.
///
/// Yeni box eklerken:
///   1. Burada sabit ekle
///   2. [HiveBoxes.openAll] içinde aç
///   3. Eğer custom tip saklayacaksan TypeAdapter register et (Faz 4+ Word,
///      Conversation gibi modellerde gerekecek)
class HiveBoxes {
  HiveBoxes._();

  /// AI'dan zenginleştirilmiş kelime detayları (IPA, örnek cümle, sinonim).
  /// Network'e gitmeden önce buraya bakılır.
  static const dictionary = 'dictionary_v1';

  /// Kullanıcının kelime listesinin offline-first cache'i.
  /// SM-2 review akışı internet yokken de çalışmalı.
  static const words = 'words_v1';

  /// Son N konuşma özeti (offline okuma için).
  static const conversations = 'conversations_v1';

  /// Course path'in aktif unit'inin dersleri.
  static const lessons = 'lessons_v1';

  /// Çevrimdışıyken biriken yazma operasyonları kuyruğu.
  /// Connectivity dönünce sırasıyla server'a gönderilir.
  static const pendingOps = 'pending_ops_v1';

  /// Kullanıcı profili (read-through cache). Profile her açılışta gerekir.
  static const profiles = 'profiles_v1';

  /// AI karakter sistemi (Lily/James/Sarah/Kai). Sistem tablo, nadir değişir.
  static const characters = 'characters_v1';

  /// Gramer konuları (seed data). Yeni içerik haftalarca gelmez → mükemmel cache.
  static const grammarTopics = 'grammar_topics_v1';

  /// Course tree (courses → units → lessons) tek RPC'den dönen JSON.
  static const contentTree = 'content_tree_v1';

  /// Kullanıcının ders + gramer ilerlemesi (SWR, 30dk TTL). Yazma noktaları
  /// (complete_lesson, quiz) ilgili girdiyi düşürür.
  static const progress = 'progress_v1';

  /// Bootstrap'tan çağrılır; tüm box'ları açıp [Hive] global'inden erişilebilir
  /// hale getirir. Bireysel feature'lar `Hive.box(HiveBoxes.words)` ile alır.
  static Future<void> openAll() async {
    await Future.wait([
      Hive.openBox<Map>(dictionary),
      Hive.openBox<Map>(words),
      Hive.openBox<Map>(conversations),
      Hive.openBox<Map>(lessons),
      Hive.openBox<Map>(pendingOps),
      Hive.openBox<Map>(profiles),
      Hive.openBox<Map>(characters),
      Hive.openBox<Map>(grammarTopics),
      Hive.openBox<Map>(contentTree),
      Hive.openBox<Map>(progress),
    ]);
  }

  /// Kullanıcıya özel box'ları boşaltır. signOut'ta çağrılır — aynı cihazda
  /// başka bir hesapla girilince önceki kullanıcının kelimeleri/profili
  /// cache'ten servis edilmesin. Sistem içerik box'larına (characters,
  /// grammarTopics, contentTree, dictionary) dokunulmaz; onlar kullanıcıdan
  /// bağımsızdır.
  static Future<void> clearUserData() async {
    await Future.wait([
      Hive.box<Map>(words).clear(),
      Hive.box<Map>(conversations).clear(),
      Hive.box<Map>(lessons).clear(),
      Hive.box<Map>(pendingOps).clear(),
      Hive.box<Map>(profiles).clear(),
      Hive.box<Map>(progress).clear(),
    ]);
  }
}
