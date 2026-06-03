import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/logger/app_logger.dart';
import '../../../l10n/generated/app_localizations.dart';
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
  // Stable filter identity keys (decoupled from localized labels).
  String _filter = 'all';
  String _query = '';

  static const _filters = ['all', 'due', 'learned', 'new'];

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
              content: Text(AppL10n.of(context).words_reviewSaveError,
                  style: AppText.ink(13, color: context.c.error)),
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
    final l = AppL10n.of(context);
    final wCtrl = TextEditingController();
    final tCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final c = ctx.c;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: GlassPanel(
            padding: const EdgeInsets.all(24),
            glowColor: c.primaryContainer,
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
                      color: c.rule,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SectionLabel(l.words_addNew, color: c.primaryContainer),
                const SizedBox(height: 14),
                Text(
                  l.words_addToLibrary,
                  style: AppText.title(22,
                          color: c.primary, weight: FontWeight.w600)
                      .copyWith(
                    shadows: neonGlow(c.primary, blur: 8, opacity: 0.4),
                  ),
                ),
                const SizedBox(height: 22),
                Text(l.words_labelEnglish,
                    style: AppText.label(10,
                        color: c.inkMuted, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                NeonField(
                    controller: wCtrl, autofocus: true, hint: l.words_hintWord),
                const SizedBox(height: 16),
                Text(l.words_labelTurkish,
                    style: AppText.label(10,
                        color: c.inkMuted, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                NeonField(controller: tCtrl, hint: l.words_hintTranslation),
                const SizedBox(height: 22),
                NeonButton(
                  label: l.common_add,
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
                            AppL10n.of(context).words_alreadyInLibrary,
                            style: AppText.ink(13, color: context.c.warn),
                          ),
                        ),
                      );
                    } catch (e, st) {
                      AppLogger.error(
                          'Arayüzden kelime eklenirken hata fırlatıldı', e, st);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppL10n.of(context).words_addFailed,
                              style: AppText.ink(13, color: context.c.error)),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Word> _applyFilter(List<Word> all) {
    Iterable<Word> r = all;
    switch (_filter) {
      case 'due':
        r = r.where((w) => w.isDue);
        break;
      case 'learned':
        r = r.where((w) => w.repetitions >= 4 && !w.isDue);
        break;
      case 'new':
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
    final l = AppL10n.of(context);
    final c = context.c;
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
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.primaryContainer),
                ),
                const SizedBox(height: 16),
                Text(l.common_saving,
                    style: AppText.label(11,
                        color: c.primaryContainer, weight: FontWeight.w700)),
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
        return Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: c.primaryContainer),
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
      loading: () => Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: c.primaryContainer),
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
                  style: AppText.body(13, color: c.error)),
              const SizedBox(height: 16),
              GhostButton(
                label: l.common_retry,
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
    final l = AppL10n.of(context);
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.words_libraryTitle,
                style: AppText.hero(28, color: c.primary, weight: FontWeight.w700)
                    .copyWith(
                  shadows: neonGlow(c.primary, blur: 12, opacity: 0.25),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: c.primaryContainer,
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
                        color: c.primaryContainer.withOpacity(0.45),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: c.onPrimary, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l.words_librarySubtitle(count),
          style: AppText.body(14, color: c.inkMuted),
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
      hint: AppL10n.of(context).words_searchHint,
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

  String _label(AppL10n l, String key) {
    switch (key) {
      case 'due':
        return l.words_filterDue;
      case 'learned':
        return l.words_filterLearned;
      case 'new':
        return l.words_filterNew;
      default:
        return l.words_filterAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
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
                    ? c.primaryContainer.withOpacity(0.10)
                    : c.bgCard.withOpacity(0.5),
                border: Border.all(
                  color: isSel
                      ? c.primaryContainer
                      : c.rule.withOpacity(0.6),
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: c.primaryContainer.withOpacity(0.2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _label(l, f).toUpperCase(),
                  style: AppText.label(10,
                      color: isSel ? c.primaryContainer : c.inkMuted,
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
        ...words.indexed.map((entry) {
          final (index, w) = entry;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StaggeredItem(
              index: index,
              child: _WordCard(
                word: w,
                onDelete: () => onDelete(w.id),
                onSpeak: () => onSpeak(w.word),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Wraps a list item in a brief fade + slide-up entrance, staggered by [index]
/// so cards cascade in. No-op (renders [child] directly) when motion is reduced.
class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem> {
  bool _shown = false;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (reduceMotion(context)) {
      _shown = true; // skip animation entirely
      return;
    }
    // Cap the cascade so far-down items don't wait too long.
    final delayMs = 40 * widget.index.clamp(0, 8);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ReviewBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      onTap: onTap,
      borderColor: c.primaryContainer.withOpacity(0.4),
      glowColor: c.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.flash_on, color: c.primaryContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.words_reviewToday,
                    style: AppText.label(9,
                        color: c.primaryContainer, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(l.words_wordsReady(count),
                    style: AppText.title(16,
                        color: c.primary, weight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: c.primaryContainer, size: 18),
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

  ({String label, Color color, IconData? icon}) _status(
      AppL10n l, AppPalette c) {
    if (word.repetitions == 0) {
      return (
        label: l.words_statusNew,
        color: c.primaryFixedDim,
        icon: Icons.auto_awesome
      );
    }
    if (word.isDue) {
      return (
        label: l.words_statusDue,
        color: c.secondaryContainer,
        icon: null,
      );
    }
    if (word.repetitions >= 4) {
      return (
        label: l.words_statusLearned,
        color: c.primaryFixed,
        icon: Icons.check_circle_outline,
      );
    }
    return (
      label: l.words_statusInProgress,
      color: c.tertiaryFixedDim,
      icon: Icons.refresh,
    );
  }

  String _intervalText(AppL10n l) {
    if (word.repetitions == 0) return l.words_intervalNew;
    final d = word.intervalDays;
    if (d == 1) return '1${l.words_unitDay}';
    if (d < 7) return '$d${l.words_unitDay}';
    if (d < 30) return '${(d / 7).round()}${l.words_unitWeek}';
    if (d < 365) return '${(d / 30).round()}${l.words_unitMonth}';
    return '${(d / 365).round()}${l.words_unitYear}';
  }

  double get _progress {
    if (word.repetitions == 0) return 0.05;
    return (word.repetitions / 6).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final s = _status(l, c);
    return Dismissible(
      key: Key(word.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: c.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Semantics(
          label: l.words_deleteWord,
          child: Icon(Icons.delete_outline, color: c.error, size: 22),
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: () => context.push('/word-detail', extra: word),
        borderRadius: BorderRadius.circular(16),
        child: GlassPanel(
          padding: EdgeInsets.zero,
          glowColor: s.color,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status accent sliver flush to the top edge.
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [s.color, s.color.withOpacity(0)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Circular mastery ring with the status icon at its
                          // center — replaces the old flat bottom progress bar.
                          _ProgressRing(
                            progress: _progress,
                            color: s.color,
                            track: c.surfaceHighest,
                            icon: s.icon,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.word,
                                  style: AppText.title(22,
                                      color: c.primary,
                                      weight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (word.ipa != null &&
                                    word.ipa!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    word.ipa!,
                                    style: AppText.code(11, color: c.inkDim),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  _intervalText(l),
                                  style: AppText.label(10,
                                      color: c.primaryContainer,
                                      weight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Prominent circular pronounce button.
                          Semantics(
                            label: l.words_pronounce,
                            button: true,
                            child: Material(
                              color: c.primaryContainer.withOpacity(0.12),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: onSpeak,
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(Icons.volume_up,
                                      color: c.primaryContainer, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              word.translation,
                              style: AppText.ink(15, color: c.ink),
                            ),
                          ),
                          const SizedBox(width: 8),
                          NeonChip(
                            text: s.label,
                            icon: s.icon,
                            color: s.color,
                          ),
                        ],
                      ),
                      if (word.exampleSentence != null &&
                          word.exampleSentence!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          word.exampleSentence!,
                          style: AppText.body(12, color: c.inkMuted)
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small circular mastery indicator: a status-colored ring over a faint track,
/// with the status icon centered. Reused only by [_WordCard].
class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color track;
  final IconData? icon;
  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.track,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (icon != null) Icon(icon, color: color, size: 18),
        ],
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
    final l = AppL10n.of(context);
    final c = context.c;
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
                color: c.primaryContainer.withOpacity(0.10),
                border:
                    Border.all(color: c.primaryContainer.withOpacity(0.3)),
              ),
              child:
                  Icon(Icons.menu_book, color: c.primaryContainer, size: 30),
            ),
            const SizedBox(height: 18),
            Text(l.words_emptyTitle,
                style: AppText.title(22,
                    color: c.primary, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              l.words_emptyBody,
              textAlign: TextAlign.center,
              style: AppText.body(13, color: c.inkMuted),
            ),
            const SizedBox(height: 22),
            NeonButton(
              label: l.words_addFirst,
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
    final l = AppL10n.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, color: c.inkDim, size: 32),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? l.words_filterEmpty : l.words_noResultsFor(query),
              style: AppText.body(13, color: c.inkDim),
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
    final l = AppL10n.of(context);
    final c = context.c;
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final Color accent;
    final String grade;
    if (pct >= 80) {
      accent = c.primaryFixed;
      grade = l.words_gradeGreat;
    } else if (pct >= 50) {
      accent = c.secondary;
      grade = l.words_gradeGood;
    } else {
      accent = c.tertiaryFixedDim;
      grade = l.words_gradeKeepGoing;
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
              SectionLabel(l.words_reviewComplete, color: accent),
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
                  _StatPill(
                      label: l.words_statCorrect,
                      value: '$correct',
                      color: accent),
                  const SizedBox(width: 10),
                  _StatPill(
                      label: l.words_statTotal,
                      value: '$total',
                      color: c.tertiaryFixedDim),
                  const SizedBox(width: 10),
                  _StatPill(
                      label: l.words_statSuccess,
                      value: l.dashboard_percentValue(pct),
                      color: accent),
                ],
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: l.words_backToLibrary,
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
    final l = AppL10n.of(context);
    final c = context.c;
    final progress = (index + 1) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, color: c.inkMuted, size: 22),
              ),
              const SizedBox(width: 8),
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
              Text('${index + 1} / $total',
                  style: AppText.code(11, color: c.inkMuted)),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onTap: revealed ? null : onReveal,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: GlassPanel(
                  padding: const EdgeInsets.all(36),
                  glowColor: c.primaryContainer,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(l.words_translate,
                          color: c.primaryContainer),
                      const SizedBox(height: 22),
                      Text(
                        word.word,
                        style: AppText.hero(40,
                                color: c.primary, weight: FontWeight.w700)
                            .copyWith(
                          shadows:
                              neonGlow(c.primary, blur: 14, opacity: 0.4),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                          height: 1,
                          color: (c.isDark ? Colors.white : Colors.black)
                              .withOpacity(0.08)),
                      const SizedBox(height: 22),
                      if (revealed)
                        Text(
                          word.translation,
                          style: AppText.title(
                            24,
                            color: c.primaryContainer,
                            weight: FontWeight.w600,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(l.words_tapToReveal,
                                style: AppText.label(10,
                                    color: c.inkDim, weight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Icon(Icons.touch_app, color: c.inkDim, size: 14),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (revealed) ...[
            Text(l.words_howWell,
                style: AppText.label(10,
                    color: c.inkDim, weight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              children: [
                _RateBtn(
                  label: l.words_rateForgot,
                  color: c.error,
                  disabled: isRating,
                  onTap: () => onRate(0),
                ),
                const SizedBox(width: 10),
                _RateBtn(
                  label: l.words_rateHard,
                  color: c.secondary,
                  disabled: isRating,
                  onTap: () => onRate(3),
                ),
                const SizedBox(width: 10),
                _RateBtn(
                  label: l.words_rateEasy,
                  color: c.primaryFixed,
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
