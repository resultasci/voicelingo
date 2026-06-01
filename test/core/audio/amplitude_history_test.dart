import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/audio/amplitude_history.dart';

void main() {
  group('AmplitudeHistory', () {
    test('addDb pushes normalized value into buffer', () {
      final h = AmplitudeHistory(bufferSize: 3);
      h.addDb(-10.0);
      h.addDb(-20.0);
      h.addDb(-30.0);
      expect(h.value.length, 3);
      for (final v in h.value) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('FIFO drops oldest beyond bufferSize', () {
      final h = AmplitudeHistory(bufferSize: 2);
      h.addDb(-10.0);
      h.addDb(-20.0);
      h.addDb(-30.0);
      expect(h.value.length, 2);
      // -10 dropped, -20 ve -30 kaldı; -20 -30'dan büyük (daha yüksek dB).
      expect(h.value.first, greaterThan(h.value.last));
    });

    test('clear empties buffer', () {
      final h = AmplitudeHistory();
      h.addDb(-15.0);
      h.clear();
      expect(h.value, isEmpty);
    });
  });
}
