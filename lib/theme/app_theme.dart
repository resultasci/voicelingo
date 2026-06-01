import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/perf/device_tier.dart';

// Font asset names (declared in pubspec.yaml). Bundled .ttf — no runtime download.
const _fontDisplay = 'SpaceGrotesk';
const _fontBody = 'Manrope';

/// COSMOS palette — neon cyan + violet on deep space black, with warm orange
/// secondary. Names mirror the design tokens from the Tailwind theme so the
/// mapping stays obvious.
class AppColors {
  // Surfaces
  static const bg = Color(0xFF0A0A0A);
  static const bgSoft = Color(0xFF131313);
  static const bgCard = Color(0xFF1C1B1B);
  static const bgElevated = Color(0xFF201F1F);
  static const surfaceHigh = Color(0xFF2A2A2A);
  static const surfaceHighest = Color(0xFF353534);

  // Ink
  static const ink = Color(0xFFE5E2E1);
  static const inkMuted = Color(0xFFB9CACB);
  static const inkDim = Color(0xFF849495);
  static const rule = Color(0xFF3A494B);

  // Primary (neon cyan)
  static const primary = Color(0xFFE1FDFF);
  static const primaryContainer = Color(0xFF00F2FF);
  static const primaryFixed = Color(0xFF74F5FF);
  static const primaryFixedDim = Color(0xFF00DBE7);
  static const onPrimary = Color(0xFF00363A);

  // Secondary (warm orange — streak)
  static const secondary = Color(0xFFFFB59A);
  static const secondaryContainer = Color(0xFFFF5E07);

  // Tertiary (violet — AI)
  static const tertiary = Color(0xFFFCF5FF);
  static const tertiaryContainer = Color(0xFF7318FF);
  static const tertiaryFixedDim = Color(0xFFD1BCFF);

  // Status
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const success = Color(0xFF74F5FF);
  static const warn = Color(0xFFFFCC66);

  // Legacy aliases kept so older references compile while we migrate.
  static const accent = primaryContainer;
  static const accentSoft = primaryFixed;
  static const sage = primaryFixedDim;
  static const azure = tertiaryFixedDim;
  static const gold = secondary;
  static const danger = error;
}

/// Typography — Space Grotesk for display/labels, Manrope for body.
class AppText {
  static TextStyle display(double size,
          {Color color = AppColors.primary,
          FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: _fontDisplay,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.05,
        letterSpacing: -size * 0.02,
      );

  static TextStyle title(double size,
          {Color color = AppColors.ink, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: _fontDisplay,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.2,
        letterSpacing: -size * 0.012,
      );

  static TextStyle hero(double size,
          {Color color = AppColors.primary,
          FontStyle? style,
          FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: _fontDisplay,
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: color,
        height: 1.05,
        letterSpacing: -size * 0.025,
      );

  static TextStyle body(double size,
          {Color color = AppColors.inkMuted,
          FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: _fontBody,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.55,
      );

  static TextStyle ink(double size,
          {Color color = AppColors.ink, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: _fontBody,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.4,
      );

  /// Uppercase wide-tracked label (Space Grotesk).
  static TextStyle label(double size,
          {Color color = AppColors.inkDim,
          FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontFamily: _fontDisplay,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 2.0,
        height: 1.4,
      );

  /// Mono-ish for codes and tiny meta — falls back to Space Grotesk weight.
  static TextStyle code(double size,
          {Color color = AppColors.inkMuted,
          FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: _fontDisplay,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 1.0,
        height: 1.4,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryContainer,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondaryContainer,
      surface: AppColors.bgCard,
      error: AppColors.error,
    ),
    fontFamily: _fontBody,
    textTheme: ThemeData.dark().textTheme.apply(fontFamily: _fontBody),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppText.label(11, color: AppColors.primaryContainer),
      iconTheme: const IconThemeData(color: AppColors.primaryContainer),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: AppText.ink(13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    ),
  );
}

ThemeData buildLightAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F0F0),
    colorScheme: const ColorScheme.light(
      primary: Color(
          0xFF00B4D8), // Darker version of primaryContainer for light theme
      onPrimary: Colors.white,
      secondary: AppColors.secondaryContainer,
      surface: Colors.white,
      error: AppColors.errorContainer,
    ),
    fontFamily: _fontBody,
    textTheme: ThemeData.light().textTheme.apply(fontFamily: _fontBody),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF0F0F0),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppText.label(11, color: const Color(0xFF00B4D8)),
      iconTheme: const IconThemeData(color: Color(0xFF00B4D8)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: AppText.ink(13, color: Colors.black87),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
    ),
  );
}

// =============================================================================
// COSMIC WIDGETS
// =============================================================================

/// Deep-space background with three soft radial color blooms + a faint star
/// field. Sits behind every screen.
class CosmicBackground extends StatelessWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        gradient: RadialGradient(
          center: Alignment(-0.7, -0.2),
          radius: 1.4,
          colors: [
            Color(0x1400F2FF),
            Color(0x000A0A0A),
          ],
        ),
      ),
      child: Stack(
        children: [
          // RepaintBoundary: static star field, never invalidates due to upstream
          // rebuilds. Without this, parent rebuilds re-rasterize ~30-70 circles.
          const Positioned.fill(
            child: RepaintBoundary(child: _StarField()),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.8, 0.6),
                    radius: 1.0,
                    colors: [
                      Color(0x147318FF),
                      Color(0x000A0A0A),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarFieldPainter());
  }
}

class _StarFieldPainter extends CustomPainter {
  // Tier-aware star count. Generated once per process.
  static final _stars = _generateStars(DevicePerf.starCount);

  static List<_Star> _generateStars(int count) {
    // Deterministic positions using LCG so the field is consistent.
    int seed = 1337;
    int next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed;
    }

    return List.generate(count, (_) {
      final x = (next() % 1000) / 1000;
      final y = (next() % 1000) / 1000;
      final r = 0.4 + (next() % 100) / 100 * 0.9;
      final o = 0.05 + (next() % 100) / 100 * 0.18;
      return _Star(x, y, r, o);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final s in _stars) {
      paint.color = Colors.white.withOpacity(s.opacity);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Star {
  final double x, y, r, opacity;
  _Star(this.x, this.y, this.r, this.opacity);
}

/// Frosted glass card with blur + subtle gradient border.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 16,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.white.withOpacity(0.10);
    final sigma = DevicePerf.glassBlurSigma;

    // Low tier: skip BackdropFilter entirely, fall back to opaque-ish gradient.
    // BackdropFilter samples the entire backing texture each frame; on low-end
    // GPUs this is the single biggest jank source.
    Widget content = Container(
      decoration: BoxDecoration(
        color: sigma == 0
            ? AppColors.bgElevated.withOpacity(0.92)
            : AppColors.bgElevated.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withOpacity(0.15),
              blurRadius: 24,
            ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (sigma > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: content,
      );
    }

    final panel = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: panel,
      ),
    );
  }
}

/// Outline + glow chip used as section labels / status pills.
class NeonChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final EdgeInsets padding;
  const NeonChip({
    super.key,
    required this.text,
    this.icon,
    this.color = AppColors.primaryContainer,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
          ],
          Text(text.toUpperCase(),
              style: AppText.label(10, color: color, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Big neon-glow primary button (cyan).
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final Color color;
  final double height;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.loading = false,
    this.color = AppColors.primaryContainer,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 22,
                spreadRadius: -2,
              ),
            ],
          ),
          height: height,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: AppColors.onPrimary),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label.toUpperCase(),
                        style: AppText.label(12,
                            color: AppColors.onPrimary,
                            weight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outline button used for secondary / destructive (matches "DISCONNECT").
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final double height;
  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = AppColors.primaryContainer,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
              ],
              Text(label.toUpperCase(),
                  style:
                      AppText.label(11, color: color, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cyan-glow underlined input that matches the design's `.neon-input`.
class NeonField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final IconData? leadingIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool readOnly;

  const NeonField({
    super.key,
    required this.controller,
    this.hint,
    this.leadingIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.autofocus = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofocus: autofocus,
      readOnly: readOnly,
      cursorColor: AppColors.primaryContainer,
      style: AppText.ink(15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(14, color: AppColors.inkDim),
        prefixIcon: leadingIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(leadingIcon, size: 20, color: AppColors.rule),
              )
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryContainer, width: 1.5),
        ),
      ),
    );
  }
}

/// Tiny uppercase label with optional leading bar — used in section headers.
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  final bool withRule;

  const SectionLabel(this.text,
      {super.key,
      this.color = AppColors.primaryContainer,
      this.withRule = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (withRule)
          Container(
              width: 24,
              height: 1,
              color: color,
              margin: const EdgeInsets.only(right: 10)),
        Text(text.toUpperCase(),
            style: AppText.label(10, color: color, weight: FontWeight.w700)),
      ],
    );
  }
}

/// Helper for cyan-glow text shadows on hero text.
List<Shadow> neonGlow(Color color, {double blur = 12, double opacity = 0.5}) =>
    [Shadow(color: color.withOpacity(opacity), blurRadius: blur)];
