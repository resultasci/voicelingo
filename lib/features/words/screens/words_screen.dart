import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/logger/app_logger.dart';
import '../../../models/word.dart';
import '../../../providers/words_provider.dart';
import '../../../theme/app_theme.dart';

class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({super.key});

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  bool _isReviewing = false;
  bool _isDone = false;
  bool _isSavingBatch = false;
  List<Word> _reviewQueue = [];
  int _reviewIndex = 0;
  bool _revealed = false;
  int _correct = 0;
  bool _isRating = false;
  final List<({String wordId, int quality})> _batch = [];
  final FlutterTts _tts = FlutterTts();

  final _searchCtrl = TextEditingController();
  String _filter = 'Tümü';
  String _query = '';

  static const _filters = ['Tümü', 'Tekrar Bekleyen', 'Öğrenilen', 'Yeni'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
    } catch (_) {
      // Speaker is best-effort; silent failure is fine.
    }
  }

  void _startReview() {
    final words = ref.read(wordsProvider).value ?? [];
    final due = words.where((w) => w.isDue).toList();
    if (due.isEmpty) return;
    setState(() {
      _reviewQueue = due;
      _reviewIndex = 0;
      _revealed = false;
      _correct = 0;
      _isReviewing = true;
      _isDone = false;
      _isRating = false;
      _batch.clear();
    });
  }

  Future<void> _rate(int quality) async {
    if (_isRating) return;
    if (_reviewIndex >= _reviewQueue.length) {
      setState(() {
        _isReviewing = false;
        _isDone = true;
      });
      return;
    }

    setState(() => _isRating = true);
    HapticFeedback.lightImpact();

    final word = _reviewQueue[_reviewIndex];
    if (quality >= 3) _correct++;
    _batch.add((wordId: word.id, quality: quality));

    if (_reviewIndex < _reviewQueue.length - 1) {
      setState(() {
        _reviewIndex++;
        _revealed = false;
        _isRating = false;
      });
    } else {
      setState(() => _isSavingBatch = true);
      try {
        await ref.read(wordsProvider.notifier).commitReviewBatch(_batch);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tekrar kaydedilemedi: $e',
                  style: AppText.ink(13, color: AppColors.error)),
            ),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _isReviewing = false;
        _isDone = true;
        _isRating = false;
        _isSavingBatch = false;
      });
    }
  }

  void _showAdd() {
    final wCtrl = TextEditingController();
    final tCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          glowColor: AppColors.primaryContainer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SectionLabel('Yeni Kelime',
                  color: AppColors.primaryContainer),
              const SizedBox(height: 14),
              Text(
                'Kütüphaneye ekle',
                style: AppText.title(22,
                        color: AppColors.primary, weight: FontWeight.w600)
                    .copyWith(
                  shadows: neonGlow(AppColors.primary, blur: 8, opacity: 0.4),
                ),
              ),
              const SizedBox(height: 22),
              Text('İNGİLİZCE',
                  style: AppText.label(10,
                      color: AppColors.inkMuted, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              NeonField(controller: wCtrl, autofocus: true, hint: 'word'),
              const SizedBox(height: 16),
              Text('TÜRKÇE',
                  style: AppText.label(10,
                      color: AppColors.inkMuted, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              NeonField(controller: tCtrl, hint: 'kelime'),
              const SizedBox(height: 22),
              NeonButton(
                label: 'Ekle',
                icon: Icons.add,
                onTap: () async {
                  final w = wCtrl.text.trim();
                  final t = tCtrl.text.trim();
                  if (w.isEmpty || t.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    AppLogger.info(
                        'Kullanıcı arayüzden yeni kelime eklemeyi denedi: $w',
                        tag: 'WordsScreen');
                    await ref.read(wordsProvider.notifier).addWord(w, t);
                  } on DuplicateWordException {
                    AppLogger.warning(
                        'Arayüzde kelime eklendi ama zaten vardı, uyarı gösteriliyor: $w',
                        tag: 'WordsScreen');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bu kelime zaten kütüphanende var.',
                          style: AppText.ink(13, color: AppColors.warn),
                        ),
                      ),
                    );
                  } catch (e, st) {
                    AppLogger.error(
                        'Arayüzden kelime eklenirken hata fırlatıldı', e, st);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kelime eklenemedi',
                            style: AppText.ink(13, color: AppColors.error)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Word> _applyFilter(List<Word> all) {
    Iterable<Word> r = all;
    switch (_filter) {
      case 'Tekrar Bekleyen':
        r = r.where((w) => w.isDue);
        break;
      case 'Öğrenilen':
        r = r.where((w) => w.repetitions >= 4 && !w.isDue);
        break;
      case 'Yeni':
        r = r.where((w) => w.repetitions == 0);
        break;
    }
    if (_query.isNotEmpty) {
      r = r.where((w) =>
          w.word.toLowerCase().contains(_query) ||
          w.translation.toLowerCase().contains(_query));
    }
    return r.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDone) {
      return _CompletionView(
        correct: _correct,
        total: _reviewQueue.length,
        onClose: () => setState(() {
          _isDone = false;
          _isReviewing = false;
        }),
      );
    }

    if (_isReviewing) {
      if (_isSavingBatch) {
        return Center(
          child: GlassPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryContainer),
                ),
                const SizedBox(height: 16),
                Text('Kaydediliyor…',
                    style: AppText.label(11,
                        color: AppColors.primaryContainer,
                        weight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }

      if (_reviewQueue.isEmpty || _reviewIndex >= _reviewQueue.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isReviewing = false;
              _isDone = true;
            });
          }
        });
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primaryContainer),
          ),
        );
      }

      return _ReviewView(
        word: _reviewQueue[_reviewIndex],
        index: _reviewIndex,
        total: _reviewQueue.length,
        revealed: _revealed,
        isRating: _isRating,
        onReveal: () => setState(() => _revealed = true),
        onRate: _rate,
        onClose: () => setState(() => _isReviewing = false),
      );
    }

    final wordsAsync = ref.watch(wordsProvider);

    return wordsAsync.when(
      data: (words) {
        final filtered = _applyFilter(words);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            _Header(count: words.length, onAdd: _showAdd),
            const SizedBox(height: 22),
            _SearchBar(controller: _searchCtrl),
            const SizedBox(height: 18),
            _FilterChips(
              filters: _filters,
              selected: _filter,
              onSelect: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 22),
            if (words.isEmpty)
              _EmptyState(onAdd: _showAdd)
            else if (filtered.isEmpty)
              _NoResults(query: _query)
            else
              _WordGrid(
                words: filtered,
                onDelete: (id) =>
                    ref.read(wordsProvider.notifier).deleteWord(id),
                onStartReview: words.any((w) => w.isDue) ? _startReview : null,
                onSpeak: _speak,
              ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primaryContainer),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getErrorMessage(context, e),
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.error)),
              const SizedBox(height: 16),
              GhostButton(
                label: 'Tekrar dene',
                icon: Icons.refresh,
                onTap: () => ref.invalidate(wordsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;
  const _Header({required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Kelime Kütüphanesi',
                style: AppText.hero(28,
                        color: AppColors.primary, weight: FontWeight.w700)
                    .copyWith(
                  shadows: neonGlow(AppColors.primary, blur: 12, opacity: 0.25),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.45),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add,
                      color: AppColors.onPrimary, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Bilişsel sözlüğün $count kelimeye genişledi.',
          style: AppText.body(14, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

// =============================================================================
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return NeonField(
      controller: controller,
      hint: 'Kelime veya çeviri ara…',
      leadingIcon: Icons.search,
    );
  }
}

// =============================================================================
class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final isSel = f == selected;
          return InkWell(
            onTap: () => onSelect(f),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSel
                    ? AppColors.primaryContainer.withOpacity(0.10)
                    : AppColors.bgCard.withOpacity(0.5),
                border: Border.all(
                  color: isSel
                      ? AppColors.primaryContainer
                      : AppColors.rule.withOpacity(0.6),
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  f.toUpperCase(),
                  style: AppText.label(10,
                      color: isSel
                          ? AppColors.primaryContainer
                          : AppColors.inkMuted,
                      weight: FontWeight.w700),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
class _WordGrid extends StatelessWidget {
  final List<Word> words;
  final void Function(String) onDelete;
  final VoidCallback? onStartReview;
  final Future<void> Function(String) onSpeak;
  const _WordGrid({
    required this.words,
    required this.onDelete,
    required this.onStartReview,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onStartReview != null) ...[
          _ReviewBanner(
            count: words.where((w) => w.isDue).length,
            onTap: onStartReview!,
          ),
          const SizedBox(height: 14),
        ],
        ...words.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WordCard(
                word: w,
                onDelete: () => onDelete(w.id),
                onSpeak: () => onSpeak(w.word),
              ),
            )),
      ],
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ReviewBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      borderColor: AppColors.primaryContainer.withOpacity(0.4),
      glowColor: AppColors.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.flash_on,
              color: AppColors.primaryContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BUGÜN TEKRAR',
                    style: AppText.label(9,
                        color: AppColors.primaryContainer,
                        weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$count kelime hazır',
                    style: AppText.title(16,
                        color: AppColors.primary, weight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward,
              color: AppColors.primaryContainer, size: 18),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final Word word;
  final VoidCallback onDelete;
  final VoidCallback onSpeak;
  const _WordCard({
    required this.word,
    required this.onDelete,
    required this.onSpeak,
  });

  ({String label, Color color, IconData? icon}) get _status {
    if (word.repetitions == 0) {
      return (
        label: 'Yeni',
        color: AppColors.primaryFixedDim,
        icon: Icons.auto_awesome
      );
    }
    if (word.isDue) {
      return (
        label: 'Tekrar',
        color: AppColors.secondaryContainer,
        icon: null,
      );
    }
    if (word.repetitions >= 4) {
      return (
        label: 'Öğrenildi',
        color: AppColors.primaryFixed,
        icon: Icons.check_circle_outline,
      );
    }
    return (
      label: 'Süreçte',
      color: AppColors.tertiaryFixedDim,
      icon: Icons.refresh,
    );
  }

  String get _intervalText {
    if (word.repetitions == 0) return 'YENİ';
    final d = word.intervalDays;
    if (d == 1) return '1G';
    if (d < 7) return '${d}G';
    if (d < 30) return '${(d / 7).round()}H';
    if (d < 365) return '${(d / 30).round()}A';
    return '${(d / 365).round()}Y';
  }

  double get _progress {
    if (word.repetitions == 0) return 0.05;
    return (word.repetitions / 6).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Dismissible(
      key: Key(word.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Semantics(
          label: 'Kelimeyi sil',
          child: const Icon(Icons.delete_outline,
              color: AppColors.error, size: 22),
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: () => context.push('/word-detail', extra: word),
        borderRadius: BorderRadius.circular(16),
        child: GlassPanel(
          padding: EdgeInsets.zero,
          glowColor: s.color,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.color.withOpacity(0.15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      word.word,
                                      style: AppText.title(22,
                                          color: AppColors.primary,
                                          weight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Semantics(
                                    label: 'Telaffuz et',
                                    button: true,
                                    child: InkWell(
                                      onTap: onSpeak,
                                      borderRadius: BorderRadius.circular(99),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(Icons.volume_up,
                                            color: AppColors.primaryContainer,
                                            size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (word.ipa != null && word.ipa!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  word.ipa!,
                                  style:
                                      AppText.code(11, color: AppColors.inkDim),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _intervalText,
                                style: AppText.label(10,
                                    color: AppColors.primaryContainer,
                                    weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        NeonChip(
                          text: s.label,
                          icon: s.icon,
                          color: s.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      word.translation,
                      style: AppText.ink(15, color: AppColors.ink),
                    ),
                    if (word.exampleSentence != null &&
                        word.exampleSentence!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        word.exampleSentence!,
                        style: AppText.body(12, color: AppColors.inkMuted)
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceHighest,
                        valueColor: AlwaysStoppedAnimation(s.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: GlassPanel(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withOpacity(0.10),
                border: Border.all(
                    color: AppColors.primaryContainer.withOpacity(0.3)),
              ),
              child: const Icon(Icons.menu_book,
                  color: AppColors.primaryContainer, size: 30),
            ),
            const SizedBox(height: 18),
            Text('Kütüphanen boş',
                style: AppText.title(22,
                    color: AppColors.primary, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Eklediğin her kelime SM-2 algoritması ile bilimsel aralıklarla karşına çıkar.',
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 22),
            NeonButton(
              label: 'İlk kelimeni ekle',
              icon: Icons.add,
              onTap: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off, color: AppColors.inkDim, size: 32),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'Bu filtre boş' : '"$query" için sonuç yok',
              style: AppText.body(13, color: AppColors.inkDim),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
class _CompletionView extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onClose;
  const _CompletionView({
    required this.correct,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final Color accent;
    final String grade;
    if (pct >= 80) {
      accent = AppColors.primaryFixed;
      grade = 'Harika!';
    } else if (pct >= 50) {
      accent = AppColors.secondary;
      grade = 'İyi iş!';
    } else {
      accent = AppColors.tertiaryFixedDim;
      grade = 'Devam et!';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          padding: const EdgeInsets.all(28),
          glowColor: accent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionLabel('Tekrar Tamamlandı', color: accent),
              const SizedBox(height: 20),
              Text(
                grade,
                style: AppText.hero(48, color: accent, weight: FontWeight.w700)
                    .copyWith(
                  shadows: neonGlow(accent, blur: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _StatPill(label: 'DOĞRU', value: '$correct', color: accent),
                  const SizedBox(width: 10),
                  _StatPill(
                      label: 'TOPLAM',
                      value: '$total',
                      color: AppColors.tertiaryFixedDim),
                  const SizedBox(width: 10),
                  _StatPill(label: 'BAŞARI', value: '%$pct', color: accent),
                ],
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: 'Kütüphaneye Dön',
                icon: Icons.arrow_back,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    AppText.title(22, color: color, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: AppText.label(8, color: color, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
class _ReviewView extends StatelessWidget {
  final Word word;
  final int index;
  final int total;
  final bool revealed;
  final bool isRating;
  final VoidCallback onReveal;
  final ValueChanged<int> onRate;
  final VoidCallback onClose;

  const _ReviewView({
    required this.word,
    required this.index,
    required this.total,
    required this.revealed,
    required this.isRating,
    required this.onReveal,
    required this.onRate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (index + 1) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close,
                    color: AppColors.inkMuted, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceHighest,
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryContainer),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${index + 1} / $total',
                  style: AppText.code(11, color: AppColors.inkMuted)),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onTap: revealed ? null : onReveal,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: GlassPanel(
                  padding: const EdgeInsets.all(36),
                  glowColor: AppColors.primaryContainer,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Çevir',
                          color: AppColors.primaryContainer),
                      const SizedBox(height: 22),
                      Text(
                        word.word,
                        style: AppText.hero(40,
                                color: AppColors.primary,
                                weight: FontWeight.w700)
                            .copyWith(
                          shadows: neonGlow(AppColors.primary,
                              blur: 14, opacity: 0.4),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                          height: 1, color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 22),
                      if (revealed)
                        Text(
                          word.translation,
                          style: AppText.title(
                            24,
                            color: AppColors.primaryContainer,
                            weight: FontWeight.w600,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text('DOKUNARAK GÖSTER',
                                style: AppText.label(10,
                                    color: AppColors.inkDim,
                                    weight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            const Icon(Icons.touch_app,
                                color: AppColors.inkDim, size: 14),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (revealed) ...[
            Text('NE KADAR BİLDİN?',
                style: AppText.label(10,
                    color: AppColors.inkDim, weight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              children: [
                _RateBtn(
                  label: 'Bilmedim',
                  color: AppColors.error,
                  disabled: isRating,
                  onTap: () => onRate(0),
                ),
                const SizedBox(width: 10),
                _RateBtn(
                  label: 'Zordu',
                  color: AppColors.secondary,
                  disabled: isRating,
                  onTap: () => onRate(3),
                ),
                const SizedBox(width: 10),
                _RateBtn(
                  label: 'Kolaydı',
                  color: AppColors.primaryFixed,
                  disabled: isRating,
                  onTap: () => onRate(5),
                ),
              ],
            ),
          ] else
            const SizedBox(height: 56),
        ],
      ),
    );
  }
}

class _RateBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;
  const _RateBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                border: Border.all(color: color.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.15), blurRadius: 12),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label.toUpperCase(),
                style: AppText.label(10, color: color, weight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
