import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/gemini_service.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/words_provider.dart';
import '../../../theme/app_theme.dart';

/// AI ile konu bazlı kelime üretme formu. [showAppBottomSheet] içinde
/// kullanılır; üretim bu widget'ın içinde await edilir — başarıda eklenen
/// kelime sayısı `int` olarak pop edilir, hata sheet açıkken gösterilir.
class GenerateWordsSheet extends ConsumerStatefulWidget {
  const GenerateWordsSheet({super.key});

  @override
  ConsumerState<GenerateWordsSheet> createState() => _GenerateWordsSheetState();
}

class _GenerateWordsSheetState extends ConsumerState<GenerateWordsSheet> {
  final _topicCtrl = TextEditingController();
  int _count = 10;
  bool _loading = false;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final l = AppL10n.of(context);
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      final added = await ref
          .read(wordsProvider.notifier)
          .generateAndAddWords(topic, _count);
      if (!mounted) return;
      Navigator.pop(context, added);
    } catch (e, st) {
      AppLogger.error('Kelime üretimi başarısız', e, st);
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e is AiException ? e.message : l.words_genFailed;
      showErrorSnack(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: c.primaryContainer, size: 18),
            const SizedBox(width: 8),
            SectionLabel(l.words_genTitle, color: c.primaryContainer),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l.words_genSubtitle,
          style: AppText.body(13, color: c.inkMuted),
        ),
        const SizedBox(height: 20),
        Text(l.words_genTopicLabel,
            style:
                AppText.label(10, color: c.inkMuted, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        NeonField(
          controller: _topicCtrl,
          autofocus: true,
          hint: l.words_genTopicHint,
        ),
        const SizedBox(height: 20),
        Text(l.words_genCount,
            style:
                AppText.label(10, color: c.inkMuted, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [5, 10, 15, 20].map((n) {
            final sel = n == _count;
            return InkWell(
              onTap: _loading ? null : () => setState(() => _count = n),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? c.primaryContainer.withOpacity(0.10)
                      : c.bgCard.withOpacity(0.5),
                  border: Border.all(
                    color: sel ? c.primaryContainer : c.rule.withOpacity(0.6),
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$n',
                  style: AppText.label(12,
                      color: sel ? c.primaryContainer : c.inkMuted,
                      weight: FontWeight.w700),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        NeonButton(
          label: l.words_genButton,
          icon: Icons.auto_awesome,
          loading: _loading,
          onTap: _run,
        ),
      ],
    );
  }
}
