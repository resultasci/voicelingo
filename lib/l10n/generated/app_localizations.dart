import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('tr'),
    Locale('en')
  ];

  /// Uygulama adı, her zaman büyük 'V' ve 'L' ile yazılır.
  ///
  /// In tr, this message translates to:
  /// **'VoiceLingo'**
  String get appName;

  /// No description provided for @common_ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get common_ok;

  /// No description provided for @common_cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get common_delete;

  /// No description provided for @common_retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get common_retry;

  /// No description provided for @common_back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get common_done;

  /// No description provided for @common_loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor…'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get common_error;

  /// No description provided for @nav_dashboard.
  ///
  /// In tr, this message translates to:
  /// **'GENEL'**
  String get nav_dashboard;

  /// No description provided for @nav_words.
  ///
  /// In tr, this message translates to:
  /// **'KELİME'**
  String get nav_words;

  /// No description provided for @nav_practice.
  ///
  /// In tr, this message translates to:
  /// **'PRATİK'**
  String get nav_practice;

  /// No description provided for @nav_profile.
  ///
  /// In tr, this message translates to:
  /// **'PROFİL'**
  String get nav_profile;

  /// No description provided for @nav_settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get nav_settings;

  /// No description provided for @nav_scenarios.
  ///
  /// In tr, this message translates to:
  /// **'Senaryolar'**
  String get nav_scenarios;

  /// No description provided for @auth_signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get auth_signIn;

  /// No description provided for @auth_signUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ol'**
  String get auth_signUp;

  /// No description provided for @auth_signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get auth_signOut;

  /// No description provided for @auth_email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get auth_password;

  /// No description provided for @auth_username.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get auth_username;

  /// No description provided for @auth_confirmPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi doğrula'**
  String get auth_confirmPassword;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get auth_forgotPassword;

  /// No description provided for @auth_changePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre değiştir'**
  String get auth_changePassword;

  /// No description provided for @auth_resetPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırla'**
  String get auth_resetPassword;

  /// No description provided for @auth_validation_fillAll.
  ///
  /// In tr, this message translates to:
  /// **'Tüm alanları doldur'**
  String get auth_validation_fillAll;

  /// No description provided for @auth_validation_passwordMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get auth_validation_passwordMismatch;

  /// No description provided for @auth_error_sessionNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Oturum bulunamadı, lütfen tekrar giriş yap.'**
  String get auth_error_sessionNotFound;

  /// No description provided for @auth_error_sessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süren doldu, lütfen tekrar giriş yap.'**
  String get auth_error_sessionExpired;

  /// No description provided for @error_network.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı sorunu. İnternetini kontrol et.'**
  String get error_network;

  /// No description provided for @error_timeout.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zaman aşımına uğradı.'**
  String get error_timeout;

  /// No description provided for @error_unexpected.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu.'**
  String get error_unexpected;

  /// No description provided for @error_rateLimit.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kullanım limitine ulaştın. Yarın tekrar dene.'**
  String get error_rateLimit;

  /// No description provided for @error_audioTooLong.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı çok uzun. Daha kısa bir kayıt dene.'**
  String get error_audioTooLong;

  /// No description provided for @error_aiUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'AI servisi şu an cevap vermiyor.'**
  String get error_aiUnavailable;

  /// No description provided for @error_invalidJson.
  ///
  /// In tr, this message translates to:
  /// **'Servisten geçersiz cevap alındı.'**
  String get error_invalidJson;

  /// No description provided for @error_offline.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı moddasın.'**
  String get error_offline;

  /// No description provided for @error_audioInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Ses tanıma servisinden geçersiz cevap alındı.'**
  String get error_audioInvalid;

  /// No description provided for @error_evalInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme servisi geçersiz yanıt döndü.'**
  String get error_evalInvalid;

  /// No description provided for @error_serverInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen sunucu yanıtı.'**
  String get error_serverInvalid;

  /// No description provided for @settings_title.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings_title;

  /// No description provided for @settings_theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get settings_theme;

  /// No description provided for @settings_themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settings_themeDark;

  /// No description provided for @settings_themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settings_themeLight;

  /// No description provided for @settings_themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get settings_themeSystem;

  /// No description provided for @settings_language.
  ///
  /// In tr, this message translates to:
  /// **'Arayüz Dili'**
  String get settings_language;

  /// No description provided for @settings_languageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get settings_languageTurkish;

  /// No description provided for @settings_languageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get settings_languageEnglish;

  /// No description provided for @settings_ttsSpeed.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma Hızı'**
  String get settings_ttsSpeed;

  /// No description provided for @settings_ttsSpeedSlow.
  ///
  /// In tr, this message translates to:
  /// **'Yavaş'**
  String get settings_ttsSpeedSlow;

  /// No description provided for @settings_ttsSpeedNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get settings_ttsSpeedNormal;

  /// No description provided for @settings_ttsSpeedFast.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı'**
  String get settings_ttsSpeedFast;

  /// No description provided for @settings_notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settings_notifications;

  /// No description provided for @settings_reviewHour.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Hatırlatma Saati'**
  String get settings_reviewHour;

  /// No description provided for @settings_textScale.
  ///
  /// In tr, this message translates to:
  /// **'Yazı Büyüklüğü'**
  String get settings_textScale;

  /// No description provided for @settings_aiCharacter.
  ///
  /// In tr, this message translates to:
  /// **'AI Karakteri'**
  String get settings_aiCharacter;

  /// No description provided for @settings_account.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get settings_account;

  /// No description provided for @settings_about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get settings_about;

  /// No description provided for @settings_version.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get settings_version;

  /// No description provided for @profile_level.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get profile_level;

  /// No description provided for @profile_xp.
  ///
  /// In tr, this message translates to:
  /// **'XP'**
  String get profile_xp;

  /// No description provided for @profile_streak.
  ///
  /// In tr, this message translates to:
  /// **'Streak'**
  String get profile_streak;

  /// No description provided for @profile_streak_days.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Henüz streak yok} =1{1 gün} other{{count} gün}}'**
  String profile_streak_days(int count);

  /// No description provided for @profile_cefr.
  ///
  /// In tr, this message translates to:
  /// **'CEFR Seviyesi'**
  String get profile_cefr;

  /// No description provided for @words_addNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kelime'**
  String get words_addNew;

  /// No description provided for @words_review_due.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Bugün tekrar yok} =1{1 kelime tekrar bekliyor} other{{count} kelime tekrar bekliyor}}'**
  String words_review_due(int count);

  /// No description provided for @words_review_remember.
  ///
  /// In tr, this message translates to:
  /// **'Hatırladım'**
  String get words_review_remember;

  /// No description provided for @words_review_hard.
  ///
  /// In tr, this message translates to:
  /// **'Zorlandım'**
  String get words_review_hard;

  /// No description provided for @words_review_forgot.
  ///
  /// In tr, this message translates to:
  /// **'Unuttum'**
  String get words_review_forgot;

  /// No description provided for @words_duplicate.
  ///
  /// In tr, this message translates to:
  /// **'\"{word}\" zaten listende.'**
  String words_duplicate(String word);

  /// No description provided for @conversation_listening.
  ///
  /// In tr, this message translates to:
  /// **'Dinleniyor…'**
  String get conversation_listening;

  /// No description provided for @conversation_thinking.
  ///
  /// In tr, this message translates to:
  /// **'Düşünüyor…'**
  String get conversation_thinking;

  /// No description provided for @conversation_speaking.
  ///
  /// In tr, this message translates to:
  /// **'Konuşuyor…'**
  String get conversation_speaking;

  /// No description provided for @conversation_idle.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon hazır'**
  String get conversation_idle;

  /// No description provided for @conversation_handsfree.
  ///
  /// In tr, this message translates to:
  /// **'Eller serbest mod'**
  String get conversation_handsfree;

  /// No description provided for @conversation_pushToTalk.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmak için basılı tut'**
  String get conversation_pushToTalk;

  /// No description provided for @conversation_micPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni gerekli. Ayarlardan açabilirsin.'**
  String get conversation_micPermissionDenied;

  /// No description provided for @notification_reviewReminder_title.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma Zamanı!'**
  String get notification_reviewReminder_title;

  /// No description provided for @notification_reviewReminder_body.
  ///
  /// In tr, this message translates to:
  /// **'\"{word}\" kelimesinin tekrar zamanı geldi!'**
  String notification_reviewReminder_body(String word);

  /// No description provided for @notification_dailyDigest_title.
  ///
  /// In tr, this message translates to:
  /// **'Günlük tekrar'**
  String get notification_dailyDigest_title;

  /// No description provided for @notification_dailyDigest_body.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Bugün tekrarlanacak kelimen yok} =1{Bugün 1 kelime tekrar bekliyor} other{Bugün {count} kelime tekrar bekliyor}}'**
  String notification_dailyDigest_body(int count);

  /// No description provided for @boot_envMissing_title.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırma eksik'**
  String get boot_envMissing_title;

  /// No description provided for @boot_envMissing_description.
  ///
  /// In tr, this message translates to:
  /// **'{key} tanımlı değil veya boş — .env dosyanızı kontrol edin.'**
  String boot_envMissing_description(String key);

  /// No description provided for @boot_dotenvFailed_title.
  ///
  /// In tr, this message translates to:
  /// **'.env yüklenemedi'**
  String get boot_dotenvFailed_title;

  /// No description provided for @boot_dotenvFailed_description.
  ///
  /// In tr, this message translates to:
  /// **'.env dosyası proje kökünde bulunmuyor veya okunamadı.'**
  String get boot_dotenvFailed_description;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppL10nEn();
    case 'tr': return AppL10nTr();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
