import 'dart:io';
import 'package:flutter/foundation.dart';

/// Cihaz performans sınıfı — heavy efekt (blur, particle, animation) bütçesini
/// ayarlamak için kullanılır. Heuristic; runtime'da tek seferlik hesaplanır
/// ([DevicePerf.detect] çağrısıyla).
enum DeviceTier { low, mid, high }

class DevicePerf {
  static DeviceTier? _cached;

  /// Tek seferlik tier hesaplama. Dart'tan RAM/CPU sorgulama yok, bu yüzden
  /// platform + debug mode ile pragmatik bir tahmin yapıyoruz.
  static DeviceTier detect() {
    if (_cached != null) return _cached!;
    if (kIsWeb) return _cached = DeviceTier.high;
    if (Platform.isIOS) return _cached = DeviceTier.high;
    if (Platform.isAndroid) {
      if (kDebugMode) return _cached = DeviceTier.mid;
      return _cached = DeviceTier.high;
    }
    return _cached = DeviceTier.high;
  }

  @visibleForTesting
  static void overrideTier(DeviceTier? tier) {
    _cached = tier;
  }

  /// Yıldız sayısı bütçesi.
  static int get starCount {
    switch (detect()) {
      case DeviceTier.low:
        return 15;
      case DeviceTier.mid:
        return 30;
      case DeviceTier.high:
        return 70;
    }
  }

  /// GlassPanel blur sigma. Low tier'da blur tamamen kapatılır.
  static double get glassBlurSigma {
    switch (detect()) {
      case DeviceTier.low:
        return 0;
      case DeviceTier.mid:
        return 8;
      case DeviceTier.high:
        return 16;
    }
  }

  /// AppBar/BottomNav blur sigma (daha geniş alan = daha pahalı).
  static double get chromeBlurSigma {
    switch (detect()) {
      case DeviceTier.low:
        return 0;
      case DeviceTier.mid:
        return 12;
      case DeviceTier.high:
        return 20;
    }
  }
}
