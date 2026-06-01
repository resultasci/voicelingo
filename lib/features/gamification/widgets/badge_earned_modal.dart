import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../services/badges_service.dart';

/// Rozet kazanıldığında gösterilen modal. Confetti + neon glow + XP info.
///
/// Kullanım:
/// ```dart
/// await BadgeEarnedModal.show(context, award);
/// ```
class BadgeEarnedModal extends StatefulWidget {
  const BadgeEarnedModal(
      {super.key, required this.award, required this.locale});

  final BadgeAwardResult award;
  final String locale;

  static Future<void> show(BuildContext context, BadgeAwardResult award,
      {String locale = 'tr'}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'badge',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) =>
          BadgeEarnedModal(award: award, locale: locale),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      ),
    );
  }

  @override
  State<BadgeEarnedModal> createState() => _BadgeEarnedModalState();
}

class _BadgeEarnedModalState extends State<BadgeEarnedModal> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final award = widget.award;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Confetti layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              maxBlastForce: 18,
              minBlastForce: 6,
              emissionFrequency: 0.06,
              numberOfParticles: 26,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                AppColors.primaryContainer,
                AppColors.secondaryContainer,
                AppColors.tertiary,
                Colors.white,
              ],
            ),
          ),
          // Center card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.4),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.35),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BadgeIcon(icon: award.icon),
                      const SizedBox(height: 18),
                      Text(
                        widget.locale == 'en'
                            ? 'Badge unlocked!'
                            : 'Rozet kazandın!',
                        style: AppText.label(11,
                            color: AppColors.primaryContainer,
                            weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        award.name(widget.locale),
                        textAlign: TextAlign.center,
                        style: AppText.title(22,
                                color: AppColors.ink, weight: FontWeight.w800)
                            .copyWith(
                          shadows: neonGlow(AppColors.primaryContainer,
                              blur: 12, opacity: 0.5),
                        ),
                      ),
                      if (award.xpReward > 0) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: AppColors.tertiary.withOpacity(0.5)),
                          ),
                          child: Text(
                            '+${award.xpReward} XP',
                            style: AppText.label(13,
                                color: AppColors.tertiary,
                                weight: FontWeight.w800),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            widget.locale == 'en' ? 'Awesome' : 'Harika',
                            style: AppText.label(13,
                                color: AppColors.onPrimary,
                                weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon});
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = _resolve(icon);
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            AppColors.primaryContainer,
            AppColors.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.6),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(iconData, size: 48, color: Colors.white),
    );
  }

  IconData _resolve(String? code) {
    switch (code) {
      case 'flame':
        return Icons.local_fire_department;
      case 'book':
        return Icons.menu_book;
      case 'mic':
        return Icons.mic;
      case 'star':
        return Icons.star;
      case 'sun':
        return Icons.wb_sunny_outlined;
      case 'moon':
        return Icons.nightlight_round;
      case 'theater_comedy':
        return Icons.theater_comedy_outlined;
      default:
        return Icons.emoji_events;
    }
  }
}
