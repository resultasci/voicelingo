import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/notification_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/app_theme.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../auth/screens/delete_account_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _notificationsEnabled;
  late int _reviewHour;
  late String _interfaceLanguage;

  @override
  void initState() {
    super.initState();
    final s = SettingsService();
    _notificationsEnabled = s.notificationsEnabled;
    _reviewHour = s.reviewHour;
    _interfaceLanguage = s.interfaceLanguage;
  }

  Future<void> _setNotifications(bool v) async {
    setState(() => _notificationsEnabled = v);
    await SettingsService().setNotificationsEnabled(v);
    if (!v) {
      await NotificationService().cancelAll();
    } else {
      // Reschedule will be re-driven on next words load; trigger it manually
      // by emitting a 0-due placeholder so the channel is set up immediately.
      await NotificationService().scheduleDailyReviewReminder(0);
    }
  }

  Future<void> _setReviewHour(int h) async {
    setState(() => _reviewHour = h);
    await SettingsService().setReviewHour(h);
    if (_notificationsEnabled) {
      await NotificationService().scheduleDailyReviewReminder(0);
    }
  }

  Future<void> _setLanguage(String lang) async {
    setState(() => _interfaceLanguage = lang);
    // localeProvider, SettingsService'i de günceller — tek kaynak.
    await ref.read(localeProvider.notifier).setLanguage(lang);
  }

  Future<void> _setTheme(ThemeMode m) async {
    await ref.read(themeModeProvider.notifier).setMode(m);
  }

  String _themeKey(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  ThemeMode _decodeTheme(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final isEn = locale == 'en';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(title: isEn ? 'SETTINGS' : 'AYARLAR'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _AccountSection(email: email, isEn: isEn),
                    const SizedBox(height: 16),
                    _CommunicationsSection(
                      enabled: _notificationsEnabled,
                      reviewHour: _reviewHour,
                      onToggle: _setNotifications,
                      onReviewHour: _setReviewHour,
                      isEn: isEn,
                    ),
                    const SizedBox(height: 16),
                    _PreferencesSection(
                      language: _interfaceLanguage,
                      theme: _themeKey(themeMode),
                      onLang: _setLanguage,
                      onTheme: (s) => _setTheme(_decodeTheme(s)),
                      isEn: isEn,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: isEn ? 'AI Coach' : 'AI Koç',
                      button: true,
                      child: GhostButton(
                        label: isEn ? 'AI Coach' : 'AI Koç',
                        icon: Icons.psychology_outlined,
                        color: AppColors.secondaryContainer,
                        onTap: () => context.push('/character-picker'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: isEn ? 'Progress' : 'İlerleme',
                      button: true,
                      child: GhostButton(
                        label:
                            isEn ? 'Progress & Stats' : 'İlerleme & İstatistik',
                        icon: Icons.insights_outlined,
                        color: AppColors.primaryFixed,
                        onTap: () => context.push('/progress'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: isEn ? 'Course Tree' : 'Ders Yolu',
                      button: true,
                      child: GhostButton(
                        label:
                            isEn ? 'Course Tree (A1-C2)' : 'Ders Yolu (A1-C2)',
                        icon: Icons.account_tree_outlined,
                        color: AppColors.success,
                        onTap: () => context.push('/lessons'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: isEn ? 'Grammar' : 'Gramer',
                      button: true,
                      child: GhostButton(
                        label: isEn ? 'Grammar' : 'Gramer',
                        icon: Icons.menu_book_outlined,
                        color: AppColors.tertiary,
                        onTap: () => context.push('/grammar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: isEn ? 'Badges' : 'Rozetler',
                      button: true,
                      child: GhostButton(
                        label: isEn ? 'Badges' : 'Rozetler',
                        icon: Icons.emoji_events_outlined,
                        color: AppColors.primaryContainer,
                        onTap: () => context.push('/badges'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Semantics(
                        label: isEn ? 'Sign Out' : 'Çıkış yap',
                        button: true,
                        child: GhostButton(
                          label: isEn ? 'Disconnect' : 'Çıkış Yap',
                          icon: Icons.logout,
                          color: AppColors.error,
                          onTap: () => _confirmSignOut(context, ref, isEn),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, WidgetRef ref, bool isEn) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          glowColor: AppColors.error,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionLabel(isEn ? 'Disconnect' : 'Çıkış',
                  color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                isEn
                    ? 'Are you sure you want to sign out?'
                    : 'Çıkmak istediğine emin misin?',
                style: AppText.title(20,
                    color: AppColors.primary, weight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: isEn ? 'Cancel' : 'Vazgeç',
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: isEn ? 'Sign Out' : 'Çıkış',
                      icon: Icons.logout,
                      color: AppColors.error,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// =============================================================================
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.primaryContainer.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.08),
              blurRadius: 30),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Geri',
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.primaryContainer, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppText.label(13,
                        color: AppColors.primaryContainer,
                        weight: FontWeight.w700)
                    .copyWith(
                  shadows: neonGlow(AppColors.primaryContainer,
                      blur: 12, opacity: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// =============================================================================
class _AccountSection extends StatelessWidget {
  final String email;
  final bool isEn;
  const _AccountSection({required this.email, required this.isEn});

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.person_outline,
      title: isEn ? 'Account' : 'Hesap',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: isEn ? 'Email Address' : 'E-Posta Adresi',
            child: NeonField(
              controller: TextEditingController(text: email),
              readOnly: true,
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: isEn ? 'Password' : 'Şifre',
            child: NeonField(
              controller: TextEditingController(text: '••••••••'),
              readOnly: true,
              obscure: true,
              suffix: Semantics(
                label: isEn ? 'Change password' : 'Şifre değiştir',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.edit,
                      color: AppColors.primaryContainer, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GhostButton(
            label: isEn
                ? 'Download Data / Delete Account'
                : 'Veri İndir / Hesabı Sil',
            icon: Icons.security,
            color: AppColors.error,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _CommunicationsSection extends StatelessWidget {
  final bool enabled;
  final int reviewHour;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onReviewHour;
  final bool isEn;

  const _CommunicationsSection({
    required this.enabled,
    required this.reviewHour,
    required this.onToggle,
    required this.onReviewHour,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.notifications_outlined,
      title: isEn ? 'Notifications' : 'Bildirimler',
      child: Column(
        children: [
          _ToggleRow(
            title:
                isEn ? 'Daily Review Reminder' : 'Günlük Tekrar Hatırlatması',
            subtitle: isEn
                ? 'One notification per day for due words'
                : 'Vadesi gelen kelimeler için günde bir bildirim',
            value: enabled,
            onChanged: onToggle,
            divider: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Reminder Time' : 'Hatırlatma Saati',
                          style: AppText.ink(15,
                              color: AppColors.ink, weight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(isEn ? 'ONCE A DAY' : 'GÜNDE BİR KEZ',
                            style: AppText.label(9,
                                color:
                                    AppColors.primaryContainer.withOpacity(0.6),
                                weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Semantics(
                    label: isEn ? 'Pick reminder time' : 'Hatırlatma saati seç',
                    button: true,
                    child: TextButton(
                      onPressed: enabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    TimeOfDay(hour: reviewHour, minute: 0),
                                helpText:
                                    isEn ? 'Reminder time' : 'Hatırlatma saati',
                              );
                              if (picked != null) {
                                onReviewHour(picked.hour);
                              }
                            }
                          : null,
                      child: Text(
                        '${reviewHour.toString().padLeft(2, '0')}:00',
                        style: AppText.title(16,
                            color: AppColors.primaryContainer,
                            weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Field(
            label: isEn ? 'COMING SOON' : 'YAKINDA',
            child: Opacity(
              opacity: 0.45,
              child: _ToggleRow(
                title: isEn ? 'System Updates' : 'Sistem Güncellemeleri',
                subtitle:
                    isEn ? 'New features — soon' : 'Yeni özellikler — yakında',
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _PreferencesSection extends StatelessWidget {
  final String language;
  final String theme;
  final ValueChanged<String> onLang;
  final ValueChanged<String> onTheme;
  final bool isEn;

  const _PreferencesSection({
    required this.language,
    required this.theme,
    required this.onLang,
    required this.onTheme,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.tune,
      title: isEn ? 'System Preferences' : 'Sistem Tercihleri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: isEn ? 'Interface Language' : 'Arayüz Dili',
            child: _NeonDropdown<String>(
              value: language,
              items: const [
                ('en', 'English'),
                ('tr', 'Türkçe'),
              ],
              onChanged: (v) => onLang(v ?? language),
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: isEn ? 'Visual Theme' : 'Görsel Tema',
            child: _NeonDropdown<String>(
              value: theme,
              items: [
                (
                  'dark',
                  isEn ? 'Obsidian Void (Dark)' : 'Obsidian Void (Karanlık)'
                ),
                (
                  'light',
                  isEn ? 'Solar Flare (Light)' : 'Solar Flare (Aydınlık)'
                ),
                ('system', isEn ? 'System Default' : 'Sistem ile uyumlu'),
              ],
              onChanged: (v) => onTheme(v ?? theme),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: AppColors.primaryContainer,
                  size: 24,
                  shadows: neonGlow(AppColors.primaryContainer,
                      blur: 10, opacity: 0.6)),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppText.title(20,
                        color: AppColors.primaryContainer,
                        weight: FontWeight.w600)
                    .copyWith(
                  shadows: neonGlow(AppColors.primaryContainer,
                      blur: 10, opacity: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.label(10,
              color: AppColors.primaryContainer.withOpacity(0.7),
              weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: divider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppColors.primaryContainer.withOpacity(0.10)),
              ),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.ink(15,
                        color: AppColors.ink, weight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle.toUpperCase(),
                    style: AppText.label(9,
                        color: AppColors.primaryContainer.withOpacity(0.6),
                        weight: FontWeight.w600)),
              ],
            ),
          ),
          Semantics(
            label: title,
            toggled: value,
            child: _NeonSwitch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _NeonSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NeonSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryContainer.withOpacity(0.18)
              : AppColors.surfaceHigh,
          border: Border.all(
            color: value
                ? AppColors.primaryContainer
                : AppColors.inkDim.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(99),
          boxShadow: value
              ? [
                  BoxShadow(
                      color: AppColors.primaryContainer.withOpacity(0.2),
                      blurRadius: 8),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.primaryContainer : AppColors.inkDim,
              boxShadow: value
                  ? [
                      BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.8),
                          blurRadius: 8),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _NeonDropdown<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  const _NeonDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.bgElevated,
          icon: const Icon(Icons.expand_more,
              color: AppColors.primaryContainer, size: 20),
          style: AppText.ink(14, color: AppColors.ink),
          borderRadius: BorderRadius.circular(12),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e.$1,
                    child: Text(e.$2),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
