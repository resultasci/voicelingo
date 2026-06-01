import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/ai/ai_character.dart';
import '../../../core/ai/characters.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
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
  late final FlutterTts _tts;
  String? _previewingId;
  String? _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.awaitSpeakCompletion(true);
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
    await _tts.setLanguage(character.ttsLocale);
    await _tts.setPitch(character.ttsPitch);
    await _tts.setSpeechRate(character.ttsRate);
    await _tts.speak(character.introLine);
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
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          locale == 'en' ? 'Pick your coach' : 'Koçunu seç',
          style: AppText.title(18,
              color: AppColors.primaryContainer, weight: FontWeight.w700),
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
                    final c = AICharacters.all[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CharacterCard(
                        character: c,
                        selected: _selectedId == c.id,
                        playing: _previewingId == c.id,
                        locale: locale,
                        onTap: () => setState(() => _selectedId = c.id),
                        onPreview: () => _preview(c),
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
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
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
                            locale == 'en'
                                ? 'Start with this coach'
                                : 'Bu koçla başla',
                            style: AppText.label(13,
                                color: AppColors.onPrimary,
                                weight: FontWeight.w700),
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
    final borderColor = selected
        ? AppColors.primaryContainer
        : AppColors.inkDim.withOpacity(0.2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withOpacity(selected ? 0.85 : 0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primaryContainer,
                  AppColors.secondaryContainer,
                ]),
              ),
              alignment: Alignment.center,
              child: Text(
                character.avatarEmoji,
                style: const TextStyle(fontSize: 36),
              ),
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
                            color: AppColors.ink, weight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          character.accent,
                          style: AppText.label(9,
                              color: AppColors.primaryContainer,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    character.bio(locale),
                    style: AppText.body(12, color: AppColors.inkDim),
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
                color:
                    playing ? AppColors.tertiary : AppColors.primaryContainer,
                size: 28,
              ),
              tooltip: locale == 'en' ? 'Listen to voice' : 'Sesini dinle',
            ),
          ],
        ),
      ),
    );
  }
}
