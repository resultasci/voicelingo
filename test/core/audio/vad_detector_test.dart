import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/audio/vad_detector.dart';

void main() {
  group('VadDetector', () {
    test('calibration phase emits no events', () async {
      final vad = VadDetector(
        calibrationDuration: const Duration(milliseconds: 100),
      );
      final events = <VadEvent>[];
      final sub = vad.events.listen(events.add);

      vad.reset();
      for (var i = 0; i < 5; i++) {
        vad.onAmplitude(-40.0);
      }

      await Future.delayed(const Duration(milliseconds: 10));
      expect(events, isEmpty);
      expect(vad.isCalibrated, isFalse);

      await sub.cancel();
      await vad.dispose();
    });

    test('dbToNormalized clamps and maps lineer', () {
      expect(VadDetector.dbToNormalized(-100.0), 0.0);
      expect(VadDetector.dbToNormalized(0.0), 1.0);
      // -22.5 dB → orta nokta civarı
      final mid = VadDetector.dbToNormalized(-22.5);
      expect(mid, greaterThan(0.3));
      expect(mid, lessThan(0.9));
    });

    test('reset clears state', () {
      final vad = VadDetector();
      vad.reset();
      expect(vad.hasDetectedSpeech, isFalse);
      expect(vad.isCalibrated, isFalse);
    });
  });
}
