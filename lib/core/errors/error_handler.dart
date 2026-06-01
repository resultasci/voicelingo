import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_exception.dart';
import '../ai/gemini_service.dart' show AiException;

/// Extracts a localized message from any Object, mapping AppException/AiException
/// down to the `AppL10n` strings.
String getErrorMessage(BuildContext context, Object e) {
  final loc = AppL10n.of(context);

  if (e is AiException) {
    if (e.isRateLimit) return loc.error_rateLimit;
    if (e.isAuth) return loc.auth_error_sessionExpired;
    if (e.statusCode == 413) return loc.error_audioTooLong;
    if (e.statusCode == 502) return loc.error_aiUnavailable;
    // Edge function server generated error string or fallback
    return e.message.isNotEmpty ? e.message : loc.error_serverInvalid;
  }

  if (e is RateLimitException) return loc.error_rateLimit;
  if (e is NetworkException) return loc.error_network;
  if (e is OfflineException) return loc.error_offline;

  if (e is AppException) {
    return e.message.isNotEmpty ? e.message : loc.error_unexpected;
  }

  return loc.error_unexpected;
}

/// Global helper to show a snackbar for any error.
void showErrorSnackbar(BuildContext context, Object error) {
  final msg = getErrorMessage(context, error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
