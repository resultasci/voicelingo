import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/tts_speaker.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/scenario.dart';
import '../../conversation/screens/conversation_screen.dart';
import '../../grammar/screens/topic_detail_screen.dart';
import '../../grammar/services/grammar_service.dart';
import '../../scenarios/services/scenarios_service.dart';
import '../models/course.dart';
import '../services/courses_service.dart';

/// Type'a göre alt-renderer dispatch eder. Tamamlandığında
/// `complete_lesson` RPC çağrılır; result modal'da gösterilir.
///
/// MVP: vocab + quiz tam implement; grammar/conversation/listening
/// kullanıcıyı ilgili mevcut ekrana yönlendiren landing card.
class LessonRunnerScreen extends ConsumerWidget {
  const LessonRunnerScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final locale = ref.watch(localeProvider).languageCode;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.ink,
        title: Text(
          lesson.title(locale),
          style: AppText.title(16,
              color: c.primaryContainer, weight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: _body(context, ref, locale),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, String locale) {
    final l = AppL10n.of(context);
    final c = context.c;
    switch (lesson.type) {
      case LessonType.vocab:
        return _VocabRunner(lesson: lesson, locale: locale);
      case LessonType.quiz:
        return _QuizRunner(lesson: lesson, locale: locale);
      case LessonType.grammar:
        return _LandingCard(
          lesson: lesson,
          locale: locale,
          icon: Icons.spellcheck_outlined,
          color: c.secondaryContainer,
          message: l.lesson_grammarBridge,
          actionLabel: l.lesson_openGrammar,
          onAction: () => _openGrammar(context, ref),
        );
      case LessonType.conversation:
        return _LandingCard(
          lesson: lesson,
          locale: locale,
          icon: Icons.mic_none_outlined,
          color: c.tertiary,
          message: l.lesson_convBridge,
          actionLabel: l.lesson_startConv,
          onAction: () => _openConversation(context, ref),
        );
      case LessonType.listening:
        return _ListeningRunner(lesson: lesson, locale: locale);
    }
  }

  Future<void> _openGrammar(BuildContext context, WidgetRef ref) async {
    final code = lesson.content['topic_code']?.toString();
    if (code == null || code.isEmpty) {
      context.push('/grammar');
      return;
    }
    final topic = await ref.read(grammarServiceProvider).getTopicByCode(code);
    if (!context.mounted) return;
    if (topic == null) {
      context.push('/grammar');
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TopicDetailScreen(topic: topic),
    ));
    // Quiz sonucu user_grammar_progress'e yazıldı; bu ders'i de "completed" işaretle.
    if (!context.mounted) return;
    await _markCompleteAndPop(context, ref, score: 80);
  }

  Future<void> _openConversation(BuildContext context, WidgetRef ref) async {
    final titleEn = lesson.content['scenario_title_en']?.toString();
    ScenarioModel? scenario;
    if (titleEn != null && titleEn.isNotEmpty) {
      final found =
          await ref.read(scenariosServiceProvider).getByTitleEn(titleEn);
      if (found != null) scenario = found.toScenarioModel();
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConversationScreen(scenario: scenario),
    ));
    if (!context.mounted) return;
    // Pop sonrası lesson'ı tamamla (kullanıcı sohbeti deneyimledi).
    await _markCompleteAndPop(context, ref, score: 80);
  }

  Future<void> _markCompleteAndPop(BuildContext context, WidgetRef ref,
      {required int score}) async {
    final res = await ref.read(coursesServiceProvider).completeLesson(
          lessonId: lesson.id,
          score: score,
        );
    ref.invalidate(lessonProgressMapProvider);
    if (!context.mounted) return;
    await _CompletionDialog.show(context, res);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

// =============================================================================
// VOCAB RUNNER — flashcards (tap to flip + I know / Practice again)
// =============================================================================
class _VocabRunner extends ConsumerStatefulWidget {
  const _VocabRunner({required this.lesson, required this.locale});
  final Lesson lesson;
  final String locale;

  @override
  ConsumerState<_VocabRunner> createState() => _VocabRunnerState();
}

class _VocabRunnerState extends ConsumerState<_VocabRunner> {
  final TtsSpeaker _tts = TtsSpeaker();
  int _index = 0;
  bool _flipped = false;
  int _correct = 0;
  bool _saving = false;

  List<Map<String, dynamic>> get _words {
    final raw = widget.lesson.content['words'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) => _tts.speak(text, sanitize: false);

  void _record(bool known) {
    if (known) _correct += 1;
    if (_index < _words.length - 1) {
      setState(() {
        _index += 1;
        _flipped = false;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final score = _words.isEmpty ? 0 : ((_correct * 100) ~/ _words.length);
    final res = await ref.read(coursesServiceProvider).completeLesson(
          lessonId: widget.lesson.id,
          score: score,
        );
    ref.invalidate(lessonProgressMapProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    await _CompletionDialog.show(context, res);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final words = _words;
    if (words.isEmpty) {
      return Center(
        child: Text(
          l.lesson_noVocab,
          style: AppText.body(13, color: c.inkDim),
        ),
      );
    }
    final w = words[_index];
    final en = w['en']?.toString() ?? '';
    final tr = w['tr']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          Text(
            '${_index + 1} / ${words.length}',
            style: AppText.label(11,
                color: c.primaryContainer, weight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _flipped = !_flipped),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey('$_index-$_flipped'),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: c.bgCard.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: c.primaryContainer.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: c.primaryContainer.withOpacity(0.18),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _flipped ? tr : en,
                        style: AppText.hero(32,
                            color: c.ink, weight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      if (!_flipped)
                        IconButton(
                          onPressed: () => _speak(en),
                          icon: Icon(Icons.volume_up,
                              color: c.primaryContainer, size: 32),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        l.lesson_tapToFlip,
                        style: AppText.label(10, color: c.inkDim),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _record(false),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.lesson_practiceAgain,
                      style: AppText.label(12, weight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.secondaryContainer,
                    side: BorderSide(
                        color: c.secondaryContainer.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _record(true),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check, size: 18),
                  label: Text(l.lesson_iKnowIt,
                      style: AppText.label(12,
                          color: c.onPrimary, weight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primaryContainer,
                    foregroundColor: c.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LISTENING RUNNER — TTS cümleyi okur, kullanıcı duyduğunu yazar.
// content['sentences']: [{"en": "...", "tr": "..."}] — skor doğru yüzdesi.
// =============================================================================
class _ListeningRunner extends ConsumerStatefulWidget {
  const _ListeningRunner({required this.lesson, required this.locale});
  final Lesson lesson;
  final String locale;

  @override
  ConsumerState<_ListeningRunner> createState() => _ListeningRunnerState();
}

class _ListeningRunnerState extends ConsumerState<_ListeningRunner> {
  final TtsSpeaker _tts = TtsSpeaker();
  final TextEditingController _ctrl = TextEditingController();
  int _index = 0;
  int _correct = 0;
  bool _checked = false;
  bool _wasCorrect = false;
  bool _saving = false;

  List<Map<String, dynamic>> get _sentences {
    final raw = widget.lesson.content['sentences'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }

  @override
  void initState() {
    super.initState();
    _tts.init();
    // Buton aktifliği yazılan metne bağlı; her değişimde yeniden değerlendir.
    _ctrl.addListener(() => setState(() {}));
    // İlk cümleyi otomatik çal — kullanıcı ekranı görünce egzersiz başlamış olur.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tts.dispose();
    super.dispose();
  }

  Future<void> _speakCurrent() async {
    final s = _sentences;
    if (_index >= s.length) return;
    await _tts.speak(s[_index]['en']?.toString() ?? '', sanitize: false);
  }

  /// Noktalama/büyük-küçük harf farkları doğruluğu etkilemesin.
  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  void _check() {
    final expected = _sentences[_index]['en']?.toString() ?? '';
    final ok = _normalize(_ctrl.text) == _normalize(expected);
    if (ok) _correct++;
    setState(() {
      _checked = true;
      _wasCorrect = ok;
    });
  }

  void _next() {
    if (_index < _sentences.length - 1) {
      setState(() {
        _index++;
        _checked = false;
        _wasCorrect = false;
        _ctrl.clear();
      });
      _speakCurrent();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final total = _sentences.length;
    final score = total == 0 ? 0 : ((_correct * 100) ~/ total);
    final res = await ref.read(coursesServiceProvider).completeLesson(
          lessonId: widget.lesson.id,
          score: score,
        );
    ref.invalidate(lessonProgressMapProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    await _CompletionDialog.show(context, res, score: score);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final sentences = _sentences;
    if (sentences.isEmpty) {
      return Center(
        child: Text(
          l.lesson_noListening,
          style: AppText.body(13, color: c.inkDim),
        ),
      );
    }
    final expected = sentences[_index]['en']?.toString() ?? '';
    final translation = sentences[_index]['tr']?.toString() ?? '';
    final isLast = _index == sentences.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.quiz_question} ${_index + 1}/${sentences.length}',
            style: AppText.label(11,
                color: c.primaryContainer, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            l.lesson_listenPrompt,
            style: AppText.title(18, color: c.ink, weight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Center(
            child: Semantics(
              label: l.conv_replay,
              button: true,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _speakCurrent,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primaryContainer.withOpacity(0.12),
                    border:
                        Border.all(color: c.primaryContainer.withOpacity(0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: c.primaryContainer.withOpacity(0.25),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Icon(Icons.volume_up_rounded,
                      color: c.primaryContainer, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          NeonField(
            controller: _ctrl,
            autofocus: true,
            hint: l.lesson_typeWhatYouHeard,
            readOnly: _checked,
          ),
          const SizedBox(height: 14),
          if (_checked)
            GlassPanel(
              padding: const EdgeInsets.all(14),
              borderColor: (_wasCorrect ? c.success : c.error).withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _wasCorrect ? l.lesson_listenCorrect : l.lesson_listenWrong,
                    style: AppText.label(11,
                        color: _wasCorrect ? c.success : c.error,
                        weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(expected, style: AppText.body(14, color: c.ink)),
                  if (translation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(translation,
                        style: AppText.body(12, color: c.inkMuted)),
                  ],
                ],
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.primaryContainer,
                foregroundColor: c.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _saving
                  ? null
                  : _checked
                      ? _next
                      : (_ctrl.text.trim().isEmpty ? null : _check),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _checked
                          ? (isLast ? l.common_finish : l.common_next)
                          : l.lesson_listenCheck,
                      style: AppText.label(13,
                          color: c.onPrimary, weight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// QUIZ RUNNER — fill / mc
// =============================================================================
class _QuizRunner extends ConsumerStatefulWidget {
  const _QuizRunner({required this.lesson, required this.locale});
  final Lesson lesson;
  final String locale;

  @override
  ConsumerState<_QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends ConsumerState<_QuizRunner> {
  int _index = 0;
  final Map<int, String> _answers = {};
  final TextEditingController _ctrl = TextEditingController();
  bool _saving = false;

  List<Map<String, dynamic>> get _questions {
    final raw = widget.lesson.content['questions'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _check(Map<String, dynamic> q, String input) {
    final ans = (q['answer'] ?? '').toString().trim().toLowerCase();
    return input.trim().toLowerCase() == ans;
  }

  void _next(Map<String, dynamic> q) {
    if (q['type'] == 'fill') _answers[_index] = _ctrl.text;
    if (_index < _questions.length - 1) {
      setState(() {
        _index += 1;
        _ctrl.text = _answers[_index] ?? '';
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    int correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_check(_questions[i], _answers[i] ?? '')) correct += 1;
    }
    final score =
        _questions.isEmpty ? 0 : ((correct * 100) ~/ _questions.length);
    final res = await ref.read(coursesServiceProvider).completeLesson(
          lessonId: widget.lesson.id,
          score: score,
        );
    ref.invalidate(lessonProgressMapProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    await _CompletionDialog.show(context, res, score: score);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final qs = _questions;
    if (qs.isEmpty) {
      return Center(
        child: Text(
          l.lesson_noQuizQuestions,
          style: AppText.body(13, color: c.inkDim),
        ),
      );
    }
    final q = qs[_index];
    final type = (q['type'] ?? 'fill').toString();
    final canAdvance = type == 'mc'
        ? _answers.containsKey(_index)
        : _ctrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.quiz_question} ${_index + 1}/${qs.length}',
            style: AppText.label(11,
                color: c.primaryContainer, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            q['prompt_en']?.toString() ?? '',
            style: AppText.title(18, color: c.ink, weight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: type == 'mc' ? _mcOptions(q) : _fillInput(),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.primaryContainer,
                foregroundColor: c.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: canAdvance ? () => _next(q) : null,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _index == qs.length - 1 ? l.common_finish : l.common_next,
                      style: AppText.label(13,
                          color: c.onPrimary, weight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mcOptions(Map<String, dynamic> q) {
    final c = context.c;
    final raw = q['options'];
    final options =
        raw is List ? raw.whereType<String>().toList() : const <String>[];
    return ListView(
      children: [
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _answers[_index] = opt),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _answers[_index] == opt
                      ? c.primaryContainer.withOpacity(0.2)
                      : c.bgCard.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _answers[_index] == opt
                        ? c.primaryContainer
                        : c.inkDim.withOpacity(0.18),
                    width: _answers[_index] == opt ? 2 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style:
                      AppText.title(15, color: c.ink, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fillInput() {
    final l = AppL10n.of(context);
    final c = context.c;
    return Align(
      alignment: Alignment.topLeft,
      child: TextField(
        controller: _ctrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: l.quiz_typeAnswer,
          hintStyle: AppText.body(14, color: c.inkDim),
          filled: true,
          fillColor: c.bgCard.withOpacity(0.55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.inkDim.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.inkDim.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.primaryContainer, width: 2),
          ),
        ),
        style: AppText.title(15, color: c.ink, weight: FontWeight.w600),
      ),
    );
  }
}

// =============================================================================
// LANDING CARD — grammar/conversation/listening için bridging UI
// =============================================================================
class _LandingCard extends StatelessWidget {
  const _LandingCard({
    required this.lesson,
    required this.locale,
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final Lesson lesson;
  final String locale;
  final IconData icon;
  final Color color;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 64),
          const SizedBox(height: 18),
          Text(
            lesson.title(locale),
            style: AppText.title(20, color: c.ink, weight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppText.body(13, color: c.inkMuted).copyWith(height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: AppText.label(13,
                    color: Colors.white, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPLETION DIALOG
// =============================================================================
class _CompletionDialog {
  static Future<void> show(
    BuildContext context,
    LessonCompletionResult res, {
    int? score,
  }) {
    final l = AppL10n.of(context);
    final c = context.c;
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          res.ok
              ? (res.status == 'mastered'
                  ? l.lesson_perfect
                  : res.status == 'completed'
                      ? l.lesson_great
                      : l.lesson_keepGoing)
              : l.lesson_errorTitle,
          style: AppText.title(20,
              color: c.primaryContainer, weight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (score != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l.lesson_scoreLabel(score),
                  style:
                      AppText.title(16, color: c.ink, weight: FontWeight.w700),
                ),
              ),
            if ((res.stars ?? 0) > 0)
              Row(
                children: List.generate(3, (i) {
                  return Icon(
                    i < (res.stars ?? 0) ? Icons.star : Icons.star_border,
                    color: c.tertiary,
                    size: 24,
                  );
                }),
              ),
            if (res.xpAwarded > 0) ...[
              const SizedBox(height: 6),
              Text('+${res.xpAwarded} XP',
                  style: AppText.label(13,
                      color: c.tertiary, weight: FontWeight.w800)),
            ],
            if (!res.ok && res.error != null)
              Text(res.error!, style: AppText.body(12, color: c.error)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.common_ok),
          ),
        ],
      ),
    );
  }
}
