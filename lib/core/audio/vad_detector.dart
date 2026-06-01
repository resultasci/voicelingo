import 'dart:async';
import 'dart:math' as math;

/// Voice Activity Detection.
///
/// `record` paketinin `onAmplitudeChanged` stream'i dBFS değerleri verir
/// (genelde -45 ila -10 arası; -45 = sessiz, 0 = clipping). Bu sınıf bu stream'i
/// emer ve adaptif threshold ile konuşma/sessizlik geçişlerini tespit eder.
///
/// Algoritma:
///   1. İlk [calibrationDuration] kadar süre baseline gürültü ortalaması ölçülür.
///   2. Threshold = baseline + [thresholdMargin]
///   3. Threshold üstüne çıkan örnek = "konuşma var"
///   4. [silenceTimeout] kadar threshold altında kalırsa onSpeechEnded tetiklenir.
///   5. [maxDuration]'ı aşan kayıt force-stop edilir.
///
/// Algoritma dış bağımlılığı yok — sadece amplitude double'ı tüketir. Test edilebilir.
class VadDetector {
  VadDetector({
    this.calibrationDuration = const Duration(milliseconds: 500),
    this.silenceTimeout = const Duration(milliseconds: 1500),
    this.maxDuration = const Duration(seconds: 30),
    this.thresholdMargin = 10.0,
    this.fallbackThresholdDb = -35.0,
  });

  /// İlk N ms baseline kalibrasyon süresi.
  final Duration calibrationDuration;

  /// Bu süre boyunca threshold altında kalınırsa konuşma bitti sayılır.
  final Duration silenceTimeout;

  /// Tek bir kayıt maksimum süresi.
  final Duration maxDuration;

  /// Baseline gürültüye eklenecek margin (dB). Daha büyük = daha az hassas.
  final double thresholdMargin;

  /// Hiç ses gelmezse veya kalibrasyon hatalıysa kullanılacak fallback (dB).
  final double fallbackThresholdDb;

  // --- runtime state ---
  final List<double> _calibrationSamples = [];
  DateTime? _startedAt;
  DateTime? _lastSpeechAt;
  double? _activeThreshold;
  bool _hasDetectedSpeech = false;

  final _eventCtrl = StreamController<VadEvent>.broadcast();
  Stream<VadEvent> get events => _eventCtrl.stream;

  /// Yeni bir kayıt başlatırken çağır.
  void reset() {
    _calibrationSamples.clear();
    _startedAt = DateTime.now();
    _lastSpeechAt = null;
    _activeThreshold = null;
    _hasDetectedSpeech = false;
  }

  /// `record` paketinin `onAmplitudeChanged` stream'inden gelen her örnek için çağır.
  /// [db] dBFS biriminde (negatif, 0 = clipping).
  void onAmplitude(double db) {
    final now = DateTime.now();
    final started = _startedAt;
    if (started == null) {
      reset();
      return;
    }

    final elapsed = now.difference(started);

    // 1) Max duration check
    if (elapsed > maxDuration) {
      _emit(VadEvent.maxDurationReached);
      return;
    }

    // 2) Calibration phase
    if (elapsed < calibrationDuration) {
      _calibrationSamples.add(db);
      return;
    }

    // 3) Threshold computation (lazy, first time after calibration)
    _activeThreshold ??= _computeThreshold();

    final threshold = _activeThreshold!;
    final isSpeech = db > threshold;

    if (isSpeech) {
      if (!_hasDetectedSpeech) {
        _hasDetectedSpeech = true;
        _emit(VadEvent.speechStarted);
      }
      _lastSpeechAt = now;
    } else if (_hasDetectedSpeech) {
      final lastSpeech = _lastSpeechAt;
      if (lastSpeech != null && now.difference(lastSpeech) >= silenceTimeout) {
        _emit(VadEvent.speechEnded);
      }
    }
  }

  double _computeThreshold() {
    if (_calibrationSamples.isEmpty) return fallbackThresholdDb;
    // Median'ı al; outlier'lara karşı ortalamadan daha sağlam.
    final sorted = [..._calibrationSamples]..sort();
    final median = sorted[sorted.length ~/ 2];
    final candidate = median + thresholdMargin;
    // Mantıksız uç değerleri kıs
    return candidate.clamp(-50.0, -5.0);
  }

  void _emit(VadEvent event) {
    if (_eventCtrl.isClosed) return;
    _eventCtrl.add(event);
  }

  Future<void> dispose() async {
    await _eventCtrl.close();
  }

  // ---- diagnostic getters (test/debug için) ----
  bool get isCalibrated => _activeThreshold != null;
  double? get currentThresholdDb => _activeThreshold;
  bool get hasDetectedSpeech => _hasDetectedSpeech;

  /// Faydalı test/UI: en son sample SqRMS olarak normalize edilmiş 0..1.
  static double dbToNormalized(double db) {
    // -45 dB = 0, 0 dB = 1; lineer haritalama, clamp.
    final v = ((db + 45) / 45).clamp(0.0, 1.0);
    // Logaritmik mapping daha doğal görünür
    return math.pow(v, 0.5).toDouble();
  }
}

enum VadEvent { speechStarted, speechEnded, maxDurationReached }
