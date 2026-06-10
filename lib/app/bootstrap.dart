import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/logger/app_logger.dart';
import '../core/storage/hive_boxes.dart';
import '../core/services/notification_service.dart';
import '../core/services/settings_service.dart';
import '../core/theme/app_theme.dart';
import 'app.dart';

/// Uygulamanın async başlatma akışı. `main()` sadece bunu çağırır.
///
/// Bağımlılık grafı:
///   - Binding + system UI (sync)
///   - .env (Env.* erişiminin önkoşulu — zorunlu ilk await)
///   - PARALEL grup: SettingsService, Hive (init+openAll), NotificationService, Supabase
///     (hiçbiri birbirine bağımlı değil; sadece .env'e bağımlı)
///   - Sentry (varsa) → runApp
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ErrorWidget'ı production'da gizli, dev'de okunaklı yap.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (Env.isProduction) {
      return const ColoredBox(color: Color(0xFF0A0A1A));
    }
    return Material(
      color: const Color(0xFF1A0F2E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '⚠️ Render hatası:\n${details.exceptionAsString()}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgCard,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 1) .env (zorunlu ilk; Env getter'ları bunu okur)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Note: To use proper l10n here without BuildContext, we just rely on static defaults
    // because BootErrorApp is meant for developer machine boot failures usually.
    runApp(BootErrorApp(
      title: '.env yüklenemedi',
      details: '.env dosyası proje kökünde bulunmuyor veya okunamadı. '
          'Lütfen örnek dosyayı (.env.example) kopyalayıp gerekli anahtarları '
          'doldurun.\n\nHata: $e',
    ));
    return;
  }

  // 2) Required env keys (sync read)
  final String supabaseUrl;
  final String supabaseAnonKey;
  try {
    supabaseUrl = Env.supabaseUrl;
    supabaseAnonKey = Env.supabaseAnonKey;
  } on EnvException catch (e) {
    runApp(BootErrorApp(title: 'Yapılandırma eksik', details: e.message));
    return;
  }

  // 3) PARALEL: üç bağımsız init aynı anda. Önceki sıralı await zinciri
  // ~1500-2500ms; paralel ile ~en yavaş tek adım kadar (genelde Supabase).
  // Settings → Notification zinciri kendi Future'ında sıralı (ikincisi
  // birincinin instance'ına bağımlı), diğerleriyle paralel.
  late final SettingsService settings;
  late final NotificationService notifications;
  await Future.wait<void>([
    Future(() async {
      settings = await SettingsService.create();
      notifications = NotificationService(settings);
      await notifications.init();
    }),
    Future(() async {
      await Hive.initFlutter();
      await HiveBoxes.openAll();
    }),
    Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey),
  ]);

  // 4) Sentry wrapper + runApp. Servis instance'ları ProviderScope override'ı
  // ile yayınlanır — provider'ların kendisi UnimplementedError fırlatır.
  Future<void> bootApp() async {
    runApp(ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settings),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const VoiceLingoApp(),
    ));
  }

  if (Env.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDsn;
        options.tracesSampleRate = Env.isProduction ? 0.1 : 0.2;
        options.release = 'voicelingo@${Env.appVersion}';
        options.environment = Env.appEnv;
      },
      appRunner: () async {
        _installGlobalErrorHandlers();
        _wireAuthUserToSentry();
        await bootApp();
      },
    );
  } else {
    await bootApp();
  }
}

/// Yakalanmamış Flutter framework + async Dart hatalarını Sentry'ye iletir.
/// Sentry init'in çağrıldığı `appRunner` içinde çağrılmalı — `Sentry.captureException`
/// init'ten önce no-op olur.
void _installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
        'Yakalanmayan Flutter hatası', details.exception, details.stack);
    FlutterError.presentError(details);
    Sentry.captureException(details.exception, stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Yakalanmayan asenkron Dart hatası', error, stack);
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };
}

/// Auth state değiştikçe Sentry user context'i güncel tutar.
void _wireAuthUserToSentry() {
  void apply(User? u) {
    if (u == null) {
      Sentry.configureScope((scope) => scope.setUser(null));
    } else {
      Sentry.configureScope(
          (scope) => scope.setUser(SentryUser(id: u.id, email: u.email)));
    }
  }

  apply(Supabase.instance.client.auth.currentUser);
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    apply(data.session?.user);
  });
}

/// Boot sırasında oluşan kritik hataları (env eksik vb.) gösteren minimal app.
/// MaterialApp dışında tutulmuş — theme bile yüklenmemiş olabilir.
class BootErrorApp extends StatelessWidget {
  const BootErrorApp({super.key, required this.title, required this.details});
  final String title;
  final String details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFFF5E07), size: 56),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
