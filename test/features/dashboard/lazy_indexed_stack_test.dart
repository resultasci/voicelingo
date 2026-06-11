import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/features/dashboard/widgets/lazy_indexed_stack.dart';

/// Sürekli dönen bir AnimationController barındıran test child'ı —
/// TickerMode susturmasının gerçekten frame üretimini durdurduğunu ölçer.
class _Spinner extends StatefulWidget {
  const _Spinner({required this.onController});
  final void Function(AnimationController) onController;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void initState() {
    super.initState();
    widget.onController(ctrl);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('gizli tab animasyonu durur, tab geri gelince devam eder',
      (tester) async {
    late AnimationController ctrl;
    Widget build(int index) => MaterialApp(
          home: LazyIndexedStack(
            index: index,
            children: [
              _Spinner(onController: (c) => ctrl = c),
              const SizedBox.shrink(),
            ],
          ),
        );

    await tester.pumpWidget(build(0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(ctrl.value, greaterThan(0), reason: 'aktif tab animasyonu işler');

    // Başka tab'a geç; stack'in kendi 240ms geçiş animasyonu bitsin.
    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(milliseconds: 300));
    final frozen = ctrl.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(ctrl.value, frozen,
        reason: 'gizli tab\'daki controller TickerMode ile susturulur');

    // Geri dön — ticker otomatik devam etmeli.
    await tester.pumpWidget(build(0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(ctrl.value, isNot(equals(frozen)),
        reason: 'tab aktifleşince animasyon kaldığı yerden sürer');
  });

  testWidgets('ziyaret edilmemiş tab hiç build edilmez', (tester) async {
    var builtCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: LazyIndexedStack(
        index: 0,
        children: [
          const SizedBox.shrink(),
          Builder(builder: (_) {
            builtCount++;
            return const SizedBox.shrink();
          }),
        ],
      ),
    ));
    expect(builtCount, 0);
  });
}
