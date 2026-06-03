import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'ai_character.dart';

/// Code-drawn vector avatar for an [AICharacter] — no external image assets.
///
/// Each character gets a deterministic two-color radial gradient (keyed off its
/// id), a neon glow, and an accent ring whose STYLE encodes gender (female =
/// double ring, male = single ring + orbiting dot) so the 3F/3M split reads at a
/// glance. The character's initial sits at the center. Theme-aware via
/// [context.c]; works in both dark and light palettes.
class CharacterAvatar extends StatelessWidget {
  final AICharacter character;
  final double size;
  final bool selected;
  const CharacterAvatar({
    super.key,
    required this.character,
    this.size = 68,
    this.selected = false,
  });

  /// Per-character accent pair. Pulled from the COSMOS palette so the avatars
  /// stay on-brand and distinct. Falls back to cyan/violet for unknown ids.
  static const _accents = <String, (Color, Color)>{
    'lily': (Color(0xFF00F2FF), Color(0xFF7318FF)), // cyan → violet
    'james': (Color(0xFF7318FF), Color(0xFF00A3FF)), // violet → blue
    'maya': (Color(0xFFFF5E07), Color(0xFFFF2E7E)), // orange → pink
    'kai': (Color(0xFF00F2FF), Color(0xFF00FF94)), // cyan → green
    'sarah': (Color(0xFFFF2E7E), Color(0xFF7318FF)), // pink → violet
    'omar': (Color(0xFF00A3FF), Color(0xFF00F2FF)), // blue → cyan
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (a, b) = _accents[character.id] ?? const (Color(0xFF00F2FF), Color(0xFF7318FF));
    final isFemale = character.gender == 'female';
    final ringColor = selected ? c.primaryContainer : a;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring (female = a second, wider halo).
          if (isFemale)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor.withOpacity(selected ? 0.6 : 0.35),
                  width: selected ? 2 : 1.5,
                ),
              ),
            ),
          // Gradient core.
          Container(
            width: size * (isFemale ? 0.78 : 0.86),
            height: size * (isFemale ? 0.78 : 0.86),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 1.0,
                colors: [a, b],
              ),
              border: Border.all(
                color: ringColor.withOpacity(selected ? 0.9 : 0.5),
                width: selected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: a.withOpacity(selected ? 0.55 : 0.3),
                  blurRadius: selected ? 18 : 10,
                  spreadRadius: selected ? 1 : 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              character.displayName.characters.first.toUpperCase(),
              style: AppText.title(
                size * 0.34,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
          ),
          // Male accent: a single small orbiting dot at top-right.
          if (!isFemale)
            Positioned(
              top: size * 0.06,
              right: size * 0.06,
              child: Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor,
                  boxShadow: [
                    BoxShadow(color: ringColor.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
