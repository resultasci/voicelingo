import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/character_avatar.dart';
import '../../../core/ai/characters.dart';
import '../../../core/audio/audio_permission_service.dart';
import '../../../features/conversation/services/characters_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../services/onboarding_service.dart';

/// 4 adımlı onboarding: welcome → permissions → goal → motivation.
/// Her adımdan sonra Continue butonu enable olur; geri gidilebilir.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  static const _totalPages = 5;
  int _page = 0;
  int _dailyMinuteGoal = 10;
  String _motivation = 'hobby';
  bool _micGranted = false;
  bool _notifGranted = false;
  String _selectedCharacterId = AICharacters.defaultCharacter.id;
  bool _saving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _totalPages - 1) {
      setState(() => _page += 1);
      await _pageCtrl.animateToPage(
        _page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _back() async {
    if (_page == 0) return;
    setState(() => _page -= 1);
    await _pageCtrl.animateToPage(
      _page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final svc = ref.read(onboardingServiceProvider);
      final characters = ref.read(charactersServiceProvider);
      await svc.savePreferences(
        dailyMinuteGoal: _dailyMinuteGoal,
        motivation: _motivation,
      );
      await characters.setSelected(_selectedCharacterId);
      ref.invalidate(selectedCharacterProvider);
      await svc.complete();
      if (!mounted) return;
      context.go('/');
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.red.shade900,
          content: Text(
            AppL10n.of(context).onb_error('$e'),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
      debugPrint('Onboarding _finish failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestMic() async {
    final svc = ref.read(audioPermissionServiceProvider);
    final status = await svc.request();
    if (!mounted) return;
    setState(() => _micGranted = status == MicPermissionStatus.granted);
  }

  Future<void> _requestNotif() async {
    await NotificationService().requestPermissions();
    if (!mounted) return;
    setState(() => _notifGranted = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final locale = ref.watch(localeProvider).languageCode;
    final isLast = _page == _totalPages - 1;

    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              _ProgressBar(page: _page, totalPages: _totalPages),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const _WelcomePage(),
                    _PermissionsPage(
                      micGranted: _micGranted,
                      notifGranted: _notifGranted,
                      onRequestMic: _requestMic,
                      onRequestNotif: _requestNotif,
                    ),
                    _GoalPage(
                      selected: _dailyMinuteGoal,
                      onSelect: (v) => setState(() => _dailyMinuteGoal = v),
                    ),
                    _MotivationPage(
                      selected: _motivation,
                      onSelect: (v) => setState(() => _motivation = v),
                    ),
                    _CharacterPage(
                      locale: locale,
                      selectedId: _selectedCharacterId,
                      onSelect: (id) =>
                          setState(() => _selectedCharacterId = id),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (_page > 0)
                      IconButton(
                        onPressed: _back,
                        icon: Icon(Icons.arrow_back, color: c.inkDim),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primaryContainer,
                          foregroundColor: c.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _next,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isLast ? l.onb_start : l.onb_continue,
                                style: AppText.label(13,
                                    color: c.onPrimary,
                                    weight: FontWeight.w700),
                              ),
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
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.page, required this.totalPages});
  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: List.generate(totalPages, (i) {
          final active = i <= page;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: active ? c.primaryContainer : c.inkDim.withOpacity(0.15),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: c.primaryContainer.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                c.primaryContainer,
                c.secondaryContainer,
              ]),
              boxShadow: [
                BoxShadow(
                  color: c.primaryContainer.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 56),
          ),
          const SizedBox(height: 32),
          Text(
            l.onb_welcomeTitle,
            style: AppText.title(26, color: c.ink, weight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l.onb_welcomeBody,
            style: AppText.body(15, color: c.inkDim).copyWith(height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    required this.micGranted,
    required this.notifGranted,
    required this.onRequestMic,
    required this.onRequestNotif,
  });
  final bool micGranted;
  final bool notifGranted;
  final VoidCallback onRequestMic;
  final VoidCallback onRequestNotif;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l.onb_permTitle,
            style: AppText.title(22, color: c.ink, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l.onb_permSubtitle,
            style: AppText.body(13, color: c.inkDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _PermissionCard(
            icon: Icons.mic,
            title: l.onb_micTitle,
            description: l.onb_micDesc,
            granted: micGranted,
            onTap: onRequestMic,
          ),
          const SizedBox(height: 16),
          _PermissionCard(
            icon: Icons.notifications_active_outlined,
            title: l.settings_notifications,
            description: l.onb_notifDesc,
            granted: notifGranted,
            onTap: onRequestNotif,
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final accent = granted ? c.success : c.primaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.18),
              border: Border.all(color: accent.withOpacity(0.5)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.title(15,
                        color: c.ink, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description,
                    style: AppText.body(12, color: c.inkDim)
                        .copyWith(height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (granted)
            Icon(Icons.check_circle, color: c.success)
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: c.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onTap,
              child: Text(
                l.onb_allow,
                style: AppText.label(11,
                    color: c.onPrimary, weight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.selected,
    required this.onSelect,
  });
  final int selected;
  final ValueChanged<int> onSelect;

  static const _options = [5, 10, 20, 30];

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l.onb_goalTitle,
            style: AppText.title(22, color: c.ink, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l.onb_goalSubtitle,
            style: AppText.body(13, color: c.inkDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: _options
                .map((m) => _OptionTile(
                      label: '$m ${l.onb_minSuffix}',
                      selected: m == selected,
                      onTap: () => onSelect(m),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _MotivationPage extends StatelessWidget {
  const _MotivationPage({
    required this.selected,
    required this.onSelect,
  });
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final items = [
      ('work', Icons.work_outline, l.scen_catWork),
      ('exam', Icons.school_outlined, l.onb_motivExam),
      ('travel', Icons.flight_outlined, l.scen_catTravel),
      ('hobby', Icons.spa_outlined, l.onb_motivHobby),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l.onb_motivTitle,
            style: AppText.title(22, color: c.ink, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l.onb_motivSubtitle,
            style: AppText.body(13, color: c.inkDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: items.map((tuple) {
              final (code, icon, label) = tuple;
              return _IconOptionTile(
                icon: icon,
                label: label,
                selected: code == selected,
                onTap: () => onSelect(code),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 110,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? c.primaryContainer.withOpacity(0.2)
              : c.bgCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? c.primaryContainer : c.inkDim.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppText.title(15,
              color: selected ? c.primaryContainer : c.ink,
              weight: FontWeight.w700),
        ),
      ),
    );
  }
}

// =============================================================================
class _CharacterPage extends StatelessWidget {
  const _CharacterPage({
    required this.locale,
    required this.selectedId,
    required this.onSelect,
  });
  final String locale;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l.charPicker_title,
            style: AppText.title(22, color: c.ink, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l.onb_charSubtitle,
            style: AppText.body(13, color: c.inkDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: AICharacters.all.length,
              itemBuilder: (_, i) {
                final character = AICharacters.all[i];
                final selected = character.id == selectedId;
                final borderColor =
                    selected ? c.primaryContainer : c.inkDim.withOpacity(0.2);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => onSelect(character.id),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.bgCard.withOpacity(selected ? 0.85 : 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: borderColor, width: selected ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          CharacterAvatar(
                            character: character,
                            size: 52,
                            selected: selected,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(character.displayName,
                                        style: AppText.title(15,
                                            color: c.ink,
                                            weight: FontWeight.w800)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c.primaryContainer
                                            .withOpacity(0.15),
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
                                const SizedBox(height: 2),
                                Text(
                                  character.bio(locale),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(11, color: c.inkDim),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle, color: c.primaryContainer),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _IconOptionTile extends StatelessWidget {
  const _IconOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = selected ? c.primaryContainer : c.inkDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 130,
        height: 110,
        decoration: BoxDecoration(
          color: selected
              ? c.primaryContainer.withOpacity(0.16)
              : c.bgCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? c.primaryContainer : c.inkDim.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppText.label(13, color: color, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
