import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Uygulamanın standart bottom sheet kabuğu: şeffaf arka plan, klavyeyle
/// yukarı itilen padding, GlassPanel ve sürükleme tutamacı.
///
/// [builder] panel içeriğini döner; tutamaç ve panel bu helper'a aittir.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  Color? glowColor,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final c = ctx.c;
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          glowColor: glowColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: c.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              builder(ctx),
            ],
          ),
        ),
      );
    },
  );
}
