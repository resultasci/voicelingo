import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/connectivity_banner.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/providers/locale_provider.dart';
import '../core/providers/theme_provider.dart';
import 'router/app_router.dart';
import '../core/theme/app_theme.dart';

/// Kök widget. Bootstrap tamamlandıktan sonra `runApp(ProviderScope(...))`
/// içinden çağrılır; tüm async setup [bootstrap.dart]'a aittir.
class VoiceLingoApp extends ConsumerWidget {
  const VoiceLingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textScale = ref.watch(textScaleProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'VoiceLingo',
      theme: buildLightAppTheme(),
      darkTheme: buildAppTheme(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          // ConnectivityBanner global mount — child'ın üstüne fixed banner.
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: ConnectivityBanner(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
