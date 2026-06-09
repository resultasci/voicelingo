// Standalone icon generator — NOT shipped with the app.
//
// Rasterizes the VoiceLingo brand mark (neon speech bubble + voice waveform,
// painted by lib/core/widgets/brand_logo.dart so app and icon never drift)
// to the PNGs consumed by flutter_launcher_icons and the Android splash:
//
//   assets/icon/app_icon.png            1024² opaque cosmic bg, full-bleed
//                                       (legacy Android + iOS source)
//   assets/icon/app_icon_foreground.png 1024² transparent, mark only with a
//                                       ~20% safe margin (Android adaptive fg)
//   android/.../drawable-*dpi/splash_logo.png
//                                       transparent mark for the launch screen
//
// No Windows desktop project is configured, so this is driven from a test
// harness (which provides a headless dart:ui) rather than `flutter run`:
//   flutter test tool/gen_icon_test.dart
// then regenerate launcher icons:
//   dart run flutter_launcher_icons

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:voicelingo/core/widgets/brand_logo.dart';

const _bg = Color(0xFF0A0A0A);
const _bgDeep = Color(0xFF05060A);
const _cyan = BrandLogo.brandCyan;
const _violet = BrandLogo.brandViolet;

/// Renders every brand PNG. Callable from a test harness.
Future<void> generateIcons() async {
  await _writePng('assets/icon/app_icon.png', 1024,
      const _LauncherPainter(background: true, scale: 0.82));
  // Adaptive foreground: transparent bg + safe inset so the launcher mask
  // never clips the bubble.
  await _writePng('assets/icon/app_icon_foreground.png', 1024,
      const _LauncherPainter(background: false, scale: 0.58));

  // Android splash logo (launch_background.xml centers it, no scaling — one
  // PNG per density bucket). ~150dp visual size.
  const densities = {
    'mdpi': 150,
    'hdpi': 225,
    'xhdpi': 300,
    'xxhdpi': 450,
    'xxxhdpi': 600,
  };
  for (final e in densities.entries) {
    await _writePng(
        'android/app/src/main/res/drawable-${e.key}/splash_logo.png',
        e.value.toDouble(),
        const _LauncherPainter(background: false, scale: 1.0));
  }
}

Future<void> _writePng(String path, double size, CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
  painter.paint(canvas, Size(size, size));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('PNG encode failed for $path');
  }
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes.buffer.asUint8List());
}

/// Wraps [BrandMarkPainter] with the cosmic launcher backdrop + scaling.
class _LauncherPainter extends CustomPainter {
  /// Whether to fill the full cosmic background (legacy/iOS) or leave it
  /// transparent (adaptive foreground / splash).
  final bool background;

  /// Mark scale relative to the canvas — < 1 leaves the adaptive safe margin.
  final double scale;

  const _LauncherPainter({required this.background, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    if (background) {
      // Cosmic radial background.
      final bgPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.4, w * 0.35),
          w * 0.85,
          [_bg, _bgDeep],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, w), bgPaint);

      // Color blooms for depth — violet bottom-right, cyan top-left.
      final violetBloom = Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.82, w * 0.85),
          w * 0.65,
          [_violet.withOpacity(0.28), _violet.withOpacity(0)],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, w), violetBloom);
      final cyanBloom = Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.15, w * 0.12),
          w * 0.55,
          [_cyan.withOpacity(0.16), _cyan.withOpacity(0)],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, w), cyanBloom);

      _drawStars(canvas, w);
    }

    // Center the (scaled) mark.
    final markSize = w * scale;
    canvas.save();
    canvas.translate((w - markSize) / 2, (w - markSize) / 2);
    const mark = BrandMarkPainter(bubbleFill: Color(0xFF10141E));
    mark.paint(canvas, Size.square(markSize));
    canvas.restore();
  }

  /// Sparse deterministic star field (LCG — same look on every run).
  void _drawStars(Canvas canvas, double w) {
    int seed = 4242;
    int next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed;
    }

    final paint = Paint();
    for (var i = 0; i < 26; i++) {
      final x = (next() % 1000) / 1000 * w;
      final y = (next() % 1000) / 1000 * w;
      final r = w * (0.002 + (next() % 100) / 100 * 0.004);
      final o = 0.25 + (next() % 100) / 100 * 0.5;
      paint.color = Colors.white.withOpacity(o);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
