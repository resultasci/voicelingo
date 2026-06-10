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
  String get auth_error_sessionNotFound =>
      'Session not found, please sign in again.';

  @override
  String get auth_error_sessionExpired =>
      'Your session expired, please sign in again.';

  @override
  String get error_network => 'Connection issue. Please check your internet.';

  @override
  String get error_timeout => 'The connection timed out.';

  @override
  String get error_unexpected => 'An unexpected error occurred.';

  @override
  String get error_rateLimit =>
      'Daily usage limit reached. Try again tomorrow.';

  @override
  String get error_audioTooLong =>
      'Audio is too long. Try a shorter recording.';

  @override
  String get error_aiUnavailable => 'The AI service is unavailable right now.';

  @override
  String get error_invalidJson => 'Invalid response from server.';

  @override
  String get error_offline => 'You are offline.';

  @override
  String get error_audioInvalid =>
      'Invalid response from speech recognition service.';

  @override
  String get error_evalInvalid =>
      'Invalid response from the evaluation service.';

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
  String get conversation_micPermissionDenied =>
      'Microphone permission required. You can enable it in Settings.';

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
  String get boot_dotenvFailed_description =>
      'The .env file was not found at the project root or could not be read.';

  @override
  String get dashboard_profileLoadError => 'Couldn\'t load profile.';

  @override
  String get dashboard_defaultName => 'Captain';

  @override
  String dashboard_greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboard_greetingSubtitle =>
      'Ready for your daily galactic goals?';

  @override
  String get dashboard_statStreak => 'STREAK';

  @override
  String dashboard_streakValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String get dashboard_aiModule => 'AI MODULE';

  @override
  String get dashboard_aiTitle => 'Deep Space Practice';

  @override
  String get dashboard_aiSubtitle =>
      'Start your daily conversation simulation with your personalized AI assistant.';

  @override
  String get dashboard_aiStart => 'Start Simulation';

  @override
  String get dashboard_dailyGoals => 'Daily Goals';

  @override
  String get dashboard_goalLanguage => 'English';

  @override
  String get dashboard_goalLoading => 'Loading Library';

  @override
  String get dashboard_goalAllCurrent => 'All Words Up to Date';

  @override
  String dashboard_percentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settings_emailAddress => 'Email Address';

  @override
  String get settings_downloadDeleteAccount => 'Download Data / Delete Account';

  @override
  String get settings_dailyReviewReminder => 'Daily Review Reminder';

  @override
  String get settings_reminderSubtitle =>
      'One notification per day for due words';

  @override
  String get settings_reminderTime => 'Reminder Time';

  @override
  String get settings_onceADay => 'ONCE A DAY';

  @override
  String get settings_systemPreferences => 'System Preferences';

  @override
  String get settings_visualTheme => 'Visual Theme';

  @override
  String get settings_themeObsidian => 'Obsidian Void (Dark)';

  @override
  String get settings_themeSolar => 'Solar Flare (Light)';

  @override
  String get settings_themeSystemDefault => 'System Default';

  @override
  String get settings_aiCoach => 'AI Coach';

  @override
  String get settings_progress => 'Progress';

  @override
  String get settings_progressStats => 'Progress & Stats';

  @override
  String get settings_courseTree => 'Course Tree';

  @override
  String get settings_courseTreeFull => 'Course Tree (A1-C2)';

  @override
  String get settings_grammar => 'Grammar';

  @override
  String get settings_badges => 'Badges';

  @override
  String get settings_disconnect => 'Disconnect';

  @override
  String get settings_signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get common_saving => 'Saving…';

  @override
  String get common_add => 'Add';

  @override
  String get words_filterAll => 'All';

  @override
  String get words_filterDue => 'Due';

  @override
  String get words_filterLearned => 'Learned';

  @override
  String get words_filterNew => 'New';

  @override
  String get words_reviewSaveError => 'Couldn\'t save review';

  @override
  String get words_addToLibrary => 'Add to library';

  @override
  String get words_labelEnglish => 'ENGLISH';

  @override
  String get words_labelTurkish => 'TURKISH';

  @override
  String get words_hintWord => 'word';

  @override
  String get words_hintTranslation => 'translation';

  @override
  String get words_alreadyInLibrary => 'This word is already in your library.';

  @override
  String get words_addFailed => 'Couldn\'t add word';

  @override
  String get words_libraryTitle => 'Word Library';

  @override
  String words_librarySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your cognitive lexicon expanded to $count words.',
      one: 'Your cognitive lexicon expanded to 1 word.',
    );
    return '$_temp0';
  }

  @override
  String get words_searchHint => 'Search word or translation…';

  @override
  String get words_reviewToday => 'REVIEW TODAY';

  @override
  String words_wordsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words ready',
      one: '1 word ready',
    );
    return '$_temp0';
  }

  @override
  String get words_statusNew => 'New';

  @override
  String get words_statusDue => 'Due';

  @override
  String get words_statusLearned => 'Learned';

  @override
  String get words_statusInProgress => 'In progress';

  @override
  String get words_intervalNew => 'NEW';

  @override
  String get words_unitDay => 'd';

  @override
  String get words_unitWeek => 'w';

  @override
  String get words_unitMonth => 'mo';

  @override
  String get words_unitYear => 'y';

  @override
  String get words_deleteWord => 'Delete word';

  @override
  String get words_pronounce => 'Pronounce';

  @override
  String get words_emptyTitle => 'Build your library';

  @override
  String get words_emptyBody =>
      'Pick a topic and let AI generate a custom word list — or add words one by one. Everything resurfaces at the right time via the SM-2 algorithm.';

  @override
  String get words_addFirst => 'Add a word manually';

  @override
  String get words_generateCta => 'Generate with AI';

  @override
  String get words_genTitle => 'Generate words';

  @override
  String get words_genSubtitle =>
      'Type a topic and let AI build a word list for you.';

  @override
  String get words_genTopicLabel => 'TOPIC';

  @override
  String get words_genTopicHint => 'e.g. Travel, Kitchen, Business English';

  @override
  String get words_genCount => 'How many?';

  @override
  String get words_genButton => 'Generate';

  @override
  String words_genAdded(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count words',
      one: 'Added 1 word',
    );
    return '$_temp0';
  }

  @override
  String get words_genNone =>
      'No new words to add — they were all already in your library.';

  @override
  String get words_genFailed => 'Couldn\'t generate words. Please try again.';

  @override
  String get words_filterEmpty => 'This filter is empty';

  @override
  String words_noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get words_gradeGreat => 'Great!';

  @override
  String get words_gradeGood => 'Good job!';

  @override
  String get words_gradeKeepGoing => 'Keep going!';

  @override
  String get words_reviewComplete => 'Review Complete';

  @override
  String get words_statCorrect => 'CORRECT';

  @override
  String get words_statTotal => 'TOTAL';

  @override
  String get words_statSuccess => 'SUCCESS';

  @override
  String get words_backToLibrary => 'Back to Library';

  @override
  String get words_translate => 'Translate';

  @override
  String get words_tapToReveal => 'TAP TO REVEAL';

  @override
  String get words_howWell => 'HOW WELL DID YOU KNOW?';

  @override
  String get words_rateForgot => 'Forgot';

  @override
  String get words_rateHard => 'Hard';

  @override
  String get words_rateEasy => 'Easy';

  @override
  String get wordDetail_loadError => 'Could not load extra details.';

  @override
  String get wordDetail_noCache =>
      'No extra details cached yet. Try again later.';

  @override
  String get wordDetail_ipaCopied => 'IPA copied';

  @override
  String get wordDetail_examples => 'Examples';

  @override
  String get wordDetail_synonyms => 'Synonyms';

  @override
  String get wordDetail_antonyms => 'Antonyms';

  @override
  String get wordDetail_collocations => 'Collocations';

  @override
  String get wordDetail_etymology => 'Etymology';

  @override
  String get flashcard_title => 'Word Practice';

  @override
  String flashcard_cardOf(int current, int total) {
    return 'CARD $current / $total';
  }

  @override
  String get flashcard_revealHint =>
      'Tap \"Show Answer\" to see the translation';

  @override
  String get flashcard_showAnswer => 'SHOW ANSWER';

  @override
  String get flashcard_congrats => 'CONGRATULATIONS!';

  @override
  String get flashcard_completeBody =>
      'You\'ve finished today\'s word review. Words will be rescheduled for you tomorrow.';

  @override
  String get flashcard_backHome => 'BACK TO HOME';

  @override
  String get conv_statusStarting => 'STARTING';

  @override
  String get conv_statusReady => 'READY';

  @override
  String get conv_statusListening => 'LISTENING';

  @override
  String get conv_statusThinking => 'THINKING';

  @override
  String get conv_statusSpeaking => 'AI SPEAKING';

  @override
  String get conv_statusError => 'ERROR';

  @override
  String conv_errTts(String msg) {
    return 'TTS error: $msg';
  }

  @override
  String get conv_errTtsInit => 'Couldn\'t start TTS.';

  @override
  String get conv_errMicPermission => 'Microphone permission required.';

  @override
  String conv_errMicOpen(String error) {
    return 'Couldn\'t open microphone: $error';
  }

  @override
  String get conv_errRecordFailed => 'Recording failed.';

  @override
  String conv_errAudioProcess(String error) {
    return 'Audio processing error: $error';
  }

  @override
  String get conv_errNoSpeech => 'Couldn\'t recognize speech.';

  @override
  String conv_errGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String conv_errSpeak(String error) {
    return 'Speech error: $error';
  }

  @override
  String get conv_errUnknown => 'Unknown error.';

  @override
  String get conv_greeting =>
      'Hi! I\'m ready to practice your English. Go ahead and speak!';

  @override
  String get conv_replyFailed =>
      'Couldn\'t get a reply. Tap the button below to try again.';

  @override
  String conv_aiNoResponse(String error) {
    return 'AI didn\'t respond: $error';
  }

  @override
  String get conv_practiceMode => 'Practice Mode';

  @override
  String get conv_handsFreeOnTip =>
      'Hands-free on — listens automatically after the AI finishes';

  @override
  String get conv_handsFreeOffTip => 'Hands-free off — you need to tap the mic';

  @override
  String get conv_pickScenario => 'Pick a scenario';

  @override
  String get conv_newChat => 'New Chat';

  @override
  String get conv_chatHistory => 'Chat history';

  @override
  String get conv_preparing => 'Preparing…';

  @override
  String get conv_aiPreparing => 'Preparing AI response…';

  @override
  String get conv_emptyHint => 'Tap the mic, type, or pick a scenario.';

  @override
  String get conv_aiPracticeMode => 'AI Practice Mode';

  @override
  String get conv_readyScenarios => 'READY SCENARIOS';

  @override
  String get conv_seeAll => 'See All';

  @override
  String get conv_inputHint => 'Type your message or speak…';

  @override
  String get conv_sendMessage => 'Send message';

  @override
  String get conv_stopRecording => 'Stop recording';

  @override
  String get conv_startRecording => 'Start recording';

  @override
  String get conv_tryAgain => 'Try again';

  @override
  String get conv_restart => 'Restart';

  @override
  String get conv_feedbackGreat => '✅ Great!';

  @override
  String conv_feedbackMoreNatural(String suggestion) {
    return '💡 More natural: $suggestion';
  }

  @override
  String conv_evalSemantics(String label) {
    return 'Speech evaluation: $label';
  }

  @override
  String conv_score(int score) {
    return 'SCORE: $score/100';
  }

  @override
  String get conv_errorsLabel => 'ERRORS';

  @override
  String get conv_replay => 'Listen again';

  @override
  String get conv_copied => 'Copied to clipboard';

  @override
  String get conv_changeCoach => 'Change AI coach';

  @override
  String get convHist_title => 'Chat History';

  @override
  String get convHist_freeChat => 'Free chat';

  @override
  String get convHist_empty => 'No saved conversations yet.';

  @override
  String get convView_title => 'Conversation';

  @override
  String convView_score(int score) {
    return 'Score: $score';
  }

  @override
  String get charPicker_title => 'Pick your coach';

  @override
  String get charPicker_start => 'Start with this coach';

  @override
  String get charPicker_listen => 'Listen to voice';

  @override
  String get scen_createWithAi => 'Create with AI';

  @override
  String get scen_allScenarios => 'All scenarios';

  @override
  String get scen_free => 'Free';

  @override
  String get scen_newScenario => 'New scenario';

  @override
  String get scen_create => 'Create';

  @override
  String get scen_empty => 'No scenarios yet. Tap Create to generate one.';

  @override
  String get scen_yours => 'Yours';

  @override
  String get scen_builtIn => 'Built-in';

  @override
  String scen_turnsCount(int count) {
    return '~$count turns';
  }

  @override
  String get scen_createTitle => 'Create scenario';

  @override
  String get scen_describeScene => 'Describe a scene';

  @override
  String get scen_descHint =>
      'e.g. \"Job interview for a senior Flutter role\"';

  @override
  String get scen_category => 'Category';

  @override
  String get scen_difficulty => 'Difficulty';

  @override
  String get scen_generate => 'Generate';

  @override
  String get scen_regenerate => 'Regenerate';

  @override
  String get scen_saveStart => 'Save & start';

  @override
  String get scen_catDaily => 'Daily';

  @override
  String get scen_catWork => 'Work';

  @override
  String get scen_catTravel => 'Travel';

  @override
  String get scen_catHealth => 'Health';

  @override
  String get scen_catEducation => 'Education';

  @override
  String get scen_catOther => 'Other';

  @override
  String get scen_aiPlays => 'AI plays';

  @override
  String get scen_youPlay => 'You play';

  @override
  String get scen_startsWith => 'Starts with';

  @override
  String get scen_goals => 'Goals';

  @override
  String get common_finish => 'Finish';

  @override
  String get grammar_level => 'Level';

  @override
  String get grammar_emptyTopics =>
      'No grammar topics yet. Make sure you applied the migration.';

  @override
  String get grammar_bestScore => 'Best score';

  @override
  String get topic_tabLesson => 'Lesson';

  @override
  String get topic_noDescription => 'No description yet.';

  @override
  String get topic_noExamples => 'No examples yet.';

  @override
  String get topic_noQuiz => 'No quiz yet.';

  @override
  String get topic_greatJob => 'Great job!';

  @override
  String get quiz_question => 'Question';

  @override
  String get quiz_typeAnswer => 'Type your answer';

  @override
  String get quiz_retry => 'Retry';

  @override
  String get lesson_courseTitle => 'Course';

  @override
  String get lesson_emptyCourse =>
      'No course yet. Make sure the migration is applied.';

  @override
  String get lesson_noUnits => 'No units yet.';

  @override
  String get lesson_englishCourse => 'English Course';

  @override
  String get lesson_lessonsSuffix => 'lessons';

  @override
  String get lesson_customScenarioTitle => 'Create Custom Scenario';

  @override
  String get lesson_customScenarioBody =>
      'Practice with AI on any topic you want.';

  @override
  String get lesson_typeVocab => 'Vocab';

  @override
  String get lesson_typeSpeaking => 'Speaking';

  @override
  String get lesson_typeListening => 'Listening';

  @override
  String get lesson_grammarBridge =>
      'This lesson opens the matching grammar topic. Complete the quiz there to mark it done here.';

  @override
  String get lesson_convBridge =>
      'Practice the conversation scenario. Min turns will count toward lesson completion.';

  @override
  String get lesson_openGrammar => 'Open Grammar';

  @override
  String get lesson_startConv => 'Start Conversation';

  @override
  String get lesson_noVocab => 'No vocabulary in this lesson.';

  @override
  String get lesson_noListening => 'No listening content in this lesson.';

  @override
  String get lesson_listenPrompt => 'Listen and type what you hear';

  @override
  String get lesson_typeWhatYouHeard => 'Type the sentence you heard…';

  @override
  String get lesson_listenCheck => 'Check';

  @override
  String get lesson_listenCorrect => 'Correct!';

  @override
  String get lesson_listenWrong => 'Correct answer:';

  @override
  String get lesson_tapToFlip => 'Tap to flip';

  @override
  String get lesson_practiceAgain => 'Practice again';

  @override
  String get lesson_iKnowIt => 'I know it';

  @override
  String get lesson_noQuizQuestions => 'No quiz questions.';

  @override
  String get lesson_perfect => 'Perfect!';

  @override
  String get lesson_great => 'Awesome!';

  @override
  String get lesson_keepGoing => 'Keep going';

  @override
  String get lesson_errorTitle => 'Error';

  @override
  String lesson_scoreLabel(int score) {
    return 'Score: $score';
  }

  @override
  String get badge_unlocked => 'Badge unlocked!';

  @override
  String get badge_awesome => 'Awesome';

  @override
  String get progress_last90 => 'Last 90 days';

  @override
  String get progress_mastery => 'Mastery';

  @override
  String get progress_noData => 'No data yet.';

  @override
  String get progress_words => 'Words';

  @override
  String get progress_lessons => 'Lessons';

  @override
  String get progress_topMistakes => 'Top mistakes (30 days)';

  @override
  String get progress_noMistakes =>
      'No mistakes recorded yet — keep practicing!';

  @override
  String get heatmap_less => 'Less';

  @override
  String get heatmap_more => 'More';

  @override
  String get profile_defaultName => 'User';

  @override
  String get profile_signOutWarning =>
      'Practice can\'t be saved until you sign in again.';

  @override
  String profile_levelTitle(int level) {
    return 'Level $level • Galactic Linguist';
  }

  @override
  String get profile_dailyStreak => 'DAILY STREAK';

  @override
  String get profile_fluency => 'FLUENCY';

  @override
  String get profile_fluencyTooltip =>
      'Fluency = correct review rate × 50 + streak (≤30d) × 30 + XP (≤2000) × 20';

  @override
  String get profile_badgesTitle => 'Badges & Achievements';

  @override
  String get profile_badge1Title => 'First Contact';

  @override
  String get profile_badge1Sub => '100 Words';

  @override
  String get profile_badge2Title => 'World Citizen';

  @override
  String get profile_badge2Sub => 'Level 5';

  @override
  String get profile_badge3Title => 'Star Hunter';

  @override
  String get profile_badge3Sub => '7-Day Streak';

  @override
  String get profile_badge4Title => 'Master Translator';

  @override
  String get profile_badge4Sub => 'Level 20';

  @override
  String get profile_locked => 'LOCKED';

  @override
  String get profile_disconnect => 'Disconnect';

  @override
  String get auth_err_enterName => 'Enter your name.';

  @override
  String get auth_err_invalidEmail => 'Enter a valid email address.';

  @override
  String get auth_err_passwordMin6 => 'Password must be at least 6 characters.';

  @override
  String get auth_err_invalidCredentials => 'Email or password is incorrect.';

  @override
  String get auth_err_emailNotConfirmed =>
      'You need to verify your email address.';

  @override
  String get auth_err_alreadyRegistered =>
      'This email is already registered. Try signing in.';

  @override
  String get auth_err_noInternet => 'No internet connection.';

  @override
  String get auth_err_generic => 'Something went wrong. Try again.';

  @override
  String get auth_subtitleLogin => 'Open your comms channel';

  @override
  String get auth_subtitleSignup => 'Begin your linguistics journey.';

  @override
  String get auth_fullName => 'FULL NAME';

  @override
  String get auth_nameHint => 'Your name';

  @override
  String get auth_emailLabel => 'EMAIL';

  @override
  String get auth_commsChannel => 'COMMS CHANNEL';

  @override
  String get auth_securityCode => 'SECURITY CODE';

  @override
  String get auth_accessKey => 'ACCESS KEY';

  @override
  String get auth_loginBtn => 'SIGN IN';

  @override
  String get auth_signupBtn => 'SIGN UP';

  @override
  String get auth_toggleToSignup => 'Not in orbit yet? ';

  @override
  String get auth_toggleToLogin => 'Already in orbit? ';

  @override
  String get auth_signUpShort => 'Sign up';

  @override
  String get auth_signInShort => 'Sign in';

  @override
  String get auth_confirmTitle => 'Check your inbox.';

  @override
  String get auth_confirmBody =>
      'we sent a verification link. After you tap it, you can sign in.';

  @override
  String get auth_backToLogin => 'Back to Sign In';

  @override
  String get cp_newMin6 => 'New password must be at least 6 characters.';

  @override
  String get cp_mismatch => 'New passwords don\'t match.';

  @override
  String get cp_mustDiffer => 'New password must differ from the old one.';

  @override
  String get cp_currentWrong => 'Current password is incorrect.';

  @override
  String get cp_weak => 'Password is too weak, choose a stronger one.';

  @override
  String get cp_updateFailed => 'Couldn\'t update password. Try again.';

  @override
  String get cp_title => 'CHANGE PASSWORD';

  @override
  String get cp_heading => 'Change Your Access Key';

  @override
  String get cp_subtitle =>
      'For your security, we first need to verify your current password.';

  @override
  String get cp_success => 'Your password was updated successfully.';

  @override
  String get cp_current => 'CURRENT PASSWORD';

  @override
  String get cp_new => 'NEW PASSWORD';

  @override
  String get cp_min6Hint => 'At least 6 characters';

  @override
  String get cp_newRepeat => 'NEW PASSWORD (REPEAT)';

  @override
  String get cp_reenterHint => 'Re-enter';

  @override
  String get cp_updateBtn => 'UPDATE PASSWORD';

  @override
  String get fp_rateLimit => 'Too many requests. Try again in a few minutes.';

  @override
  String get fp_title => 'Forgot your password?';

  @override
  String get fp_subtitle =>
      'Enter your email and we\'ll send you a link to set a new password.';

  @override
  String get fp_sendBtn => 'SEND LINK';

  @override
  String get fp_sentTitle => 'Link is on its way.';

  @override
  String get fp_sentBody =>
      'we sent a link. Check your inbox (and spam folder) — tapping the link opens the app and lets you set a new password.';

  @override
  String get rp_mismatch => 'Passwords don\'t match.';

  @override
  String get rp_expired => 'The link has expired. Request a new one.';

  @override
  String get rp_title => 'Set a New Password';

  @override
  String get rp_subtitle =>
      'Link verified. Choose a new password for your account.';

  @override
  String get rp_saveBtn => 'SAVE PASSWORD';

  @override
  String get rp_successTitle => 'Password updated';

  @override
  String get rp_successBody => 'You can sign in with your new password.';

  @override
  String get rp_backBtn => 'BACK TO SIGN IN';

  @override
  String get del_confirmWord => 'DELETE';

  @override
  String get del_exported => 'Your data was exported.';

  @override
  String get del_exportFailed => 'Couldn\'t export data.';

  @override
  String get del_deleteFailed => 'Couldn\'t delete account. Try again.';

  @override
  String get del_finalConfirm => 'Final Confirmation';

  @override
  String get del_finalWarning =>
      'You\'re about to permanently delete your account and all your data. This action cannot be undone.';

  @override
  String get del_deleteAccount => 'Delete Account';

  @override
  String get del_title => 'DELETE ACCOUNT';

  @override
  String get del_downloadTitle => 'Download Your Data';

  @override
  String get del_downloadBody =>
      'Before deleting, you can download and keep all your data (profile, words, practice sessions, messages) in JSON format.';

  @override
  String get del_exportBtn => 'Export My Data';

  @override
  String get del_deleteIntro =>
      'This action cannot be undone. When you delete your account, all of the following data is permanently removed:';

  @override
  String get del_bullet1 => 'Profile and username';

  @override
  String get del_bullet2 => 'Word library and review history';

  @override
  String get del_bullet3 => 'All practice sessions and chat logs';

  @override
  String get del_bullet4 => 'Earned XP, level and streak days';

  @override
  String get del_understood => 'I understand this action cannot be undone.';

  @override
  String del_typeToConfirm(String word) {
    return 'TYPE \"$word\" TO CONFIRM';
  }

  @override
  String get del_deleting => 'Deleting…';

  @override
  String get del_deletePermanent => 'PERMANENTLY DELETE MY ACCOUNT';

  @override
  String onb_error(String error) {
    return 'Onboarding error: $error';
  }

  @override
  String get onb_start => 'Start learning';

  @override
  String get onb_continue => 'Continue';

  @override
  String get onb_welcomeTitle => 'Welcome to VoiceLingo';

  @override
  String get onb_welcomeBody =>
      'Speak. Improve. Repeat.\nYour AI coach guides every conversation.';

  @override
  String get onb_permTitle => 'Two quick permissions';

  @override
  String get onb_permSubtitle => 'We need these to coach you properly.';

  @override
  String get onb_micTitle => 'Microphone';

  @override
  String get onb_micDesc => 'Hear your speech, give feedback on pronunciation.';

  @override
  String get onb_notifDesc => 'Gentle reminders to keep your streak alive.';

  @override
  String get onb_allow => 'Allow';

  @override
  String get onb_goalTitle => 'Your daily goal';

  @override
  String get onb_goalSubtitle => 'How many minutes per day?';

  @override
  String get onb_minSuffix => 'min';

  @override
  String get onb_motivTitle => 'Why are you learning?';

  @override
  String get onb_motivSubtitle =>
      'This helps us pick the right scenarios for you.';

  @override
  String get onb_motivExam => 'Exam';

  @override
  String get onb_motivHobby => 'Hobby';

  @override
  String get onb_charSubtitle =>
      'Each coach has a different voice and style. You can change this anytime in Settings.';

  @override
  String get placement_title => 'Placement Test';

  @override
  String get placement_result => 'Result';

  @override
  String placement_correctCount(int correct) {
    return '$correct / 10 correct';
  }

  @override
  String get conn_offlineBanner =>
      'You are offline. Saved progress will sync later.';

  @override
  String get levelup_title => 'LEVEL UP!';

  @override
  String levelup_body(int level) {
    return 'You\'re doing great! You reached a new level:\nLevel $level';
  }

  @override
  String get levelup_continue => 'CONTINUE';

  @override
  String get quests_title => 'Daily Quests';

  @override
  String quests_completed(int done, int total) {
    return '$done/$total';
  }

  @override
  String quests_xp(int xp) {
    return '+$xp XP';
  }

  @override
  String get quest_learnWords => 'Learn new words';

  @override
  String get quest_reviewWords => 'Review words';

  @override
  String get quest_practiceMinutes => 'Practice';

  @override
  String get quest_conversationTurns => 'Complete conversation turns';

  @override
  String get quest_perfectScore => 'Get a perfect score';
}
