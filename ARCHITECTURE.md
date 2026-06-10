# VoiceLingo Mimari Kuralları

Bu doküman kod yerleşimi ve bağımlılık yönü için **bağlayıcı** kuralları
tanımlar. "Neden böyle?" soruları için ilgili bölümdeki gerekçeye bakın;
kuralı değiştirmek istiyorsanız önce bu dosyayı güncelleyin.

## 1. Katman diyagramı

```
app  ──────►  features  ──────►  core
 │                │                │
 └────────────────┴────────────────┴──►  l10n/generated (yaprak)
```

| Katman | İçerik | Örnek |
|---|---|---|
| `lib/app/` | Kompozisyon: bootstrap, kök widget, router | `bootstrap.dart`, `router/app_router.dart` |
| `lib/features/<x>/` | Dikey dilimler: `screens/`, `widgets/`, `controllers/`, `services/`, `providers/`, `models/` | `features/words/` |
| `lib/core/` | Paylaşılan altyapı: `ai`, `audio`, `config`, `errors`, `logger`, `models`, `network`, `offline`, `providers`, `services`, `storage`, `theme`, `widgets` | `core/errors/app_exception.dart` |

## 2. Bağımlılık yönü kuralları

1. `core` → asla `features/` veya `app/` import etmez.
2. `features` → `core`'u serbestçe import eder.
3. `app` → her şeyi compose eder (router tüm ekranları görür — normaldir).
4. **Cross-feature import yalnız diğer feature'ın `services/` veya
   `providers/` katmanından yapılır**, ekran/widget'ından değil. Kutsanmış
   mevcut kenarlar:
   - `onboarding` → `conversation/services/characters_service` (karakter seçimi)
   - `words` → `gamification` (quest bump'ları)
   - `lessons` → `grammar`/`conversation`/`scenarios` (ders dispatcher'ı)
   Yeni bir kenar eklemeden önce bu listeye ekleyin.

## 3. Model yerleşim kuralı

2+ feature **veya** core tarafından kullanılan model → `lib/core/models/`
(`word`, `user_profile`, `conversation`, `chat_models`, `scenario`).
Tek feature'a özel model → o feature'ın `models/` klasörü
(`dictionary_entry`, `daily_quest`, `grammar_topic`, `course`, ...).
Gerekçe: feature→feature model import'u yasak; ortak nokta core'dur.

Modeller elle yazılır: `fromMap`/`toMap`, Supabase kolon adlarıyla simetrik.
**Codegen yok** (freezed / json_serializable / riverpod_generator) — uygulama
boyutunda churn'e değmediğine karar verildi (2026-06). Hive round-trip'leri
int→double genişletebilir; `(x as num?)?.toInt()` deseni kullanın
(`core/models/word.dart` örnek).

## 4. Provider konvansiyonları

- Manuel Riverpod 2.x: `Provider`, `StateNotifierProvider`,
  `FutureProvider(.autoDispose)`. `@riverpod` codegen kullanılmaz.
- Servisler `Provider<XService>` ile yayınlanır ve adı `xServiceProvider`.
- Fetch'ler `FutureProvider.autoDispose`; ekran-lokal provider'lar dosya
  içinde `_private` kalabilir.
- **Singleton-arkası-provider deseni:** `runApp`'ten önce init gerektiren
  servisler (`SettingsService`, `NotificationService`) bootstrap'ta kurulur
  ve `ProviderScope(overrides: [xProvider.overrideWithValue(instance)])` ile
  yayınlanır; provider gövdesi `UnimplementedError` fırlatır. Testlerde
  `overrideWithValue` + sahte bağımlılık (`SharedPreferences.setMockInitialValues`).
- Profil cache'i: XP/streak yazan her akış `bustProfileCache()` +
  `ref.invalidate(profileProvider)` çifti kullanır.

## 5. Controller sözleşmesi

Karmaşık ekran iş mantığı `controllers/` altında ChangeNotifier'dır.
Kanonik örnek: `features/conversation/controllers/conversation_controller.dart`.

- State'in **sahip olduğu** nesnedir (provider değil); `dispose` State'te.
- Bağımlılıklar **fonksiyon olarak** enjekte edilir (`read`, `signIn`, ...);
  controller `ref` veya servis sınıfı tutmaz.
- **BuildContext tutmaz.** Hatalar enum'dur (`ConvError`, `AuthError`);
  lokalize metne çeviri widget'ta build sırasında yapılır.
- Dispose-sonrası notify guard'ı: `_notify() { if (!_disposed) notifyListeners(); }`

Her ekrana controller gerekmez: tek async çağrı + loading flag'lik ekranlar
(forgot/reset password gibi) inline kalır.

## 6. Hata sınır kuralı

Tek hata idiyomu: **typed exception fırlat**. `Result<T>` tipi bilinçli
olarak silindi (2026-06) — iki rakip idiyom drift yaratıyordu.

- Hiyerarşi `core/errors/app_exception.dart`: `AppException` +
  `Network/Offline/RateLimit/Validation/Auth/Unexpected/AiException`.
- **Servis/repository sınırında** üçüncü parti hatalar ya `AppException` alt
  tipine çevrilir (örn. `AuthService._translate` Supabase `AuthException`'ını
  bizimkine, `WordsRepository.insertWord` Postgres 23505'i
  `DuplicateWordException`'a çevirir) ya da `// best-effort` yorumuyla
  bilinçli yutulur (`ConversationRepository` yazma metodları şablondur).
- Controller'lar `on AppException` yakalar → error enum'a eşler.
- Ekranlar yalnız `getErrorMessage(context, e)` / `showErrorSnackbar` çağırır;
  asla ham üçüncü parti tip yakalamaz.
- Okuma yolları (FutureProvider besleyen) fırlatır — error state UI'da görünür;
  yazma yolları best-effort olabilir.

## 7. Veri erişim kuralı

`Supabase.instance` yalnız `services/`, `providers/` (repository kurarken) ve
`app/` katmanında görünür. **Ekran ve widget'larda yasaktır.** Şablonlar:
`ConversationRepository`, `WordsRepository`, `ProfileRepository`.
Repository'ler `SupabaseClient`'ı constructor'dan alır (test edilebilirlik).

## 8. Test stratejisi

- Saf mantık (SM-2, validator, redirect matrisi) → tablo testleri.
- Controller'lar → fonksiyon-injection sayesinde mock'suz birim test
  (`auth_controller_test`, `review_controller_test`).
- Router gate'leri → `computeRedirect` saf fonksiyonu + matris testi
  (`test/app/router_redirect_test.dart`). Redirect mantığını değiştiren
  herkes bu tabloyu güncellemek zorundadır.
- Hive'a dokunan kod → temp-dir gerçek Hive box (`cached_repository_test`).
- CI: format + analyze --fatal-warnings + test (+ lcov artefaktı). Coverage
  eşiği bilinçli olarak yok.
