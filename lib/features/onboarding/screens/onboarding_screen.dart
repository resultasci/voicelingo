import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/characters.dart';
import '../../../core/audio/audio_permission_service.dart';
import '../../../features/conversation/services/characters_service.dart';
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
            'Onboarding hatası: $e',
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
    // Mevcut requestPermissions() void dönüyor; izin gerçekten verildi mi
    // sonradan platform-specific kontrolle anlaşılır. Şimdilik istek atıldı
    // = "kullanıcı diyalogla karşılaştı" sayıyoruz; gating yumuşak.
    setState(() => _notifGranted = true);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isLast = _page == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppColors.bg,
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
                    _WelcomePage(locale: locale),
                    _PermissionsPage(
                      locale: locale,
                      micGranted: _micGranted,
                      notifGranted: _notifGranted,
                      onRequestMic: _requestMic,
                      onRequestNotif: _requestNotif,
                    ),
                    _GoalPage(
                      locale: locale,
                      selected: _dailyMinuteGoal,
                      onSelect: (v) => setState(() => _dailyMinuteGoal = v),
                    ),
                    _MotivationPage(
                      locale: locale,
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
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.inkDim),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimary,
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
                                isLast
                                    ? (locale == 'en'
                                        ? 'Start learning'
                                        : 'Başlayalım')
                                    : (locale == 'en' ? 'Continue' : 'Devam'),
                                style: AppText.label(13,
                                    color: AppColors.onPrimary,
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
                color: active
                    ? AppColors.primaryContainer
                    : AppColors.inkDim.withOpacity(0.15),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.5),
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
  const _WelcomePage({required this.locale});
  final String locale;

  @override
  Widget build(BuildContext context) {
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
              gradient: const RadialGradient(colors: [
                AppColors.primaryContainer,
                AppColors.secondaryContainer,
              ]),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withOpacity(0.5),
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
            locale == 'en'
                ? 'Welcome to VoiceLingo'
                : 'VoiceLingo\'ya hoş geldin',
            style: AppText.title(26,
                color: AppColors.ink, weight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            locale == 'en'
                ? 'Speak. Improve. Repeat.\nYour AI coach guides every conversation.'
                : 'Konuş. Gelişeceksin. Tekrarla.\nAI koçun her konuşmada yanında.',
            style:
                AppText.body(15, color: AppColors.inkDim).copyWith(height: 1.4),
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
    required this.locale,
    required this.micGranted,
    required this.notifGranted,
    required this.onRequestMic,
    required this.onRequestNotif,
  });
  final String locale;
  final bool micGranted;
  final bool notifGranted;
  final VoidCallback onRequestMic;
  final VoidCallback onRequestNotif;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            locale == 'en' ? 'Two quick permissions' : 'İki hızlı izin',
            style: AppText.title(22,
                color: AppColors.ink, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            locale == 'en'
                ? 'We need these to coach you properly.'
                : 'Düzgün koçluk yapabilmemiz için gerekli.',
            style: AppText.body(13, color: AppColors.inkDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _PermissionCard(
            icon: Icons.mic,
            title: locale == 'en' ? 'Microphone' : 'Mikrofon',
            description: locale == 'en'
                ? 'Hear your speech, give feedback on pronunciation.'
                : 'Konuşmanı duy, telaffuza geri bildirim ver.',
            granted: micGranted,
            onTap: onRequestMic,
            locale: locale,
          ),
          const SizedBox(height: 16),
          _PermissionCard(
            icon: Icons.notifications_active_outlined,
            title: locale == 'en' ? 'Notifications' : 'Bildirimler',
            description: locale == 'en'
                ? 'Gentle reminders to keep your streak alive.'
                : 'Streak\'ini canlı tutmak için nazik hatırlatmalar.',
            granted: notifGranted,
            onTap: onRequestNotif,
            locale: locale,
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
    required this.locale,
  });
  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onTap;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final accent = granted ? AppColors.success : AppColors.primaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.6),
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
                        color: AppColors.ink, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description,
                    style: AppText.body(12, color: AppColors.inkDim)
                        .copyWith(height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (granted)
            const Icon(Icons.check_circle, color: AppColors.success)
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppColors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onTap,
              child: Text(
                locale == 'en' ? 'Allow' : 'İzin ver',
                style: AppText.label(11,
                    color: AppColors.onPrimary, weight: FontWeight.w700),
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
    required this.locale,
    required this.selected,
    required this.onSelect,
  });
  final String locale;
  final int selected;
  final ValueChanged<int> onSelect;

  static const _options = [5, 10, 20, 30];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            locale == 'en' ? 'Your daily goal' : 'Günlük hedefin',
            style: AppText.title(22,
                color: AppColors.ink, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            locale == 'en'
                ? 'How many minutes per day?'
                : 'Günde kaç dakika çalışmak istersin?',
            style: AppText.body(13, color: AppColors.inkDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: _options
                .map((m) => _OptionTile(
                      label: '$m ${locale == 'en' ? 'min' : 'dk'}',
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
    required this.locale,
    required this.selected,
    required this.onSelect,
  });
  final String locale;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('work', Icons.work_outline, locale == 'en' ? 'Work' : 'İş'),
      ('exam', Icons.school_outlined, locale == 'en' ? 'Exam' : 'Sınav'),
      ('travel', Icons.flight_outlined, locale == 'en' ? 'Travel' : 'Seyahat'),
      ('hobby', Icons.spa_outlined, locale == 'en' ? 'Hobby' : 'Hobi'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            locale == 'en' ? 'Why are you learning?' : 'Neden öğreniyorsun?',
            style: AppText.title(22,
                color: AppColors.ink, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            locale == 'en'
                ? 'This helps us pick the right scenarios for you.'
                : 'Sana uygun senaryoları seçmemize yardım eder.',
            style: AppText.body(13, color: AppColors.inkDim),
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
              ? AppColors.primaryContainer.withOpacity(0.2)
              : AppColors.bgCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.inkDim.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppText.title(15,
              color: selected ? AppColors.primaryContainer : AppColors.ink,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            locale == 'en' ? 'Choose your coach' : 'Koçunu seç',
            style: AppText.title(22,
                color: AppColors.ink, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            locale == 'en'
                ? 'Each coach has a different voice and style. You can change this anytime in Settings.'
                : 'Her koçun farklı sesi ve tarzı var. Ayarlardan istediğin zaman değiştirebilirsin.',
            style: AppText.body(13, color: AppColors.inkDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: AICharacters.all.length,
              itemBuilder: (_, i) {
                final c = AICharacters.all[i];
                final selected = c.id == selectedId;
                final borderColor = selected
                    ? AppColors.primaryContainer
                    : AppColors.inkDim.withOpacity(0.2);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => onSelect(c.id),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            AppColors.bgCard.withOpacity(selected ? 0.85 : 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: borderColor, width: selected ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                AppColors.primaryContainer,
                                AppColors.secondaryContainer,
                              ]),
                            ),
                            alignment: Alignment.center,
                            child: Text(c.avatarEmoji,
                                style: const TextStyle(fontSize: 26)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(c.displayName,
                                        style: AppText.title(15,
                                            color: AppColors.ink,
                                            weight: FontWeight.w800)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c.accent,
                                        style: AppText.label(9,
                                            color: AppColors.primaryContainer,
                                            weight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.bio(locale),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppText.body(11, color: AppColors.inkDim),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: AppColors.primaryContainer),
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
    final color = selected ? AppColors.primaryContainer : AppColors.inkDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 130,
        height: 110,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer.withOpacity(0.16)
              : AppColors.bgCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.inkDim.withOpacity(0.2),
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
