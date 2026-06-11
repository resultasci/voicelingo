import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';

/// Boot ve kritik akışların süre ölçümü. Release build'de no-op — loglar
/// yalnız dev/profile'da AppLogger üzerinden akar ([DevicePerf] gibi pragmatik,
/// ek bağımlılık yok).
///
/// Kullanım:
///   PerfTrace.markBoot();                  // bootstrap()'ın ilk satırı
///   PerfTrace.mark('env loaded');          // boot'a göre +XXms loglar
///   final done = PerfTrace.span('fetch');  // bağımsız süre; done() loglar
///   PerfTrace.start('turn');               // çok adımlı akış kronometresi
///   PerfTrace.lap('turn', 'reply');        // 'turn.reply +XXms'
class PerfTrace {
  PerfTrace._();

  static final Stopwatch _boot = Stopwatch();
  static final Map<String, Stopwatch> _named = {};

  /// Testlerde release-mode davranışını sabitlemek için; null ise
  /// `!kReleaseMode` geçerlidir.
  @visibleForTesting
  static bool? enabledOverride;

  static bool get _enabled => enabledOverride ?? !kReleaseMode;

  /// Kaydedilen (label, ms) çiftleri — test doğrulaması ve manuel önce/sonra
  /// karşılaştırması için.
  @visibleForTesting
  static final List<(String, int)> marks = [];

  /// Boot kronometresini başlatır; tüm [mark] çağrıları buna göredir.
  static void markBoot() {
    if (!_enabled) return;
    marks.clear();
    _boot
      ..reset()
      ..start();
    _log('boot', 0);
  }

  /// Boot'a göre geçen süreyi loglar. [markBoot] çağrılmadıysa anlamsız değer
  /// üretmemek için sessizce atlanır.
  static void mark(String label) {
    if (!_enabled || !_boot.isRunning) return;
    _log(label, _boot.elapsedMilliseconds);
  }

  /// Bağımsız bir ölçüm başlatır; dönen closure çağrılınca elapsed loglanır.
  static void Function() span(String label) {
    if (!_enabled) return () {};
    final sw = Stopwatch()..start();
    return () => _log(label, sw.elapsedMilliseconds);
  }

  /// Çok adımlı bir akış için adlandırılmış kronometre başlatır.
  static void start(String name) {
    if (!_enabled) return;
    _named[name] = Stopwatch()..start();
  }

  /// [start] edilmiş akışta ara süre loglar; akış yoksa no-op (ör. greeting
  /// gibi turn dışı yollardan gelen çağrılar).
  static void lap(String name, String label) {
    final sw = _named[name];
    if (sw == null) return;
    _log('$name.$label', sw.elapsedMilliseconds);
  }

  /// Adlandırılmış kronometreyi sonlandırır; sonraki [lap]'ler no-op olur.
  static void stop(String name) {
    _named.remove(name)?.stop();
  }

  static void _log(String label, int ms) {
    marks.add((label, ms));
    AppLogger.info('$label +${ms}ms', tag: 'Perf');
  }

  @visibleForTesting
  static void resetForTest() {
    marks.clear();
    _named.clear();
    _boot
      ..stop()
      ..reset();
    enabledOverride = null;
  }
}
