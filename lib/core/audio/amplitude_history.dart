import 'package:flutter/foundation.dart';

import 'vad_detector.dart';

/// Real-time ses amplitude'larını sabit boyutlu pencere içinde tutar.
///
/// `record` paketinden gelen dB değerlerini normalize edip [bufferSize] kadar
/// son örneği tutar. Widget'lar `ValueListenable<List<double>>` olarak dinler
/// ve [WaveformPainter]'a aktarır.
class AmplitudeHistory extends ValueNotifier<List<double>> {
  AmplitudeHistory({this.bufferSize = 60}) : super(const []);

  final int bufferSize;

  /// dBFS değerini ekle (negatif, 0=clipping).
  void addDb(double db) {
    final normalized = VadDetector.dbToNormalized(db);
    final next = [...value, normalized];
    if (next.length > bufferSize) {
      next.removeRange(0, next.length - bufferSize);
    }
    value = next;
  }

  void clear() {
    value = const [];
  }
}
