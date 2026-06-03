// Standalone icon generator — NOT shipped with the app.
//
// Draws the VoiceLingo brand mark (neon-cyan globe + a voice/sound accent on a
// deep cosmic background) with a CustomPainter and rasterizes it to PNG via
// dart:ui. Produces two files consumed by flutter_launcher_icons:
//
//   assets/icon/app_icon.png            1024² opaque cosmic bg, full-bleed
//                                       (legacy Android + iOS source)
//   assets/icon/app_icon_foreground.png 1024² transparent, mark only with a
//                                       ~20% safe margin (Android adaptive fg)
//
// No Windows desktop project is configured, so this is driven from a test
// harness (which provides a headless dart:ui) rather than `flutter run`:
//   flutter test tool/gen_icon_test.dart
// then regenerate launcher icons:
//   dart run flutter_launcher_icons

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const _bg = Color(0xFF0A0A0A);
const _bgDeep = Color(0xFF05060A);
const _cyan = Color(0xFF00F2FF);
const _violet = Color(0xFF7318FF);

/// Renders both icon PNGs into assets/icon/. Callable from a test harness.
Future<void> generateIcons() async {
  await writeIconPng('assets/icon/app_icon.png',
      const IconPainter(background: true, scale: 1.0));
  // Adaptive foreground: transparent bg + ~20% safe inset so the launcher mask
  // never clips the globe.
  await writeIconPng('assets/icon/app_icon_foreground.png',
      const IconPainter(background: false, scale: 0.66));
}

Future<void> writeIconPng(String path, CustomPainter painter) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
  painter.paint(canvas, const Size(size, size));
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

class IconPainter extends CustomPainter {
  /// Whether to fill the full cosmic background (legacy/iOS) or leave it
  /// transparent (adaptive foreground).
  final bool background;

  /// Mark scale relative to the canvas — < 1 leaves the adaptive safe margin.
  final double scale;

  const IconPainter({required this.background, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, w / 2);

    if (background) {
      // Cosmic radial background.
      final bgPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.4, w * 0.35),
          w * 0.85,
          [_bg, _bgDeep],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, w), bgPaint);

      // Faint violet bloom bottom-right for depth.
      final bloom = Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.8, w * 0.82),
          w * 0.6,
          [_violet.withOpacity(0.22), _violet.withOpacity(0)],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, w), bloom);
    }

    final r = w * 0.30 * scale; // globe radius

    // Outer neon glow halo.
    final glow = Paint()
      ..color = _cyan.withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05 * scale);
    canvas.drawCircle(center, r * 1.02, glow);

    // Globe disc — cyan → violet gradient.
    final disc = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-r * 0.3, -r * 0.35),
        r * 1.4,
        [_cyan, _violet],
      );
    canvas.drawCircle(center, r, disc);

    // Globe outline.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012 * scale
      ..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(center, r, outline);

    _drawMeridians(canvas, center, r, w);
    _drawSoundWaves(canvas, center, r, w);
  }

  /// Latitude/longitude arcs that read as a globe.
  void _drawMeridians(Canvas canvas, Offset c, double r, double w) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.009 * scale
      ..color = Colors.white.withOpacity(0.7);

    // Equator + two latitudes (ellipses flattened vertically).
    for (final f in [0.0, 0.5, -0.5]) {
      final rect = Rect.fromCenter(
        center: c.translate(0, f * r),
        width: r * 2 * math.sqrt(1 - f * f),
        height: r * 0.5 * (1 - f.abs() * 0.4),
      );
      canvas.drawOval(rect, line);
    }
    // Central meridian (vertical) + two longitudes (ellipses flattened horiz).
    for (final fw in [1.0, 0.55]) {
      final rect = Rect.fromCenter(
        center: c,
        width: r * 2 * (fw == 1.0 ? 0.42 : 1.0),
        height: r * 2,
      );
      if (fw == 1.0) {
        // vertical center line
        canvas.drawLine(c.translate(0, -r), c.translate(0, r), line);
      } else {
        canvas.drawOval(rect, line);
      }
    }
  }

  /// Voice accent — three concentric "sound wave" arcs to the right of the
  /// globe, signaling speech/voice.
  void _drawSoundWaves(Canvas canvas, Offset c, double r, double w) {
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = _cyan;
    final origin = c.translate(r * 0.92, -r * 0.05);
    for (var i = 1; i <= 3; i++) {
      wave.strokeWidth = w * 0.018 * scale * (1 - i * 0.12);
      wave.color = _cyan.withOpacity(1.0 - (i - 1) * 0.28);
      final rect = Rect.fromCircle(center: origin, radius: r * 0.28 * i);
      // arc opening to the right (-50°..+50°)
      canvas.drawArc(rect, -0.9, 1.8, false, wave);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
