# Mobil Uygulama Geliştirme — Laboratuvar Çalışmaları Dokümanı

**Öğrenci:** Resul Taşçı
**Numara:** 235541074
**Ders:** Fonksiyonel Programlama — Laboratuvar
**Kapsam:** LAB 2 – LAB 6 (Haftalık Planlama Aşamaları)

---

## 0. Bu Dokümanın Amacı ve AI İçin Talimatlar

> **Bu bölüm AI asistanı (Claude / kod içine entegre AI) içindir. Hoca sunumunda bu bölüm okunmak zorunda değildir, ancak çıktının nasıl üretildiğini gösterdiği için saydamlık amacıyla bırakılmıştır.**

Bu doküman, VS Code içinde **halihazırda açık olan projenin kaynak kodu** temel alınarak doldurulacaktır. AI asistanının izlemesi gereken adımlar:

1. **Önce kodu incele.** Proje dizinindeki dosyaları, klasör yapısını, ekran/sayfa dosyalarını, veri modellerini, kullanılan paket/kütüphaneleri (`package.json`, `pubspec.yaml`, `requirements.txt`, `build.gradle` vb.) ve genel mimariyi oku.
2. **Projenin ne yaptığını koddan çıkar.** Uygulamanın amacını, hangi problemi çözdüğünü, hangi ekranların var olduğunu, verinin nasıl saklandığını kodun kendisinden tespit et. Kullanıcıya konuyu sorma — kod kaynak doğrudur.
3. **Her LAB bölümünü, projenin gerçek koduyla tutarlı şekilde doldur.** Uydurma özellik ekleme; kodda olmayan ekranı "varmış gibi" yazma. Eğer bir gereksinim kodda eksikse, bunu açıkça belirt ("Bu ekran henüz kodda yok, eklenmesi öneriliyor").
4. **Tutarlılık zinciri:** LAB 3 senaryoları LAB 2 problemine; LAB 4 wireframe'leri LAB 3 senaryolarına; LAB 6 mimarisi LAB 4 + LAB 5'e dayanmalıdır. Bölümler birbiriyle çelişmemelidir.
5. **Dil ve üslup:** Akademik, sade, profesyonel Türkçe. Teknik jargon yalnızca gerektiği yerde (özellikle LAB 5 ve LAB 6'da). LAB 2, 3, 4'te teknoloji/kod ismi kullanma — föyler bunu yasaklıyor.
6. **Her bölümü doldurduktan sonra**, o haftaya ait föyün "Öğrenciden Beklenen Çıktılar" maddelerini sağladığından emin ol.

---

## LAB 2 — Problem Tanımı ve Gereksinim Analizi

> **Föy kuralı:** Kod yazılmaz, yalnızca analiz/planlama. Teknik detay ve teknoloji ismi YOK. Önerilen uzunluk: 1 sayfa.

### 2.1 Problem Tanımı
*[AI: Uygulamanın çözdüğü temel problemi koddan çıkarıp, günlük hayatta karşılaşılan gerçek bir ihtiyaç olarak, teknik detay içermeden 2–3 cümleyle yaz.]*

### 2.2 Hedef Kullanıcı
*[AI: Uygulamayı kimlerin kullanacağını kısa ve net tanımla.]*

### 2.3 Problemin Önemi ve Etkisi
*[AI: Problemin neden önemli olduğunu ve kullanıcı üzerindeki etkilerini açıkla.]*

### 2.4 Uygulamanın Kapsamı
**İçereceği işlevler:**
*[AI: Kodda var olan temel işlevleri madde madde listele.]*

**İçermeyeceği işlevler (kapsam dışı):**
*[AI: Uygulamanın bilinçli olarak yapmadığı şeyleri yaz — kapsamın gereksiz büyümesini engellemek için.]*

---

## LAB 3 — Kullanıcı Senaryoları (Use Case)

> **Föy kuralı:** En az 3 senaryo. Kullanıcı bakış açısıyla, metin halinde. Teknik terim/kod/teknoloji ismi YOK. Her senaryo 6–8 adımı geçmemeli. LAB 2 problemiyle doğrudan ilişkili olmalı.

### Senaryo 1
- **Senaryo Adı:** *[AI]*
- **Kullanıcı:** *[AI]*
- **Amaç:** *[AI]*
- **Adımlar:**
  1. *[AI]*
  2. ...

### Senaryo 2
- **Senaryo Adı:** *[AI]*
- **Kullanıcı:** *[AI]*
- **Amaç:** *[AI]*
- **Adımlar:**
  1. *[AI]*
  2. ...

### Senaryo 3
- **Senaryo Adı:** *[AI]*
- **Kullanıcı:** *[AI]*
- **Amaç:** *[AI]*
- **Adımlar:**
  1. *[AI]*
  2. ...

> *[AI: Kodda 3'ten fazla anlamlı kullanıcı akışı varsa ek senaryolar ekleyebilirsin. Her senaryo kodda gerçekten karşılığı olan bir akış olmalı.]*

---

## LAB 4 — Wireframe ve Ekran Akışları

> **Föy kuralı:** En az 3 ekran. Kod yazılmaz, renk/font/estetik önemsiz. Her wireframe'de ekran adı + temel bileşenler olmalı. Zorunlu ekranlar: Liste/Ana ekran, Veri ekleme ekranı, (varsa) detay/güncelleme ekranı. Ekranlar arası geçişler oklarla. LAB 3 senaryolarıyla uyumlu.

### 4.1 Ekran Listesi ve Bileşenleri
*[AI: Kodda var olan ekranları/sayfaları tespit et. Her ekran için aşağıdaki formatta doldur.]*

**Ekran 1 — [Ekran Adı]**
- Temel bileşenler: *[buton, liste, form alanı vb.]*

**Ekran 2 — [Ekran Adı]**
- Temel bileşenler: *[...]*

**Ekran 3 — [Ekran Adı]**
- Temel bileşenler: *[...]*

### 4.2 Ekran Akış Diyagramı
*[AI: Ekranlar arası geçişleri metin tabanlı bir diyagramla göster. Her ok bir kullanıcı senaryosu adımına karşılık gelmeli. Örnek format aşağıda — projeye göre değiştir.]*

```
[Ana Ekran / Liste]
      |
      |  "Yeni ekle" butonu  (Senaryo 1, Adım 2)
      v
[Veri Ekleme Ekranı]
      |
      |  "Kaydet" butonu  (Senaryo 1, Adım 4)
      v
[Ana Ekran / Liste]  --- öğeye tıkla ---> [Detay / Güncelleme Ekranı]
```

> **Not (hoca için):** Görsel wireframe çizimleri (elle veya Canva/Draw.io) ayrıca eklenecektir. Bu doküman ekran yapısının ve akışın metinsel tanımını içerir.

---

## LAB 5 — Teknoloji Seçimi ve Gerekçelendirme

> **Föy kuralı:** Burada artık teknoloji isimleri SERBESTTİR (önceki labların aksine). Her seçim için kısa, mantıklı gerekçe. Önerilen uzunluk: 1–2 sayfa. Problem yapısı, kullanıcı sayısı beklentisi ve geliştirme süresi dikkate alınmalı.

### 5.1 Mobil Geliştirme Teknolojisi
*[AI: Kodda kullanılan gerçek teknolojiyi tespit et (Flutter, React Native, Native Android/iOS vb. — koddan oku, varsayma).]*
- **Seçim:** *[AI]*

### 5.2 Veri Kaynağı
*[AI: Kodda verinin nasıl saklandığını tespit et (yerel DB, bulut DB, dosya tabanlı vb.).]*
- **Seçim:** *[AI]*

### 5.3 Ek Araçlar ve Kütüphaneler
*[AI: package.json / pubspec.yaml / gradle vb. dosyalardan kullanılan önemli kütüphaneleri listele. Zorunlu değil ama varsa yaz.]*

### 5.4 Gerekçelendirme
*[AI: Yukarıdaki her seçim için, problem yapısı + beklenen kullanıcı sayısı + geliştirme süresi açısından kısa ve mantıklı gerekçe sun. "Bildiğim teknolojiyi kullandım" değil, "probleme uygun teknoloji seçtim" yaklaşımıyla yaz.]*

---

## LAB 6 — Yazılım Mimarisi ve Veri Akışı

> **Föy kuralı:** Son planlama aşaması. Kod yazılmaz, diyagramlar basit. Karmaşık UML değil, yapıyı netleştirmek amaç. Katmanlı yapı + bileşenler + veri akışı (oklarla). LAB 4 ve LAB 5 ile tutarlı olmalı. Üç bileşen ZORUNLU: UI, İş Mantığı, Veri Kaynağı.

### 6.1 Mimari Bileşenler
*[AI: Kodun gerçek yapısına göre doldur.]*
- **Kullanıcı Arayüzü (UI / Ekranlar):** *[AI — LAB 4'teki ekranlarla tutarlı]*
- **İş Mantığı (Uygulama Kuralları):** *[AI — ekleme/güncelleme/silme vb. kurallar]*
- **Veri Kaynağı:** *[AI — LAB 5'teki veri kaynağı seçimiyle tutarlı]*

### 6.2 Katmanlı Yapı
```
┌─────────────────────────────────┐
│   SUNUM KATMANI (UI / Ekranlar)  │   <- LAB 4 ekranları
└─────────────────────────────────┘
                ↕
┌─────────────────────────────────┐
│      İŞ MANTIĞI KATMANI          │   <- Uygulama kuralları
└─────────────────────────────────┘
                ↕
┌─────────────────────────────────┐
│        VERİ KATMANI              │   <- LAB 5 veri kaynağı
└─────────────────────────────────┘
```
*[AI: Katmanlar arası ilişkileri projenin gerçek yapısına göre güncelle.]*

### 6.3 Veri Akışı
*[AI: Kullanıcının bir işlem başlatmasıyla (örn. veri ekleme) verinin katmanlar arasında nasıl aktığını oklarla, yönü tutarlı şekilde göster. Örnek format aşağıda — projeye göre değiştir.]*

```
Kullanıcı [Ekle butonu]
   │  (1) girilen veri
   ▼
UI Katmanı
   │  (2) kaydet isteği
   ▼
İş Mantığı Katmanı  ──(3) doğrulama/kural──┐
   │  (4) geçerli veri                      │
   ▼                                        │
Veri Katmanı (kaydet)                       │
   │  (5) başarı yanıtı                      │
   ▼                                        │
İş Mantığı ──(6) güncellenmiş liste──► UI ◄─┘
   │  (7) ekranda göster
   ▼
Kullanıcı (güncel liste)
```

---

## Tutarlılık Kontrol Listesi (AI doldurduktan sonra kontrol etmeli)

- [ ] LAB 2: Teknoloji/kod ismi yok, problem net ve mobille çözülebilir
- [ ] LAB 3: En az 3 senaryo, her biri ≤8 adım, LAB 2 ile ilişkili, teknik terim yok
- [ ] LAB 4: En az 3 ekran, zorunlu ekranlar mevcut, akış oklarla, LAB 3 ile uyumlu
- [ ] LAB 5: Gerçek koddaki teknoloji, her seçim gerekçeli
- [ ] LAB 6: UI + İş Mantığı + Veri Kaynağı üçü de var, veri akışı oklarla, LAB 4 ve 5 ile tutarlı
- [ ] Hiçbir bölüm kodda olmayan bir özelliği "varmış gibi" anlatmıyor

---

## Teslim Bilgileri (Föylere Göre)

| Lab | Format | Önerilen Uzunluk |
|-----|--------|------------------|
| LAB 2 | PDF | 1 sayfa |
| LAB 3 | PDF | 1–2 sayfa |
| LAB 4 | PDF | 1–2 sayfa |
| LAB 5 | PDF | 1–2 sayfa |
| LAB 6 | PDF | — |
