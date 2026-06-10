import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tek satırlık, tema-duyarlı snackbar kısayolları — ekranlarda kopyalanan
/// `ScaffoldMessenger...SnackBar(AppText.ink(...))` bloklarının yerine.
void showErrorSnack(BuildContext context, String message) =>
    _show(context, message, context.c.error);

void showWarnSnack(BuildContext context, String message) =>
    _show(context, message, context.c.warn);

void showSuccessSnack(BuildContext context, String message) =>
    _show(context, message, context.c.primaryContainer);

void _show(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: AppText.ink(13, color: color)),
    ),
  );
}
