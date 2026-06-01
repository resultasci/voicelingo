import 'package:flutter/material.dart';

/// Real-time ses dalga görselleştirmesi için CustomPainter.
///
/// Kullanım:
/// ```dart
/// AnimatedBuilder(
///   animation: amplitudes, // ValueListenable<List<double>>
///   builder: (_, __) => CustomPaint(
///     painter: WaveformPainter(
///       amplitudes: amplitudes.value,
///       color: AppColors.primaryContainer,
///     ),
///   ),
/// );
/// ```
///
/// [amplitudes] her bir double 0..1 aralığında — yeni örnek listenin sonuna
/// eklenir, eski örnekler düşürülür (FIFO). Caller kendi history buffer'ını
/// yönetir; bu painter sadece dilim çizer.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.amplitudes,
    required this.color,
    this.barWidth = 3.0,
    this.gap = 2.0,
    this.minBarHeight = 4.0,
    this.glow = true,
  });

  final List<double> amplitudes;
  final Color color;
  final double barWidth;
  final double gap;
  final double minBarHeight;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final step = barWidth + gap;
    final maxBars = (size.width / step).floor();
    final visible = amplitudes.length > maxBars
        ? amplitudes.sublist(amplitudes.length - maxBars)
        : amplitudes;

    final centerY = size.height / 2;
    var x = size.width - visible.length * step + gap / 2;

    for (final a in visible) {
      final h =
          (a.clamp(0.0, 1.0) * size.height).clamp(minBarHeight, size.height);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - h / 2, barWidth, h),
        const Radius.circular(2),
      );
      if (glow && a > 0.4) canvas.drawRRect(rect, glowPaint);
      canvas.drawRRect(rect, paint);
      x += step;
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      oldDelegate.amplitudes != amplitudes ||
      oldDelegate.color != color ||
      oldDelegate.barWidth != barWidth;
}
