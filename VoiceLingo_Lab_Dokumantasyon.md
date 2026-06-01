# VoiceLingo — Lab 2–6 Dokümantasyonu

**Öğrenci Adı:** [Adınızı buraya yazın]
**Proje Adı:** VoiceLingo
**Tarih:** 21.05.2026

---

# LAB 2 — Problem Tanımı ve Gereksinim Analizi

## 1. Problem Tanımı

Türkiye'de İngilizce öğrenmek isteyen bireylerin büyük çoğunluğu, dilbilgisi ve okuma odaklı klasik yöntemler yüzünden konuşma pratiği yapmakta zorlanmaktadır. Konuşma ortamı yetersizliği, yanlış telaffuz korkusu ve uygun fiyatlı bir konuşma partnerinin bulunamaması, dili gerçek hayatta kullanabilme becerisinin gelişmesini engellemektedir. Bu durum, yıllarca İngilizce dersi alan kullanıcıların bile basit bir günlük diyalog kuramamasıyla sonuçlanmaktadır.

## 2. Hedef Kullanıcı

Konuşma pratiği yapacak ortam bulamayan, kendi hızında ve utanmadan İngilizce konuşma alışkanlığı kazanmak isteyen 15–45 yaş arası Türk öğrenciler ve çalışan bireyler.

## 3. Problemin Önemi ve Etkisi

İngilizce konuşma yetkinliği bugün üniversite kabul, iş başvurusu ve kariyer ilerlemesinde belirleyici bir faktör hâline gelmiştir. Buna rağmen kullanıcıların çoğu, özel ders ücretlerinin yüksekliği veya yabancı biriyle konuşma çekincesi nedeniyle pratik fırsatlarından uzak kalmaktadır. Bu eksiklik, uzun süre yapılan teorik çalışmaların yerini gerçek bir konuşma becerisine bırakmamasına yol açar. Ayrıca dil öğrenmeye başlayan kullanıcıların büyük kısmı, ilerleme görünür olmadığı için ilk birkaç hafta içinde motivasyonunu kaybeder ve uygulamayı bırakır. Sonuç olarak hem zaman hem de para boşa harcanmaktadır.

## 4. Uygulamanın Kapsamı

### 4.1 Uygulamanın İçerdiği İşlevler
- Yapay zekâ destekli sesli sohbet pratiği (mikrofonla konuşma + AI cevabı dinleme)
- AI karakterlerinden birini seçerek farklı konuşma tarzlarını deneme
- Hazır ve özel oluşturulmuş senaryolarla (restoran, mülakat vb.) rol oynama pratiği
- Konuşma sırasında geçen kelimelerin sözlüğe eklenmesi ve aralıklı tekrar (flashcard) yöntemiyle çalışılması
- Konuya göre dilbilgisi (gramer) bölümlerini okuyup pratik yapma
- A1–C2 seviyesine göre yapılandırılmış ders ağacı içinde ünite ve ders ilerlemesi
- Seviye belirleme testi ve ilk açılış (onboarding) ile kişisel hedef belirleme
- Günlük görev, seri (streak), seviye sistemi ve rozetlerle motivasyon takibi
- Konuşma geçmişini ve günlük aktiviteyi görüntülemeye yarayan ilerleme paneli (ısı haritası, grafikler)
- Profil yönetimi, kullanıcı adı/şifre değiştirme ve hesap silme
- Bildirimlerle günlük çalışma hatırlatması
- Tema (açık/koyu) ve dil (Türkçe/İngilizce arayüz) seçenekleri

### 4.2 Uygulamanın İçermediği İşlevler (Kapsam Dışı)
- Canlı bir öğretmenle birebir video/ses ders
- Diğer kullanıcılarla mesajlaşma veya arkadaşlık ekleme
- Sosyal medya paylaşımı ve genel liderlik tablosu (global leaderboard)
- Ücretli içerik satışı ve abonelik sistemi (MVP'de paywall yok)
- İngilizce dışında başka bir dilin öğretimi
- Yazılı sınav benzeri sertifikalı seviye belgesi verme

---

# LAB 3 — Kullanıcı Senaryoları

## Senaryo 1: AI ile Sesli Konuşma Pratiği Yapma

- **Kullanıcı:** Konuşma pratiği yapmak isteyen Türk dil öğrencisi
- **Amaç:** Mikrofonu kullanarak yapay zekâ ile günlük bir İngilizce sohbet etmek ve yanıtları dinlemek

**Adımlar:**
1. Kullanıcı uygulamayı açar ve daha önce hesabıyla giriş yaptığı için doğrudan ana ekrana ulaşır.
2. Alt menüden "PRATİK" sekmesine geçer.
3. Mikrofon butonuna basıp İngilizce bir cümle söyler.
4. Uygulama söyleneni metne çevirir ve seçili AI karakter sesli bir cevap üretir.
5. Kullanıcı cevabı dinler, ekranda yazılı hâlini görür ve geri bildirim (örn. doğruluk puanı) alır.
6. Sohbeti istediği kadar sürdürür; bitirince geçmiş "konuşma geçmişi"ne kaydedilir.

---

## Senaryo 2: Kelime Tekrarı (Flashcard) Yapma

- **Kullanıcı:** Daha önce sohbet sırasında karşılaştığı kelimeleri kalıcı hâle getirmek isteyen kullanıcı
- **Amaç:** O gün tekrar edilmesi gereken kelimeleri çalışıp kendine puan vererek hafızada tutmak

**Adımlar:**
1. Kullanıcı ana ekranda "Tekrar Bekleyen" kelime sayısını görür.
2. Tekrar başlatma butonuna dokunur.
3. Ekranda bir kelime (örn. "accomplish") görüntülenir; kullanıcı anlamını hatırlamaya çalışır.
4. "Göster" butonuna basarak Türkçe karşılığını ve örnek cümleyi görür.
5. "Bilmedim", "Zordu" veya "Kolaydı" seçeneklerinden birine basar.
6. Uygulama bu cevaba göre kelimeyi bir sonraki tekrar gününe günceller ve sıradaki kelimeye geçer; tüm kelimeler bittiğinde günlük hedef tamamlanır.

---

## Senaryo 3: Senaryo Bazlı Konuşma (Restoran, Mülakat vb.)

- **Kullanıcı:** Belirli bir günlük durumu (örn. yurt dışında restoran siparişi) önceden prova etmek isteyen kullanıcı
- **Amaç:** Hazır bir senaryo seçerek o senaryoya özel kelimelerle pratik yapmak

**Adımlar:**
1. Kullanıcı "PRATİK" sekmesindeyken sağ alttaki "Senaryo" butonuna basar.
2. Açılan listeden hazır bir senaryo seçer (örn. "Restoranda Sipariş Verme") veya kendi senaryosunu yazıp oluşturur.
3. Senaryo açıklaması ve AI'ın rolü ekranda görüntülenir.
4. Kullanıcı mikrofonla rolünü oynamaya başlar; AI karakteri seçilen senaryoya uygun cevaplar verir.
5. Sohbet sırasında kullanıcı kelime kaydedebilir veya yanlış telaffuzlar için anlık geri bildirim alır.
6. Senaryo bittiğinde günlük görev ilerlemesi güncellenir ve gerekirse yeni bir rozet kazanıldığı bildirilir.

> **Not:** Senaryolar Lab 2'deki "İngilizce konuşma pratiği yapacak ortam bulamayan kullanıcı" problemini birebir karşılamak için seçilmiştir.

---

# LAB 4 — Wireframe ve Ekran Akışları

## 1. Uygulama Ekranları

Aşağıda VoiceLingo'nun ana ekranlarının metinsel wireframe'leri verilmiştir.

### Ekran 1: Ana Ekran (Genel / Dashboard)

```
┌─────────────────────────────────────┐
│  [V]  VOICELINGO            [⚙]     │
├─────────────────────────────────────┤
│                                     │
│  Merhaba, [Kullanıcı Adı] 👋        │
│  Seviye: A2 • Seri: 5 gün 🔥        │
│                                     │
│  ┌─── XP HUD ─────────────────────┐ │
│  │ ⭐ 1240 XP   📘 87 kelime      │ │
│  └────────────────────────────────┘ │
│                                     │
│  ╔══════════════════════════════╗   │
│  ║   🎙  AI ile Pratik Yap      ║   │
│  ║   Bugün 5 dakika konuş!      ║   │
│  ╚══════════════════════════════╝   │
│                                     │
│  Günlük Hedef: 12 / 20 kelime       │
│  ▓▓▓▓▓▓▓▓░░░░░░░ %60                │
│                                     │
├─────────────────────────────────────┤
│  [GENEL] [KELİME] [PRATİK] [PROFİL] │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- Üst başlık çubuğu (uygulama logosu + ayarlar butonu)
- Karşılama metni ve seviye/seri bilgisi
- XP ve toplam kelime sayısını gösteren küçük gösterge kartı
- AI pratiğine yönlendiren büyük çağrı kartı
- Günlük hedef ilerleme çubuğu
- 4 sekmeli alt navigasyon (GENEL / KELİME / PRATİK / PROFİL)

---

### Ekran 2: Kelime Ekranı (Liste + Tekrar Modu)

```
┌─────────────────────────────────────┐
│  [V]  VOICELINGO            [⚙]     │
├─────────────────────────────────────┤
│                                     │
│  🔍 [ Kelime ara...             ]   │
│                                     │
│  [ Tümü ] [ Tekrar ] [ Yeni ] [Öğr] │
│                                     │
│  ─────────────────────────          │
│  ▢ accomplish — başarmak  🔊        │
│  ▢ adventure  — macera    🔊        │
│  ▢ borrow     — ödünç al  🔊        │
│  ▢ confident  — kendinden... 🔊     │
│  ...                                │
│                                     │
│             [▶ TEKRARA BAŞLA]       │
│                                     │
├─────────────────────────────────────┤
│  [GENEL] [KELİME] [PRATİK] [PROFİL] │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- Arama çubuğu
- Filtre çipleri (Tümü / Tekrar Bekleyen / Yeni / Öğrenilen)
- Kelime listesi (sesli okuma ikonu ile birlikte)
- Tekrara başlama butonu

---

### Ekran 3: Pratik (AI Sohbet) Ekranı

```
┌─────────────────────────────────────┐
│  [V]  VOICELINGO            [⚙]     │
├─────────────────────────────────────┤
│                                     │
│  Karakter: Lily 🎭                  │
│                                     │
│  ┌──────────────────────────────┐   │
│  │ AI: Hi! How was your day?    │   │
│  └──────────────────────────────┘   │
│         ┌────────────────────────┐  │
│         │ Sen: It was tiring...  │  │
│         │ ✅ %92 doğruluk         │  │
│         └────────────────────────┘  │
│  ┌──────────────────────────────┐   │
│  │ AI: I'm sorry to hear that.  │   │
│  │ What made it tiring?         │   │
│  └──────────────────────────────┘   │
│                                     │
│   ╔═══════════════════════╗         │
│   ║         🎙             ║        │
│   ║   (Konuşmak için bas)  ║        │
│   ╚═══════════════════════╝         │
│                                     │
│                    [ Senaryo ▸ ]    │
├─────────────────────────────────────┤
│  [GENEL] [KELİME] [PRATİK] [PROFİL] │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- Seçili AI karakter göstergesi
- Sohbet baloncukları (AI / kullanıcı) ve cevap için doğruluk geri bildirimi
- Büyük mikrofon (kayıt) butonu
- Sağ alt: Senaryo seçici çıkış butonu

---

### Ekran 4: Profil Ekranı

```
┌─────────────────────────────────────┐
│  [V]  VOICELINGO            [⚙]     │
├─────────────────────────────────────┤
│                                     │
│         ┌────────┐                  │
│         │   V    │                  │
│         └────────┘                  │
│        Kullanıcı Adı                │
│      Seviye A2 • 1240 XP            │
│                                     │
│  📊 İlerleme Paneli           ▸     │
│  🏅 Rozetlerim                ▸     │
│  📚 Ders Ağacı                ▸     │
│  📝 Gramer Konuları           ▸     │
│  🎭 Senaryolar Galerisi       ▸     │
│  ⚙  Ayarlar                   ▸     │
│                                     │
├─────────────────────────────────────┤
│  [GENEL] [KELİME] [PRATİK] [PROFİL] │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- Profil resmi ve özet (seviye + XP)
- İlerleme paneline, rozetlere, derslere, gramer ve senaryolara giden menü satırları
- Ayarlar bağlantısı

---

### Ekran 5: Senaryo Seçici

```
┌─────────────────────────────────────┐
│  [← Geri]   Senaryolar              │
├─────────────────────────────────────┤
│                                     │
│  🍽  Restoranda Sipariş Verme       │
│  ✈  Havalimanında Check-In          │
│  💼 İş Mülakatı                     │
│  🏥 Doktor Randevusu                │
│  ☕ Kafede Sohbet                   │
│                                     │
│   ┌────────────────────────────┐    │
│   │  + Kendi Senaryonu Oluştur │    │
│   └────────────────────────────┘    │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- Hazır senaryolar listesi
- Yeni senaryo oluşturma butonu (galeri / builder ekranına yönlendirir)

---

## 2. Ekran Akış Diyagramı

```
                ┌────────────────────────┐
                │   Giriş / Kayıt Ekranı │
                └───────────┬────────────┘
                            │ Başarılı giriş
                            ▼
                ┌────────────────────────┐
                │ Seviye Belirleme Testi │
                │ (yalnız ilk kullanım)  │
                └───────────┬────────────┘
                            ▼
                ┌────────────────────────┐
                │     Onboarding         │
                │     (ilk kurulum)      │
                └───────────┬────────────┘
                            ▼
                ┌────────────────────────┐
                │     ANA EKRAN          │
                │      (Dashboard)       │◄───────────┐
                └──┬─────┬─────┬──────┬──┘            │
                   │     │     │      │               │
       Tab "KELİME"│     │     │      │ Tab "PROFİL"  │
                   ▼     │     │      ▼               │
            ┌───────────┐│     │  ┌─────────────┐     │
            │  Kelime   ││     │  │   Profil    │     │
            │  Listesi  ││     │  └──────┬──────┘     │
            └─────┬─────┘│     │         │            │
                  │      │     │         ▼            │
           "Tekrara başla"     │  ┌─────────────┐     │
                  ▼      │     │  │  İlerleme / │     │
            ┌──────────┐ │     │  │  Rozetler / │     │
            │ Flashcard│ │     │  │  Dersler /  │     │
            │  Tekrar  │ │     │  │  Gramer     │     │
            └────┬─────┘ │     │  └─────────────┘     │
                 │       │     │                      │
                 └───────│─────│──────────────────────┘
                Tab "PRATİK"   │
                         ▼     │
                  ┌───────────────┐
                  │   AI Sohbet   │
                  │    Ekranı     │
                  └──┬─────────┬──┘
                     │         │
              "Senaryo" │      │ "Karakter Değiştir"
                     ▼         ▼
            ┌──────────────┐ ┌──────────────────┐
            │ Senaryo      │ │  Karakter Seçimi │
            │ Seçici       │ └──────────────────┘
            └──────┬───────┘
                   │ "Yeni senaryo"
                   ▼
            ┌──────────────┐
            │ Senaryo      │
            │ Oluşturucu   │
            └──────────────┘
```

### Geçiş Açıklamaları
- **Giriş → Seviye Testi → Onboarding → Ana Ekran:** Yalnızca ilk girişte çalışır; sonraki açılışlarda doğrudan Ana Ekran açılır.
- **Ana Ekran → Pratik Sekmesi:** Kullanıcı alt menüden "PRATİK"e dokunarak AI sohbet ekranına geçer (Senaryo 1).
- **Ana Ekran → Kelime → Flashcard:** Kullanıcı kelime sekmesinden "Tekrara Başla" diyerek günlük kelimeleri çalışır (Senaryo 2).
- **Pratik → Senaryo Seçici → Sohbet:** Kullanıcı belirli bir günlük durumu prova etmek için senaryo seçer (Senaryo 3).
- **Profil → İlerleme/Rozetler/Dersler:** Kullanıcı kendi gelişimini incelemek veya yapılandırılmış derslere göz atmak için profil sekmesinden ilgili kartı seçer.

---

# LAB 5 — Teknoloji Seçimi ve Gerekçelendirme

## 1. Mobil Geliştirme Teknolojisi

**Seçim:** Flutter (Dart SDK ^3.5.3)

**Gerekçe:**
Uygulamanın hedef kitlesi hem Android hem iOS kullanan Türk kullanıcılardan oluştuğu için tek kod tabanından iki platforma da çıkış almak büyük bir hız ve maliyet avantajı sağlamaktadır. Flutter'ın widget tabanlı yapısı, COSMOS adı verilen özel neon temalı arayüzün (degrade, parlamalar, animasyonlu butonlar) iki platformda da birebir aynı görünmesini kolaylaştırır. Ayrıca sesli kayıt, anlık ses oynatma, mikrofon izni ve titreşim gibi platforma yakın özellikleri tek paket ile yönetebilmek, projenin temel ihtiyacı olan "düşük gecikmeli sesli sohbet" deneyimini desteklemektedir. Geliştirici tek kişi olduğu için, iki ayrı native kod tabanını sürdürmek yerine Flutter ile geliştirme süresi belirgin biçimde kısalmıştır.

---

## 2. Veri Kaynağı

**Seçim:** Bulut tabanlı **Supabase** (PostgreSQL + Auth + Edge Functions) + yerel **Hive** önbelleği ve **SharedPreferences** / **flutter_secure_storage**

**Gerekçe:**
Kullanıcı verisi (profil, seviye, XP, seri, kelime ilerlemesi, konuşma geçmişi) cihazlar arası senkron olmak zorundadır; kullanıcı telefonunu değiştirdiğinde kayıp yaşamamalıdır. Bu nedenle ana veri kaynağı olarak Supabase (PostgreSQL altyapısı) seçilmiştir. Supabase, yerleşik kimlik doğrulama, satır seviyesinde güvenlik (RLS) ve sunucu tarafı fonksiyonlar sağladığı için ayrı bir backend yazmaya gerek kalmamıştır. Yerel taraf için Hive bir önbellek katmanı olarak kullanılır: çevrimdışı senaryolarda kullanıcı kelimelerini görebilir, internet geri geldiğinde otomatik eşleşir. Hassas veriler (oturum anahtarları) `flutter_secure_storage` ile cihazda şifreli olarak tutulmaktadır.

---

## 3. Ek Araçlar ve Kütüphaneler

| Kütüphane / Araç | Kullanım Amacı |
|------------------|----------------|
| `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` | Uygulama genelinde durum (state) yönetimi ve bağımlılık enjeksiyonu |
| `go_router` | Ekranlar arası yönlendirme, oturum durumuna göre yönlendirme (redirect) ve derin bağlantı yönetimi |
| `supabase_flutter` | Kullanıcı girişi, kayıt, şifre sıfırlama ve veritabanı sorguları |
| `dio` | AI servisine (Groq) HTTP istekleri ve dosya yükleme |
| `record` | Mikrofondan sesli kayıt alma (konuşma pratiği için) |
| `audioplayers` | AI'ın ürettiği seslerin oynatılması |
| `flutter_tts` | Kelimelerin doğru telaffuzunun sesli okunması |
| `permission_handler` | Mikrofon ve bildirim izinlerini yönetme |
| `connectivity_plus` | Çevrimdışı/çevrimiçi durumu algılama ve banner gösterme |
| `hive`, `hive_flutter` | Kelime ve sözlük verilerinin yerel önbelleklenmesi |
| `shared_preferences` | Kullanıcı tercihleri (tema, dil, onboarding tamamlandı mı vb.) |
| `flutter_secure_storage` | Hassas verilerin (token, oturum) şifreli saklanması |
| `flutter_local_notifications`, `timezone` | Günlük çalışma hatırlatıcıları |
| `fl_chart` | İlerleme panelinde grafiklerin çizimi |
| `lottie`, `confetti`, `shimmer` | Seviye atlama, rozet kazanma ve yükleme animasyonları |
| `google_fonts`, `flutter_svg`, `cached_network_image` | Özel yazı tipleri, vektör ikonlar ve görsel önbellekleme |
| `sentry_flutter` | Üretimdeki hataların izlenmesi ve raporlanması |
| `flutter_dotenv` | API anahtarlarının `.env` dosyasından güvenli okunması |
| `flutter_localizations`, `intl` | Türkçe / İngilizce arayüz desteği |
| `share_plus` | İlerleme/rozet paylaşımı |
| `uuid` | Konuşma mesajları ve kelime kayıtları için benzersiz kimlik üretimi |

---

## 4. Genel Değerlendirme

Seçilen teknoloji yığını, "Türk kullanıcıya yönelik AI destekli sesli dil pratiği" amacına doğrudan hizmet eder: Flutter ile iki platforma hızlı çıkış, Supabase ile sunucu tarafını sıfırdan yazmadan güvenli kullanıcı yönetimi, Riverpod ile büyüyen ekran sayısına rağmen sürdürülebilir bir kod tabanı sağlanmıştır. Hive ve `connectivity_plus` ikilisi, kötü internet koşullarında bile kelime tekrarı gibi temel görevlerin çalışmasına imkân verir. Sentry ile gerçek kullanıcı hatalarının yakalanması, uygulamanın yayın sonrası da güvenle iyileştirilmesini mümkün kılar. Sonuç olarak yığın; düşük başlangıç maliyeti, yüksek geliştirici verimi ve makul ölçeklenebilirlik dengesini sağlamaktadır.

---

# LAB 6 — Yazılım Mimarisi ve Veri Akışı

## 1. Mimari Bileşenler

VoiceLingo, üç ana katmandan oluşan temiz bir mimariyi (layered / clean-architecture) izler.

### 1.1 Sunum Katmanı (UI)

Sunum katmanı Flutter widget'ları ile inşa edilmiştir. Lab 4'te tanımlanan ekranların hepsi bu katmanda yer alır:
- **Kimlik akışı:** Giriş, kayıt, şifre sıfırlama, seviye belirleme, onboarding
- **Ana sekmeler:** Dashboard (Genel), Kelime listesi, AI Pratik (Sohbet), Profil
- **Detay/akış ekranları:** Flashcard tekrarı, Senaryo seçici/galerisi/oluşturucusu, Karakter seçici, İlerleme paneli, Rozetler, Ders ağacı (Course Tree) ve ders koşturucusu (Lesson Runner), Gramer konuları, Kelime detayı, Ayarlar

Tüm ekranlar `Riverpod` ile durum (state) sağlayıcılarına bağlanır; tema ise özel "COSMOS" neon tasarım sistemi (`app_theme.dart`) üzerinden gelir. Navigasyon `go_router` ile yönetilir ve oturum/seviye testi/onboarding durumlarına göre otomatik yönlendirme yapılır.

### 1.2 İş Mantığı Katmanı

Bu katman, ekranlar ile veri kaynağı arasındaki tüm kuralları içerir. **Riverpod provider'ları** + **servis sınıfları** ikilisiyle kurulmuştur:

- **Provider'lar (durum yönetimi):** `authProvider`, `profileProvider`, `wordsProvider`, `groqProvider`, `accountProvider`, `themeProvider`, `localeProvider`, `navProvider`, `gamificationProviders`
- **Servisler (iş kuralları):**
  - `auth_service`, `account_service` — giriş, kayıt, şifre, hesap silme
  - `groq_service` — yapay zekâ ile sohbet ve konuşma değerlendirmesi
  - `audio_service`, `audio_recorder_service`, `vad_detector` — sesli kayıt ve sesli aktivite algılama
  - `notification_service` — günlük hatırlatıcılar
  - `settings_service` — kullanıcı tercihleri
  - `characters_service` — AI karakterleri
  - `dictionary_service`, `grammar_service` — sözlük ve gramer içerikleri
  - `scenarios_service` — hazır ve dinamik senaryolar
  - `courses_service` — A1–C2 ders ağacı
  - `activity_service` — günlük aktivite ve ısı haritası
  - `badges_service`, `daily_quests_service`, `streak_service` — gamification kuralları
  - `onboarding_service` — ilk açılış akışı

Kelime tekrarı (flashcard) için bu katmanda **SM-2 aralıklı tekrar algoritması** uygulanır; konuşma sırasında üretilen geri bildirim ve XP/seviye hesaplamaları da burada yapılır.

### 1.3 Veri Katmanı

Veri katmanı, Lab 5'te seçilen kaynakları kapsar:
- **Supabase** (PostgreSQL + Auth + Edge Functions): Kullanıcı, profil, kelimeler, konuşma geçmişi, senaryolar, dersler, gamification verileri için ana kaynak
- **Hive**: Kelimelerin ve sözlük verisinin yerel önbelleği (çevrimdışı kullanım)
- **SharedPreferences**: Tema, dil, onboarding/placement tamamlandı durumu gibi küçük tercihler
- **flutter_secure_storage**: Oturum anahtarları gibi hassas veriler
- **Groq API** (`dio` üzerinden): Konuşma metnine çevirme (Whisper) ve AI yanıtı üretme (Llama 3.3 70b)

`core/network/connectivity_service.dart` ile çevrimdışı durum izlenir ve uygun banner gösterilir.

---

## 2. Katmanlı Yapı Diyagramı

```
┌──────────────────────────────────────────────────────────────┐
│                  SUNUM KATMANI (Flutter / UI)                │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌───────────┐  │
│  │ Dashboard  │ │  Kelime    │ │  Pratik    │ │  Profil   │  │
│  │ Ekranı     │ │  Listesi   │ │  (AI)      │ │  Ekranı   │  │
│  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬─────┘  │
│        │ Flashcard,   │              │ Senaryo /    │         │
│        │ Detay        │              │ Karakter     │         │
└────────┼──────────────┼──────────────┼──────────────┼─────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
┌──────────────────────────────────────────────────────────────┐
│                İŞ MANTIĞI KATMANI                            │
│   [State: Riverpod Provider'ları]                            │
│   • auth / profile / words / groq / gamification             │
│   [Servisler / Kurallar]                                     │
│   • Konuşma → AI'a gönderme, cevap değerlendirme             │
│   • SM-2 algoritması ile kelime tekrar planlaması            │
│   • Günlük görev, streak, XP, seviye, rozet hesaplama        │
│   • Onboarding & placement durum makinesi                    │
└────────────────────────┬─────────────────────────────────────┘
                         │
              ┌──────────┼───────────┐
              ▼          ▼           ▼
┌────────────────┐ ┌──────────┐ ┌───────────────────────┐
│  SUPABASE      │ │  HIVE +  │ │   GROQ API (HTTP/Dio) │
│  (PostgreSQL,  │ │  Shared  │ │   - Whisper (STT)     │
│  Auth, RLS,    │ │  Prefs + │ │   - Llama 3.3 70b     │
│  Edge Fn)      │ │  Secure  │ │     (AI cevap)        │
│                │ │  Storage │ │                       │
└────────────────┘ └──────────┘ └───────────────────────┘
        │              │                   │
        └──── Çevrimdışı Algılama (connectivity_plus) ───┘

         [ Sentry: Hata izleme — tüm katmanları sarar ]
```

---

## 3. Veri Akışı (Örnek: Kullanıcının AI ile Konuşması)

```
   [Kullanıcı]
        │  Mikrofon butonuna basar, İngilizce konuşur
        ▼
   [Pratik Ekranı (UI)]
        │  Sesli kayıt başlatma talebi
        ▼
   [audio_recorder_service / VAD]
        │  Kayıt biter (sessizlik algılanır)
        ▼
   [groq_service (İş Mantığı)]
        │  1) Ses dosyasını Whisper'a gönderir → metin
        │  2) Metin + sohbet geçmişini Llama'ya gönderir
        ▼
   [Groq API (Veri)]
        │  AI cevap metni döner + değerlendirme
        ▼
   [groq_service]
        │  Cevabı UI'a iletir, kelimeleri ayrıştırır
        ▼
   [Pratik Ekranı]
        │  AI cevabını ekrana yazar
        ▼
   [flutter_tts]
        │  AI cevabını sesli okur
        ▼
   [Supabase (Veri)]
        │  Konuşma geçmişi, yeni kelimeler kaydedilir
        ▼
   [gamification_providers]
        │  Günlük görev / XP / streak güncellenir
        ▼
   [Dashboard]
        │  Geri dönüldüğünde güncel ilerleme görünür
```

---

## 4. Mimari Notlar

- **Tutarlılık:** Bu mimari LAB 4'teki ekran akışı (Sohbet → Senaryo → Karakter / Kelime → Flashcard) ve LAB 5'te seçilen teknolojiler (Flutter, Supabase, Hive, Groq, Riverpod) ile bire bir uyumludur.
- **Genişletilebilirlik:** Katmanlı yapı sayesinde planlanan ileri özellikler (Azure Speech ile fonem tabanlı telaffuz analizi, PostHog analytics, FCM push bildirimi, tam offline desteği) yalnız ilgili servisin altına yeni bir uyarlayıcı eklenerek entegre edilebilir.
- **Bakım Kolaylığı:** Sorumluluklar net şekilde ayrılmıştır — bir ekrandaki widget değişikliği iş mantığını, iş mantığındaki bir kural değişikliği veri kaynağını etkilemez. Riverpod sayesinde aynı veriye birden fazla ekran abone olabilir ve değişiklikler otomatik yansır.
- **Gözlemlenebilirlik:** Sentry tüm katmanları sararak hataların hangi ekran ve hangi servis çağrısı sırasında oluştuğunu raporlar.

---

## Tamamlama Notu

Bu doküman; VoiceLingo projesinin gerçek `pubspec.yaml`, `lib/` klasörü, router ve servis dosyalarının analizinden elde edilen bilgilerle hazırlanmıştır. 5 lab (LAB 2–LAB 6) birbiriyle tutarlıdır: LAB 2'deki "Türk kullanıcının konuşma pratiği eksikliği" problemi, LAB 3'teki AI sohbet / kelime tekrarı / senaryo bazlı pratik senaryolarını, LAB 4'teki Dashboard–Kelime–Pratik–Profil ekran akışını, LAB 5'teki Flutter + Supabase + Groq + Riverpod yığınını ve LAB 6'daki üç katmanlı mimariyi doğrudan destekler.
