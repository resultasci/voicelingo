import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
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
    final l = AppL10n.of(context);
    final c = context.c;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(title: l.settings_title.toUpperCase()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _AccountSection(email: email),
                    const SizedBox(height: 16),
                    _CommunicationsSection(
                      enabled: _notificationsEnabled,
                      reviewHour: _reviewHour,
                      onToggle: _setNotifications,
                      onReviewHour: _setReviewHour,
                    ),
                    const SizedBox(height: 16),
                    _PreferencesSection(
                      language: _interfaceLanguage,
                      theme: _themeKey(themeMode),
                      onLang: _setLanguage,
                      onTheme: (s) => _setTheme(_decodeTheme(s)),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: l.settings_aiCoach,
                      button: true,
                      child: GhostButton(
                        label: l.settings_aiCoach,
                        icon: Icons.psychology_outlined,
                        color: c.secondaryContainer,
                        onTap: () => context.push('/character-picker'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: l.settings_progress,
                      button: true,
                      child: GhostButton(
                        label: l.settings_progressStats,
                        icon: Icons.insights_outlined,
                        color: c.primaryFixed,
                        onTap: () => context.push('/progress'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: l.settings_courseTree,
                      button: true,
                      child: GhostButton(
                        label: l.settings_courseTreeFull,
                        icon: Icons.account_tree_outlined,
                        color: c.success,
                        onTap: () => context.push('/lessons'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: l.settings_grammar,
                      button: true,
                      child: GhostButton(
                        label: l.settings_grammar,
                        icon: Icons.menu_book_outlined,
                        color: c.tertiary,
                        onTap: () => context.push('/grammar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: l.settings_badges,
                      button: true,
                      child: GhostButton(
                        label: l.settings_badges,
                        icon: Icons.emoji_events_outlined,
                        color: c.primaryContainer,
                        onTap: () => context.push('/badges'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Semantics(
                        label: l.auth_signOut,
                        button: true,
                        child: GhostButton(
                          label: l.settings_disconnect,
                          icon: Icons.logout,
                          color: c.error,
                          onTap: () => _confirmSignOut(context, ref),
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

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final c = context.c;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          glowColor: c.error,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionLabel(l.settings_disconnect, color: c.error),
              const SizedBox(height: 14),
              Text(
                l.settings_signOutConfirm,
                style: AppText.title(20,
                    color: c.primary, weight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: l.common_cancel,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: l.auth_signOut,
                      icon: Icons.logout,
                      color: c.error,
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
    final l = AppL10n.of(context);
    final c = context.c;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.primaryContainer.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(
              color: c.primaryContainer.withOpacity(0.08), blurRadius: 30),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            label: l.common_back,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: c.primaryContainer, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppText.label(13,
                        color: c.primaryContainer, weight: FontWeight.w700)
                    .copyWith(
                  shadows: neonGlow(c.primaryContainer, blur: 12, opacity: 0.8),
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
  const _AccountSection({required this.email});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return _Section(
      icon: Icons.person_outline,
      title: l.settings_account,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: l.settings_emailAddress,
            child: NeonField(
              controller: TextEditingController(text: email),
              readOnly: true,
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: l.auth_password,
            child: NeonField(
              controller: TextEditingController(text: '••••••••'),
              readOnly: true,
              obscure: true,
              suffix: Semantics(
                label: l.auth_changePassword,
                button: true,
                child: IconButton(
                  icon: Icon(Icons.edit, color: c.primaryContainer, size: 18),
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
            label: l.settings_downloadDeleteAccount,
            icon: Icons.security,
            color: c.error,
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

  const _CommunicationsSection({
    required this.enabled,
    required this.reviewHour,
    required this.onToggle,
    required this.onReviewHour,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return _Section(
      icon: Icons.notifications_outlined,
      title: l.settings_notifications,
      child: Column(
        children: [
          _ToggleRow(
            title: l.settings_dailyReviewReminder,
            subtitle: l.settings_reminderSubtitle,
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
                          l.settings_reminderTime,
                          style: AppText.ink(15,
                              color: c.ink, weight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(l.settings_onceADay,
                            style: AppText.label(9,
                                color: c.primaryContainer.withOpacity(0.6),
                                weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Semantics(
                    label: l.settings_reminderTime,
                    button: true,
                    child: TextButton(
                      onPressed: enabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    TimeOfDay(hour: reviewHour, minute: 0),
                                helpText: l.settings_reminderTime,
                              );
                              if (picked != null) {
                                onReviewHour(picked.hour);
                              }
                            }
                          : null,
                      child: Text(
                        '${reviewHour.toString().padLeft(2, '0')}:00',
                        style: AppText.title(16,
                            color: c.primaryContainer, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
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

  const _PreferencesSection({
    required this.language,
    required this.theme,
    required this.onLang,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return _Section(
      icon: Icons.tune,
      title: l.settings_systemPreferences,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: l.settings_language,
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
            label: l.settings_visualTheme,
            child: _NeonDropdown<String>(
              value: theme,
              items: [
                ('dark', l.settings_themeObsidian),
                ('light', l.settings_themeSolar),
                ('system', l.settings_themeSystemDefault),
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
    final c = context.c;
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: c.primaryContainer,
                  size: 24,
                  shadows:
                      neonGlow(c.primaryContainer, blur: 10, opacity: 0.6)),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppText.title(20,
                        color: c.primaryContainer, weight: FontWeight.w600)
                    .copyWith(
                  shadows: neonGlow(c.primaryContainer, blur: 10, opacity: 0.5),
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
              color: context.c.primaryContainer.withOpacity(0.7),
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
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: divider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.primaryContainer.withOpacity(0.10)),
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
                    style:
                        AppText.ink(15, color: c.ink, weight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle.toUpperCase(),
                    style: AppText.label(9,
                        color: c.primaryContainer.withOpacity(0.6),
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
    final c = context.c;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? c.primaryContainer.withOpacity(0.18) : c.surfaceHigh,
          border: Border.all(
            color: value ? c.primaryContainer : c.inkDim.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(99),
          boxShadow: value
              ? [
                  BoxShadow(
                      color: c.primaryContainer.withOpacity(0.2),
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
              color: value ? c.primaryContainer : c.inkDim,
              boxShadow: value
                  ? [
                      BoxShadow(
                          color: c.primaryContainer.withOpacity(0.8),
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
    final c = context.c;
    final hairline = (c.isDark ? Colors.white : Colors.black).withOpacity(0.05);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surfaceHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: c.bgElevated,
          icon: Icon(Icons.expand_more, color: c.primaryContainer, size: 20),
          style: AppText.ink(14, color: c.ink),
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
