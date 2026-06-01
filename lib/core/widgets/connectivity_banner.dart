import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import '../../theme/app_theme.dart';

/// App'in her yerinde, üst banner. Çevrimdışıyken görünür, online iken gizli.
///
/// Kullanım: [VoiceLingoApp] builder içinde child'ın üstüne stack'lenir veya
/// individual screen'lerin appbar altında gösterilir. Şimdilik standalone widget.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, this.locale = 'tr'});
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              color: AppColors.warn.withOpacity(0.18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: AppColors.warn, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale == 'en'
                          ? 'You are offline. Saved progress will sync later.'
                          : 'Çevrimdışısın. İlerlemen bağlanınca senkronize olur.',
                      style: AppText.label(11,
                          color: AppColors.warn, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
