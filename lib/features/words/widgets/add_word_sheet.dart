import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Manuel kelime ekleme formu. [showAppBottomSheet] içinde kullanılır;
/// girilen çift `(word, translation)` record'u olarak pop edilir — ekleme
/// işleminin kendisi (ve hata/duplicate snackbar'ları) çağıran ekranda.
class AddWordSheet extends StatefulWidget {
  const AddWordSheet({super.key});

  @override
  State<AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<AddWordSheet> {
  final _wCtrl = TextEditingController();
  final _tCtrl = TextEditingController();

  @override
  void dispose() {
    _wCtrl.dispose();
    _tCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final w = _wCtrl.text.trim();
    final t = _tCtrl.text.trim();
    if (w.isEmpty || t.isEmpty) return;
    Navigator.pop(context, (word: w, translation: t));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l.words_addNew, color: c.primaryContainer),
        const SizedBox(height: 14),
        Text(
          l.words_addToLibrary,
          style: AppText.title(22, color: c.primary, weight: FontWeight.w600)
              .copyWith(
            shadows: neonGlow(c.primary, blur: 8, opacity: 0.4),
          ),
        ),
        const SizedBox(height: 22),
        Text(l.words_labelEnglish,
            style:
                AppText.label(10, color: c.inkMuted, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        NeonField(controller: _wCtrl, autofocus: true, hint: l.words_hintWord),
        const SizedBox(height: 16),
        Text(l.words_labelTurkish,
            style:
                AppText.label(10, color: c.inkMuted, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        NeonField(controller: _tCtrl, hint: l.words_hintTranslation),
        const SizedBox(height: 22),
        NeonButton(
          label: l.common_add,
          icon: Icons.add,
          onTap: _submit,
        ),
      ],
    );
  }
}
