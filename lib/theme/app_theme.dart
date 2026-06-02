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

/// Theme-aware semantic palette. Mirrors the [AppColors] token names but is
/// resolved per-[ThemeMode] via [ThemeExtension], so the same widget code renders
/// correctly in both dark (Obsidian Void) and light (Solar Flare) themes.
///
/// Access from any widget with `context.c.<token>` (see [PaletteX]). The dark
/// instance reuses the [AppColors] constants so the dark look is unchanged; the
/// light instance is a hand-tuned palette with readable contrast on light surfaces.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  // Surfaces
  final Color bg;
  final Color bgSoft;
  final Color bgCard;
  final Color bgElevated;
  final Color surfaceHigh;
  final Color surfaceHighest;
  // Ink
  final Color ink;
  final Color inkMuted;
  final Color inkDim;
  final Color rule;
  // Primary (neon cyan)
  final Color primary;
  final Color primaryContainer;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color onPrimary;
  // Secondary (warm orange)
  final Color secondary;
  final Color secondaryContainer;
  // Tertiary (violet)
  final Color tertiary;
  final Color tertiaryContainer;
  final Color tertiaryFixedDim;
  // Status
  final Color error;
  final Color errorContainer;
  final Color success;
  final Color warn;
  // Whether this palette is the dark variant — lets widgets soften glows/blooms
  // in light mode without hardcoding a brightness check.
  final bool isDark;

  const AppPalette({
    required this.bg,
    required this.bgSoft,
    required this.bgCard,
    required this.bgElevated,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.ink,
    required this.inkMuted,
    required this.inkDim,
    required this.rule,
    required this.primary,
    required this.primaryContainer,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.tertiaryFixedDim,
    required this.error,
    required this.errorContainer,
    required this.success,
    required this.warn,
    required this.isDark,
  });

  // Legacy aliases (kept so migrated call sites can still resolve old names).
  Color get accent => primaryContainer;
  Color get accentSoft => primaryFixed;
  Color get sage => primaryFixedDim;
  Color get azure => tertiaryFixedDim;
  Color get gold => secondary;
  Color get danger => error;

  /// Obsidian Void — original dark palette (unchanged values via [AppColors]).
  static const dark = AppPalette(
    bg: AppColors.bg,
    bgSoft: AppColors.bgSoft,
    bgCard: AppColors.bgCard,
    bgElevated: AppColors.bgElevated,
    surfaceHigh: AppColors.surfaceHigh,
    surfaceHighest: AppColors.surfaceHighest,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    inkDim: AppColors.inkDim,
    rule: AppColors.rule,
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryContainer,
    primaryFixed: AppColors.primaryFixed,
    primaryFixedDim: AppColors.primaryFixedDim,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryContainer,
    tertiary: AppColors.tertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    tertiaryFixedDim: AppColors.tertiaryFixedDim,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    success: AppColors.success,
    warn: AppColors.warn,
    isDark: true,
  );

  /// Solar Flare — hand-tuned light palette. Keeps the cyan/violet/orange
  /// identity but darkens accents and inverts surfaces for contrast on light bg.
  static const light = AppPalette(
    bg: Color(0xFFF4F6F8),
    bgSoft: Color(0xFFEDF0F3),
    bgCard: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE7EBEF),
    surfaceHighest: Color(0xFFDCE2E7),
    ink: Color(0xFF11181C),
    inkMuted: Color(0xFF3E4A50),
    inkDim: Color(0xFF6B767C),
    rule: Color(0xFFC2CCD2),
    primary: Color(0xFF004E57),
    primaryContainer: Color(0xFF008CA6),
    primaryFixed: Color(0xFF1FA9C2),
    primaryFixedDim: Color(0xFF00798F),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC1410B),
    secondaryContainer: Color(0xFFE25400),
    tertiary: Color(0xFF4A2A86),
    tertiaryContainer: Color(0xFF6B26D9),
    tertiaryFixedDim: Color(0xFF7E5FC4),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFF93000A),
    success: Color(0xFF0E7A5F),
    warn: Color(0xFFB26A00),
    isDark: false,
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? bgSoft,
    Color? bgCard,
    Color? bgElevated,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? ink,
    Color? inkMuted,
    Color? inkDim,
    Color? rule,
    Color? primary,
    Color? primaryContainer,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? onPrimary,
    Color? secondary,
    Color? secondaryContainer,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? tertiaryFixedDim,
    Color? error,
    Color? errorContainer,
    Color? success,
    Color? warn,
    bool? isDark,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      bgSoft: bgSoft ?? this.bgSoft,
      bgCard: bgCard ?? this.bgCard,
      bgElevated: bgElevated ?? this.bgElevated,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkDim: inkDim ?? this.inkDim,
      rule: rule ?? this.rule,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      success: success ?? this.success,
      warn: warn ?? this.warn,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSoft: Color.lerp(bgSoft, other.bgSoft, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkDim: Color.lerp(inkDim, other.inkDim, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      primaryFixedDim: Color.lerp(primaryFixedDim, other.primaryFixedDim, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryContainer: Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      tertiaryFixedDim: Color.lerp(tertiaryFixedDim, other.tertiaryFixedDim, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Short accessor: `context.c.bg` resolves the active [AppPalette].
extension PaletteX on BuildContext {
  AppPalette get c => Theme.of(this).extension<AppPalette>()!;
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
    extensions: const [AppPalette.dark],
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
    extensions: const [AppPalette.light],
    scaffoldBackgroundColor: AppPalette.light.bg,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF008CA6), // light primaryContainer
      onPrimary: Colors.white,
      secondary: Color(0xFFE25400),
      surface: Colors.white,
      error: Color(0xFFBA1A1A),
    ),
    fontFamily: _fontBody,
    textTheme: ThemeData.light().textTheme.apply(fontFamily: _fontBody),
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.light.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppText.label(11, color: AppPalette.light.primaryContainer),
      iconTheme: const IconThemeData(color: Color(0xFF008CA6)),
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
    final palette = context.c;
    final dark = palette.isDark;
    // Bloom tints: cyan top-left, violet bottom-right — softer in light mode.
    final cyanBloom = dark ? const Color(0x1400F2FF) : const Color(0x0F008CA6);
    final violetBloom = dark ? const Color(0x147318FF) : const Color(0x0D6B26D9);
    final fade = palette.bg.withOpacity(0);
    return Container(
      decoration: BoxDecoration(
        color: palette.bg,
        gradient: RadialGradient(
          center: const Alignment(-0.7, -0.2),
          radius: 1.4,
          colors: [cyanBloom, fade],
        ),
      ),
      child: Stack(
        children: [
          // RepaintBoundary: static star field, never invalidates due to upstream
          // rebuilds. Only rendered on dark surfaces (white stars vanish on light).
          if (dark)
            const Positioned.fill(
              child: RepaintBoundary(child: _StarField()),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, 0.6),
                    radius: 1.0,
                    colors: [violetBloom, fade],
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
    final palette = context.c;
    final border = borderColor ??
        (palette.isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.black.withOpacity(0.08));
    final sigma = DevicePerf.glassBlurSigma;

    // Low tier: skip BackdropFilter entirely, fall back to opaque-ish gradient.
    // BackdropFilter samples the entire backing texture each frame; on low-end
    // GPUs this is the single biggest jank source.
    Widget content = Container(
      decoration: BoxDecoration(
        color: sigma == 0
            ? palette.bgElevated.withOpacity(0.92)
            : palette.bgElevated.withOpacity(0.6),
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
  final Color? color;
  final EdgeInsets padding;
  const NeonChip({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.c.primaryContainer;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 6),
          ],
          Text(text.toUpperCase(),
              style: AppText.label(10, color: accent, weight: FontWeight.w700)),
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
  final Color? color;
  final double height;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.loading = false,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.c.primaryContainer;
    final onAccent = context.c.onPrimary;
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.4),
                blurRadius: 22,
                spreadRadius: -2,
              ),
            ],
          ),
          height: height,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: onAccent),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: onAccent),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label.toUpperCase(),
                        style: AppText.label(12,
                            color: onAccent,
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
  final Color? color;
  final double height;
  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.c.primaryContainer;
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
            border: Border.all(color: accent.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 8),
              ],
              Text(label.toUpperCase(),
                  style:
                      AppText.label(11, color: accent, weight: FontWeight.w700)),
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
    final palette = context.c;
    final hairline = palette.isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.08);
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofocus: autofocus,
      readOnly: readOnly,
      cursorColor: palette.primaryContainer,
      style: AppText.ink(15, color: palette.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(14, color: palette.inkDim),
        prefixIcon: leadingIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(leadingIcon, size: 20, color: palette.rule),
              )
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: palette.surfaceHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: palette.primaryContainer, width: 1.5),
        ),
      ),
    );
  }
}

/// Tiny uppercase label with optional leading bar — used in section headers.
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final bool withRule;

  const SectionLabel(this.text,
      {super.key, this.color, this.withRule = true});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.c.primaryContainer;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (withRule)
          Container(
              width: 24,
              height: 1,
              color: accent,
              margin: const EdgeInsets.only(right: 10)),
        Text(text.toUpperCase(),
            style: AppText.label(10, color: accent, weight: FontWeight.w700)),
      ],
    );
  }
}

/// Helper for cyan-glow text shadows on hero text.
List<Shadow> neonGlow(Color color, {double blur = 12, double opacity = 0.5}) =>
    [Shadow(color: color.withOpacity(opacity), blurRadius: blur)];
