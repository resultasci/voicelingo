import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/errors/app_exception.dart';
import 'package:voicelingo/core/errors/error_handler.dart';
import 'package:voicelingo/l10n/generated/app_localizations.dart';

/// getErrorMessage BuildContext üzerinden l10n okur — TR locale'li minimal
/// bir widget pump'layıp context'i yakalıyoruz.
void main() {
  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Builder(builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      }),
    ));
    return captured;
  }

  testWidgets('AiException maps by status code', (tester) async {
    final context = await pumpContext(tester);
    final l = AppL10n.of(context);
    expect(getErrorMessage(context, AiException(429, '')), l.error_rateLimit);
    expect(getErrorMessage(context, AiException(401, '')),
        l.auth_error_sessionExpired);
    expect(
        getErrorMessage(context, AiException(413, '')), l.error_audioTooLong);
    expect(
        getErrorMessage(context, AiException(502, '')), l.error_aiUnavailable);
    expect(getErrorMessage(context, AiException(500, 'server says X')),
        'server says X');
    expect(
        getErrorMessage(context, AiException(500, '')), l.error_serverInvalid);
  });

  testWidgets('typed exceptions map to localized strings', (tester) async {
    final context = await pumpContext(tester);
    final l = AppL10n.of(context);
    expect(getErrorMessage(context, const RateLimitException('x')),
        l.error_rateLimit);
    expect(
        getErrorMessage(context, const NetworkException('x')), l.error_network);
    expect(getErrorMessage(context, const OfflineException()), l.error_offline);
  });

  testWidgets('AppException falls back to its message, unknown to generic',
      (tester) async {
    final context = await pumpContext(tester);
    final l = AppL10n.of(context);
    expect(getErrorMessage(context, const AuthException('Oturum bulunamadı.')),
        'Oturum bulunamadı.');
    expect(getErrorMessage(context, StateError('boom')), l.error_unexpected);
  });
}
