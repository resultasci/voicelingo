import 'package:flutter/material.dart';

import '../../../core/ai/gemini_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// Kullanıcı balonunun altındaki değerlendirme rozeti; tıklanınca skor,
/// açıklama ve gramer hatalarını içeren paneli açar.
class FeedbackPill extends StatefulWidget {
  final SpeechEvaluation evaluation;
  const FeedbackPill({super.key, required this.evaluation});

  @override
  State<FeedbackPill> createState() => _FeedbackPillState();
}

class _FeedbackPillState extends State<FeedbackPill> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final eval = widget.evaluation;
    final isHigh = eval.score >= 80;
    final color = isHigh ? c.primaryFixed : c.tertiaryFixedDim;
    final label = isHigh
        ? l.conv_feedbackGreat
        : l.conv_feedbackMoreNatural(
            eval.correct.isNotEmpty ? eval.correct : "—");

    return Semantics(
      label: l.conv_evalSemantics(label),
      button: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                border: Border.all(color: color.withOpacity(0.45)),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.label(10,
                          color: color, weight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: GlassPanel(
                  padding: const EdgeInsets.all(12),
                  borderColor: color.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.conv_score(eval.score),
                          style: AppText.label(10,
                              color: color, weight: FontWeight.w700)),
                      if (eval.explanation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(eval.explanation,
                            style: AppText.body(12, color: c.ink)),
                      ],
                      if (eval.grammarErrors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(l.conv_errorsLabel,
                            style: AppText.label(9,
                                color: c.inkDim, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        ...eval.grammarErrors.map((e) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('• $e',
                                  style: AppText.body(12, color: c.inkMuted)),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
