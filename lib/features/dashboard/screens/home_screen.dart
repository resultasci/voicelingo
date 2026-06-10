import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/perf/device_tier.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/nav_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/level_up_dialog.dart';
import '../../conversation/screens/conversation_screen.dart';
import '../../onboarding/screens/placement_test_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../words/screens/words_screen.dart';
import '../widgets/lazy_indexed_stack.dart';
import 'dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _screens = [
    DashboardScreen(),
    WordsScreen(),
    ConversationScreen(showBackButton: false),
    ProfileScreen(),
  ];

  int? _previousLevel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => NotificationService().requestPermissions());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunPlacement());
  }

  Future<void> _maybeRunPlacement() async {
    if (!mounted) return;
    if (SettingsService().placementDone) return;
    final profile = await ref.read(profileProvider.future);
    if (!mounted) return;
    if (profile?.cefrLevel != null && profile!.cefrLevel!.isNotEmpty) {
      await SettingsService().setPlacementDone(true);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlacementTestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for level up events globally on HomeScreen
    ref.listen(profileProvider, (previous, next) {
      final currentLevel = next.value?.level;
      if (currentLevel != null) {
        if (_previousLevel != null && currentLevel > _previousLevel!) {
          // Level Up!
          Future.microtask(() {
            if (!mounted) return;
            LevelUpDialog.show(this.context, currentLevel);
          });
        }
        _previousLevel = currentLevel;
      }
    });

    final index = ref.watch(selectedTabProvider);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: context.c.bg,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: CosmicBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: padding.top + 64,
                  bottom: padding.bottom + 72 + 8,
                ),
                child: LazyIndexedStack(index: index, children: _screens),
              ),
            ),
            const _TopAppBar(),
            _BottomNav(
              index: index,
              onTap: (i) => ref.read(selectedTabProvider.notifier).state = i,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
class _TopAppBar extends ConsumerWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;

    final blur = DevicePerf.chromeBlurSigma;
    final chromeBase = c.isDark ? Colors.black : Colors.white;
    final hairline = (c.isDark ? Colors.white : Colors.black).withOpacity(0.08);
    Widget chromeContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: blur == 0
              ? [
                  chromeBase.withOpacity(0.82),
                  chromeBase.withOpacity(0.70),
                ]
              : [
                  chromeBase.withOpacity(0.55),
                  chromeBase.withOpacity(0.30),
                ],
        ),
        border: Border(
          bottom: BorderSide(color: hairline),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const BrandLogo(size: 34),
                const SizedBox(width: 12),
                Text(
                  'VOICELINGO',
                  style: AppText.title(18,
                          color: c.primaryContainer, weight: FontWeight.w700)
                      .copyWith(
                    letterSpacing: -0.4,
                    shadows:
                        neonGlow(c.primaryContainer, blur: 8, opacity: 0.5),
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: l.nav_settings,
                  button: true,
                  child: IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: c.inkDim, size: 26),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (blur > 0) {
      chromeContent = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: chromeContent,
      );
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(child: chromeContent),
    );
  }
}

// =============================================================================
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final items = [
      (Icons.grid_view_outlined, Icons.grid_view, l.nav_dashboard),
      (Icons.menu_book_outlined, Icons.menu_book, l.nav_words),
      (Icons.chat_bubble_outline, Icons.chat_bubble, l.nav_practice),
      (Icons.person_outline, Icons.person, l.nav_profile),
    ];
    final blur = DevicePerf.chromeBlurSigma;
    final chromeBase = c.isDark ? Colors.black : Colors.white;
    final hairline = (c.isDark ? Colors.white : Colors.black).withOpacity(0.10);
    Widget navContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: blur == 0
              ? [
                  chromeBase.withOpacity(0.85),
                  chromeBase.withOpacity(0.95),
                ]
              : [
                  chromeBase.withOpacity(0.55),
                  chromeBase.withOpacity(0.75),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: hairline),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.5 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final selected = i == index;
                final (off, on, label) = items[i];
                return _NavItem(
                  icon: selected ? on : off,
                  label: label,
                  selected: selected,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );

    if (blur > 0) {
      navContent = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: navContent,
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: navContent,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = selected ? c.primaryContainer : c.inkDim;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 76,
          transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
                shadows: selected
                    ? neonGlow(c.primaryContainer, blur: 10, opacity: 0.6)
                    : null,
                semanticLabel: null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppText.label(9,
                    color: color,
                    weight: selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
