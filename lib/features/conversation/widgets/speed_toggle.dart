import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// TTS speed toggle: cycles through 0.5x / 0.75x / 1.0x.
class SpeedToggle extends StatelessWidget {
  final double rate;
  final ValueChanged<double> onChanged;
  const SpeedToggle({super.key, required this.rate, required this.onChanged});

  static const _options = [0.5, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final idx = _options.indexOf(rate).clamp(0, _options.length - 1);
    final label =
        '${_options[idx].toStringAsFixed(2).replaceAll(RegExp(r"0+$"), "").replaceAll(RegExp(r"\.$"), "")}×';
    return Semantics(
      label: AppL10n.of(context).settings_ttsSpeed,
      value: label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {
          final next = _options[(idx + 1) % _options.length];
          onChanged(next);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: c.primaryContainer.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: AppText.label(11,
                color: c.primaryContainer, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
