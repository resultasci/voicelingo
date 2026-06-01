import 'package:flutter/material.dart';

/// IndexedStack benzeri davranır ama tab'ları **yalnızca ilk ziyaret edildiğinde**
/// inşa eder. Ziyaret edildikten sonra widget state'i Offstage altında korunur
/// (animation/scroll position kaybolmaz); ziyaret edilmemiş tab'lar hiç build
/// edilmez.
///
/// Standart IndexedStack açılışta tüm children'ı eager olarak build eder —
/// ConversationScreen gibi recorder/TTS başlatan ekranlar arka planda bile canlı
/// kalır. LazyIndexedStack bunu önler.
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

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _visited;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List<Widget>.generate(widget.children.length, (i) {
        if (!_visited[i]) {
          // Placeholder: zero-cost build, hiçbir state oluşturulmaz.
          return const SizedBox.shrink();
        }
        return widget.children[i];
      }),
    );
  }
}
