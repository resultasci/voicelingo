import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/tts_speaker.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/word.dart';
import '../../../core/theme/app_theme.dart';
import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';

/// Kelime detay sayfası — IPA, örnekler, eş anlamlılar, etimoloji.
///
/// İlk açılışta cache'i okur; AI enrichment varsa kullanır, yoksa fetch eder.
class WordDetailScreen extends ConsumerStatefulWidget {
  const WordDetailScreen({super.key, required this.word});
  final Word word;

  @override
  ConsumerState<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends ConsumerState<WordDetailScreen> {
  final TtsSpeaker _tts = TtsSpeaker();

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

  Future<void> _speak(String text) => _tts.speak(text);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final entryAsync = ref.watch(dictionaryEntryProvider(widget.word.word));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.ink,
        title: Text(
          widget.word.word,
          style: AppText.title(18,
              color: c.primaryContainer, weight: FontWeight.w700),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Header(
                word: widget.word,
                onSpeak: () => _speak(widget.word.word),
              ),
              const SizedBox(height: 20),
              entryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    _SectionPlaceholder(text: l.wordDetail_loadError),
                data: (entry) {
                  if (entry == null) {
                    return _SectionPlaceholder(text: l.wordDetail_noCache);
                  }
                  return _EnrichedSections(
                    entry: entry,
                    fallbackIpa: widget.word.ipa,
                    fallbackExample: widget.word.exampleSentence,
                    onSpeak: _speak,
                  );
                },
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
  const _Header({required this.word, required this.onSpeak});
  final Word word;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.bgCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.primaryContainer.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: c.primaryContainer.withOpacity(0.18),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style:
                      AppText.hero(28, color: c.ink, weight: FontWeight.w800),
                ),
                if (word.translation.isNotEmpty)
                  Text(
                    word.translation,
                    style: AppText.body(15, color: c.inkDim),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primaryContainer.withOpacity(0.18),
              border: Border.all(color: c.primaryContainer.withOpacity(0.5)),
            ),
            child: IconButton(
              icon: Icon(Icons.volume_up, color: c.primaryContainer, size: 24),
              onPressed: onSpeak,
              tooltip: l.words_pronounce,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _EnrichedSections extends StatelessWidget {
  const _EnrichedSections({
    required this.entry,
    required this.fallbackIpa,
    required this.fallbackExample,
    required this.onSpeak,
  });
  final DictionaryEntry entry;
  final String? fallbackIpa;
  final String? fallbackExample;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final ipa = entry.ipa ?? fallbackIpa;
    final examples = entry.examples.isNotEmpty
        ? entry.examples
        : (fallbackExample != null && fallbackExample!.isNotEmpty
            ? [DictExample(en: fallbackExample!)]
            : <DictExample>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ipa != null && ipa.isNotEmpty) ...[
          const _SectionHeader(title: 'IPA'),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: ipa));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.wordDetail_ipaCopied),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: _PillBox(
              child: Text(
                ipa,
                style: AppText.title(18,
                    color: c.primaryContainer, weight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (examples.isNotEmpty) ...[
          _SectionHeader(title: l.wordDetail_examples),
          for (final ex in examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PillBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ex.en,
                        style: AppText.title(14,
                            color: c.ink, weight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up_outlined,
                          color: c.primaryContainer, size: 20),
                      onPressed: () => onSpeak(ex.en),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (entry.synonyms.isNotEmpty) ...[
          _SectionHeader(title: l.wordDetail_synonyms),
          _ChipRow(items: entry.synonyms, color: c.success),
          const SizedBox(height: 18),
        ],
        if (entry.antonyms.isNotEmpty) ...[
          _SectionHeader(title: l.wordDetail_antonyms),
          _ChipRow(items: entry.antonyms, color: c.error),
          const SizedBox(height: 18),
        ],
        if (entry.collocations.isNotEmpty) ...[
          _SectionHeader(title: l.wordDetail_collocations),
          _ChipRow(items: entry.collocations, color: c.secondaryContainer),
          const SizedBox(height: 18),
        ],
        if (entry.etymologyBrief != null &&
            entry.etymologyBrief!.isNotEmpty) ...[
          _SectionHeader(title: l.wordDetail_etymology),
          _PillBox(
            child: Text(
              entry.etymologyBrief!,
              style: AppText.body(13, color: c.inkMuted).copyWith(height: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        title.toUpperCase(),
        style: AppText.label(11,
            color: context.c.primaryContainer, weight: FontWeight.w700),
      ),
    );
  }
}

class _PillBox extends StatelessWidget {
  const _PillBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.inkDim.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.items, required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                i,
                style: AppText.label(11, color: color, weight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.inkDim.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: AppText.body(13, color: c.inkDim),
      ),
    );
  }
}
