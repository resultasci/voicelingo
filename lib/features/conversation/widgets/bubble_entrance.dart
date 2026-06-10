import 'package:flutter/material.dart';

/// One-shot entrance for chat bubbles: fade + slide-up + a tiny horizontal
/// push from the sender's side. Owns its controller so the animation runs
/// exactly once per insertion and survives parent rebuilds mid-flight.
class BubbleEntrance extends StatefulWidget {
  final Widget child;
  final bool fromRight;
  const BubbleEntrance(
      {super.key, required this.child, required this.fromRight});

  @override
  State<BubbleEntrance> createState() => _BubbleEntranceState();
}

class _BubbleEntranceState extends State<BubbleEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();
  late final CurvedAnimation _t =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _t.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dx = widget.fromRight ? 0.06 : -0.06;
    return FadeTransition(
      opacity: _t,
      child: SlideTransition(
        position: _t.drive(
          Tween(begin: Offset(dx, 0.25), end: Offset.zero),
        ),
        child: widget.child,
      ),
    );
  }
}
