<p align="center">
  <img src="assets/icon/app_icon.png" alt="VoiceLingo logo" width="120">
</p>

# VoiceLingo 🎙️

> Türk kullanıcılar için tasarlanmış, **AI destekli sesli İngilizce öğrenme** uygulaması.
> Konuş, anında geri bildirim al, seviyeni gerçek bir AI koçla geliştir.

**VoiceLingo**, Flutter ile yazılmış mobil-öncelikli bir uygulamadır. Konuşma, gramer, kelime, dinamik senaryolar ve yapılandırılmış A1–C2 ders yolunu; oyunlaştırma (XP, rozet, seri) ve ilerleme analiziyle birleştirir. Tüm AI çağrıları sunucu tarafında **Google Gemini** (`gemini-2.5-flash`, multimodal) üzerinden, API anahtarı asla istemciye sızmadan bir Supabase Edge Function proxy'siyle yapılır.

- 📦 **Repo:** [github.com/resultasci/voicelingo](https://github.com/resultasci/voicelingo) (public)
- 📱 **Platform:** Android & iOS (mobil-öncelikli)
- 🏷️ **Sürüm:** `0.1.0+1`

---

## ✨ Özellikler

| Modül | Açıklama |
|-------|----------|
| 🗣️ **Sesli sohbet** | Gemini multimodal STT + AI koç tek round-trip'te (transcript + cevap + değerlendirme). 4 farklı AI karakter (Lily, Mr. James, Sarah, Kai) — ayrı aksan, kişilik ve ders stili. |
| 🎧 **Eller serbest mod** | VAD (Voice Activity Detection) ile konuşma bitince otomatik durdurma; canlı dalga formu görselleştirmesi. |
| 🧭 **Ders yolu (A1–C2)** | Yapılandırılmış ünite/ders ağacı, ön-koşul (prerequisite) ile kilit açma, SM-2 tabanlı tekrar planı, 3-yıldız puanlama. |
| 📚 **Gramer modülü** | Konu anlatımı + örnekler + quiz (boşluk doldurma / çoktan seçmeli), idempotent XP ödülü. |
| 🔤 **Sözlük + AI enrichment** | IPA, örnek cümle, eş/zıt anlam, kolokasyon, etimoloji — cache'li, gerektiğinde AI'dan zenginleştirme. |
| 🎬 **Dinamik senaryolar** | Kullanıcı tarifinden AI ile senaryo üretimi (rol, hedefler, anahtar ifadeler); kişisel + hazır senaryo galerisi. |
| 🏆 **Oyunlaştırma** | XP & otomatik seviye (DB trigger), günlük seri (streak) + dondurma, rozetler, günlük questler. |
| 📈 **İlerleme analizi** | 90 günlük aktivite heatmap'i, mastery dökümü (kelime/gramer/ders), en sık yapılan hatalar. |
| 🌐 **Offline & çoklu dil** | Hive tabanlı read-through cache, bağlantı durumu banner'ı, TR + EN tam yerelleştirme. |
| 🎨 **COSMOS tasarım sistemi** | Kod-çizimi marka logosu (konuşma balonu + ses dalgası), neon cyan/violet tema (koyu + açık), yumuşak sayfa/tab geçiş animasyonları, cihaz katmanına duyarlı performans (blur/yıldız/animasyon bütçesi). |

---

## 🧱 Tech Stack

| Katman | Teknoloji |
|--------|-----------|
| **Uygulama** | Flutter 3.24+ · Dart `^3.5.3` |
| **State / DI** | Riverpod 2.x (`flutter_riverpod`) — codegen'siz, bilinçli tercih |
| **Yönlendirme** | `go_router` 14 |
| **Backend** | Supabase — Auth + Postgres + Edge Functions (Deno/TypeScript) |
| **AI** | Google Gemini `gemini-2.5-flash` (multimodal: metin + ses), `ai-proxy` Edge Function üzerinden |
| **Ses** | `record` (Opus kayıt) · özel `VadDetector` · `flutter_tts` |
| **Yerel depolama** | `hive` · `shared_preferences` · `flutter_secure_storage` |
| **Ağ** | `dio` (exponential backoff retry) |
| **UI / görsel** | `lottie` · `confetti` · `shimmer` — grafikler ve marka logosu CustomPainter ile kod-çizimi |
| **Bildirim** | `flutter_local_notifications` + `timezone` |
| **Gözlemlenebilirlik** | Sentry (`sentry_flutter`) |
| **Yerelleştirme** | `flutter_localizations` + `intl` (ARB → `flutter gen-l10n`) |

---

## 🏗️ Mimari

İstemci hiçbir zaman doğrudan AI sağlayıcısına bağlanmaz. Tüm AI trafiği, JWT doğrulayan ve kullanıcı başına günlük kota uygulayan `ai-proxy` Edge Function'ından geçer:

```text
Flutter (GeminiService, Dio)
        │  Authorization: Bearer <JWT> + apikey
        ▼
Supabase Edge Function  ── ai-proxy ──►  JWT doğrula → rate-limit (api ledger)
        │                                         │
        │                                         ▼
        │                           Google Gemini API (gemini-2.5-flash)
        ▼
Supabase Postgres (RLS + FORCE RLS, RPC'ler, trigger'lar)
```

- **Katmanlı feature-first** yapı: bağımlılık yönü `app → features → core`; core asla features/app import etmez. Kuralların tamamı: [ARCHITECTURE.md](ARCHITECTURE.md).
- **Controller sözleşmesi:** State'in sahip olduğu `ChangeNotifier`, fonksiyon-injected bağımlılıklar, `BuildContext` yok, hatalar enum — UI'a lokalize edilerek çevrilir.
- Tek **exception sınırı** (`AppException`): servisler üçüncü parti hataları tiplenmiş alt sınıflara çevirir; ekranlar yalnız lokalize `getErrorMessage` kullanır.
- Tek **ses pipeline'ı** (`AudioRecorderService`: Opus + amplitude stream + VAD).
- API anahtarları **yalnızca** Supabase function secret'ı olarak; istemci bundle'ında değil.

### Performans

- **Paralel bootstrap:** Settings+Notifications / Hive / Supabase init'leri eşzamanlı; profil boot biter bitmez arka planda ön-ısıtılır.
- **Stale-while-revalidate cache katmanı** (`CachedRepository` + Hive): profil (6s), ders/gramer ilerlemesi (30dk), içerik ağacı ve gramer konuları (7g), sözlük (30g). Ekranlar cache'ten anında dolar, arka planda tazelenir; yazma noktaları ilgili girdiyi düşürür.
- **Tek round-trip RPC'ler:** `complete_lesson`, `append_message`, `commit_word_reviews`, `record_grammar_quiz` — çok adımlı istemci akışları atomik sunucu fonksiyonlarına katlanmış.
- **Render disiplini:** konuşma kontrolcüsü status'u ayrı `ValueNotifier` kanalından yayınlar (sıcak input bar mesaj eklenince rebuild olmaz), mesaj balonları/dalga formu `RepaintBoundary` ile izole, listeler sliver tabanlı sanal, gizli sekme animasyonları `TickerMode` ile duraklatılır.
- **`PerfTrace`:** boot kırılımı ve konuşma turu gecikmesi için release'te no-op ölçüm işaretleri.

---

## 🔌 Edge Functions

### `ai-proxy` — tek AI ağ geçidi

JWT doğrular, eylemi yönlendirir ve kullanıcı/UTC-gün başına yumuşak kota uygular (`incr_api_usage` RPC + api ledger). Kota aşımında `429`, oturum yoksa `401` döner.

| Endpoint | İşlev | Günlük limit / kullanıcı |
|----------|-------|--------------------------|
| `/turn` | Multimodal tur: ses → `{transcript, reply, evaluation}` (tek çağrı) | 300 |
| `/chat` | Metin sohbet (AI koç cevabı) | 200 |
| `/evaluate` | Cümle değerlendirme (`{correct, score, explanation, grammar_errors, cefr_band?}`) | 200 |
| `/transcribe` | Ses → metin (STT) | 100 |
| `/enrich` | Kelime zenginleştirme (IPA + örnek) | 100 |
| `/generate-words` | Konudan tematik kelime listesi üretimi | 20 |
| `/generate-scenario` | Tarif → yapılandırılmış senaryo (JSON) | 30 |

### `account-admin` — hesap yönetimi

Kullanıcı verisinin güvenli silinmesi (doğrudan tablo silme + `auth.users` CASCADE).

---

## 🗄️ Veritabanı (Supabase / Postgres)

- **35 migration** — şema, RLS, rate-limit ledger, oyunlaştırma, ders yolu, gramer/sözlük, senaryolar, analiz view/RPC'leri ve bütünlük kısıtları.
- **Güvenlik:** kullanıcıya ait tüm tablolarda RLS + `FORCE ROW LEVEL SECURITY`; `SECURITY DEFINER` fonksiyonlarda `search_path` sabitlenmiş.
- **Bütünlük:** XP/level/skor/durum alanlarında 13 `CHECK` kısıtı (hepsi doğrulanmış), FK ve sık sorgulanan kolonlarda index'ler.
- **Atomik mantık RPC'lerde:** `complete_lesson`, `add_xp`, `record_grammar_quiz`, badge/quest ilerleme, `incr_api_usage`, analiz RPC'leri; tek round-trip batch RPC'ler (`add_words_batch`, `commit_word_reviews`, `append_message`).

---

## 📁 Proje Yapısı

```text
lib/
├── app/                    # bootstrap (paralel init, Sentry), router (+ gate'ler), kök widget
├── core/                   # Cross-cutting altyapı (asla features/app import etmez)
│   ├── ai/                 # GeminiService (ai-proxy istemcisi), AI karakterler
│   ├── audio/              # AudioRecorderService (Opus), VadDetector, TtsSpeaker, Waveform
│   ├── config/             # Env, feature flag'ler (app_config tablosundan)
│   ├── errors/             # AppException hiyerarşisi + lokalize error_handler
│   ├── models/             # 2+ feature'ın paylaştığı domain modeller
│   ├── network/            # Dio fabrikası (retry), connectivity service
│   ├── perf/               # DeviceTier bütçeleri + PerfTrace ölçüm işaretleri
│   ├── storage/            # Hive box kayıtları + CachedRepository (SWR)
│   ├── services/           # Settings, Notification, Streak
│   ├── theme/              # COSMOS tasarım sistemi (AppPalette, koyu/açık)
│   └── widgets/            # Paylaşılan widget'lar (ConnectivityBanner, BrandLogo…)
├── features/               # Feature-first modüller — her biri:
│   │                       #   screens/ widgets/ controllers/ services/ providers/ models/
│   ├── auth/  conversation/  dashboard/  gamification/  grammar/
│   ├── lessons/  onboarding/  profile/  progress/  scenarios/
│   └── settings/  words/
└── l10n/                   # TR + EN ARB dosyaları (generate: true)

supabase/
├── functions/ai-proxy/      # Gemini proxy + rate limit
├── functions/account-admin/ # Hesap silme
└── migrations/              # 35 migration
```

---

## 🚀 Kurulum

### Ön koşullar
- Flutter **3.24+** (Dart `^3.5.3`)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Bir Supabase projesi + bir **Gemini API anahtarı** ([Google AI Studio](https://aistudio.google.com/app/apikey))

### 1) Bağımlılıklar
```bash
flutter pub get
```

### 2) `.env` dosyası
```bash
cp .env.example .env
```
```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```
> Gemini anahtarı `.env`'e **konmaz** — yalnızca sunucu tarafında secret olarak tutulur.

### 3) Supabase
```bash
# Projeyi bağla
supabase link --project-ref <project-ref>

# Migration'ları uygula
supabase db push

# AI anahtarını secret olarak ayarla
supabase secrets set GEMINI_API_KEY=<gemini-api-key>

# Edge Function'ları deploy et
supabase functions deploy ai-proxy
supabase functions deploy account-admin
```

### 4) Sentry (opsiyonel)
```bash
flutter run --dart-define=SENTRY_DSN=<dsn>
```

### 5) Çalıştır
```bash
flutter run
```

---

## 🛠️ Komutlar

| Komut | Açıklama |
|-------|----------|
| `flutter analyze --fatal-warnings` | Statik analiz (CI ile aynı; 0 issue beklenir) |
| `flutter test` | Birim + widget testleri (94 test) |
| `dart format lib test` | Kod formatlama |
| `flutter gen-l10n` | ARB'lerden yerelleştirme üretimi |
| `flutter build apk --release` | Android release derleme (R8/ProGuard kuralları dahil) |

---

## ✅ Test & CI

- **94 test**: router redirect gate matrisi, cache TTL/round-trip, hata eşleme, SM-2 review akışı, konuşma kontrolcüsü bildirim kanalları, VAD, sözlük cache'i, gramer rubriği ve daha fazlası.
- GitHub Actions CI (`.github/workflows/ci.yml`): **format kontrolü + `analyze --fatal-warnings` + test** (coverage artifact'ı ile).

---

## 📄 Lisans & Durum

Bu repo **public** olarak yayınlanmıştır. Henüz resmi bir açık kaynak lisansı tanımlanmamıştır; bu nedenle varsayılan olarak **tüm hakları saklıdır** (telif hakkı sahibinin izni olmadan kullanım/dağıtım kapsam dışıdır). Açık kaynak olarak paylaşmak istersen depoya bir `LICENSE` dosyası (ör. MIT / Apache-2.0) eklemen yeterli.
