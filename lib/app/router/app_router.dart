import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/word.dart';
import '../../core/services/settings_service.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/conversation/screens/character_picker_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/gamification/screens/badges_screen.dart';
import '../../features/grammar/models/grammar_topic.dart';
import '../../features/grammar/screens/grammar_screen.dart';
import '../../features/grammar/screens/topic_detail_screen.dart';
import '../../features/lessons/models/course.dart';
import '../../features/lessons/screens/course_tree_screen.dart';
import '../../features/lessons/screens/lesson_runner_screen.dart';
import '../../features/lessons/screens/unit_detail_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/placement_test_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/progress/screens/progress_dashboard_screen.dart';
import '../../features/scenarios/screens/scenario_builder_screen.dart';
import '../../features/scenarios/screens/scenarios_gallery_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/words/screens/word_detail_screen.dart';
import '../../features/words/screens/words_screen.dart';

final supabase = Supabase.instance.client;

/// `Supabase.auth.onAuthStateChange` Stream'ini GoRouter'ın izleyebileceği
/// `Listenable`'a sarar. Auth değişince `notifyListeners()` çağrılır → router
/// `redirect`'i yeniden değerlendirir → signOut otomatik `/login`'e gider.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _sub = supabase.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Auth/placement/onboarding gate matrisi — saf fonksiyon, tablo testiyle
/// korunur (`test/app/router_redirect_test.dart`). null = yönlendirme yok.
@visibleForTesting
String? computeRedirect({
  required bool signedIn,
  required bool placementDone,
  required bool onboardingDone,
  required String path,
}) {
  final isLoggingIn = path == '/login';
  final isResettingPassword = path == '/reset-password';
  final isTakingPlacementTest = path == '/placement-test';
  final isOnboarding = path == '/onboarding';

  if (!signedIn && !isLoggingIn && !isResettingPassword) {
    return '/login';
  }

  if (signedIn) {
    // Auth ekranlarından geliyorsa uygun yere yönlendir
    if (isLoggingIn || isResettingPassword) {
      if (!placementDone) return '/placement-test';
      if (!onboardingDone) return '/onboarding';
      return '/';
    }

    // Placement henüz yapılmamışsa öncelikli
    if (!placementDone && !isTakingPlacementTest) {
      return '/placement-test';
    }
    if (placementDone && isTakingPlacementTest) {
      // Placement biter, onboarding'e geç
      return onboardingDone ? '/' : '/onboarding';
    }

    // Placement OK ama onboarding bekliyor
    if (placementDone && !onboardingDone && !isOnboarding) {
      return '/onboarding';
    }
    // Onboarding tamamsa ve hala /onboarding'de duruyorsa eve gönder
    if (onboardingDone && isOnboarding) {
      return '/';
    }
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final settings = ref.read(settingsServiceProvider);
      return computeRedirect(
        signedIn: supabase.auth.currentSession != null,
        placementDone: settings.placementDone,
        onboardingDone: settings.onboardingDone,
        path: state.uri.toString(),
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/placement-test',
        builder: (context, state) => const PlacementTestScreen(),
      ),
      // Need a shell route for Bottom Navigation Bar later, but for now simple routing
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/words',
        builder: (context, state) => const WordsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: '/character-picker',
        builder: (context, state) => const CharacterPickerScreen(),
      ),
      GoRoute(
        path: '/grammar',
        builder: (context, state) => const GrammarScreen(),
        routes: [
          GoRoute(
            path: ':topicId',
            redirect: (context, state) {
              // extra GrammarTopic değilse listeye dön.
              return state.extra is GrammarTopic ? null : '/grammar';
            },
            builder: (context, state) =>
                TopicDetailScreen(topic: state.extra as GrammarTopic),
          ),
        ],
      ),
      GoRoute(
        path: '/word-detail',
        redirect: (context, state) {
          // extra Word değilse ana sayfaya geri dön (deep link veya geçersiz state).
          return state.extra is Word ? null : '/';
        },
        builder: (context, state) =>
            WordDetailScreen(word: state.extra as Word),
      ),
      GoRoute(
        path: '/scenarios',
        builder: (context, state) => const ScenariosGalleryScreen(),
      ),
      GoRoute(
        path: '/scenario-builder',
        builder: (context, state) => const ScenarioBuilderScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressDashboardScreen(),
      ),
      GoRoute(
        path: '/lessons',
        builder: (context, state) => const CourseTreeScreen(),
        routes: [
          GoRoute(
            path: 'unit/:unitId',
            redirect: (context, state) =>
                state.extra is CourseUnit ? null : '/lessons',
            builder: (context, state) =>
                UnitDetailScreen(unit: state.extra as CourseUnit),
          ),
          GoRoute(
            path: 'run/:lessonId',
            redirect: (context, state) =>
                state.extra is Lesson ? null : '/lessons',
            builder: (context, state) =>
                LessonRunnerScreen(lesson: state.extra as Lesson),
          ),
        ],
      ),
    ],
  );
});
