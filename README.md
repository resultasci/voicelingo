# VoiceLingo

Türk kullanıcılar için tasarlanmış AI destekli sesli İngilizce öğrenme uygulaması. Flutter + Supabase + Groq (Llama 3.3 70B + Whisper) üzerine kurulu.

## Özellikler

- **Sesli sohbet**: Whisper STT + Llama 3.3 70B AI koç + flutter_tts
- **AI karakter sistemi**: Lily / Mr. James / Sarah / Kai — farklı aksan, kişilik, ders stili
- **Eller serbest mod**: VAD (Voice Activity Detection) ile otomatik durdurma
- **Course path (A1-C2)**: Yapılandırılmış ders ağacı, prerequisite unlock, SM-2 review
- **Gramer modülü**: Topic'ler + örnekler + quiz (fill / multiple choice)
- **Sözlük + AI enrichment**: IPA, örnek cümle, synonyms/antonyms
- **Dinamik senaryolar**: AI ile kullanıcı tarifinden senaryo üretimi
- **Gamification**: Rozetler, günlük questler, XP, streak
- **İlerleme analizi**: Aktivite heatmap, mastery breakdown, en sık hatalar

## Tech Stack

- **Flutter** 3.5+ (Dart 3.5)
- **State**: Riverpod 2.x
- **Routing**: go_router 14
- **Backend**: Supabase (Auth + Postgres + Edge Functions)
- **AI**: Groq API (server-side, Supabase Edge Function proxy)
- **Local**: SharedPreferences + Hive + flutter_secure_storage
- **Observability**: Sentry

## Setup

### 1. Bağımlılıklar

```bash
flutter pub get
```

### 2. `.env` dosyası

```bash
cp .env.example .env
```

`.env` içeriği:

```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

### 3. Supabase setup

```bash
# Migration'ları uygula
supabase db push --db-url <session-pooler-url>

# Edge Function secret
supabase secrets set GROQ_API_KEY=<groq-api-key>
supabase functions deploy ai-proxy
supabase functions deploy account-admin
```

### 4. Sentry (opsiyonel)

`--dart-define=SENTRY_DSN=<dsn>` build sırasında.

### 5. Çalıştır

```bash
flutter run
```

## Proje Yapısı

```text
lib/
├── app/                    # Bootstrap + root widget
├── core/                   # Cross-cutting: ai, audio, errors, network, storage, widgets
│   ├── audio/              # AudioRecorderService (Opus), VadDetector, WaveformPainter
│   ├── errors/             # AppException sealed hierarchy
│   └── widgets/            # Reusable widgets (ConnectivityBanner, LevelUpDialog)
├── features/               # Feature-first modüller
│   ├── auth/
│   ├── conversation/       # Sohbet ekranı, AI karakter
│   ├── dashboard/
│   ├── gamification/       # Rozetler, daily quests
│   ├── grammar/
│   ├── lessons/            # Course path A1-C2
│   ├── onboarding/
│   ├── profile/
│   ├── progress/           # Heatmap + mastery + top errors
│   ├── scenarios/          # Dinamik senaryolar
│   ├── settings/
│   └── words/              # Sözlük + flashcard
├── l10n/                   # TR + EN ARB dosyaları
├── models/                 # Domain modeller
├── providers/              # Global Riverpod providers (auth, theme, locale, words)
├── router/                 # GoRouter config
├── services/               # Auth, Groq, Account, Notification, Settings
└── theme/                  # COSMOS design system

supabase/
├── functions/ai-proxy/     # Groq proxy + rate limit
├── functions/account-admin/
└── migrations/             # 18 migration
```

## Komutlar

```bash
flutter analyze              # Lint
flutter test                 # Unit + widget testler
dart format .                # Format
flutter build apk --release  # Android release
```

## Lisans

Bu proje şu an private. Lisans henüz tanımlanmadı.
