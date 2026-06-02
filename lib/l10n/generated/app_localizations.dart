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

  /// No description provided for @dashboard_profileLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi.'**
  String get dashboard_profileLoadError;

  /// No description provided for @dashboard_defaultName.
  ///
  /// In tr, this message translates to:
  /// **'Kaptan'**
  String get dashboard_defaultName;

  /// No description provided for @dashboard_greeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba, {name}'**
  String dashboard_greeting(String name);

  /// No description provided for @dashboard_greetingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük galaktik hedeflerine hazır mısın?'**
  String get dashboard_greetingSubtitle;

  /// No description provided for @dashboard_statStreak.
  ///
  /// In tr, this message translates to:
  /// **'SERİ'**
  String get dashboard_statStreak;

  /// No description provided for @dashboard_streakValue.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 Gün} other{{count} Gün}}'**
  String dashboard_streakValue(int count);

  /// No description provided for @dashboard_aiModule.
  ///
  /// In tr, this message translates to:
  /// **'YAPAY ZEKA MODÜLÜ'**
  String get dashboard_aiModule;

  /// No description provided for @dashboard_aiTitle.
  ///
  /// In tr, this message translates to:
  /// **'Derin Uzay Pratiği'**
  String get dashboard_aiTitle;

  /// No description provided for @dashboard_aiSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kişiselleştirilmiş AI asistanın ile günlük konuşma simülasyonunu başlat.'**
  String get dashboard_aiSubtitle;

  /// No description provided for @dashboard_aiStart.
  ///
  /// In tr, this message translates to:
  /// **'Simülasyonu Başlat'**
  String get dashboard_aiStart;

  /// No description provided for @dashboard_dailyGoals.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Görevler'**
  String get dashboard_dailyGoals;

  /// No description provided for @dashboard_goalLanguage.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get dashboard_goalLanguage;

  /// No description provided for @dashboard_goalLoading.
  ///
  /// In tr, this message translates to:
  /// **'Kütüphane Yükleniyor'**
  String get dashboard_goalLoading;

  /// No description provided for @dashboard_goalAllCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Kelimeler Güncel'**
  String get dashboard_goalAllCurrent;

  /// No description provided for @dashboard_percentValue.
  ///
  /// In tr, this message translates to:
  /// **'%{percent}'**
  String dashboard_percentValue(int percent);

  /// No description provided for @settings_emailAddress.
  ///
  /// In tr, this message translates to:
  /// **'E-Posta Adresi'**
  String get settings_emailAddress;

  /// No description provided for @settings_downloadDeleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Veri İndir / Hesabı Sil'**
  String get settings_downloadDeleteAccount;

  /// No description provided for @settings_dailyReviewReminder.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Tekrar Hatırlatması'**
  String get settings_dailyReviewReminder;

  /// No description provided for @settings_reminderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Vadesi gelen kelimeler için günde bir bildirim'**
  String get settings_reminderSubtitle;

  /// No description provided for @settings_reminderTime.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma Saati'**
  String get settings_reminderTime;

  /// No description provided for @settings_onceADay.
  ///
  /// In tr, this message translates to:
  /// **'GÜNDE BİR KEZ'**
  String get settings_onceADay;

  /// No description provided for @settings_comingSoon.
  ///
  /// In tr, this message translates to:
  /// **'YAKINDA'**
  String get settings_comingSoon;

  /// No description provided for @settings_systemUpdates.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Güncellemeleri'**
  String get settings_systemUpdates;

  /// No description provided for @settings_systemUpdatesSub.
  ///
  /// In tr, this message translates to:
  /// **'Yeni özellikler — yakında'**
  String get settings_systemUpdatesSub;

  /// No description provided for @settings_systemPreferences.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Tercihleri'**
  String get settings_systemPreferences;

  /// No description provided for @settings_visualTheme.
  ///
  /// In tr, this message translates to:
  /// **'Görsel Tema'**
  String get settings_visualTheme;

  /// No description provided for @settings_themeObsidian.
  ///
  /// In tr, this message translates to:
  /// **'Obsidian Void (Karanlık)'**
  String get settings_themeObsidian;

  /// No description provided for @settings_themeSolar.
  ///
  /// In tr, this message translates to:
  /// **'Solar Flare (Aydınlık)'**
  String get settings_themeSolar;

  /// No description provided for @settings_themeSystemDefault.
  ///
  /// In tr, this message translates to:
  /// **'Sistem ile uyumlu'**
  String get settings_themeSystemDefault;

  /// No description provided for @settings_aiCoach.
  ///
  /// In tr, this message translates to:
  /// **'AI Koç'**
  String get settings_aiCoach;

  /// No description provided for @settings_progress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get settings_progress;

  /// No description provided for @settings_progressStats.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme & İstatistik'**
  String get settings_progressStats;

  /// No description provided for @settings_courseTree.
  ///
  /// In tr, this message translates to:
  /// **'Ders Yolu'**
  String get settings_courseTree;

  /// No description provided for @settings_courseTreeFull.
  ///
  /// In tr, this message translates to:
  /// **'Ders Yolu (A1-C2)'**
  String get settings_courseTreeFull;

  /// No description provided for @settings_grammar.
  ///
  /// In tr, this message translates to:
  /// **'Gramer'**
  String get settings_grammar;

  /// No description provided for @settings_badges.
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get settings_badges;

  /// No description provided for @settings_disconnect.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get settings_disconnect;

  /// No description provided for @settings_signOutConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Çıkmak istediğine emin misin?'**
  String get settings_signOutConfirm;

  /// No description provided for @common_saving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor…'**
  String get common_saving;

  /// No description provided for @common_add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get common_add;

  /// No description provided for @words_filterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get words_filterAll;

  /// No description provided for @words_filterDue.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Bekleyen'**
  String get words_filterDue;

  /// No description provided for @words_filterLearned.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenilen'**
  String get words_filterLearned;

  /// No description provided for @words_filterNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get words_filterNew;

  /// No description provided for @words_reviewSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar kaydedilemedi'**
  String get words_reviewSaveError;

  /// No description provided for @words_addToLibrary.
  ///
  /// In tr, this message translates to:
  /// **'Kütüphaneye ekle'**
  String get words_addToLibrary;

  /// No description provided for @words_labelEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İNGİLİZCE'**
  String get words_labelEnglish;

  /// No description provided for @words_labelTurkish.
  ///
  /// In tr, this message translates to:
  /// **'TÜRKÇE'**
  String get words_labelTurkish;

  /// No description provided for @words_hintWord.
  ///
  /// In tr, this message translates to:
  /// **'word'**
  String get words_hintWord;

  /// No description provided for @words_hintTranslation.
  ///
  /// In tr, this message translates to:
  /// **'kelime'**
  String get words_hintTranslation;

  /// No description provided for @words_alreadyInLibrary.
  ///
  /// In tr, this message translates to:
  /// **'Bu kelime zaten kütüphanende var.'**
  String get words_alreadyInLibrary;

  /// No description provided for @words_addFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kelime eklenemedi'**
  String get words_addFailed;

  /// No description provided for @words_libraryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kelime Kütüphanesi'**
  String get words_libraryTitle;

  /// No description provided for @words_librarySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Bilişsel sözlüğün 1 kelimeye genişledi.} other{Bilişsel sözlüğün {count} kelimeye genişledi.}}'**
  String words_librarySubtitle(int count);

  /// No description provided for @words_searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Kelime veya çeviri ara…'**
  String get words_searchHint;

  /// No description provided for @words_reviewToday.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN TEKRAR'**
  String get words_reviewToday;

  /// No description provided for @words_wordsReady.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 kelime hazır} other{{count} kelime hazır}}'**
  String words_wordsReady(int count);

  /// No description provided for @words_statusNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get words_statusNew;

  /// No description provided for @words_statusDue.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get words_statusDue;

  /// No description provided for @words_statusLearned.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenildi'**
  String get words_statusLearned;

  /// No description provided for @words_statusInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Süreçte'**
  String get words_statusInProgress;

  /// No description provided for @words_intervalNew.
  ///
  /// In tr, this message translates to:
  /// **'YENİ'**
  String get words_intervalNew;

  /// No description provided for @words_unitDay.
  ///
  /// In tr, this message translates to:
  /// **'G'**
  String get words_unitDay;

  /// No description provided for @words_unitWeek.
  ///
  /// In tr, this message translates to:
  /// **'H'**
  String get words_unitWeek;

  /// No description provided for @words_unitMonth.
  ///
  /// In tr, this message translates to:
  /// **'A'**
  String get words_unitMonth;

  /// No description provided for @words_unitYear.
  ///
  /// In tr, this message translates to:
  /// **'Y'**
  String get words_unitYear;

  /// No description provided for @words_deleteWord.
  ///
  /// In tr, this message translates to:
  /// **'Kelimeyi sil'**
  String get words_deleteWord;

  /// No description provided for @words_pronounce.
  ///
  /// In tr, this message translates to:
  /// **'Telaffuz et'**
  String get words_pronounce;

  /// No description provided for @words_emptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kütüphanen boş'**
  String get words_emptyTitle;

  /// No description provided for @words_emptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Eklediğin her kelime SM-2 algoritması ile bilimsel aralıklarla karşına çıkar.'**
  String get words_emptyBody;

  /// No description provided for @words_addFirst.
  ///
  /// In tr, this message translates to:
  /// **'İlk kelimeni ekle'**
  String get words_addFirst;

  /// No description provided for @words_filterEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtre boş'**
  String get words_filterEmpty;

  /// No description provided for @words_noResultsFor.
  ///
  /// In tr, this message translates to:
  /// **'\"{query}\" için sonuç yok'**
  String words_noResultsFor(String query);

  /// No description provided for @words_gradeGreat.
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get words_gradeGreat;

  /// No description provided for @words_gradeGood.
  ///
  /// In tr, this message translates to:
  /// **'İyi iş!'**
  String get words_gradeGood;

  /// No description provided for @words_gradeKeepGoing.
  ///
  /// In tr, this message translates to:
  /// **'Devam et!'**
  String get words_gradeKeepGoing;

  /// No description provided for @words_reviewComplete.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Tamamlandı'**
  String get words_reviewComplete;

  /// No description provided for @words_statCorrect.
  ///
  /// In tr, this message translates to:
  /// **'DOĞRU'**
  String get words_statCorrect;

  /// No description provided for @words_statTotal.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM'**
  String get words_statTotal;

  /// No description provided for @words_statSuccess.
  ///
  /// In tr, this message translates to:
  /// **'BAŞARI'**
  String get words_statSuccess;

  /// No description provided for @words_backToLibrary.
  ///
  /// In tr, this message translates to:
  /// **'Kütüphaneye Dön'**
  String get words_backToLibrary;

  /// No description provided for @words_translate.
  ///
  /// In tr, this message translates to:
  /// **'Çevir'**
  String get words_translate;

  /// No description provided for @words_tapToReveal.
  ///
  /// In tr, this message translates to:
  /// **'DOKUNARAK GÖSTER'**
  String get words_tapToReveal;

  /// No description provided for @words_howWell.
  ///
  /// In tr, this message translates to:
  /// **'NE KADAR BİLDİN?'**
  String get words_howWell;

  /// No description provided for @words_rateForgot.
  ///
  /// In tr, this message translates to:
  /// **'Bilmedim'**
  String get words_rateForgot;

  /// No description provided for @words_rateHard.
  ///
  /// In tr, this message translates to:
  /// **'Zordu'**
  String get words_rateHard;

  /// No description provided for @words_rateEasy.
  ///
  /// In tr, this message translates to:
  /// **'Kolaydı'**
  String get words_rateEasy;

  /// No description provided for @wordDetail_loadError.
  ///
  /// In tr, this message translates to:
  /// **'Ek detaylar yüklenemedi.'**
  String get wordDetail_loadError;

  /// No description provided for @wordDetail_noCache.
  ///
  /// In tr, this message translates to:
  /// **'Cache\'de ek detay yok. Sonra tekrar dene.'**
  String get wordDetail_noCache;

  /// No description provided for @wordDetail_ipaCopied.
  ///
  /// In tr, this message translates to:
  /// **'IPA kopyalandı'**
  String get wordDetail_ipaCopied;

  /// No description provided for @wordDetail_examples.
  ///
  /// In tr, this message translates to:
  /// **'Örnekler'**
  String get wordDetail_examples;

  /// No description provided for @wordDetail_synonyms.
  ///
  /// In tr, this message translates to:
  /// **'Eş anlamlılar'**
  String get wordDetail_synonyms;

  /// No description provided for @wordDetail_antonyms.
  ///
  /// In tr, this message translates to:
  /// **'Zıt anlamlılar'**
  String get wordDetail_antonyms;

  /// No description provided for @wordDetail_collocations.
  ///
  /// In tr, this message translates to:
  /// **'Birliktelikler'**
  String get wordDetail_collocations;

  /// No description provided for @wordDetail_etymology.
  ///
  /// In tr, this message translates to:
  /// **'Etimoloji'**
  String get wordDetail_etymology;

  /// No description provided for @flashcard_title.
  ///
  /// In tr, this message translates to:
  /// **'Kelime Pratiği'**
  String get flashcard_title;

  /// No description provided for @flashcard_cardOf.
  ///
  /// In tr, this message translates to:
  /// **'KART {current} / {total}'**
  String flashcard_cardOf(int current, int total);

  /// No description provided for @flashcard_revealHint.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi görmek için \"Cevabı Göster\"e dokun'**
  String get flashcard_revealHint;

  /// No description provided for @flashcard_showAnswer.
  ///
  /// In tr, this message translates to:
  /// **'CEVABI GÖSTER'**
  String get flashcard_showAnswer;

  /// No description provided for @flashcard_congrats.
  ///
  /// In tr, this message translates to:
  /// **'TEBRİKLER!'**
  String get flashcard_congrats;

  /// No description provided for @flashcard_completeBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünlük kelime tekrarını bitirdin. Kelimeler yarın senin için tekrar planlanacak.'**
  String get flashcard_completeBody;

  /// No description provided for @flashcard_backHome.
  ///
  /// In tr, this message translates to:
  /// **'ANA SAYFAYA DÖN'**
  String get flashcard_backHome;

  /// No description provided for @conv_statusStarting.
  ///
  /// In tr, this message translates to:
  /// **'BAŞLANIYOR'**
  String get conv_statusStarting;

  /// No description provided for @conv_statusReady.
  ///
  /// In tr, this message translates to:
  /// **'HAZIR'**
  String get conv_statusReady;

  /// No description provided for @conv_statusListening.
  ///
  /// In tr, this message translates to:
  /// **'DİNLİYOR'**
  String get conv_statusListening;

  /// No description provided for @conv_statusThinking.
  ///
  /// In tr, this message translates to:
  /// **'DÜŞÜNÜYOR'**
  String get conv_statusThinking;

  /// No description provided for @conv_statusSpeaking.
  ///
  /// In tr, this message translates to:
  /// **'AI KONUŞUYOR'**
  String get conv_statusSpeaking;

  /// No description provided for @conv_statusError.
  ///
  /// In tr, this message translates to:
  /// **'HATA'**
  String get conv_statusError;

  /// No description provided for @conv_errTts.
  ///
  /// In tr, this message translates to:
  /// **'TTS hatası: {msg}'**
  String conv_errTts(String msg);

  /// No description provided for @conv_errTtsInit.
  ///
  /// In tr, this message translates to:
  /// **'TTS başlatılamadı.'**
  String get conv_errTtsInit;

  /// No description provided for @conv_errMicPermission.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni gerekli.'**
  String get conv_errMicPermission;

  /// No description provided for @conv_errMicOpen.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon açılamadı: {error}'**
  String conv_errMicOpen(String error);

  /// No description provided for @conv_errRecordFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı başarısız.'**
  String get conv_errRecordFailed;

  /// No description provided for @conv_errAudioProcess.
  ///
  /// In tr, this message translates to:
  /// **'Ses işleme hatası: {error}'**
  String conv_errAudioProcess(String error);

  /// No description provided for @conv_errNoSpeech.
  ///
  /// In tr, this message translates to:
  /// **'Ses tanınamadı.'**
  String get conv_errNoSpeech;

  /// No description provided for @conv_errGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String conv_errGeneric(String error);

  /// No description provided for @conv_errSpeak.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma hatası: {error}'**
  String conv_errSpeak(String error);

  /// No description provided for @conv_errUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen hata.'**
  String get conv_errUnknown;

  /// No description provided for @conv_greeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba! İngilizceni pratik yapmak için hazırım. Konuş!'**
  String get conv_greeting;

  /// No description provided for @conv_replyFailed.
  ///
  /// In tr, this message translates to:
  /// **'Cevap alınamadı. Tekrar denemek için aşağıdaki butona dokun.'**
  String get conv_replyFailed;

  /// No description provided for @conv_aiNoResponse.
  ///
  /// In tr, this message translates to:
  /// **'AI yanıt vermedi: {error}'**
  String conv_aiNoResponse(String error);

  /// No description provided for @conv_practiceMode.
  ///
  /// In tr, this message translates to:
  /// **'Pratik Modu'**
  String get conv_practiceMode;

  /// No description provided for @conv_handsFreeOnTip.
  ///
  /// In tr, this message translates to:
  /// **'Eller serbest açık — AI bittikten sonra otomatik dinler'**
  String get conv_handsFreeOnTip;

  /// No description provided for @conv_handsFreeOffTip.
  ///
  /// In tr, this message translates to:
  /// **'Eller serbest kapalı — mikrofona basman gerekir'**
  String get conv_handsFreeOffTip;

  /// No description provided for @conv_pickScenario.
  ///
  /// In tr, this message translates to:
  /// **'Senaryo seç'**
  String get conv_pickScenario;

  /// No description provided for @conv_newChat.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Sohbet'**
  String get conv_newChat;

  /// No description provided for @conv_chatHistory.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet geçmişi'**
  String get conv_chatHistory;

  /// No description provided for @conv_preparing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor…'**
  String get conv_preparing;

  /// No description provided for @conv_aiPreparing.
  ///
  /// In tr, this message translates to:
  /// **'AI yanıt hazırlanıyor…'**
  String get conv_aiPreparing;

  /// No description provided for @conv_emptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofona dokun, yaz ya da bir senaryo seç.'**
  String get conv_emptyHint;

  /// No description provided for @conv_aiPracticeMode.
  ///
  /// In tr, this message translates to:
  /// **'AI Pratik Modu'**
  String get conv_aiPracticeMode;

  /// No description provided for @conv_readyScenarios.
  ///
  /// In tr, this message translates to:
  /// **'HAZIR SENARYOLAR'**
  String get conv_readyScenarios;

  /// No description provided for @conv_seeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get conv_seeAll;

  /// No description provided for @conv_inputHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesajını yaz veya konuş…'**
  String get conv_inputHint;

  /// No description provided for @conv_sendMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesajı gönder'**
  String get conv_sendMessage;

  /// No description provided for @conv_stopRecording.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı durdur'**
  String get conv_stopRecording;

  /// No description provided for @conv_startRecording.
  ///
  /// In tr, this message translates to:
  /// **'Kayda başla'**
  String get conv_startRecording;

  /// No description provided for @conv_tryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dene'**
  String get conv_tryAgain;

  /// No description provided for @conv_restart.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Başla'**
  String get conv_restart;

  /// No description provided for @conv_feedbackGreat.
  ///
  /// In tr, this message translates to:
  /// **'✅ Harika!'**
  String get conv_feedbackGreat;

  /// No description provided for @conv_feedbackMoreNatural.
  ///
  /// In tr, this message translates to:
  /// **'💡 Daha doğal: {suggestion}'**
  String conv_feedbackMoreNatural(String suggestion);

  /// No description provided for @conv_evalSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma değerlendirmesi: {label}'**
  String conv_evalSemantics(String label);

  /// No description provided for @conv_score.
  ///
  /// In tr, this message translates to:
  /// **'PUAN: {score}/100'**
  String conv_score(int score);

  /// No description provided for @conv_errorsLabel.
  ///
  /// In tr, this message translates to:
  /// **'HATALAR'**
  String get conv_errorsLabel;

  /// No description provided for @convHist_title.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet Geçmişi'**
  String get convHist_title;

  /// No description provided for @convHist_freeChat.
  ///
  /// In tr, this message translates to:
  /// **'Serbest sohbet'**
  String get convHist_freeChat;

  /// No description provided for @convHist_empty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kaydedilmiş bir sohbet yok.'**
  String get convHist_empty;

  /// No description provided for @convView_title.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get convView_title;

  /// No description provided for @convView_score.
  ///
  /// In tr, this message translates to:
  /// **'Puan: {score}'**
  String convView_score(int score);

  /// No description provided for @charPicker_title.
  ///
  /// In tr, this message translates to:
  /// **'Koçunu seç'**
  String get charPicker_title;

  /// No description provided for @charPicker_start.
  ///
  /// In tr, this message translates to:
  /// **'Bu koçla başla'**
  String get charPicker_start;

  /// No description provided for @charPicker_listen.
  ///
  /// In tr, this message translates to:
  /// **'Sesini dinle'**
  String get charPicker_listen;

  /// No description provided for @scen_createWithAi.
  ///
  /// In tr, this message translates to:
  /// **'AI ile yarat'**
  String get scen_createWithAi;

  /// No description provided for @scen_allScenarios.
  ///
  /// In tr, this message translates to:
  /// **'Tüm senaryolar'**
  String get scen_allScenarios;

  /// No description provided for @scen_free.
  ///
  /// In tr, this message translates to:
  /// **'Serbest'**
  String get scen_free;

  /// No description provided for @scen_newScenario.
  ///
  /// In tr, this message translates to:
  /// **'Yeni senaryo'**
  String get scen_newScenario;

  /// No description provided for @scen_create.
  ///
  /// In tr, this message translates to:
  /// **'Yarat'**
  String get scen_create;

  /// No description provided for @scen_empty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz senaryo yok. Yarat butonuna bas.'**
  String get scen_empty;

  /// No description provided for @scen_yours.
  ///
  /// In tr, this message translates to:
  /// **'Senin yarattıkların'**
  String get scen_yours;

  /// No description provided for @scen_builtIn.
  ///
  /// In tr, this message translates to:
  /// **'Hazır senaryolar'**
  String get scen_builtIn;

  /// No description provided for @scen_turnsCount.
  ///
  /// In tr, this message translates to:
  /// **'~{count} tur'**
  String scen_turnsCount(int count);

  /// No description provided for @scen_createTitle.
  ///
  /// In tr, this message translates to:
  /// **'Senaryo yarat'**
  String get scen_createTitle;

  /// No description provided for @scen_describeScene.
  ///
  /// In tr, this message translates to:
  /// **'Bir sahne tarif et'**
  String get scen_describeScene;

  /// No description provided for @scen_descHint.
  ///
  /// In tr, this message translates to:
  /// **'ör: \"Berberde saç kesimi\"'**
  String get scen_descHint;

  /// No description provided for @scen_category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get scen_category;

  /// No description provided for @scen_difficulty.
  ///
  /// In tr, this message translates to:
  /// **'Zorluk'**
  String get scen_difficulty;

  /// No description provided for @scen_generate.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get scen_generate;

  /// No description provided for @scen_regenerate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden üret'**
  String get scen_regenerate;

  /// No description provided for @scen_saveStart.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet & başla'**
  String get scen_saveStart;

  /// No description provided for @scen_catDaily.
  ///
  /// In tr, this message translates to:
  /// **'Gündelik'**
  String get scen_catDaily;

  /// No description provided for @scen_catWork.
  ///
  /// In tr, this message translates to:
  /// **'İş'**
  String get scen_catWork;

  /// No description provided for @scen_catTravel.
  ///
  /// In tr, this message translates to:
  /// **'Seyahat'**
  String get scen_catTravel;

  /// No description provided for @scen_catHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get scen_catHealth;

  /// No description provided for @scen_catEducation.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim'**
  String get scen_catEducation;

  /// No description provided for @scen_catOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get scen_catOther;

  /// No description provided for @scen_aiPlays.
  ///
  /// In tr, this message translates to:
  /// **'AI rolü'**
  String get scen_aiPlays;

  /// No description provided for @scen_youPlay.
  ///
  /// In tr, this message translates to:
  /// **'Senin rolün'**
  String get scen_youPlay;

  /// No description provided for @scen_startsWith.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get scen_startsWith;

  /// No description provided for @scen_goals.
  ///
  /// In tr, this message translates to:
  /// **'Hedefler'**
  String get scen_goals;

  /// No description provided for @common_finish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get common_finish;

  /// No description provided for @grammar_level.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get grammar_level;

  /// No description provided for @grammar_emptyTopics.
  ///
  /// In tr, this message translates to:
  /// **'Henüz gramer konusu yok. Veritabanı yenilemesi (migration) uygulandı mı kontrol et.'**
  String get grammar_emptyTopics;

  /// No description provided for @grammar_bestScore.
  ///
  /// In tr, this message translates to:
  /// **'En iyi skor'**
  String get grammar_bestScore;

  /// No description provided for @topic_tabLesson.
  ///
  /// In tr, this message translates to:
  /// **'Konu'**
  String get topic_tabLesson;

  /// No description provided for @topic_noDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama yok.'**
  String get topic_noDescription;

  /// No description provided for @topic_noExamples.
  ///
  /// In tr, this message translates to:
  /// **'Henüz örnek yok.'**
  String get topic_noExamples;

  /// No description provided for @topic_noQuiz.
  ///
  /// In tr, this message translates to:
  /// **'Henüz quiz yok.'**
  String get topic_noQuiz;

  /// No description provided for @topic_greatJob.
  ///
  /// In tr, this message translates to:
  /// **'Harikasın!'**
  String get topic_greatJob;

  /// No description provided for @quiz_question.
  ///
  /// In tr, this message translates to:
  /// **'Soru'**
  String get quiz_question;

  /// No description provided for @quiz_typeAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Cevabını yaz'**
  String get quiz_typeAnswer;

  /// No description provided for @quiz_retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get quiz_retry;

  /// No description provided for @lesson_courseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ders Yolu'**
  String get lesson_courseTitle;

  /// No description provided for @lesson_emptyCourse.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kurs yok. Veritabanında derslerin kurulu olduğundan emin ol.'**
  String get lesson_emptyCourse;

  /// No description provided for @lesson_noUnits.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ünite yok.'**
  String get lesson_noUnits;

  /// No description provided for @lesson_englishCourse.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce Kursu'**
  String get lesson_englishCourse;

  /// No description provided for @lesson_lessonsSuffix.
  ///
  /// In tr, this message translates to:
  /// **'ders'**
  String get lesson_lessonsSuffix;

  /// No description provided for @lesson_customScenarioTitle.
  ///
  /// In tr, this message translates to:
  /// **'Özel Senaryo Oluştur'**
  String get lesson_customScenarioTitle;

  /// No description provided for @lesson_customScenarioBody.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zeka ile dilediğin konuda pratik yap.'**
  String get lesson_customScenarioBody;

  /// No description provided for @lesson_typeVocab.
  ///
  /// In tr, this message translates to:
  /// **'Kelime'**
  String get lesson_typeVocab;

  /// No description provided for @lesson_typeSpeaking.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma'**
  String get lesson_typeSpeaking;

  /// No description provided for @lesson_typeListening.
  ///
  /// In tr, this message translates to:
  /// **'Dinleme'**
  String get lesson_typeListening;

  /// No description provided for @lesson_grammarBridge.
  ///
  /// In tr, this message translates to:
  /// **'Bu ders, ilgili gramer konusunu açar. Oradaki quiz\'i bitirince bu ders de tamamlanır.'**
  String get lesson_grammarBridge;

  /// No description provided for @lesson_convBridge.
  ///
  /// In tr, this message translates to:
  /// **'İlgili senaryoyu konuş. Minimum tur sayısı bu ders için sayılır.'**
  String get lesson_convBridge;

  /// No description provided for @lesson_listenBridge.
  ///
  /// In tr, this message translates to:
  /// **'Dinleme egzersizleri yakında. Şimdilik tamamlanmış sayılıyor.'**
  String get lesson_listenBridge;

  /// No description provided for @lesson_openGrammar.
  ///
  /// In tr, this message translates to:
  /// **'Grameri Aç'**
  String get lesson_openGrammar;

  /// No description provided for @lesson_startConv.
  ///
  /// In tr, this message translates to:
  /// **'Sohbete Başla'**
  String get lesson_startConv;

  /// No description provided for @lesson_markComplete.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı işaretle'**
  String get lesson_markComplete;

  /// No description provided for @lesson_noVocab.
  ///
  /// In tr, this message translates to:
  /// **'Bu derste kelime yok.'**
  String get lesson_noVocab;

  /// No description provided for @lesson_tapToFlip.
  ///
  /// In tr, this message translates to:
  /// **'Çevirmek için dokun'**
  String get lesson_tapToFlip;

  /// No description provided for @lesson_practiceAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get lesson_practiceAgain;

  /// No description provided for @lesson_iKnowIt.
  ///
  /// In tr, this message translates to:
  /// **'Biliyorum'**
  String get lesson_iKnowIt;

  /// No description provided for @lesson_noQuizQuestions.
  ///
  /// In tr, this message translates to:
  /// **'Quiz sorusu yok.'**
  String get lesson_noQuizQuestions;

  /// No description provided for @lesson_perfect.
  ///
  /// In tr, this message translates to:
  /// **'Mükemmel!'**
  String get lesson_perfect;

  /// No description provided for @lesson_great.
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get lesson_great;

  /// No description provided for @lesson_keepGoing.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get lesson_keepGoing;

  /// No description provided for @lesson_errorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get lesson_errorTitle;

  /// No description provided for @lesson_scoreLabel.
  ///
  /// In tr, this message translates to:
  /// **'Skor: {score}'**
  String lesson_scoreLabel(int score);

  /// No description provided for @badge_unlocked.
  ///
  /// In tr, this message translates to:
  /// **'Rozet kazandın!'**
  String get badge_unlocked;

  /// No description provided for @badge_awesome.
  ///
  /// In tr, this message translates to:
  /// **'Harika'**
  String get badge_awesome;

  /// No description provided for @progress_last90.
  ///
  /// In tr, this message translates to:
  /// **'Son 90 gün'**
  String get progress_last90;

  /// No description provided for @progress_mastery.
  ///
  /// In tr, this message translates to:
  /// **'Ustalaşma'**
  String get progress_mastery;

  /// No description provided for @progress_noData.
  ///
  /// In tr, this message translates to:
  /// **'Henüz veri yok.'**
  String get progress_noData;

  /// No description provided for @progress_words.
  ///
  /// In tr, this message translates to:
  /// **'Kelimeler'**
  String get progress_words;

  /// No description provided for @progress_lessons.
  ///
  /// In tr, this message translates to:
  /// **'Dersler'**
  String get progress_lessons;

  /// No description provided for @progress_topMistakes.
  ///
  /// In tr, this message translates to:
  /// **'En sık hatalar (30 gün)'**
  String get progress_topMistakes;

  /// No description provided for @progress_noMistakes.
  ///
  /// In tr, this message translates to:
  /// **'Henüz hata kaydı yok — pratik yapmaya devam!'**
  String get progress_noMistakes;

  /// No description provided for @heatmap_less.
  ///
  /// In tr, this message translates to:
  /// **'Az'**
  String get heatmap_less;

  /// No description provided for @heatmap_more.
  ///
  /// In tr, this message translates to:
  /// **'Çok'**
  String get heatmap_more;

  /// No description provided for @profile_defaultName.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get profile_defaultName;

  /// No description provided for @profile_signOutWarning.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar giriş yapana kadar pratik kaydedilemez.'**
  String get profile_signOutWarning;

  /// No description provided for @profile_levelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level} • Galaktik Dilbilimci'**
  String profile_levelTitle(int level);

  /// No description provided for @profile_dailyStreak.
  ///
  /// In tr, this message translates to:
  /// **'GÜNLÜK SERİ'**
  String get profile_dailyStreak;

  /// No description provided for @profile_fluency.
  ///
  /// In tr, this message translates to:
  /// **'AKICILIK'**
  String get profile_fluency;

  /// No description provided for @profile_fluencyTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Akıcılık = doğru tekrar oranı × 50 + seri (≤30g) × 30 + XP (≤2000) × 20'**
  String get profile_fluencyTooltip;

  /// No description provided for @profile_badgesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rozetler & Başarılar'**
  String get profile_badgesTitle;

  /// No description provided for @profile_badge1Title.
  ///
  /// In tr, this message translates to:
  /// **'İlk Temas'**
  String get profile_badge1Title;

  /// No description provided for @profile_badge1Sub.
  ///
  /// In tr, this message translates to:
  /// **'100 Kelime'**
  String get profile_badge1Sub;

  /// No description provided for @profile_badge2Title.
  ///
  /// In tr, this message translates to:
  /// **'Dünya Vatandaşı'**
  String get profile_badge2Title;

  /// No description provided for @profile_badge2Sub.
  ///
  /// In tr, this message translates to:
  /// **'Seviye 5'**
  String get profile_badge2Sub;

  /// No description provided for @profile_badge3Title.
  ///
  /// In tr, this message translates to:
  /// **'Yıldız Avcısı'**
  String get profile_badge3Title;

  /// No description provided for @profile_badge3Sub.
  ///
  /// In tr, this message translates to:
  /// **'7 Gün Seri'**
  String get profile_badge3Sub;

  /// No description provided for @profile_badge4Title.
  ///
  /// In tr, this message translates to:
  /// **'Usta Çevirmen'**
  String get profile_badge4Title;

  /// No description provided for @profile_badge4Sub.
  ///
  /// In tr, this message translates to:
  /// **'Seviye 20'**
  String get profile_badge4Sub;

  /// No description provided for @profile_locked.
  ///
  /// In tr, this message translates to:
  /// **'KİLİTLİ'**
  String get profile_locked;

  /// No description provided for @profile_disconnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı Kes'**
  String get profile_disconnect;

  /// No description provided for @auth_err_enterName.
  ///
  /// In tr, this message translates to:
  /// **'Adını gir.'**
  String get auth_err_enterName;

  /// No description provided for @auth_err_invalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get auth_err_invalidEmail;

  /// No description provided for @auth_err_passwordMin6.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı.'**
  String get auth_err_passwordMin6;

  /// No description provided for @auth_err_invalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre yanlış.'**
  String get auth_err_invalidCredentials;

  /// No description provided for @auth_err_emailNotConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresini doğrulaman gerekiyor.'**
  String get auth_err_emailNotConfirmed;

  /// No description provided for @auth_err_alreadyRegistered.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta zaten kayıtlı. Giriş yapmayı dene.'**
  String get auth_err_alreadyRegistered;

  /// No description provided for @auth_err_noInternet.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok.'**
  String get auth_err_noInternet;

  /// No description provided for @auth_err_generic.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Tekrar dene.'**
  String get auth_err_generic;

  /// No description provided for @auth_subtitleLogin.
  ///
  /// In tr, this message translates to:
  /// **'İletişim Kanalını Başlat'**
  String get auth_subtitleLogin;

  /// No description provided for @auth_subtitleSignup.
  ///
  /// In tr, this message translates to:
  /// **'Dilbilim yolculuğuna başla.'**
  String get auth_subtitleSignup;

  /// No description provided for @auth_fullName.
  ///
  /// In tr, this message translates to:
  /// **'AD SOYAD'**
  String get auth_fullName;

  /// No description provided for @auth_nameHint.
  ///
  /// In tr, this message translates to:
  /// **'Adın'**
  String get auth_nameHint;

  /// No description provided for @auth_emailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-POSTA'**
  String get auth_emailLabel;

  /// No description provided for @auth_commsChannel.
  ///
  /// In tr, this message translates to:
  /// **'İLETİŞİM KANALI'**
  String get auth_commsChannel;

  /// No description provided for @auth_securityCode.
  ///
  /// In tr, this message translates to:
  /// **'GÜVENLİK KODU'**
  String get auth_securityCode;

  /// No description provided for @auth_accessKey.
  ///
  /// In tr, this message translates to:
  /// **'ERİŞİM ANAHTARI'**
  String get auth_accessKey;

  /// No description provided for @auth_loginBtn.
  ///
  /// In tr, this message translates to:
  /// **'GİRİŞ YAP'**
  String get auth_loginBtn;

  /// No description provided for @auth_signupBtn.
  ///
  /// In tr, this message translates to:
  /// **'KAYDOL'**
  String get auth_signupBtn;

  /// No description provided for @auth_toggleToSignup.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yörüngede değil misin? '**
  String get auth_toggleToSignup;

  /// No description provided for @auth_toggleToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Zaten yörüngede misin? '**
  String get auth_toggleToLogin;

  /// No description provided for @auth_signUpShort.
  ///
  /// In tr, this message translates to:
  /// **'Kaydol'**
  String get auth_signUpShort;

  /// No description provided for @auth_signInShort.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get auth_signInShort;

  /// No description provided for @auth_confirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelen kutunu aç.'**
  String get auth_confirmTitle;

  /// No description provided for @auth_confirmBody.
  ///
  /// In tr, this message translates to:
  /// **'adresine bir doğrulama linki gönderdik. Linke tıkladıktan sonra giriş yapabilirsin.'**
  String get auth_confirmBody;

  /// No description provided for @auth_backToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Ekranına Dön'**
  String get auth_backToLogin;

  /// No description provided for @cp_newMin6.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre en az 6 karakter olmalı.'**
  String get cp_newMin6;

  /// No description provided for @cp_mismatch.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifreler eşleşmiyor.'**
  String get cp_mismatch;

  /// No description provided for @cp_mustDiffer.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre eskisinden farklı olmalı.'**
  String get cp_mustDiffer;

  /// No description provided for @cp_currentWrong.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre yanlış.'**
  String get cp_currentWrong;

  /// No description provided for @cp_weak.
  ///
  /// In tr, this message translates to:
  /// **'Şifre çok zayıf, daha güçlü bir şifre seç.'**
  String get cp_weak;

  /// No description provided for @cp_updateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Şifre güncellenemedi. Tekrar dene.'**
  String get cp_updateFailed;

  /// No description provided for @cp_title.
  ///
  /// In tr, this message translates to:
  /// **'ŞİFRE DEĞİŞTİR'**
  String get cp_title;

  /// No description provided for @cp_heading.
  ///
  /// In tr, this message translates to:
  /// **'Erişim Anahtarını Değiştir'**
  String get cp_heading;

  /// No description provided for @cp_subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenliğin için önce mevcut şifreni doğrulamamız gerekiyor.'**
  String get cp_subtitle;

  /// No description provided for @cp_success.
  ///
  /// In tr, this message translates to:
  /// **'Şifren başarıyla güncellendi.'**
  String get cp_success;

  /// No description provided for @cp_current.
  ///
  /// In tr, this message translates to:
  /// **'MEVCUT ŞİFRE'**
  String get cp_current;

  /// No description provided for @cp_new.
  ///
  /// In tr, this message translates to:
  /// **'YENİ ŞİFRE'**
  String get cp_new;

  /// No description provided for @cp_min6Hint.
  ///
  /// In tr, this message translates to:
  /// **'En az 6 karakter'**
  String get cp_min6Hint;

  /// No description provided for @cp_newRepeat.
  ///
  /// In tr, this message translates to:
  /// **'YENİ ŞİFRE (TEKRAR)'**
  String get cp_newRepeat;

  /// No description provided for @cp_reenterHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden gir'**
  String get cp_reenterHint;

  /// No description provided for @cp_updateBtn.
  ///
  /// In tr, this message translates to:
  /// **'ŞİFREYİ GÜNCELLE'**
  String get cp_updateBtn;

  /// No description provided for @fp_rateLimit.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla istek. Birkaç dakika sonra tekrar dene.'**
  String get fp_rateLimit;

  /// No description provided for @fp_title.
  ///
  /// In tr, this message translates to:
  /// **'Şifreni mi unuttun?'**
  String get fp_title;

  /// No description provided for @fp_subtitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresini gir, sana yeni bir şifre belirleyeceğin bir bağlantı gönderelim.'**
  String get fp_subtitle;

  /// No description provided for @fp_sendBtn.
  ///
  /// In tr, this message translates to:
  /// **'BAĞLANTI GÖNDER'**
  String get fp_sendBtn;

  /// No description provided for @fp_sentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı yola çıktı.'**
  String get fp_sentTitle;

  /// No description provided for @fp_sentBody.
  ///
  /// In tr, this message translates to:
  /// **'adresine bir bağlantı gönderdik. Gelen kutunu (ve spam klasörünü) kontrol et — bağlantıya tıkladığında uygulama açılacak ve yeni şifreni belirleyebileceksin.'**
  String get fp_sentBody;

  /// No description provided for @rp_mismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get rp_mismatch;

  /// No description provided for @rp_expired.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantının süresi dolmuş. Yeniden talep et.'**
  String get rp_expired;

  /// No description provided for @rp_title.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre Belirle'**
  String get rp_title;

  /// No description provided for @rp_subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı doğrulandı. Hesabın için yeni bir şifre seç.'**
  String get rp_subtitle;

  /// No description provided for @rp_saveBtn.
  ///
  /// In tr, this message translates to:
  /// **'ŞİFREYİ KAYDET'**
  String get rp_saveBtn;

  /// No description provided for @rp_successTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifren güncellendi'**
  String get rp_successTitle;

  /// No description provided for @rp_successBody.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifrenle giriş yapabilirsin.'**
  String get rp_successBody;

  /// No description provided for @rp_backBtn.
  ///
  /// In tr, this message translates to:
  /// **'GİRİŞ EKRANINA DÖN'**
  String get rp_backBtn;

  /// No description provided for @del_confirmWord.
  ///
  /// In tr, this message translates to:
  /// **'SİL'**
  String get del_confirmWord;

  /// No description provided for @del_exported.
  ///
  /// In tr, this message translates to:
  /// **'Verilerin dışa aktarıldı.'**
  String get del_exported;

  /// No description provided for @del_exportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Veriler dışa aktarılamadı.'**
  String get del_exportFailed;

  /// No description provided for @del_deleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinemedi. Tekrar dene.'**
  String get del_deleteFailed;

  /// No description provided for @del_finalConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Son Onay'**
  String get del_finalConfirm;

  /// No description provided for @del_finalWarning.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını ve tüm verilerini kalıcı olarak silmek üzeresin. Bu işlem geri alınamaz.'**
  String get del_finalWarning;

  /// No description provided for @del_deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get del_deleteAccount;

  /// No description provided for @del_title.
  ///
  /// In tr, this message translates to:
  /// **'HESABI SİL'**
  String get del_title;

  /// No description provided for @del_downloadTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verilerini İndir'**
  String get del_downloadTitle;

  /// No description provided for @del_downloadBody.
  ///
  /// In tr, this message translates to:
  /// **'Silmeden önce tüm verilerini (profil, kelimeler, pratik oturumları, mesajlar) JSON formatında indirip saklayabilirsin.'**
  String get del_downloadBody;

  /// No description provided for @del_exportBtn.
  ///
  /// In tr, this message translates to:
  /// **'Verilerimi Dışa Aktar'**
  String get del_exportBtn;

  /// No description provided for @del_deleteIntro.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Hesabını sildiğinde aşağıdaki tüm veriler kalıcı olarak silinir:'**
  String get del_deleteIntro;

  /// No description provided for @del_bullet1.
  ///
  /// In tr, this message translates to:
  /// **'Profil ve kullanıcı adın'**
  String get del_bullet1;

  /// No description provided for @del_bullet2.
  ///
  /// In tr, this message translates to:
  /// **'Kelime hazinen ve tekrar geçmişin'**
  String get del_bullet2;

  /// No description provided for @del_bullet3.
  ///
  /// In tr, this message translates to:
  /// **'Tüm pratik oturumların ve sohbet kayıtların'**
  String get del_bullet3;

  /// No description provided for @del_bullet4.
  ///
  /// In tr, this message translates to:
  /// **'Kazandığın XP, seviye ve seri günler'**
  String get del_bullet4;

  /// No description provided for @del_understood.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlemin geri alınamaz olduğunu anladım.'**
  String get del_understood;

  /// No description provided for @del_typeToConfirm.
  ///
  /// In tr, this message translates to:
  /// **'ONAYLAMAK İÇİN \"{word}\" YAZ'**
  String del_typeToConfirm(String word);

  /// No description provided for @del_deleting.
  ///
  /// In tr, this message translates to:
  /// **'Siliniyor…'**
  String get del_deleting;

  /// No description provided for @del_deletePermanent.
  ///
  /// In tr, this message translates to:
  /// **'HESABIMI KALICI OLARAK SİL'**
  String get del_deletePermanent;

  /// No description provided for @onb_error.
  ///
  /// In tr, this message translates to:
  /// **'Onboarding hatası: {error}'**
  String onb_error(String error);

  /// No description provided for @onb_start.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get onb_start;

  /// No description provided for @onb_continue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get onb_continue;

  /// No description provided for @onb_welcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'VoiceLingo\'ya hoş geldin'**
  String get onb_welcomeTitle;

  /// No description provided for @onb_welcomeBody.
  ///
  /// In tr, this message translates to:
  /// **'Konuş. Gelişeceksin. Tekrarla.\nAI koçun her konuşmada yanında.'**
  String get onb_welcomeBody;

  /// No description provided for @onb_permTitle.
  ///
  /// In tr, this message translates to:
  /// **'İki hızlı izin'**
  String get onb_permTitle;

  /// No description provided for @onb_permSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzgün koçluk yapabilmemiz için gerekli.'**
  String get onb_permSubtitle;

  /// No description provided for @onb_micTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon'**
  String get onb_micTitle;

  /// No description provided for @onb_micDesc.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmanı duy, telaffuza geri bildirim ver.'**
  String get onb_micDesc;

  /// No description provided for @onb_notifDesc.
  ///
  /// In tr, this message translates to:
  /// **'Streak\'ini canlı tutmak için nazik hatırlatmalar.'**
  String get onb_notifDesc;

  /// No description provided for @onb_allow.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get onb_allow;

  /// No description provided for @onb_goalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedefin'**
  String get onb_goalTitle;

  /// No description provided for @onb_goalSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Günde kaç dakika çalışmak istersin?'**
  String get onb_goalSubtitle;

  /// No description provided for @onb_minSuffix.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get onb_minSuffix;

  /// No description provided for @onb_motivTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neden öğreniyorsun?'**
  String get onb_motivTitle;

  /// No description provided for @onb_motivSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana uygun senaryoları seçmemize yardım eder.'**
  String get onb_motivSubtitle;

  /// No description provided for @onb_motivExam.
  ///
  /// In tr, this message translates to:
  /// **'Sınav'**
  String get onb_motivExam;

  /// No description provided for @onb_motivHobby.
  ///
  /// In tr, this message translates to:
  /// **'Hobi'**
  String get onb_motivHobby;

  /// No description provided for @onb_charSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her koçun farklı sesi ve tarzı var. Ayarlardan istediğin zaman değiştirebilirsin.'**
  String get onb_charSubtitle;

  /// No description provided for @placement_title.
  ///
  /// In tr, this message translates to:
  /// **'Seviye Belirleme'**
  String get placement_title;

  /// No description provided for @placement_result.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç'**
  String get placement_result;

  /// No description provided for @placement_correctCount.
  ///
  /// In tr, this message translates to:
  /// **'{correct} / 10 doğru'**
  String placement_correctCount(int correct);

  /// No description provided for @conn_offlineBanner.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışısın. İlerlemen bağlanınca senkronize olur.'**
  String get conn_offlineBanner;

  /// No description provided for @levelup_title.
  ///
  /// In tr, this message translates to:
  /// **'SEVİYE ATLADIN!'**
  String get levelup_title;

  /// No description provided for @levelup_body.
  ///
  /// In tr, this message translates to:
  /// **'Harika gidiyorsun! Yeni seviyeye ulaştın:\nSeviye {level}'**
  String levelup_body(int level);

  /// No description provided for @levelup_continue.
  ///
  /// In tr, this message translates to:
  /// **'DEVAM ET'**
  String get levelup_continue;
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
