import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../features/profile/services/profile_repository.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';

class _Question {
  final String prompt;
  final List<String> options;
  final int correct;
  const _Question(this.prompt, this.options, this.correct);
}

const _placementQuestions = <_Question>[
  _Question('"Apple" Türkçe ne demek?', ['Elma', 'Armut', 'Çilek', 'Üzüm'], 0),
  _Question('"I ___ a student."', ['am', 'is', 'are', 'be'], 0),
  _Question(
      '"Hello" — anlamı?', ['Merhaba', 'Hoşçakal', 'Lütfen', 'Teşekkür'], 0),
  _Question('She ___ to school every day.', ['go', 'goes', 'going', 'gone'], 1),
  _Question('"Big" zıt anlamlısı?', ['Tall', 'Small', 'Wide', 'Heavy'], 1),
  _Question('Yesterday I ___ a movie.',
      ['watch', 'watched', 'watching', 'watches'], 1),
  _Question('If I ___ rich, I would travel.', ['am', 'was', 'were', 'be'], 2),
  _Question('"I have been waiting ___ two hours."',
      ['since', 'for', 'during', 'in'], 1),
  _Question(
      'Choose the correct passive: "Someone stole my bike."',
      [
        'My bike was stolen.',
        'My bike is stole.',
        'My bike has stole.',
        'My bike stole.'
      ],
      0),
  _Question('"He suggested ___ a movie."',
      ['to watch', 'watching', 'watch', 'watched'], 1),
];

String cefrFromScore(int correct) {
  if (correct >= 10) return 'B2';
  if (correct >= 7) return 'B1';
  if (correct >= 4) return 'A2';
  return 'A1';
}

class PlacementTestScreen extends ConsumerStatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  ConsumerState<PlacementTestScreen> createState() =>
      _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  int _index = 0;
  int _correct = 0;
  bool _saving = false;
  String? _result;

  void _answer(int picked) {
    if (picked == _placementQuestions[_index].correct) _correct++;
    if (_index < _placementQuestions.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _result = cefrFromScore(_correct);
    });
    await ref.read(profileRepositoryProvider).saveCefrLevel(_result!);
    await ref.read(settingsServiceProvider).setPlacementDone(true);
    ref.invalidate(profileProvider);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: _result != null
                ? _ResultView(
                    cefr: _result!,
                    correct: _correct,
                    saving: _saving,
                    onContinue: () => context.go('/'),
                  )
                : _QuestionView(
                    index: _index,
                    total: _placementQuestions.length,
                    question: _placementQuestions[_index],
                    onAnswer: _answer,
                  ),
          ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final int index;
  final int total;
  final _Question question;
  final ValueChanged<int> onAnswer;
  const _QuestionView({
    required this.index,
    required this.total,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final progress = (index + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: c.surfaceHighest,
                  valueColor: AlwaysStoppedAnimation(c.primaryContainer),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${index + 1}/$total',
                style: AppText.code(11, color: c.inkDim)),
          ],
        ),
        // Question + options scroll so long prompts / large text scaling never
        // overflow on small screens.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                SectionLabel(l.placement_title, color: c.primaryContainer),
                const SizedBox(height: 14),
                Text(
                  question.prompt,
                  style: AppText.title(22,
                      color: c.primary, weight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                ...List.generate(question.options.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GhostButton(
                      label: question.options[i],
                      onTap: () => onAnswer(i),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final String cefr;
  final int correct;
  final bool saving;
  final VoidCallback onContinue;
  const _ResultView({
    required this.cefr,
    required this.correct,
    required this.saving,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Center(
      child: GlassPanel(
        padding: const EdgeInsets.all(28),
        glowColor: c.primaryContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionLabel(l.placement_result, color: c.primaryContainer),
            const SizedBox(height: 18),
            Text(
              cefr,
              style: AppText.hero(64, color: c.primary, weight: FontWeight.w800)
                  .copyWith(
                shadows: neonGlow(c.primary, blur: 18, opacity: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(l.placement_correctCount(correct),
                style: AppText.body(13, color: c.inkMuted)),
            const SizedBox(height: 24),
            if (saving) ...[
              SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.primaryContainer)),
            ] else
              NeonButton(
                label: l.onb_continue,
                icon: Icons.arrow_forward,
                onTap: onContinue,
              ),
          ],
        ),
      ),
    );
  }
}
