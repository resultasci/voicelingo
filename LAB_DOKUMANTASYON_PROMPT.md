# 📱 Mobil Uygulama Lab Dokümantasyon Asistanı

> Bu dosya, VS Code'daki Claude'a verilmek üzere hazırlanmıştır. Claude bu dosyayı okuyacak, **mevcut projeyi analiz edecek** ve aşağıda tanımlanan **5 lab dokümanını** (Lab 2, 3, 4, 5, 6) hocanın istediği formatta tek tek `.md` dosyaları olarak oluşturacaktır.

---

## 🎯 GÖREV (Claude için)

Sen bir mobil uygulama dokümantasyon asistanısın. Aşağıdaki adımları **sırayla** takip et:

### 1. Projeyi Analiz Et
Çalışma alanındaki dosyaları inceleyerek aşağıdaki bilgileri **çıkarsamadan, gerçek koddan** elde et:

- **Proje teknolojisi:** `pubspec.yaml` (Flutter), `package.json` (React Native/Expo), `build.gradle` (Native Android), `Info.plist` (Native iOS) dosyalarına bak.
- **Kütüphaneler ve bağımlılıklar:** Yukarıdaki dosyalardaki `dependencies` bölümlerini oku.
- **Ekranlar (Screens / Pages):** `lib/screens/`, `lib/pages/`, `src/screens/`, `app/screens/` veya benzeri klasörlerdeki dosya isimlerini ve içeriklerini incele. Her ekrandaki widget/component'leri (Button, TextField, ListView, AppBar vb.) listele.
- **Navigasyon / Geçişler:** `Navigator.push`, `Navigator.pushNamed`, `MaterialApp.routes`, `GoRouter`, `react-navigation` gibi yapıları bularak ekranlar arası geçişleri haritala.
- **Veri kaynağı:** Firebase, Firestore, SQLite, Hive, SharedPreferences, REST API çağrıları (`http`, `dio`, `axios`, `fetch`) gibi yapılar var mı? `pubspec.yaml`/`package.json`'dan ve servis/repository klasörlerinden tespit et.
- **Veri modelleri:** `models/`, `entities/` klasörlerindeki sınıfları incele.
- **İş mantığı:** `services/`, `controllers/`, `viewmodels/`, `blocs/`, `cubits/`, `providers/`, `repositories/` klasörlerine bak.
- **Uygulamanın amacı:** `README.md`, `pubspec.yaml`'daki `description`, `app_name`, ana ekrandaki başlıklar/metinlerden uygulamanın ne işe yaradığını çıkar.

### 2. Belirsizlik Olursa
Eğer projenin ne yaptığı (problem/hedef kullanıcı) koddan **net anlaşılmıyorsa**, dokümanı doldurmadan **ÖNCE** bana şu soruları sor:
- Uygulamanın çözmeyi hedeflediği günlük hayat problemi nedir?
- Hedef kullanıcı kim? (öğrenci, çalışan, sporcu, hasta, ev hanımı vb.)
- Hangi temel işlevler **kapsam dışı** bırakıldı?

Kod analizinden çıkarılabilen her şey için **soru sorma**, doğrudan dokümana yaz.

### 3. Çıktıları Üret
Aşağıdaki **5 ayrı `.md` dosyasını** projenin kök dizininde `/lab_docs/` klasörü altında oluştur:

```
/lab_docs/
  ├── LAB2_Problem_Tanimi.md
  ├── LAB3_Kullanici_Senaryolari.md
  ├── LAB4_Wireframe_Ekran_Akisi.md
  ├── LAB5_Teknoloji_Secimi.md
  └── LAB6_Mimari_Tasarim.md
```

### 4. Kurallara Uy
- ❌ **Kod yazma** (sadece Lab 4 ve Lab 6'da metinsel/ASCII şema olabilir).
- ❌ **Teknik terim kullanmaktan kaçın** (özellikle Lab 2 ve Lab 3'te). "API çağrısı yapar" yerine "verileri görüntüler".
- ❌ **Uydurma yapma.** Projede olmayan ekranı, kütüphaneyi veya özelliği yazma.
- ✅ Her dokümanı **sade, açık, anlaşılır Türkçe** ile yaz.
- ✅ Her doküman **1–2 sayfa** uzunluğunda olmalı (Lab 3 hariç, o 1-2 sayfa).
- ✅ Tüm laboratuvarlar **birbirleriyle tutarlı** olmalı: Lab 2'deki problem → Lab 3 senaryolarını → Lab 4 ekranlarını → Lab 6 mimarisini desteklemeli.

---

## 📄 ÇIKTI ŞABLONLARI

Aşağıdaki şablonların **her birini ayrı bir `.md` dosyası** olarak üret. Köşeli parantezler `[...]` içindeki alanları **proje analizinden elde ettiğin gerçek bilgilerle** doldur.

---

### 📘 LAB2_Problem_Tanimi.md

```markdown
# LAB 2 — Problem Tanımı ve Gereksinim Analizi

**Öğrenci Adı:** [Buraya kendi adını yazacaksın]
**Proje Adı:** [pubspec.yaml veya package.json'dan al]
**Tarih:** [Bugünün tarihi]

---

## 1. Problem Tanımı

[Uygulamanın çözmeyi hedeflediği günlük hayat problemini 2–3 cümle ile, **teknik detay içermeden** açıkla. Örneğin: "Bireylerin günlük su tüketim miktarını takip etmemesi, yeterli sıvı alımını zorlaştırmakta ve sağlık sorunlarına yol açmaktadır."]

## 2. Hedef Kullanıcı

[Uygulamayı kullanacak kullanıcı profilini kısa ve net şekilde tanımla. Örneğin: "Düzenli su içme alışkanlığı kazanmak isteyen 18–45 yaş arası bireyler."]

## 3. Problemin Önemi ve Etkisi

[Problemin neden önemli olduğunu ve kullanıcı üzerindeki olumsuz etkilerini 3–5 cümle ile açıkla. Sayısal veya somut etkilerden bahset.]

## 4. Uygulamanın Kapsamı

### 4.1 Uygulamanın İçerdiği İşlevler
- [Proje koddundan tespit edilen ana işlev 1]
- [Ana işlev 2]
- [Ana işlev 3]
- [Ana işlev 4]
- [...]

### 4.2 Uygulamanın İçermediği İşlevler (Kapsam Dışı)
- [Projede yer almayan ama akla gelebilecek bir özellik 1, örn: "Sosyal medya paylaşımı"]
- [Kapsam dışı özellik 2, örn: "Çevrimdışı senkronizasyon"]
- [Kapsam dışı özellik 3]
```

---

### 📗 LAB3_Kullanici_Senaryolari.md

```markdown
# LAB 3 — Kullanıcı Senaryoları

**Öğrenci Adı:** [Adın]
**Proje Adı:** [Proje adı]

---

## Senaryo 1: [Senaryo Adı — projedeki ana CRUD işleminden türet, örn: "Yeni Görev Ekleme"]

- **Kullanıcı:** [Hedef kullanıcı, Lab 2 ile tutarlı olmalı]
- **Amaç:** [Kullanıcının bu senaryoyu gerçekleştirme amacı, 1 cümle]

**Adımlar:**
1. Kullanıcı uygulamayı açar.
2. [Ana ekrandaki ilgili butona/seçeneğe tıklar]
3. [Gerekli bilgileri girer]
4. [Onay/kaydetme adımı]
5. [Sistem yanıtı]
6. [Sonucun kullanıcıya gösterimi]

---

## Senaryo 2: [Senaryo Adı — örn: "Mevcut Kaydı Görüntüleme"]

- **Kullanıcı:** [Hedef kullanıcı]
- **Amaç:** [1 cümle]

**Adımlar:**
1. [Adım 1]
2. [Adım 2]
3. [Adım 3]
4. [Adım 4]
5. [Adım 5]
6. [Adım 6]

---

## Senaryo 3: [Senaryo Adı — örn: "Kaydı Güncelleme veya Silme"]

- **Kullanıcı:** [Hedef kullanıcı]
- **Amaç:** [1 cümle]

**Adımlar:**
1. [Adım 1]
2. [Adım 2]
3. [Adım 3]
4. [Adım 4]
5. [Adım 5]
6. [Adım 6]

---

> **Not:** Senaryolar 6–8 adımı geçmemeli, teknik terim içermemeli ve LAB 2'deki problem tanımıyla doğrudan ilişkili olmalıdır.
```

---

### 📙 LAB4_Wireframe_Ekran_Akisi.md

```markdown
# LAB 4 — Wireframe ve Ekran Akışları

**Öğrenci Adı:** [Adın]
**Proje Adı:** [Proje adı]

---

## 1. Uygulama Ekranları

Aşağıda projedeki ekranların metinsel wireframe'leri (kutu-şema yapısında) sunulmuştur.

### Ekran 1: [Ana Ekran / Liste Ekranı adı — kod analizinden]

```
┌─────────────────────────────────────┐
│  [Üst Bar: Uygulama Adı]   [⚙ Ayar] │
├─────────────────────────────────────┤
│                                     │
│  📋 [Liste Başlığı]                 │
│  ─────────────────────────          │
│  ▢ [Liste Öğesi 1]                  │
│  ▢ [Liste Öğesi 2]                  │
│  ▢ [Liste Öğesi 3]                  │
│  ...                                │
│                                     │
│                                     │
│                          [ + Ekle ] │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- Üst başlık çubuğu (AppBar)
- [Kod analizinde tespit edilen liste widget'ı, örn: ListView]
- Yeni kayıt ekleme butonu (FAB)
- [Diğer tespit edilen bileşenler]

---

### Ekran 2: [Veri Ekleme Ekranı adı]

```
┌─────────────────────────────────────┐
│  [← Geri]   Yeni Kayıt              │
├─────────────────────────────────────┤
│                                     │
│  [Form Alanı 1 Etiketi]             │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Form Alanı 2 Etiketi]             │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  [   Kaydet   ]    [   İptal   ]    │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- [Tespit edilen form alanları]
- Kaydet butonu
- İptal butonu

---

### Ekran 3: [Detay / Güncelleme Ekranı adı]

```
┌─────────────────────────────────────┐
│  [← Geri]   Detay         [🗑 Sil]  │
├─────────────────────────────────────┤
│                                     │
│  [Alan 1]: [Değer]                  │
│  [Alan 2]: [Değer]                  │
│  [Alan 3]: [Değer]                  │
│                                     │
│  [   Güncelle   ]                   │
└─────────────────────────────────────┘
```

**Temel Bileşenler:**
- [Detay görüntüleme alanları]
- Güncelle butonu
- Silme butonu

---

## 2. Ekran Akış Diyagramı

```
        ┌──────────────────┐
        │   Ana Ekran      │
        │  (Liste)         │
        └──────┬───────┬───┘
               │       │
   "+ Ekle"    │       │  Listeden öğeye dokunma
               ▼       ▼
   ┌────────────────┐  ┌────────────────────┐
   │ Veri Ekleme    │  │  Detay / Güncelle  │
   │  Ekranı        │  │   Ekranı           │
   └──────┬─────────┘  └──────┬─────────────┘
          │ Kaydet            │ Güncelle / Sil
          ▼                   ▼
   ┌────────────────────────────────┐
   │       Ana Ekran (Liste)        │
   └────────────────────────────────┘
```

### Geçiş Açıklamaları
- **Ana Ekran → Veri Ekleme:** Kullanıcı "+" butonuna basar (Senaryo 1).
- **Ana Ekran → Detay Ekranı:** Kullanıcı listedeki bir öğeye dokunur (Senaryo 2).
- **Detay → Ana Ekran:** Kullanıcı güncelleme veya silme işlemini tamamlar (Senaryo 3).
```

---

### 📕 LAB5_Teknoloji_Secimi.md

```markdown
# LAB 5 — Teknoloji Seçimi ve Gerekçelendirme

**Öğrenci Adı:** [Adın]
**Proje Adı:** [Proje adı]

---

## 1. Mobil Geliştirme Teknolojisi

**Seçim:** [Flutter / React Native / Native Android / Native iOS — kod analizinden tespit edilen GERÇEK teknoloji]

**Gerekçe:**
[Bu teknolojinin neden seçildiğini 3–4 cümle ile açıkla. Problem yapısı, kullanıcı sayısı beklentisi ve geliştirme süresini dikkate al. Örn: Cross-platform ise tek kod tabanı avantajı, native ise platform-özel optimizasyon vurgulanabilir.]

---

## 2. Veri Kaynağı

**Seçim:** [Bulut tabanlı (Firebase Firestore/Supabase) / Yerel veritabanı (SQLite/Hive/Isar) / Dosya tabanlı (SharedPreferences) / REST API — kod analizinden tespit edilen]

**Gerekçe:**
[Veri yapısının basitliği/karmaşıklığı, çevrimdışı kullanım ihtiyacı, kullanıcılar arası senkronizasyon ihtiyacı, güvenlik gibi faktörleri kullanarak 3–4 cümle ile gerekçelendir.]

---

## 3. Ek Araçlar ve Kütüphaneler

| Kütüphane / Araç | Kullanım Amacı |
|------------------|----------------|
| [pubspec.yaml veya package.json'dan tespit edilen kütüphane 1] | [Ne için kullanılıyor] |
| [Kütüphane 2] | [Kullanım amacı] |
| [Kütüphane 3] | [Kullanım amacı] |
| [...] | [...] |

---

## 4. Genel Değerlendirme

[Tüm seçimlerin birbiriyle uyumunu ve uygulamanın ihtiyaçlarına nasıl cevap verdiğini 3–4 cümle ile özetle. Geliştirme süresi, bakım kolaylığı ve ölçeklenebilirlik açısından değerlendirme yap.]
```

---

### 📔 LAB6_Mimari_Tasarim.md

```markdown
# LAB 6 — Yazılım Mimarisi ve Veri Akışı

**Öğrenci Adı:** [Adın]
**Proje Adı:** [Proje adı]

---

## 1. Mimari Bileşenler

Uygulamanın temel bileşenleri aşağıda tanımlanmıştır:

### 1.1 Sunum Katmanı (UI)
[Lab 4'teki ekranları burada tekrar say: Ana Ekran, Veri Ekleme Ekranı, Detay Ekranı vb. Hangi widget framework'ünün kullanıldığını belirt — Flutter Widget Tree / React Components / SwiftUI vb.]

### 1.2 İş Mantığı Katmanı
[Projedeki state management / business logic yapısını belirt: Provider, Riverpod, BLoC, GetX, Redux, Zustand, MobX vb. Hangi kuralları yönettiğini açıkla — örn: "Görev ekleme kuralı, doğrulama, silme onayı".]

### 1.3 Veri Katmanı
[Lab 5'te seçilen veri kaynağına atıfta bulun: Firebase Firestore, SQLite (sqflite), Hive, REST API vb. Repository pattern kullanılıyorsa belirt.]

---

## 2. Katmanlı Yapı Diyagramı

```
┌─────────────────────────────────────────────┐
│        SUNUM KATMANI (UI)                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │  Ana     │ │  Ekleme  │ │  Detay   │    │
│  │  Ekran   │ │  Ekranı  │ │  Ekranı  │    │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘    │
└───────┼────────────┼────────────┼──────────┘
        │            │            │
        ▼            ▼            ▼
┌─────────────────────────────────────────────┐
│       İŞ MANTIĞI KATMANI                    │
│   [State Management: ... ]                  │
│   • Ekleme kuralları                        │
│   • Güncelleme/silme kuralları              │
│   • Doğrulama (validation)                  │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│        VERİ KATMANI                         │
│   [Veri Kaynağı: ... ]                      │
│   • Veri okuma (read)                       │
│   • Veri yazma (write/update/delete)        │
└─────────────────────────────────────────────┘
```

---

## 3. Veri Akışı (Örnek: Yeni Kayıt Ekleme)

```
   [Kullanıcı]
        │  "+" butonuna basar
        ▼
   [Ana Ekran]
        │  Veri Ekleme Ekranına geçiş
        ▼
   [Ekleme Ekranı]  ◄── Kullanıcı form alanlarını doldurur
        │  "Kaydet" butonuna basılır
        ▼
   [İş Mantığı Katmanı]
        │  Veri doğrulanır
        ▼
   [Veri Katmanı]
        │  Veri kaynağına kaydedilir
        ▼
   [İş Mantığı Katmanı]
        │  Başarılı yanıt döner
        ▼
   [Ana Ekran]  ◄── Güncellenmiş liste görüntülenir
```

---

## 4. Mimari Notlar

- **Tutarlılık:** Bu mimari LAB 4 (wireframe) ve LAB 5 (teknoloji seçimi) ile tam uyumludur.
- **Genişletilebilirlik:** Katmanlı yapı sayesinde gelecekte eklenmesi planlanan özellikler (örn: bildirim, çevrimdışı destek), mevcut mimariye minimum müdahale ile entegre edilebilir.
- **Bakım Kolaylığı:** Sorumluluk ayrımı (separation of concerns) sayesinde bir katmandaki değişiklik diğer katmanları etkilemez.
```

---

## ✅ Tamamlama Kontrolü

Tüm dosyaları oluşturduktan sonra şu kontrolleri yap ve bana bir özet ver:

- [ ] 5 doküman da `/lab_docs/` klasörüne yazıldı mı?
- [ ] Lab 2'deki problem, Lab 3 senaryoları ve Lab 4 ekranları ile **mantıksal olarak tutarlı** mı?
- [ ] Lab 5'teki teknolojiler, Lab 6 mimarisinde aynı şekilde geçiyor mu?
- [ ] Hiçbir dokümana **gerçekte projede olmayan** özellik/kütüphane eklenmedi mi?
- [ ] Lab 2 ve Lab 3'te teknik terim **kullanılmadı** mı?
- [ ] Her dokümanın uzunluğu hocanın istediği aralıkta mı (1–2 sayfa)?

Son olarak bana şunu söyle:
> "5 lab dokümanı `/lab_docs/` klasörüne oluşturuldu. Şu bilgileri projeden tespit ettim: [kısa özet]. Şu konularda emin değildim ve şu varsayımları yaptım: [varsa]."

---

## 🚀 Kullanım Talimatı (Kullanıcı için, Claude bu kısmı görmezden gelir)

1. Bu `.md` dosyasını projenin **kök dizinine** kopyala.
2. VS Code'da Claude eklentisini aç.
3. Claude'a şu mesajı yaz:
   > "Kök dizindeki `LAB_DOKUMANTASYON_PROMPT.md` dosyasını oku ve içindeki talimatlara göre 5 lab dokümanını oluştur."
4. Claude projeyi analiz edip `/lab_docs/` klasörü altında 5 dosyayı üretecek.
5. Eksik gördüğün yerleri Claude'a söyleyerek revize ettir.
