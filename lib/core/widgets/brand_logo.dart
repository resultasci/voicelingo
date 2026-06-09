import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// VoiceLingo brand mark — a neon speech bubble holding a voice waveform.
///
/// Single source of truth for the logo: the launcher icon generator
/// (tool/gen_icon.dart), the Android splash PNGs and every in-app usage all
/// paint through [BrandMarkPainter], so the brand stays pixel-identical
/// everywhere. Code-drawn (no image assets) → crisp at any size, theme-aware.
class BrandLogo extends StatelessWidget {
  final double size;

  /// Waveform/stroke gradient start (defaults to brand cyan).
  final Color? colorA;

  /// Waveform/stroke gradient end (defaults to brand violet).
  final Color? colorB;

  /// Paint a soft outer glow behind the bubble.
  final bool glow;

  const BrandLogo({
    super.key,
    this.size = 56,
    this.colorA,
    this.colorB,
    this.glow = true,
  });

  static const brandCyan = Color(0xFF00F2FF);
  static const brandViolet = Color(0xFF7318FF);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: BrandMarkPainter(
          colorA: colorA ?? brandCyan,
          colorB: colorB ?? brandViolet,
          glow: glow,
        ),
      ),
    );
  }
}

/// Paints the speech-bubble + waveform mark filling [Size] (square assumed).
/// Transparent background — callers draw their own backdrop when needed.
class BrandMarkPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;
  final bool glow;

  /// Optional fill behind the waveform (used by the launcher icon so the
  /// bubble reads as a solid object on any wallpaper). Null = translucent.
  final Color? bubbleFill;

  const BrandMarkPainter({
    this.colorA = BrandLogo.brandCyan,
    this.colorB = BrandLogo.brandViolet,
    this.glow = true,
    this.bubbleFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.shortestSide;
    final bubble = _bubblePath(w);
    final strokeW = w * 0.052;

    final gradient = ui.Gradient.linear(
      Offset(w * 0.12, w * 0.2),
      Offset(w * 0.9, w * 0.85),
      [colorA, colorB],
    );

    // Soft neon halo behind everything.
    if (glow) {
      final halo = Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.045);
      canvas.drawPath(bubble, halo);
    }

    // Bubble fill — keeps the waveform legible over busy backgrounds.
    final fill = Paint()
      ..color = bubbleFill ?? const Color(0xFF0B1018).withOpacity(0.55);
    canvas.drawPath(bubble, fill);

    // Gradient bubble outline.
    final stroke = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bubble, stroke);

    _drawWaveform(canvas, w, gradient);
  }

  /// Rounded speech bubble with a smooth tail at the bottom-left.
  Path _bubblePath(double w) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.08, w * 0.10, w * 0.92, w * 0.72),
      Radius.circular(w * 0.21),
    );
    final path = Path()..addRRect(body);
    // Tail: starts on the bottom edge, sweeps down-left to a rounded point.
    final tail = Path()
      ..moveTo(w * 0.22, w * 0.66)
      ..quadraticBezierTo(w * 0.22, w * 0.84, w * 0.14, w * 0.93)
      ..quadraticBezierTo(w * 0.30, w * 0.90, w * 0.40, w * 0.715)
      ..close();
    return Path.combine(PathOperation.union, path, tail);
  }

  /// Five rounded waveform bars — the "voice" inside the bubble.
  void _drawWaveform(Canvas canvas, double w, ui.Shader gradient) {
    const xs = [0.28, 0.39, 0.50, 0.61, 0.72];
    const hs = [0.14, 0.26, 0.40, 0.26, 0.14];
    final cy = w * 0.41;
    final barW = w * 0.062;

    final bar = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = barW
      ..strokeCap = StrokeCap.round;

    if (glow) {
      final barGlow = Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.03);
      for (var i = 0; i < xs.length; i++) {
        final x = xs[i] * w;
        final h = hs[i] * w / 2;
        canvas.drawLine(Offset(x, cy - h), Offset(x, cy + h), barGlow);
      }
    }

    for (var i = 0; i < xs.length; i++) {
      final x = xs[i] * w;
      final h = hs[i] * w / 2;
      canvas.drawLine(Offset(x, cy - h), Offset(x, cy + h), bar);
    }
  }

  @override
  bool shouldRepaint(covariant BrandMarkPainter oldDelegate) =>
      oldDelegate.colorA != colorA ||
      oldDelegate.colorB != colorB ||
      oldDelegate.glow != glow ||
      oldDelegate.bubbleFill != bubbleFill;
}
