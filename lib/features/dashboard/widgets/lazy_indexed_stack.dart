import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// IndexedStack benzeri davranır ama tab'ları **yalnızca ilk ziyaret edildiğinde**
/// inşa eder. Ziyaret edildikten sonra widget state'i Offstage altında korunur
/// (animation/scroll position kaybolmaz); ziyaret edilmemiş tab'lar hiç build
/// edilmez.
///
/// Standart IndexedStack açılışta tüm children'ı eager olarak build eder —
/// ConversationScreen gibi recorder/TTS başlatan ekranlar arka planda bile canlı
/// kalır. LazyIndexedStack bunu önler.
///
/// Ziyaret edilmiş ama aktif olmayan tab'lar [TickerMode] ile sarılır: gizli
/// tab'lardaki tüm AnimationController'lar (profil halkası, shimmer, stagger)
/// frame üretmeyi durdurur, tab'a dönüldüğünde otomatik devam eder.
///
/// Tab değişiminde içerik hafif bir fade + yukarı kayma ile girer. Animasyon
/// IndexedStack'in DIŞINDA bir sarmalayıcıda koşar; child element ağacı yerinde
/// kaldığı için tab state'i korunur. [reduceMotion] aktifse animasyon atlanır.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack>
    with SingleTickerProviderStateMixin {
  late final List<bool> _visited;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final CurvedAnimation _t =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    _visited = List<bool>.filled(widget.children.length, false);
    _visited[widget.index] = true;
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      if (widget.index >= 0 && widget.index < _visited.length) {
        _visited[widget.index] = true;
      }
      if (!reduceMotion(context)) {
        _ctrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: SlideTransition(
        position: _t.drive(
          Tween(begin: const Offset(0, 0.012), end: Offset.zero),
        ),
        child: IndexedStack(
          index: widget.index,
          children: List<Widget>.generate(widget.children.length, (i) {
            if (!_visited[i]) {
              // Placeholder: zero-cost build, hiçbir state oluşturulmaz.
              return const SizedBox.shrink();
            }
            return TickerMode(
              enabled: i == widget.index,
              child: widget.children[i],
            );
          }),
        ),
      ),
    );
  }
}
