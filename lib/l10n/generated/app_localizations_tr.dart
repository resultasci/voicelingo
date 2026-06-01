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
  String get auth_error_sessionNotFound => 'Oturum bulunamadı, lütfen tekrar giriş yap.';

  @override
  String get auth_error_sessionExpired => 'Oturum süren doldu, lütfen tekrar giriş yap.';

  @override
  String get error_network => 'Bağlantı sorunu. İnternetini kontrol et.';

  @override
  String get error_timeout => 'Bağlantı zaman aşımına uğradı.';

  @override
  String get error_unexpected => 'Beklenmeyen bir hata oluştu.';

  @override
  String get error_rateLimit => 'Günlük kullanım limitine ulaştın. Yarın tekrar dene.';

  @override
  String get error_audioTooLong => 'Ses kaydı çok uzun. Daha kısa bir kayıt dene.';

  @override
  String get error_aiUnavailable => 'AI servisi şu an cevap vermiyor.';

  @override
  String get error_invalidJson => 'Servisten geçersiz cevap alındı.';

  @override
  String get error_offline => 'Çevrimdışı moddasın.';

  @override
  String get error_audioInvalid => 'Ses tanıma servisinden geçersiz cevap alındı.';

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
  String get conversation_micPermissionDenied => 'Mikrofon izni gerekli. Ayarlardan açabilirsin.';

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
  String get boot_dotenvFailed_description => '.env dosyası proje kökünde bulunmuyor veya okunamadı.';
}
