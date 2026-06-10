import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_character.dart';
import '../../../core/ai/character_avatar.dart';
import '../../../core/ai/characters.dart';
import '../../../core/audio/tts_speaker.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/characters_service.dart';

/// AI karakteri seçim ekranı. Card layout, her birinde avatar + bio +
/// "Sesini dinle" butonu. Seçim hem onboarding'de hem settings'ten erişilebilir.
///
/// [onSelected] verilirse picker bir alt-akış (onboarding) gibi davranır;
/// null ise standalone (Settings) — seçim yapılınca pop edilir.
class CharacterPickerScreen extends ConsumerStatefulWidget {
  const CharacterPickerScreen({super.key, this.onSelected});

  final void Function(AICharacter character)? onSelected;

  @override
  ConsumerState<CharacterPickerScreen> createState() =>
      _CharacterPickerScreenState();
}

class _CharacterPickerScreenState extends ConsumerState<CharacterPickerScreen> {
  late final TtsSpeaker _tts =
      TtsSpeaker(rate: ref.read(settingsServiceProvider).ttsRate);
  String? _previewingId;
  String? _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tts.setAwaitSpeakCompletion(true);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _previewingId = null);
    });
    _initSelected();
  }

  Future<void> _initSelected() async {
    final svc = ref.read(charactersServiceProvider);
    final current = await svc.getSelected();
    if (mounted) setState(() => _selectedId = current.id);
  }

  Future<void> _preview(AICharacter character) async {
    if (_previewingId == character.id) {
      await _tts.stop();
      if (mounted) setState(() => _previewingId = null);
      return;
    }
    setState(() => _previewingId = character.id);
    await _tts.configure(
      language: character.ttsLocale,
      pitch: character.ttsPitch,
      rate: character.ttsRate,
    );
    await _tts.speak(character.introLine, sanitize: false);
  }

  Future<void> _confirm() async {
    final id = _selectedId;
    if (id == null) return;
    setState(() => _saving = true);
    final svc = ref.read(charactersServiceProvider);
    await svc.setSelected(id);
    ref.invalidate(selectedCharacterProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    final character = AICharacters.byId(id);
    if (widget.onSelected != null) {
      widget.onSelected!(character);
    } else if (Navigator.canPop(context)) {
      Navigator.of(context).pop(character);
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final locale = ref.watch(localeProvider).languageCode;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.ink,
        title: Text(
          l.charPicker_title,
          style: AppText.title(18,
              color: c.primaryContainer, weight: FontWeight.w700),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  itemCount: AICharacters.all.length,
                  itemBuilder: (_, i) {
                    final character = AICharacters.all[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CharacterCard(
                        character: character,
                        selected: _selectedId == character.id,
                        playing: _previewingId == character.id,
                        locale: locale,
                        onTap: () => setState(() => _selectedId = character.id),
                        onPreview: () => _preview(character),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primaryContainer,
                      foregroundColor: c.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _selectedId == null || _saving ? null : _confirm,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            l.charPicker_start,
                            style: AppText.label(13,
                                color: c.onPrimary, weight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.selected,
    required this.playing,
    required this.locale,
    required this.onTap,
    required this.onPreview,
  });

  final AICharacter character;
  final bool selected;
  final bool playing;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final borderColor =
        selected ? c.primaryContainer : c.inkDim.withOpacity(0.2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.bgCard.withOpacity(selected ? 0.85 : 0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.primaryContainer.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            CharacterAvatar(
              character: character,
              size: 68,
              selected: selected,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        character.displayName,
                        style: AppText.title(17,
                            color: c.ink, weight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.primaryContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          character.accent,
                          style: AppText.label(9,
                              color: c.primaryContainer,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    character.bio(locale),
                    style: AppText.body(12, color: c.inkDim),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onPreview,
              icon: Icon(
                playing ? Icons.stop_circle : Icons.volume_up_outlined,
                color: playing ? c.tertiary : c.primaryContainer,
                size: 28,
              ),
              tooltip: l.charPicker_listen,
            ),
          ],
        ),
      ),
    );
  }
}
