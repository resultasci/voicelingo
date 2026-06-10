import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

class LevelUpDialog extends StatefulWidget {
  final int level;
  final VoidCallback onDismiss;

  const LevelUpDialog({
    super.key,
    required this.level,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, int level) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return LevelUpDialog(
          level: level,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          ),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Cinematic confetti — yukarıdan iner, geniş yelpaze.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              maxBlastForce: 22,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 32,
              gravity: 0.22,
              shouldLoop: false,
              colors: [
                c.primaryContainer,
                c.secondaryContainer,
                c.tertiary,
                Colors.white,
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GlassPanel(
                borderColor: c.primaryContainer.withOpacity(0.5),
                glowColor: c.primaryContainer,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.network(
                        'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json',
                        repeat: false,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.star_rounded,
                            color: c.primaryContainer,
                            size: 100,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.levelup_title,
                      style: AppText.hero(28,
                              color: c.primaryContainer,
                              weight: FontWeight.w800)
                          .copyWith(
                        shadows: neonGlow(c.primaryContainer,
                            blur: 16, opacity: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.levelup_body(widget.level),
                      style: AppText.body(15, color: c.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: GhostButton(
                        label: l.levelup_continue,
                        icon: Icons.rocket_launch,
                        color: c.primaryContainer,
                        onTap: widget.onDismiss,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
