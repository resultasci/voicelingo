import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'VoiceLingo';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_done => 'Done';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_error => 'Something went wrong';

  @override
  String get nav_dashboard => 'HOME';

  @override
  String get nav_words => 'WORDS';

  @override
  String get nav_practice => 'PRACTICE';

  @override
  String get nav_profile => 'PROFILE';

  @override
  String get nav_settings => 'Settings';

  @override
  String get nav_scenarios => 'Scenarios';

  @override
  String get auth_signIn => 'Sign in';

  @override
  String get auth_signUp => 'Sign up';

  @override
  String get auth_signOut => 'Sign out';

  @override
  String get auth_email => 'Email';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_username => 'Username';

  @override
  String get auth_confirmPassword => 'Confirm password';

  @override
  String get auth_forgotPassword => 'Forgot password';

  @override
  String get auth_changePassword => 'Change password';

  @override
  String get auth_resetPassword => 'Reset password';

  @override
  String get auth_validation_fillAll => 'Please fill in all fields';

  @override
  String get auth_validation_passwordMismatch => 'Passwords do not match';

  @override
  String get auth_error_sessionNotFound => 'Session not found, please sign in again.';

  @override
  String get auth_error_sessionExpired => 'Your session expired, please sign in again.';

  @override
  String get error_network => 'Connection issue. Please check your internet.';

  @override
  String get error_timeout => 'The connection timed out.';

  @override
  String get error_unexpected => 'An unexpected error occurred.';

  @override
  String get error_rateLimit => 'Daily usage limit reached. Try again tomorrow.';

  @override
  String get error_audioTooLong => 'Audio is too long. Try a shorter recording.';

  @override
  String get error_aiUnavailable => 'The AI service is unavailable right now.';

  @override
  String get error_invalidJson => 'Invalid response from server.';

  @override
  String get error_offline => 'You are offline.';

  @override
  String get error_audioInvalid => 'Invalid response from speech recognition service.';

  @override
  String get error_evalInvalid => 'Invalid response from the evaluation service.';

  @override
  String get error_serverInvalid => 'Unexpected server response.';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_themeDark => 'Dark';

  @override
  String get settings_themeLight => 'Light';

  @override
  String get settings_themeSystem => 'System';

  @override
  String get settings_language => 'Interface Language';

  @override
  String get settings_languageTurkish => 'Turkish';

  @override
  String get settings_languageEnglish => 'English';

  @override
  String get settings_ttsSpeed => 'Speech Rate';

  @override
  String get settings_ttsSpeedSlow => 'Slow';

  @override
  String get settings_ttsSpeedNormal => 'Normal';

  @override
  String get settings_ttsSpeedFast => 'Fast';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_reviewHour => 'Daily Reminder Time';

  @override
  String get settings_textScale => 'Text Size';

  @override
  String get settings_aiCharacter => 'AI Character';

  @override
  String get settings_account => 'Account';

  @override
  String get settings_about => 'About';

  @override
  String get settings_version => 'Version';

  @override
  String get profile_level => 'Level';

  @override
  String get profile_xp => 'XP';

  @override
  String get profile_streak => 'Streak';

  @override
  String profile_streak_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String get profile_cefr => 'CEFR Level';

  @override
  String get words_addNew => 'New Word';

  @override
  String words_review_due(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words due for review',
      one: '1 word due for review',
      zero: 'No reviews due today',
    );
    return '$_temp0';
  }

  @override
  String get words_review_remember => 'I remembered';

  @override
  String get words_review_hard => 'Hard';

  @override
  String get words_review_forgot => 'Forgot';

  @override
  String words_duplicate(String word) {
    return '\"$word\" is already in your list.';
  }

  @override
  String get conversation_listening => 'Listening…';

  @override
  String get conversation_thinking => 'Thinking…';

  @override
  String get conversation_speaking => 'Speaking…';

  @override
  String get conversation_idle => 'Microphone ready';

  @override
  String get conversation_handsfree => 'Hands-free mode';

  @override
  String get conversation_pushToTalk => 'Hold to talk';

  @override
  String get conversation_micPermissionDenied => 'Microphone permission required. You can enable it in Settings.';

  @override
  String get notification_reviewReminder_title => 'Review time!';

  @override
  String notification_reviewReminder_body(String word) {
    return 'Time to review \"$word\"!';
  }

  @override
  String get notification_dailyDigest_title => 'Daily review';

  @override
  String notification_dailyDigest_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words due for review today',
      one: '1 word due for review today',
      zero: 'No words due today',
    );
    return '$_temp0';
  }

  @override
  String get boot_envMissing_title => 'Configuration missing';

  @override
  String boot_envMissing_description(String key) {
    return '$key is undefined or empty — please check your .env file.';
  }

  @override
  String get boot_dotenvFailed_title => 'Failed to load .env';

  @override
  String get boot_dotenvFailed_description => 'The .env file was not found at the project root or could not be read.';
}
