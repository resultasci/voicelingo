import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/core/perf/perf_trace.dart';

void main() {
  setUp(PerfTrace.resetForTest);
  tearDown(PerfTrace.resetForTest);

  test('mark kayıtları boot referanslı ve monoton artar', () {
    PerfTrace.enabledOverride = true;
    PerfTrace.markBoot();
    PerfTrace.mark('a');
    PerfTrace.mark('b');
    PerfTrace.mark('c');

    expect(PerfTrace.marks.first, ('boot', 0));
    expect(PerfTrace.marks, hasLength(4));
    for (var i = 1; i < PerfTrace.marks.length; i++) {
      expect(
        PerfTrace.marks[i].$2,
        greaterThanOrEqualTo(PerfTrace.marks[i - 1].$2),
        reason: 'mark süreleri geriye gidemez',
      );
    }
  });

  test('devre dışıyken (release) tüm API no-op', () {
    PerfTrace.enabledOverride = false;
    PerfTrace.markBoot();
    PerfTrace.mark('a');
    PerfTrace.span('s')();
    PerfTrace.start('t');
    PerfTrace.lap('t', 'x');

    expect(PerfTrace.marks, isEmpty);
  });

  test('markBoot çağrılmadan mark no-op (anlamsız değer üretmez)', () {
    PerfTrace.enabledOverride = true;
    PerfTrace.mark('orphan');
    expect(PerfTrace.marks, isEmpty);
  });

  test('span bağımsız süre kaydeder', () {
    PerfTrace.enabledOverride = true;
    final done = PerfTrace.span('fetch');
    done();

    expect(PerfTrace.marks, hasLength(1));
    expect(PerfTrace.marks.single.$1, 'fetch');
    expect(PerfTrace.marks.single.$2, greaterThanOrEqualTo(0));
  });

  test('lap yalnız start edilmiş akışta kaydeder; stop sonrası no-op', () {
    PerfTrace.enabledOverride = true;
    PerfTrace.lap('turn', 'orphan');
    expect(PerfTrace.marks, isEmpty);

    PerfTrace.start('turn');
    PerfTrace.lap('turn', 'reply');
    expect(PerfTrace.marks.single.$1, 'turn.reply');

    PerfTrace.stop('turn');
    PerfTrace.lap('turn', 'after-stop');
    expect(PerfTrace.marks, hasLength(1));
  });
}
