import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/conversation_message.dart';

/// Self-animating "AI is thinking" dot. Owns its controller so the blink loop
/// repaints only this 6×6 dot — the previous TweenAnimationBuilder+onEnd
/// approach rebuilt the entire conversation screen every cycle.
class BlinkingDot extends StatefulWidget {
  final int index;
  const BlinkingDot({super.key, required this.index});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + (widget.index * 200)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl.drive(Tween(begin: 0.2, end: 1.0)),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: context.c.primaryContainer,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class MicButton extends StatelessWidget {
  final ConvStatus status;
  final double pulse;
  final VoidCallback? onTap;
  const MicButton({
    super.key,
    required this.status,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isListening = status == ConvStatus.listening;
    final isThinking = status == ConvStatus.thinking;
    final size = isListening ? 48.0 + pulse * 4 : 48.0;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isListening)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.primaryContainer.withOpacity(0.3 + pulse * 0.4),
                    width: 1.5,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: c.primaryContainer.withOpacity(0.6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Center(
                child: isThinking
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onPrimary,
                        ),
                      )
                    : Icon(
                        isListening ? Icons.stop_rounded : Icons.mic,
                        color: c.onPrimary,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
