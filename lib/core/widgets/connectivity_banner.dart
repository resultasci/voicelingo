import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// App'in her yerinde, üst banner. Çevrimdışıyken görünür, online iken gizli.
///
/// Kullanım: [VoiceLingoApp] builder içinde child'ın üstüne stack'lenir veya
/// individual screen'lerin appbar altında gösterilir. Şimdilik standalone widget.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final statusAsync = ref.watch(connectivityStatusProvider);
    final online = statusAsync.value ?? true;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axisAlignment: -1,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: online
          ? const SizedBox.shrink(key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: c.warn.withOpacity(0.18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, color: c.warn, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppL10n.of(context).conn_offlineBanner,
                      style: AppText.label(11,
                          color: c.warn, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
