import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../models/grammar_topic.dart';
import '../services/grammar_service.dart';

/// Gramer konu detay sayfası — 3 tab: Açıklama, Örnekler, Quiz.
class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topic});
  final GrammarTopic topic;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tts = FlutterTts()
      ..setLanguage('en-US')
      ..setPitch(1.0)
      ..setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final t = widget.topic;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          t.title(locale),
          style: AppText.title(16,
              color: AppColors.primaryContainer, weight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primaryContainer,
          labelColor: AppColors.primaryContainer,
          unselectedLabelColor: AppColors.inkDim,
          labelStyle: AppText.label(12, weight: FontWeight.w700),
          tabs: [
            Tab(text: locale == 'en' ? 'Lesson' : 'Konu'),
            Tab(text: locale == 'en' ? 'Examples' : 'Örnekler'),
            const Tab(text: 'Quiz'),
          ],
        ),
      ),
      body: CosmicBackground(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _LessonTab(topic: t, locale: locale),
            _ExamplesTab(topic: t, locale: locale, onSpeak: _speak),
            _QuizTab(topic: t, locale: locale),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
class _LessonTab extends StatelessWidget {
  const _LessonTab({required this.topic, required this.locale});
  final GrammarTopic topic;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final desc = topic.description(locale) ??
        (locale == 'en' ? 'No description yet.' : 'Açıklama yok.');
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primaryContainer.withOpacity(0.5)),
            ),
            child: Text(
              topic.level,
              style: AppText.label(11,
                  color: AppColors.primaryContainer, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            topic.title(locale),
            style: AppText.title(22,
                color: AppColors.ink, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: AppText.body(14, color: AppColors.inkMuted)
                .copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _ExamplesTab extends StatelessWidget {
  const _ExamplesTab({
    required this.topic,
    required this.locale,
    required this.onSpeak,
  });
  final GrammarTopic topic;
  final String locale;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    if (topic.examples.isEmpty) {
      return Center(
        child: Text(
          locale == 'en' ? 'No examples yet.' : 'Henüz örnek yok.',
          style: AppText.body(13, color: AppColors.inkDim),
        ),
      );
    }
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: topic.examples.length,
        itemBuilder: (_, i) {
          final ex = topic.examples[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.inkDim.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ex.en,
                          style: AppText.title(15,
                              color: AppColors.ink, weight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined,
                            color: AppColors.primaryContainer),
                        onPressed: () => onSpeak(ex.en),
                      ),
                    ],
                  ),
                  if (ex.tr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ex.tr,
                      style: AppText.body(13, color: AppColors.inkDim),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Quiz — basit fill/mc desteği
// =============================================================================
class _QuizTab extends ConsumerStatefulWidget {
  const _QuizTab({required this.topic, required this.locale});
  final GrammarTopic topic;
  final String locale;

  @override
  ConsumerState<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<_QuizTab> {
  int _index = 0;
  final Map<int, String> _answers = {};
  final TextEditingController _fillCtrl = TextEditingController();
  bool _submitted = false;
  int? _resultScore;
  bool _saving = false;

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  void _selectMc(String value) {
    setState(() => _answers[_index] = value);
  }

  void _submitFill() {
    setState(() => _answers[_index] = _fillCtrl.text.trim());
  }

  void _nextQuestion() {
    final q = widget.topic.quiz[_index];
    if (q.type == 'fill') _submitFill();
    if (_index < widget.topic.quiz.length - 1) {
      setState(() {
        _index += 1;
        _fillCtrl.text = _answers[_index] ?? '';
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    int correct = 0;
    for (var i = 0; i < widget.topic.quiz.length; i++) {
      final q = widget.topic.quiz[i];
      final ans = _answers[i] ?? '';
      if (q.checkAnswer(ans)) correct += 1;
    }
    final total = widget.topic.quiz.length;
    final score = total == 0 ? 0 : ((correct * 100) ~/ total);

    try {
      final svc = ref.read(grammarServiceProvider);
      await svc.recordQuizResult(
        topicId: widget.topic.id,
        score: score,
        xpReward: widget.topic.xpReward,
      );
      ref.invalidate(grammarProgressProvider);
    } catch (_) {
      // Best-effort persistence
    }

    if (!mounted) return;
    setState(() {
      _submitted = true;
      _resultScore = score;
      _saving = false;
    });
  }

  void _retry() {
    setState(() {
      _answers.clear();
      _fillCtrl.clear();
      _index = 0;
      _submitted = false;
      _resultScore = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.topic;
    final locale = widget.locale;

    if (t.quiz.isEmpty) {
      return Center(
        child: Text(
          locale == 'en' ? 'No quiz yet.' : 'Henüz quiz yok.',
          style: AppText.body(13, color: AppColors.inkDim),
        ),
      );
    }

    if (_submitted) return _resultView(locale);

    final q = t.quiz[_index];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${locale == 'en' ? 'Question' : 'Soru'} ${_index + 1}/${t.quiz.length}',
              style: AppText.label(11,
                  color: AppColors.primaryContainer, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              q.promptEn,
              style: AppText.title(18,
                  color: AppColors.ink, weight: FontWeight.w700),
            ),
            if (q.promptTr != null && q.promptTr!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                q.promptTr!,
                style: AppText.body(12, color: AppColors.inkDim),
              ),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: q.type == 'mc' ? _mcOptions(q) : _fillInput(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _canAdvance() ? _nextQuestion : null,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _index == t.quiz.length - 1
                            ? (locale == 'en' ? 'Finish' : 'Bitir')
                            : (locale == 'en' ? 'Next' : 'İleri'),
                        style: AppText.label(13,
                            color: AppColors.onPrimary,
                            weight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAdvance() {
    final q = widget.topic.quiz[_index];
    if (q.type == 'mc') return _answers.containsKey(_index);
    return _fillCtrl.text.trim().isNotEmpty;
  }

  Widget _mcOptions(QuizQuestion q) {
    return ListView(
      children: [
        for (final opt in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _selectMc(opt),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _answers[_index] == opt
                      ? AppColors.primaryContainer.withOpacity(0.2)
                      : AppColors.bgCard.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _answers[_index] == opt
                        ? AppColors.primaryContainer
                        : AppColors.inkDim.withOpacity(0.18),
                    width: _answers[_index] == opt ? 2 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: AppText.title(15,
                      color: AppColors.ink, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fillInput() {
    return Align(
      alignment: Alignment.topLeft,
      child: TextField(
        controller: _fillCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: widget.locale == 'en' ? 'Type your answer' : 'Cevabını yaz',
          hintStyle: AppText.body(14, color: AppColors.inkDim),
          filled: true,
          fillColor: AppColors.bgCard.withOpacity(0.55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.inkDim.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.inkDim.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primaryContainer, width: 2),
          ),
        ),
        style: AppText.title(15, color: AppColors.ink, weight: FontWeight.w600),
      ),
    );
  }

  Widget _resultView(String locale) {
    final score = _resultScore ?? 0;
    final passed = score >= 70;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.workspace_premium : Icons.refresh,
              size: 88,
              color: passed ? AppColors.tertiary : AppColors.secondaryContainer,
            ),
            const SizedBox(height: 18),
            Text(
              '$score%',
              style: AppText.hero(48,
                  color: AppColors.primaryContainer, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              passed
                  ? (locale == 'en' ? 'Great job!' : 'Harikasın!')
                  : (locale == 'en' ? 'Try again' : 'Tekrar dene'),
              style: AppText.title(18,
                  color: AppColors.ink, weight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.primaryContainer.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      locale == 'en' ? 'Retry' : 'Tekrar',
                      style: AppText.label(13,
                          color: AppColors.primaryContainer,
                          weight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      locale == 'en' ? 'Done' : 'Bitir',
                      style: AppText.label(13,
                          color: AppColors.onPrimary, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
