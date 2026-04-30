import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/Splash/splash_view.dart';

void main() {
  group('resolveStartupManifestRouteHint', () {
    test('returns manifest route hint while manifest is fresh', () {
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 1000,
          freshWindowMs: 5000,
          routeHint: 'nav_explore',
        ),
        'nav_explore',
      );
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 1000,
          freshWindowMs: 5000,
          routeHint: 'nav_profile',
        ),
        'nav_profile',
      );
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 1000,
          freshWindowMs: 5000,
          routeHint: 'nav_education',
        ),
        'nav_education',
      );
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 1000,
          freshWindowMs: 5000,
          routeHint: 'nav_feed',
        ),
        'nav_feed',
      );
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 1000,
          freshWindowMs: 5000,
          routeHint: 'nav_home',
        ),
        'nav_home',
      );
    });

    test('trims accepted manifest route hints', () {
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 1000,
          freshWindowMs: 5000,
          routeHint: ' nav_profile ',
        ),
        'nav_profile',
      );
    });

    test('keeps route hint fresh at the exact freshness boundary', () {
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 5000,
          freshWindowMs: 5000,
          routeHint: 'nav_explore',
        ),
        'nav_explore',
      );
    });

    test('falls back to unknown when manifest is stale or invalid', () {
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: null,
          freshWindowMs: 5000,
          routeHint: 'nav_explore',
        ),
        'unknown',
      );
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: -1,
          freshWindowMs: 5000,
          routeHint: 'nav_profile',
        ),
        'unknown',
      );
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 6000,
          freshWindowMs: 5000,
          routeHint: 'nav_explore',
        ),
        'unknown',
      );
      expect(
        resolveStartupManifestRouteHint(
          manifestAgeMs: 1000,
          freshWindowMs: 5000,
          routeHint: 'unexpected_route',
        ),
        'unknown',
      );
    });
  });
}
