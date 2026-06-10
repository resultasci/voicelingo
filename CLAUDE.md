# VoiceLingo — Claude Code Rehberi

Flutter + Riverpod + Supabase + Gemini sesli İngilizce öğrenme uygulaması.
Mimari kuralların tam hali: [ARCHITECTURE.md](ARCHITECTURE.md). Bu dosya
operasyonel özettir.

## Komutlar

```
flutter analyze --fatal-warnings   # CI ile aynı; 0 issue beklenir
flutter test                       # tüm suite
dart format lib test              # commit öncesi
flutter gen-l10n                   # ARB değişince
```

## Katman kuralları (5 madde)

1. Yön: `app → features → core`; core asla features/app import etmez.
2. Cross-feature import yalnız hedef feature'ın `services|providers`
   katmanından; yeni kenar ARCHITECTURE.md §2 listesine eklenir.
3. Model yerleşimi: 2+ feature veya core kullanıyorsa `core/models/`,
   değilse `features/<x>/models/`.
4. Controller sözleşmesi: State'in sahip olduğu ChangeNotifier,
   fonksiyon-injected bağımlılık, BuildContext yok, hatalar enum
   (kanonik örnek: `conversation_controller.dart`).
5. Hata sınırı: servis/repo üçüncü parti hatayı `AppException` alt tipine
   çevirir veya `// best-effort` yorumuyla yutar; ekran yalnız
   `getErrorMessage`/`showErrorSnackbar` kullanır.

## Yapma

- Codegen bağımlılığı ekleme (freezed/json_serializable/riverpod_generator) —
  bilinçli red, ARCHITECTURE.md §3.
- Ekran/widget içinde `Supabase.instance` — repository'ye taşı.
- Yeni singleton — provider'a sar; init gerekiyorsa bootstrap override
  deseni (`settingsServiceProvider` örnek).
- Servis sınırında yorumsuz generic `catch (e)`.
- l10n'siz UI string — TR/EN ARB (`lib/l10n/`), `AppL10n.of(context)`.
- `Result<T>` tipi geri getirme — typed exception fırlatıyoruz.
- PowerShell `Get-Content/Set-Content` ile Dart dosyası düzenleme —
  Türkçe karakterleri bozar (mojibake); Edit aracı veya Git Bash `sed` kullan.

## Dosya yerleşim karar ağacı

```
Yeni kod nereye?
├─ Tüm app'i compose mu ediyor (boot/router/kök widget)? → lib/app/
├─ Tek feature'a mı ait?       → lib/features/<x>/{screens,widgets,controllers,services,providers,models}
└─ 2+ feature/core mu kullanacak? → lib/core/<uygun-klasör>
```

## Sık tuzaklar

- `TtsSpeaker` ekran başına instance'tır, singleton DEĞİL; kullanıcı hızına
  saygı için `rate: ref.read(settingsServiceProvider).ttsRate` geç.
- Router gate'lerini (`computeRedirect`) değiştirirsen
  `test/app/router_redirect_test.dart` matrisini güncelle.
- XP/streak yazan akış `bustProfileCache()` + `ref.invalidate(profileProvider)`
  çiftini çağırmalı.
- Hive round-trip int→double genişletir; `(x as num?)?.toInt()` kullan.
- `unawaited_futures` lint'i aktif — bilinçli fire-and-forget'i
  `unawaited(...)` ile sar.
