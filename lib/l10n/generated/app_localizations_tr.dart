import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppL10nTr extends AppL10n {
  AppL10nTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'VoiceLingo';

  @override
  String get common_ok => 'Tamam';

  @override
  String get common_cancel => 'İptal';

  @override
  String get common_save => 'Kaydet';

  @override
  String get common_delete => 'Sil';

  @override
  String get common_retry => 'Tekrar dene';

  @override
  String get common_back => 'Geri';

  @override
  String get common_next => 'İleri';

  @override
  String get common_done => 'Tamam';

  @override
  String get common_loading => 'Yükleniyor…';

  @override
  String get common_error => 'Bir hata oluştu';

  @override
  String get nav_dashboard => 'GENEL';

  @override
  String get nav_words => 'KELİME';

  @override
  String get nav_practice => 'PRATİK';

  @override
  String get nav_profile => 'PROFİL';

  @override
  String get nav_settings => 'Ayarlar';

  @override
  String get nav_scenarios => 'Senaryolar';

  @override
  String get auth_signIn => 'Giriş yap';

  @override
  String get auth_signUp => 'Kayıt ol';

  @override
  String get auth_signOut => 'Çıkış yap';

  @override
  String get auth_email => 'E-posta';

  @override
  String get auth_password => 'Şifre';

  @override
  String get auth_username => 'Kullanıcı adı';

  @override
  String get auth_confirmPassword => 'Şifreyi doğrula';

  @override
  String get auth_forgotPassword => 'Şifremi unuttum';

  @override
  String get auth_changePassword => 'Şifre değiştir';

  @override
  String get auth_resetPassword => 'Şifre sıfırla';

  @override
  String get auth_validation_fillAll => 'Tüm alanları doldur';

  @override
  String get auth_validation_passwordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get auth_error_sessionNotFound =>
      'Oturum bulunamadı, lütfen tekrar giriş yap.';

  @override
  String get auth_error_sessionExpired =>
      'Oturum süren doldu, lütfen tekrar giriş yap.';

  @override
  String get error_network => 'Bağlantı sorunu. İnternetini kontrol et.';

  @override
  String get error_timeout => 'Bağlantı zaman aşımına uğradı.';

  @override
  String get error_unexpected => 'Beklenmeyen bir hata oluştu.';

  @override
  String get error_rateLimit =>
      'Günlük kullanım limitine ulaştın. Yarın tekrar dene.';

  @override
  String get error_audioTooLong =>
      'Ses kaydı çok uzun. Daha kısa bir kayıt dene.';

  @override
  String get error_aiUnavailable => 'AI servisi şu an cevap vermiyor.';

  @override
  String get error_invalidJson => 'Servisten geçersiz cevap alındı.';

  @override
  String get error_offline => 'Çevrimdışı moddasın.';

  @override
  String get error_audioInvalid =>
      'Ses tanıma servisinden geçersiz cevap alındı.';

  @override
  String get error_evalInvalid => 'Değerlendirme servisi geçersiz yanıt döndü.';

  @override
  String get error_serverInvalid => 'Beklenmeyen sunucu yanıtı.';

  @override
  String get settings_title => 'Ayarlar';

  @override
  String get settings_theme => 'Tema';

  @override
  String get settings_themeDark => 'Koyu';

  @override
  String get settings_themeLight => 'Açık';

  @override
  String get settings_themeSystem => 'Sistem';

  @override
  String get settings_language => 'Arayüz Dili';

  @override
  String get settings_languageTurkish => 'Türkçe';

  @override
  String get settings_languageEnglish => 'İngilizce';

  @override
  String get settings_ttsSpeed => 'Konuşma Hızı';

  @override
  String get settings_ttsSpeedSlow => 'Yavaş';

  @override
  String get settings_ttsSpeedNormal => 'Normal';

  @override
  String get settings_ttsSpeedFast => 'Hızlı';

  @override
  String get settings_notifications => 'Bildirimler';

  @override
  String get settings_reviewHour => 'Günlük Hatırlatma Saati';

  @override
  String get settings_textScale => 'Yazı Büyüklüğü';

  @override
  String get settings_aiCharacter => 'AI Karakteri';

  @override
  String get settings_account => 'Hesap';

  @override
  String get settings_about => 'Hakkında';

  @override
  String get settings_version => 'Sürüm';

  @override
  String get profile_level => 'Seviye';

  @override
  String get profile_xp => 'XP';

  @override
  String get profile_streak => 'Streak';

  @override
  String profile_streak_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
      zero: 'Henüz streak yok',
    );
    return '$_temp0';
  }

  @override
  String get profile_cefr => 'CEFR Seviyesi';

  @override
  String get words_addNew => 'Yeni Kelime';

  @override
  String words_review_due(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelime tekrar bekliyor',
      one: '1 kelime tekrar bekliyor',
      zero: 'Bugün tekrar yok',
    );
    return '$_temp0';
  }

  @override
  String get words_review_remember => 'Hatırladım';

  @override
  String get words_review_hard => 'Zorlandım';

  @override
  String get words_review_forgot => 'Unuttum';

  @override
  String words_duplicate(String word) {
    return '\"$word\" zaten listende.';
  }

  @override
  String get conversation_listening => 'Dinleniyor…';

  @override
  String get conversation_thinking => 'Düşünüyor…';

  @override
  String get conversation_speaking => 'Konuşuyor…';

  @override
  String get conversation_idle => 'Mikrofon hazır';

  @override
  String get conversation_handsfree => 'Eller serbest mod';

  @override
  String get conversation_pushToTalk => 'Konuşmak için basılı tut';

  @override
  String get conversation_micPermissionDenied =>
      'Mikrofon izni gerekli. Ayarlardan açabilirsin.';

  @override
  String get notification_reviewReminder_title => 'Hatırlatma Zamanı!';

  @override
  String notification_reviewReminder_body(String word) {
    return '\"$word\" kelimesinin tekrar zamanı geldi!';
  }

  @override
  String get notification_dailyDigest_title => 'Günlük tekrar';

  @override
  String notification_dailyDigest_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count kelime tekrar bekliyor',
      one: 'Bugün 1 kelime tekrar bekliyor',
      zero: 'Bugün tekrarlanacak kelimen yok',
    );
    return '$_temp0';
  }

  @override
  String get boot_envMissing_title => 'Yapılandırma eksik';

  @override
  String boot_envMissing_description(String key) {
    return '$key tanımlı değil veya boş — .env dosyanızı kontrol edin.';
  }

  @override
  String get boot_dotenvFailed_title => '.env yüklenemedi';

  @override
  String get boot_dotenvFailed_description =>
      '.env dosyası proje kökünde bulunmuyor veya okunamadı.';

  @override
  String get dashboard_profileLoadError => 'Profil yüklenemedi.';

  @override
  String get dashboard_defaultName => 'Kaptan';

  @override
  String dashboard_greeting(String name) {
    return 'Merhaba, $name';
  }

  @override
  String get dashboard_greetingSubtitle =>
      'Günlük galaktik hedeflerine hazır mısın?';

  @override
  String get dashboard_statStreak => 'SERİ';

  @override
  String dashboard_streakValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gün',
      one: '1 Gün',
    );
    return '$_temp0';
  }

  @override
  String get dashboard_aiModule => 'YAPAY ZEKA MODÜLÜ';

  @override
  String get dashboard_aiTitle => 'Derin Uzay Pratiği';

  @override
  String get dashboard_aiSubtitle =>
      'Kişiselleştirilmiş AI asistanın ile günlük konuşma simülasyonunu başlat.';

  @override
  String get dashboard_aiStart => 'Simülasyonu Başlat';

  @override
  String get dashboard_dailyGoals => 'Günlük Görevler';

  @override
  String get dashboard_goalLanguage => 'İngilizce';

  @override
  String get dashboard_goalLoading => 'Kütüphane Yükleniyor';

  @override
  String get dashboard_goalAllCurrent => 'Tüm Kelimeler Güncel';

  @override
  String dashboard_percentValue(int percent) {
    return '%$percent';
  }

  @override
  String get settings_emailAddress => 'E-Posta Adresi';

  @override
  String get settings_downloadDeleteAccount => 'Veri İndir / Hesabı Sil';

  @override
  String get settings_dailyReviewReminder => 'Günlük Tekrar Hatırlatması';

  @override
  String get settings_reminderSubtitle =>
      'Vadesi gelen kelimeler için günde bir bildirim';

  @override
  String get settings_reminderTime => 'Hatırlatma Saati';

  @override
  String get settings_onceADay => 'GÜNDE BİR KEZ';

  @override
  String get settings_comingSoon => 'YAKINDA';

  @override
  String get settings_systemUpdates => 'Sistem Güncellemeleri';

  @override
  String get settings_systemUpdatesSub => 'Yeni özellikler — yakında';

  @override
  String get settings_systemPreferences => 'Sistem Tercihleri';

  @override
  String get settings_visualTheme => 'Görsel Tema';

  @override
  String get settings_themeObsidian => 'Obsidian Void (Karanlık)';

  @override
  String get settings_themeSolar => 'Solar Flare (Aydınlık)';

  @override
  String get settings_themeSystemDefault => 'Sistem ile uyumlu';

  @override
  String get settings_aiCoach => 'AI Koç';

  @override
  String get settings_progress => 'İlerleme';

  @override
  String get settings_progressStats => 'İlerleme & İstatistik';

  @override
  String get settings_courseTree => 'Ders Yolu';

  @override
  String get settings_courseTreeFull => 'Ders Yolu (A1-C2)';

  @override
  String get settings_grammar => 'Gramer';

  @override
  String get settings_badges => 'Rozetler';

  @override
  String get settings_disconnect => 'Çıkış Yap';

  @override
  String get settings_signOutConfirm => 'Çıkmak istediğine emin misin?';

  @override
  String get common_saving => 'Kaydediliyor…';

  @override
  String get common_add => 'Ekle';

  @override
  String get words_filterAll => 'Tümü';

  @override
  String get words_filterDue => 'Tekrar Bekleyen';

  @override
  String get words_filterLearned => 'Öğrenilen';

  @override
  String get words_filterNew => 'Yeni';

  @override
  String get words_reviewSaveError => 'Tekrar kaydedilemedi';

  @override
  String get words_addToLibrary => 'Kütüphaneye ekle';

  @override
  String get words_labelEnglish => 'İNGİLİZCE';

  @override
  String get words_labelTurkish => 'TÜRKÇE';

  @override
  String get words_hintWord => 'word';

  @override
  String get words_hintTranslation => 'kelime';

  @override
  String get words_alreadyInLibrary => 'Bu kelime zaten kütüphanende var.';

  @override
  String get words_addFailed => 'Kelime eklenemedi';

  @override
  String get words_libraryTitle => 'Kelime Kütüphanesi';

  @override
  String words_librarySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bilişsel sözlüğün $count kelimeye genişledi.',
      one: 'Bilişsel sözlüğün 1 kelimeye genişledi.',
    );
    return '$_temp0';
  }

  @override
  String get words_searchHint => 'Kelime veya çeviri ara…';

  @override
  String get words_reviewToday => 'BUGÜN TEKRAR';

  @override
  String words_wordsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelime hazır',
      one: '1 kelime hazır',
    );
    return '$_temp0';
  }

  @override
  String get words_statusNew => 'Yeni';

  @override
  String get words_statusDue => 'Tekrar';

  @override
  String get words_statusLearned => 'Öğrenildi';

  @override
  String get words_statusInProgress => 'Süreçte';

  @override
  String get words_intervalNew => 'YENİ';

  @override
  String get words_unitDay => 'G';

  @override
  String get words_unitWeek => 'H';

  @override
  String get words_unitMonth => 'A';

  @override
  String get words_unitYear => 'Y';

  @override
  String get words_deleteWord => 'Kelimeyi sil';

  @override
  String get words_pronounce => 'Telaffuz et';

  @override
  String get words_emptyTitle => 'Kütüphaneni oluştur';

  @override
  String get words_emptyBody =>
      'Bir konu seç, yapay zeka sana özel kelime listesi üretsin — ya da tek tek kelime ekle. Her kelime SM-2 algoritması ile doğru zamanda karşına çıkar.';

  @override
  String get words_addFirst => 'Elle kelime ekle';

  @override
  String get words_generateCta => 'Yapay zeka ile üret';

  @override
  String get words_genTitle => 'Kelime üret';

  @override
  String get words_genSubtitle =>
      'Bir konu yaz, yapay zeka senin için kelime listesi oluştursun.';

  @override
  String get words_genTopicLabel => 'KONU';

  @override
  String get words_genTopicHint => 'ör. Seyahat, Mutfak, İş İngilizcesi';

  @override
  String get words_genCount => 'Kaç tane?';

  @override
  String get words_genButton => 'Üret';

  @override
  String words_genAdded(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelime eklendi',
      one: '1 kelime eklendi',
    );
    return '$_temp0';
  }

  @override
  String get words_genNone =>
      'Eklenecek yeni kelime yok — hepsi zaten kütüphanende vardı.';

  @override
  String get words_genFailed => 'Kelimeler üretilemedi. Lütfen tekrar dene.';

  @override
  String get words_filterEmpty => 'Bu filtre boş';

  @override
  String words_noResultsFor(String query) {
    return '\"$query\" için sonuç yok';
  }

  @override
  String get words_gradeGreat => 'Harika!';

  @override
  String get words_gradeGood => 'İyi iş!';

  @override
  String get words_gradeKeepGoing => 'Devam et!';

  @override
  String get words_reviewComplete => 'Tekrar Tamamlandı';

  @override
  String get words_statCorrect => 'DOĞRU';

  @override
  String get words_statTotal => 'TOPLAM';

  @override
  String get words_statSuccess => 'BAŞARI';

  @override
  String get words_backToLibrary => 'Kütüphaneye Dön';

  @override
  String get words_translate => 'Çevir';

  @override
  String get words_tapToReveal => 'DOKUNARAK GÖSTER';

  @override
  String get words_howWell => 'NE KADAR BİLDİN?';

  @override
  String get words_rateForgot => 'Bilmedim';

  @override
  String get words_rateHard => 'Zordu';

  @override
  String get words_rateEasy => 'Kolaydı';

  @override
  String get wordDetail_loadError => 'Ek detaylar yüklenemedi.';

  @override
  String get wordDetail_noCache => 'Cache\'de ek detay yok. Sonra tekrar dene.';

  @override
  String get wordDetail_ipaCopied => 'IPA kopyalandı';

  @override
  String get wordDetail_examples => 'Örnekler';

  @override
  String get wordDetail_synonyms => 'Eş anlamlılar';

  @override
  String get wordDetail_antonyms => 'Zıt anlamlılar';

  @override
  String get wordDetail_collocations => 'Birliktelikler';

  @override
  String get wordDetail_etymology => 'Etimoloji';

  @override
  String get flashcard_title => 'Kelime Pratiği';

  @override
  String flashcard_cardOf(int current, int total) {
    return 'KART $current / $total';
  }

  @override
  String get flashcard_revealHint =>
      'Çeviriyi görmek için \"Cevabı Göster\"e dokun';

  @override
  String get flashcard_showAnswer => 'CEVABI GÖSTER';

  @override
  String get flashcard_congrats => 'TEBRİKLER!';

  @override
  String get flashcard_completeBody =>
      'Bugünlük kelime tekrarını bitirdin. Kelimeler yarın senin için tekrar planlanacak.';

  @override
  String get flashcard_backHome => 'ANA SAYFAYA DÖN';

  @override
  String get conv_statusStarting => 'BAŞLANIYOR';

  @override
  String get conv_statusReady => 'HAZIR';

  @override
  String get conv_statusListening => 'DİNLİYOR';

  @override
  String get conv_statusThinking => 'DÜŞÜNÜYOR';

  @override
  String get conv_statusSpeaking => 'AI KONUŞUYOR';

  @override
  String get conv_statusError => 'HATA';

  @override
  String conv_errTts(String msg) {
    return 'TTS hatası: $msg';
  }

  @override
  String get conv_errTtsInit => 'TTS başlatılamadı.';

  @override
  String get conv_errMicPermission => 'Mikrofon izni gerekli.';

  @override
  String conv_errMicOpen(String error) {
    return 'Mikrofon açılamadı: $error';
  }

  @override
  String get conv_errRecordFailed => 'Ses kaydı başarısız.';

  @override
  String conv_errAudioProcess(String error) {
    return 'Ses işleme hatası: $error';
  }

  @override
  String get conv_errNoSpeech => 'Ses tanınamadı.';

  @override
  String conv_errGeneric(String error) {
    return 'Hata: $error';
  }

  @override
  String conv_errSpeak(String error) {
    return 'Konuşma hatası: $error';
  }

  @override
  String get conv_errUnknown => 'Bilinmeyen hata.';

  @override
  String get conv_greeting =>
      'Merhaba! İngilizceni pratik yapmak için hazırım. Konuş!';

  @override
  String get conv_replyFailed =>
      'Cevap alınamadı. Tekrar denemek için aşağıdaki butona dokun.';

  @override
  String conv_aiNoResponse(String error) {
    return 'AI yanıt vermedi: $error';
  }

  @override
  String get conv_practiceMode => 'Pratik Modu';

  @override
  String get conv_handsFreeOnTip =>
      'Eller serbest açık — AI bittikten sonra otomatik dinler';

  @override
  String get conv_handsFreeOffTip =>
      'Eller serbest kapalı — mikrofona basman gerekir';

  @override
  String get conv_pickScenario => 'Senaryo seç';

  @override
  String get conv_newChat => 'Yeni Sohbet';

  @override
  String get conv_chatHistory => 'Sohbet geçmişi';

  @override
  String get conv_preparing => 'Hazırlanıyor…';

  @override
  String get conv_aiPreparing => 'AI yanıt hazırlanıyor…';

  @override
  String get conv_emptyHint => 'Mikrofona dokun, yaz ya da bir senaryo seç.';

  @override
  String get conv_aiPracticeMode => 'AI Pratik Modu';

  @override
  String get conv_readyScenarios => 'HAZIR SENARYOLAR';

  @override
  String get conv_seeAll => 'Tümünü Gör';

  @override
  String get conv_inputHint => 'Mesajını yaz veya konuş…';

  @override
  String get conv_sendMessage => 'Mesajı gönder';

  @override
  String get conv_stopRecording => 'Kaydı durdur';

  @override
  String get conv_startRecording => 'Kayda başla';

  @override
  String get conv_tryAgain => 'Yeniden dene';

  @override
  String get conv_restart => 'Yeniden Başla';

  @override
  String get conv_feedbackGreat => '✅ Harika!';

  @override
  String conv_feedbackMoreNatural(String suggestion) {
    return '💡 Daha doğal: $suggestion';
  }

  @override
  String conv_evalSemantics(String label) {
    return 'Konuşma değerlendirmesi: $label';
  }

  @override
  String conv_score(int score) {
    return 'PUAN: $score/100';
  }

  @override
  String get conv_errorsLabel => 'HATALAR';

  @override
  String get conv_replay => 'Tekrar dinle';

  @override
  String get conv_copied => 'Panoya kopyalandı';

  @override
  String get conv_changeCoach => 'AI koçu değiştir';

  @override
  String get convHist_title => 'Sohbet Geçmişi';

  @override
  String get convHist_freeChat => 'Serbest sohbet';

  @override
  String get convHist_empty => 'Henüz kaydedilmiş bir sohbet yok.';

  @override
  String get convView_title => 'Sohbet';

  @override
  String convView_score(int score) {
    return 'Puan: $score';
  }

  @override
  String get charPicker_title => 'Koçunu seç';

  @override
  String get charPicker_start => 'Bu koçla başla';

  @override
  String get charPicker_listen => 'Sesini dinle';

  @override
  String get scen_createWithAi => 'AI ile yarat';

  @override
  String get scen_allScenarios => 'Tüm senaryolar';

  @override
  String get scen_free => 'Serbest';

  @override
  String get scen_newScenario => 'Yeni senaryo';

  @override
  String get scen_create => 'Yarat';

  @override
  String get scen_empty => 'Henüz senaryo yok. Yarat butonuna bas.';

  @override
  String get scen_yours => 'Senin yarattıkların';

  @override
  String get scen_builtIn => 'Hazır senaryolar';

  @override
  String scen_turnsCount(int count) {
    return '~$count tur';
  }

  @override
  String get scen_createTitle => 'Senaryo yarat';

  @override
  String get scen_describeScene => 'Bir sahne tarif et';

  @override
  String get scen_descHint => 'ör: \"Berberde saç kesimi\"';

  @override
  String get scen_category => 'Kategori';

  @override
  String get scen_difficulty => 'Zorluk';

  @override
  String get scen_generate => 'Oluştur';

  @override
  String get scen_regenerate => 'Yeniden üret';

  @override
  String get scen_saveStart => 'Kaydet & başla';

  @override
  String get scen_catDaily => 'Gündelik';

  @override
  String get scen_catWork => 'İş';

  @override
  String get scen_catTravel => 'Seyahat';

  @override
  String get scen_catHealth => 'Sağlık';

  @override
  String get scen_catEducation => 'Eğitim';

  @override
  String get scen_catOther => 'Diğer';

  @override
  String get scen_aiPlays => 'AI rolü';

  @override
  String get scen_youPlay => 'Senin rolün';

  @override
  String get scen_startsWith => 'Başlangıç';

  @override
  String get scen_goals => 'Hedefler';

  @override
  String get common_finish => 'Bitir';

  @override
  String get grammar_level => 'Seviye';

  @override
  String get grammar_emptyTopics =>
      'Henüz gramer konusu yok. Veritabanı yenilemesi (migration) uygulandı mı kontrol et.';

  @override
  String get grammar_bestScore => 'En iyi skor';

  @override
  String get topic_tabLesson => 'Konu';

  @override
  String get topic_noDescription => 'Açıklama yok.';

  @override
  String get topic_noExamples => 'Henüz örnek yok.';

  @override
  String get topic_noQuiz => 'Henüz quiz yok.';

  @override
  String get topic_greatJob => 'Harikasın!';

  @override
  String get quiz_question => 'Soru';

  @override
  String get quiz_typeAnswer => 'Cevabını yaz';

  @override
  String get quiz_retry => 'Tekrar';

  @override
  String get lesson_courseTitle => 'Ders Yolu';

  @override
  String get lesson_emptyCourse =>
      'Henüz kurs yok. Veritabanında derslerin kurulu olduğundan emin ol.';

  @override
  String get lesson_noUnits => 'Henüz ünite yok.';

  @override
  String get lesson_englishCourse => 'İngilizce Kursu';

  @override
  String get lesson_lessonsSuffix => 'ders';

  @override
  String get lesson_customScenarioTitle => 'Özel Senaryo Oluştur';

  @override
  String get lesson_customScenarioBody =>
      'Yapay zeka ile dilediğin konuda pratik yap.';

  @override
  String get lesson_typeVocab => 'Kelime';

  @override
  String get lesson_typeSpeaking => 'Konuşma';

  @override
  String get lesson_typeListening => 'Dinleme';

  @override
  String get lesson_grammarBridge =>
      'Bu ders, ilgili gramer konusunu açar. Oradaki quiz\'i bitirince bu ders de tamamlanır.';

  @override
  String get lesson_convBridge =>
      'İlgili senaryoyu konuş. Minimum tur sayısı bu ders için sayılır.';

  @override
  String get lesson_listenBridge =>
      'Dinleme egzersizleri yakında. Şimdilik tamamlanmış sayılıyor.';

  @override
  String get lesson_openGrammar => 'Grameri Aç';

  @override
  String get lesson_startConv => 'Sohbete Başla';

  @override
  String get lesson_markComplete => 'Tamamlandı işaretle';

  @override
  String get lesson_noVocab => 'Bu derste kelime yok.';

  @override
  String get lesson_tapToFlip => 'Çevirmek için dokun';

  @override
  String get lesson_practiceAgain => 'Tekrar';

  @override
  String get lesson_iKnowIt => 'Biliyorum';

  @override
  String get lesson_noQuizQuestions => 'Quiz sorusu yok.';

  @override
  String get lesson_perfect => 'Mükemmel!';

  @override
  String get lesson_great => 'Harika!';

  @override
  String get lesson_keepGoing => 'Devam et';

  @override
  String get lesson_errorTitle => 'Hata';

  @override
  String lesson_scoreLabel(int score) {
    return 'Skor: $score';
  }

  @override
  String get badge_unlocked => 'Rozet kazandın!';

  @override
  String get badge_awesome => 'Harika';

  @override
  String get progress_last90 => 'Son 90 gün';

  @override
  String get progress_mastery => 'Ustalaşma';

  @override
  String get progress_noData => 'Henüz veri yok.';

  @override
  String get progress_words => 'Kelimeler';

  @override
  String get progress_lessons => 'Dersler';

  @override
  String get progress_topMistakes => 'En sık hatalar (30 gün)';

  @override
  String get progress_noMistakes =>
      'Henüz hata kaydı yok — pratik yapmaya devam!';

  @override
  String get heatmap_less => 'Az';

  @override
  String get heatmap_more => 'Çok';

  @override
  String get profile_defaultName => 'Kullanıcı';

  @override
  String get profile_signOutWarning =>
      'Tekrar giriş yapana kadar pratik kaydedilemez.';

  @override
  String profile_levelTitle(int level) {
    return 'Seviye $level • Galaktik Dilbilimci';
  }

  @override
  String get profile_dailyStreak => 'GÜNLÜK SERİ';

  @override
  String get profile_fluency => 'AKICILIK';

  @override
  String get profile_fluencyTooltip =>
      'Akıcılık = doğru tekrar oranı × 50 + seri (≤30g) × 30 + XP (≤2000) × 20';

  @override
  String get profile_badgesTitle => 'Rozetler & Başarılar';

  @override
  String get profile_badge1Title => 'İlk Temas';

  @override
  String get profile_badge1Sub => '100 Kelime';

  @override
  String get profile_badge2Title => 'Dünya Vatandaşı';

  @override
  String get profile_badge2Sub => 'Seviye 5';

  @override
  String get profile_badge3Title => 'Yıldız Avcısı';

  @override
  String get profile_badge3Sub => '7 Gün Seri';

  @override
  String get profile_badge4Title => 'Usta Çevirmen';

  @override
  String get profile_badge4Sub => 'Seviye 20';

  @override
  String get profile_locked => 'KİLİTLİ';

  @override
  String get profile_disconnect => 'Bağlantıyı Kes';

  @override
  String get auth_err_enterName => 'Adını gir.';

  @override
  String get auth_err_invalidEmail => 'Geçerli bir e-posta adresi gir.';

  @override
  String get auth_err_passwordMin6 => 'Şifre en az 6 karakter olmalı.';

  @override
  String get auth_err_invalidCredentials => 'E-posta veya şifre yanlış.';

  @override
  String get auth_err_emailNotConfirmed =>
      'E-posta adresini doğrulaman gerekiyor.';

  @override
  String get auth_err_alreadyRegistered =>
      'Bu e-posta zaten kayıtlı. Giriş yapmayı dene.';

  @override
  String get auth_err_noInternet => 'İnternet bağlantısı yok.';

  @override
  String get auth_err_generic => 'Bir hata oluştu. Tekrar dene.';

  @override
  String get auth_subtitleLogin => 'İletişim Kanalını Başlat';

  @override
  String get auth_subtitleSignup => 'Dilbilim yolculuğuna başla.';

  @override
  String get auth_fullName => 'AD SOYAD';

  @override
  String get auth_nameHint => 'Adın';

  @override
  String get auth_emailLabel => 'E-POSTA';

  @override
  String get auth_commsChannel => 'İLETİŞİM KANALI';

  @override
  String get auth_securityCode => 'GÜVENLİK KODU';

  @override
  String get auth_accessKey => 'ERİŞİM ANAHTARI';

  @override
  String get auth_loginBtn => 'GİRİŞ YAP';

  @override
  String get auth_signupBtn => 'KAYDOL';

  @override
  String get auth_toggleToSignup => 'Henüz yörüngede değil misin? ';

  @override
  String get auth_toggleToLogin => 'Zaten yörüngede misin? ';

  @override
  String get auth_signUpShort => 'Kaydol';

  @override
  String get auth_signInShort => 'Giriş yap';

  @override
  String get auth_confirmTitle => 'Gelen kutunu aç.';

  @override
  String get auth_confirmBody =>
      'adresine bir doğrulama linki gönderdik. Linke tıkladıktan sonra giriş yapabilirsin.';

  @override
  String get auth_backToLogin => 'Giriş Ekranına Dön';

  @override
  String get cp_newMin6 => 'Yeni şifre en az 6 karakter olmalı.';

  @override
  String get cp_mismatch => 'Yeni şifreler eşleşmiyor.';

  @override
  String get cp_mustDiffer => 'Yeni şifre eskisinden farklı olmalı.';

  @override
  String get cp_currentWrong => 'Mevcut şifre yanlış.';

  @override
  String get cp_weak => 'Şifre çok zayıf, daha güçlü bir şifre seç.';

  @override
  String get cp_updateFailed => 'Şifre güncellenemedi. Tekrar dene.';

  @override
  String get cp_title => 'ŞİFRE DEĞİŞTİR';

  @override
  String get cp_heading => 'Erişim Anahtarını Değiştir';

  @override
  String get cp_subtitle =>
      'Güvenliğin için önce mevcut şifreni doğrulamamız gerekiyor.';

  @override
  String get cp_success => 'Şifren başarıyla güncellendi.';

  @override
  String get cp_current => 'MEVCUT ŞİFRE';

  @override
  String get cp_new => 'YENİ ŞİFRE';

  @override
  String get cp_min6Hint => 'En az 6 karakter';

  @override
  String get cp_newRepeat => 'YENİ ŞİFRE (TEKRAR)';

  @override
  String get cp_reenterHint => 'Yeniden gir';

  @override
  String get cp_updateBtn => 'ŞİFREYİ GÜNCELLE';

  @override
  String get fp_rateLimit =>
      'Çok fazla istek. Birkaç dakika sonra tekrar dene.';

  @override
  String get fp_title => 'Şifreni mi unuttun?';

  @override
  String get fp_subtitle =>
      'E-posta adresini gir, sana yeni bir şifre belirleyeceğin bir bağlantı gönderelim.';

  @override
  String get fp_sendBtn => 'BAĞLANTI GÖNDER';

  @override
  String get fp_sentTitle => 'Bağlantı yola çıktı.';

  @override
  String get fp_sentBody =>
      'adresine bir bağlantı gönderdik. Gelen kutunu (ve spam klasörünü) kontrol et — bağlantıya tıkladığında uygulama açılacak ve yeni şifreni belirleyebileceksin.';

  @override
  String get rp_mismatch => 'Şifreler eşleşmiyor.';

  @override
  String get rp_expired => 'Bağlantının süresi dolmuş. Yeniden talep et.';

  @override
  String get rp_title => 'Yeni Şifre Belirle';

  @override
  String get rp_subtitle =>
      'Bağlantı doğrulandı. Hesabın için yeni bir şifre seç.';

  @override
  String get rp_saveBtn => 'ŞİFREYİ KAYDET';

  @override
  String get rp_successTitle => 'Şifren güncellendi';

  @override
  String get rp_successBody => 'Yeni şifrenle giriş yapabilirsin.';

  @override
  String get rp_backBtn => 'GİRİŞ EKRANINA DÖN';

  @override
  String get del_confirmWord => 'SİL';

  @override
  String get del_exported => 'Verilerin dışa aktarıldı.';

  @override
  String get del_exportFailed => 'Veriler dışa aktarılamadı.';

  @override
  String get del_deleteFailed => 'Hesap silinemedi. Tekrar dene.';

  @override
  String get del_finalConfirm => 'Son Onay';

  @override
  String get del_finalWarning =>
      'Hesabını ve tüm verilerini kalıcı olarak silmek üzeresin. Bu işlem geri alınamaz.';

  @override
  String get del_deleteAccount => 'Hesabı Sil';

  @override
  String get del_title => 'HESABI SİL';

  @override
  String get del_downloadTitle => 'Verilerini İndir';

  @override
  String get del_downloadBody =>
      'Silmeden önce tüm verilerini (profil, kelimeler, pratik oturumları, mesajlar) JSON formatında indirip saklayabilirsin.';

  @override
  String get del_exportBtn => 'Verilerimi Dışa Aktar';

  @override
  String get del_deleteIntro =>
      'Bu işlem geri alınamaz. Hesabını sildiğinde aşağıdaki tüm veriler kalıcı olarak silinir:';

  @override
  String get del_bullet1 => 'Profil ve kullanıcı adın';

  @override
  String get del_bullet2 => 'Kelime hazinen ve tekrar geçmişin';

  @override
  String get del_bullet3 => 'Tüm pratik oturumların ve sohbet kayıtların';

  @override
  String get del_bullet4 => 'Kazandığın XP, seviye ve seri günler';

  @override
  String get del_understood => 'Bu işlemin geri alınamaz olduğunu anladım.';

  @override
  String del_typeToConfirm(String word) {
    return 'ONAYLAMAK İÇİN \"$word\" YAZ';
  }

  @override
  String get del_deleting => 'Siliniyor…';

  @override
  String get del_deletePermanent => 'HESABIMI KALICI OLARAK SİL';

  @override
  String onb_error(String error) {
    return 'Onboarding hatası: $error';
  }

  @override
  String get onb_start => 'Başlayalım';

  @override
  String get onb_continue => 'Devam';

  @override
  String get onb_welcomeTitle => 'VoiceLingo\'ya hoş geldin';

  @override
  String get onb_welcomeBody =>
      'Konuş. Gelişeceksin. Tekrarla.\nAI koçun her konuşmada yanında.';

  @override
  String get onb_permTitle => 'İki hızlı izin';

  @override
  String get onb_permSubtitle => 'Düzgün koçluk yapabilmemiz için gerekli.';

  @override
  String get onb_micTitle => 'Mikrofon';

  @override
  String get onb_micDesc => 'Konuşmanı duy, telaffuza geri bildirim ver.';

  @override
  String get onb_notifDesc =>
      'Streak\'ini canlı tutmak için nazik hatırlatmalar.';

  @override
  String get onb_allow => 'İzin ver';

  @override
  String get onb_goalTitle => 'Günlük hedefin';

  @override
  String get onb_goalSubtitle => 'Günde kaç dakika çalışmak istersin?';

  @override
  String get onb_minSuffix => 'dk';

  @override
  String get onb_motivTitle => 'Neden öğreniyorsun?';

  @override
  String get onb_motivSubtitle =>
      'Sana uygun senaryoları seçmemize yardım eder.';

  @override
  String get onb_motivExam => 'Sınav';

  @override
  String get onb_motivHobby => 'Hobi';

  @override
  String get onb_charSubtitle =>
      'Her koçun farklı sesi ve tarzı var. Ayarlardan istediğin zaman değiştirebilirsin.';

  @override
  String get placement_title => 'Seviye Belirleme';

  @override
  String get placement_result => 'Sonuç';

  @override
  String placement_correctCount(int correct) {
    return '$correct / 10 doğru';
  }

  @override
  String get conn_offlineBanner =>
      'Çevrimdışısın. İlerlemen bağlanınca senkronize olur.';

  @override
  String get levelup_title => 'SEVİYE ATLADIN!';

  @override
  String levelup_body(int level) {
    return 'Harika gidiyorsun! Yeni seviyeye ulaştın:\nSeviye $level';
  }

  @override
  String get levelup_continue => 'DEVAM ET';
}
