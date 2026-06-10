import 'package:flutter_test/flutter_test.dart';
import 'package:voicelingo/app/router/app_router.dart';

/// Auth/placement/onboarding gate matrisi. Bu tablo uygulamanın en korkutucu
/// sessiz-regresyon yüzeyini sabitler: yanlış bir dal kullanıcıyı login
/// döngüsüne ya da atlanmış onboarding'e sokar.
void main() {
  String? redirect({
    required bool signedIn,
    bool placementDone = false,
    bool onboardingDone = false,
    required String path,
  }) =>
      computeRedirect(
        signedIn: signedIn,
        placementDone: placementDone,
        onboardingDone: onboardingDone,
        path: path,
      );

  group('signed out', () {
    test('any app path bounces to /login', () {
      expect(redirect(signedIn: false, path: '/'), '/login');
      expect(redirect(signedIn: false, path: '/words'), '/login');
      expect(redirect(signedIn: false, path: '/settings'), '/login');
    });

    test('auth screens stay reachable', () {
      expect(redirect(signedIn: false, path: '/login'), isNull);
      expect(redirect(signedIn: false, path: '/reset-password'), isNull);
    });
  });

  group('signed in, coming from auth screens', () {
    test('login routes by gate progress', () {
      expect(redirect(signedIn: true, path: '/login'), '/placement-test');
      expect(
        redirect(signedIn: true, placementDone: true, path: '/login'),
        '/onboarding',
      );
      expect(
        redirect(
            signedIn: true,
            placementDone: true,
            onboardingDone: true,
            path: '/login'),
        '/',
      );
    });

    test('reset-password follows the same gates', () {
      expect(
          redirect(signedIn: true, path: '/reset-password'), '/placement-test');
      expect(
        redirect(
            signedIn: true,
            placementDone: true,
            onboardingDone: true,
            path: '/reset-password'),
        '/',
      );
    });
  });

  group('signed in, placement gate', () {
    test('placement pending forces /placement-test from anywhere', () {
      expect(redirect(signedIn: true, path: '/'), '/placement-test');
      expect(redirect(signedIn: true, path: '/words'), '/placement-test');
      expect(redirect(signedIn: true, path: '/onboarding'), '/placement-test');
    });

    test('placement pending on /placement-test stays put', () {
      expect(redirect(signedIn: true, path: '/placement-test'), isNull);
    });

    test('placement done while on /placement-test moves forward', () {
      expect(
        redirect(signedIn: true, placementDone: true, path: '/placement-test'),
        '/onboarding',
      );
      expect(
        redirect(
            signedIn: true,
            placementDone: true,
            onboardingDone: true,
            path: '/placement-test'),
        '/',
      );
    });
  });

  group('signed in, onboarding gate', () {
    test('onboarding pending forces /onboarding from app paths', () {
      expect(
        redirect(signedIn: true, placementDone: true, path: '/'),
        '/onboarding',
      );
      expect(
        redirect(signedIn: true, placementDone: true, path: '/words'),
        '/onboarding',
      );
    });

    test('onboarding pending on /onboarding stays put', () {
      expect(
        redirect(signedIn: true, placementDone: true, path: '/onboarding'),
        isNull,
      );
    });

    test('onboarding done on /onboarding goes home', () {
      expect(
        redirect(
            signedIn: true,
            placementDone: true,
            onboardingDone: true,
            path: '/onboarding'),
        '/',
      );
    });
  });

  test('fully gated user navigates freely', () {
    for (final path in ['/', '/words', '/settings', '/grammar', '/badges']) {
      expect(
        redirect(
            signedIn: true,
            placementDone: true,
            onboardingDone: true,
            path: path),
        isNull,
        reason: 'path: $path',
      );
    }
  });
}
