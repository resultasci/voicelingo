import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/word.dart';
import '../../../providers/words_provider.dart';
import '../../../theme/app_theme.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final List<Word> dueWords;
  const FlashcardScreen({super.key, required this.dueWords});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;

  void _onQualitySelected(int quality) {
    if (_currentIndex >= widget.dueWords.length) return;

    final currentWord = widget.dueWords[_currentIndex];
    ref.read(wordsProvider.notifier).reviewWord(currentWord, quality);

    setState(() {
      _currentIndex++;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.dueWords.length) {
      return const _CompletedView();
    }

    final word = widget.dueWords[_currentIndex];
    final progress = (_currentIndex) / widget.dueWords.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryContainer),
        title: Text(
          'Kelime Pratiği',
          style: AppText.title(20,
                  color: AppColors.primary, weight: FontWeight.w600)
              .copyWith(
                  shadows: neonGlow(AppColors.primary, blur: 8, opacity: 0.3)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceHighest,
            valueColor:
                const AlwaysStoppedAnimation(AppColors.primaryContainer),
          ),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'KART ${_currentIndex + 1} / ${widget.dueWords.length}',
                  style: AppText.label(12,
                      color: AppColors.inkDim, weight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _buildCard(word, key: ValueKey(word.id)),
                  ),
                ),
                const SizedBox(height: 24),
                _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Word word, {Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryContainer.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.word,
              style: AppText.hero(36,
                      color: AppColors.primary, weight: FontWeight.bold)
                  .copyWith(
                      shadows: neonGlow(AppColors.primaryContainer,
                          blur: 12, opacity: 0.4)),
              textAlign: TextAlign.center,
            ),
            if (word.ipa != null && word.ipa!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '/${word.ipa}/',
                style: AppText.body(16, color: AppColors.secondary),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            if (_showAnswer) ...[
              Divider(color: AppColors.inkDim.withOpacity(0.3)),
              const Spacer(),
              Text(
                word.translation,
                style: AppText.title(28,
                    color: AppColors.tertiaryFixedDim, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              if (word.exampleSentence != null &&
                  word.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  word.exampleSentence!,
                  style: AppText.body(15, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
              ],
            ] else ...[
              Icon(Icons.touch_app,
                  color: AppColors.inkDim.withOpacity(0.5), size: 48),
              const SizedBox(height: 16),
              Text(
                'Çeviriyi görmek için "Cevabı Göster"e dokun',
                style: AppText.body(14, color: AppColors.inkDim),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (!_showAnswer) {
      return NeonButton(
        label: 'CEVABI GÖSTER',
        icon: Icons.visibility,
        onTap: () => setState(() => _showAnswer = true),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _OutcomeButton(
                label: 'BİLMEDİM',
                color: AppColors.error,
                icon: Icons.close,
                onTap: () => _onQualitySelected(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutcomeButton(
                label: 'ZORDU',
                color: AppColors.secondary,
                icon: Icons.warning_amber_rounded,
                onTap: () => _onQualitySelected(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutcomeButton(
                label: 'KOLAYDI',
                color: AppColors.primaryContainer,
                icon: Icons.check,
                onTap: () => _onQualitySelected(5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _OutcomeButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppText.label(12, color: color, weight: FontWeight.w700),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================

class _CompletedView extends StatelessWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: GlassPanel(
                padding: const EdgeInsets.all(32),
                borderColor: AppColors.primaryFixedDim.withOpacity(0.5),
                glowColor: AppColors.primaryFixedDim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.primaryFixedDim, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      'TEBRİKLER!',
                      style: AppText.hero(28,
                          color: AppColors.primary, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bugünlük kelime tekrarını bitirdin. Kelimeler yarın senin için tekrar planlanacak.',
                      style: AppText.body(16, color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    NeonButton(
                      label: 'ANA SAYFAYA DÖN',
                      icon: Icons.home,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
