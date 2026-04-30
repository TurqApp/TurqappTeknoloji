import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Runtime/app_decision_coordinator.dart';
import 'package:turqappv2/Runtime/startup_decision.dart';

void main() {
  group('AppDecisionCoordinator', () {
    const coordinator = AppDecisionCoordinator();

    test('normalizes startup route hints in one runtime helper', () {
      expect(startupRouteHintKind('nav_feed'), StartupRouteHint.feed);
      expect(startupRouteHintKind('nav_home'), StartupRouteHint.home);
      expect(startupRouteHintKind('nav_explore'), StartupRouteHint.explore);
      expect(startupRouteHintKind('nav_profile'), StartupRouteHint.profile);
      expect(
        startupRouteHintKind('nav_education'),
        StartupRouteHint.education,
      );
      expect(startupRouteHintKind('unexpected'), StartupRouteHint.unknown);
      expect(normalizeStartupRouteHint('nav_feed'), 'nav_feed');
      expect(normalizeStartupRouteHint('nav_home'), 'nav_home');
      expect(normalizeStartupRouteHint('nav_explore'), 'nav_explore');
      expect(normalizeStartupRouteHint('nav_profile'), 'nav_profile');
      expect(normalizeStartupRouteHint('nav_education'), 'nav_education');
      expect(normalizeStartupRouteHint(' nav_profile '), 'nav_profile');
      expect(normalizeStartupRouteHint('unexpected'), 'unknown');
      expect(normalizeStartupRouteHint(''), 'unknown');
    });

    test('centralizes startup route hints that require warm readiness', () {
      expect(startupRouteHintRequiresWarmReadiness('nav_explore'), isTrue);
      expect(startupRouteHintRequiresWarmReadiness('nav_profile'), isTrue);
      expect(startupRouteHintRequiresWarmReadiness(' nav_profile '), isTrue);
      expect(startupRouteHintRequiresWarmReadiness('nav_education'), isTrue);
      expect(startupRouteHintRequiresWarmReadiness('nav_feed'), isFalse);
      expect(startupRouteHintRequiresWarmReadiness('nav_home'), isFalse);
      expect(startupRouteHintRequiresWarmReadiness(''), isFalse);
      expect(startupRouteHintRequiresWarmReadiness('unexpected'), isFalse);
    });

    test('route hint parser reuses enum values instead of duplicate literals',
        () {
      final source =
          File('lib/Runtime/app_decision_coordinator.dart').readAsStringSync();
      final parserStart =
          source.indexOf('StartupRouteHint startupRouteHintKind(');
      final parserEnd =
          source.indexOf('String normalizeStartupRouteHint', parserStart);
      final parserBody = source.substring(parserStart, parserEnd);

      expect(parserStart, isNonNegative);
      expect(parserEnd, greaterThan(parserStart));
      expect(parserBody, contains('StartupRouteHint.values'));
      expect(parserBody, contains('hint.value == normalized'));
      expect(parserBody, isNot(contains("case 'nav_")));
      expect(parserBody, isNot(contains("return StartupRouteHint.feed;")));
      expect(parserBody, isNot(contains("return StartupRouteHint.profile;")));
      expect(parserBody, isNot(contains("return StartupRouteHint.education;")));
    });

    test('StartupDecision copyWith preserves and clears primary tab explicitly',
        () {
      const decision = StartupDecision(
        authState: StartupAuthState.authenticated,
        rootTarget: StartupRootTarget.authenticatedHome,
        primaryTab: StartupPrimaryTab.profile,
        effectiveUserId: 'uid-1',
        minimumStartupPrepared: true,
      );

      final preserved = decision.copyWith(degraded: true);
      final replaced = decision.copyWith(primaryTab: StartupPrimaryTab.explore);
      final cleared = decision.copyWith(
        rootTarget: StartupRootTarget.signIn,
        clearPrimaryTab: true,
        effectiveUserId: '',
        fallbackReason: 'signed_out',
      );

      expect(preserved.primaryTab, StartupPrimaryTab.profile);
      expect(preserved.degraded, isTrue);
      expect(replaced.primaryTab, StartupPrimaryTab.explore);
      expect(cleared.rootTarget, StartupRootTarget.signIn);
      expect(cleared.primaryTab, isNull);
      expect(cleared.effectiveUserId, isEmpty);
      expect(cleared.fallbackReason, 'signed_out');
    });

    test('StartupDecision root target helpers stay mutually exclusive', () {
      const splash = StartupDecision(
        authState: StartupAuthState.unknown,
        rootTarget: StartupRootTarget.splash,
      );
      const signIn = StartupDecision(
        authState: StartupAuthState.unauthenticated,
        rootTarget: StartupRootTarget.signIn,
      );
      const authenticatedHome = StartupDecision(
        authState: StartupAuthState.authenticated,
        rootTarget: StartupRootTarget.authenticatedHome,
        primaryTab: StartupPrimaryTab.feed,
      );

      expect(splash.shouldStayOnSplash, isTrue);
      expect(splash.shouldOpenSignIn, isFalse);
      expect(splash.shouldOpenAuthenticatedHome, isFalse);
      expect(signIn.shouldStayOnSplash, isFalse);
      expect(signIn.shouldOpenSignIn, isTrue);
      expect(signIn.shouldOpenAuthenticatedHome, isFalse);
      expect(authenticatedHome.shouldStayOnSplash, isFalse);
      expect(authenticatedHome.shouldOpenSignIn, isFalse);
      expect(authenticatedHome.shouldOpenAuthenticatedHome, isTrue);
    });

    test('keeps app on splash while auth state is unknown', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.unknown,
          effectiveUserId: 'uid-1',
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.splash);
      expect(decision.shouldStayOnSplash, isTrue);
      expect(decision.effectiveUserId, 'uid-1');
    });

    test('marks unknown auth timeout as degraded instead of signing out', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.unknown,
          authRestoreTimedOut: true,
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.splash);
      expect(decision.degraded, isTrue);
      expect(decision.fallbackReason, 'auth_restore_pending');
    });

    test('routes unauthenticated startup to sign in', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.unauthenticated,
          effectiveUserId: 'stale-uid',
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.signIn);
      expect(decision.shouldOpenSignIn, isTrue);
      expect(decision.effectiveUserId, isEmpty);
    });

    test('unauthenticated startup ignores requested tab and route hint', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.unauthenticated,
          effectiveUserId: 'stale-uid',
          requestedRouteHint: 'nav_profile',
          requestedTab: StartupPrimaryTab.education,
          educationEnabled: true,
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.signIn);
      expect(decision.primaryTab, isNull);
      expect(decision.effectiveUserId, isEmpty);
      expect(decision.degraded, isFalse);
    });

    test('unknown auth does not apply requested startup tab yet', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.unknown,
          effectiveUserId: 'uid-1',
          requestedRouteHint: 'nav_explore',
          requestedTab: StartupPrimaryTab.profile,
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.splash);
      expect(decision.primaryTab, isNull);
      expect(decision.effectiveUserId, 'uid-1');
    });

    test('unknown auth timeout keeps route hints out of startup decision', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.unknown,
          effectiveUserId: 'uid-1',
          requestedRouteHint: 'nav_profile',
          requestedTab: StartupPrimaryTab.education,
          minimumStartupPrepared: true,
          authRestoreTimedOut: true,
          routeHintIsWarm: false,
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.splash);
      expect(decision.primaryTab, isNull);
      expect(decision.minimumStartupPrepared, isTrue);
      expect(decision.degraded, isTrue);
      expect(decision.fallbackReason, 'auth_restore_pending');
    });

    test('unauthenticated cold route hints do not create degraded fallback',
        () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.unauthenticated,
          effectiveUserId: 'stale-uid',
          requestedRouteHint: 'nav_explore',
          requestedTab: StartupPrimaryTab.profile,
          authRestoreTimedOut: true,
          routeHintIsWarm: false,
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.signIn);
      expect(decision.primaryTab, isNull);
      expect(decision.effectiveUserId, isEmpty);
      expect(decision.degraded, isFalse);
      expect(decision.fallbackReason, isEmpty);
    });

    test('routes authenticated startup to semantic primary tab', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.authenticated,
          effectiveUserId: 'uid-1',
          requestedRouteHint: 'nav_profile',
          minimumStartupPrepared: true,
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.authenticatedHome);
      expect(decision.primaryTab, StartupPrimaryTab.profile);
      expect(decision.minimumStartupPrepared, isTrue);
    });

    test('routes home and unknown startup hints to feed deterministically', () {
      for (final routeHint in <String>[
        'nav_home',
        'nav_feed',
        'unknown',
        '',
        'unexpected',
      ]) {
        final decision = coordinator.decideStartup(
          StartupDecisionInput(
            authState: StartupAuthState.authenticated,
            effectiveUserId: 'uid-1',
            requestedRouteHint: routeHint,
          ),
        );

        expect(
          decision.primaryTab,
          StartupPrimaryTab.feed,
          reason: 'routeHint=$routeHint',
        );
      }
    });

    test('falls education route back to feed when education is disabled', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.authenticated,
          effectiveUserId: 'uid-1',
          requestedRouteHint: 'nav_education',
          educationEnabled: false,
        ),
      );

      expect(decision.primaryTab, StartupPrimaryTab.feed);
    });

    test('normalizes short as a non-persisted primary startup tab', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.authenticated,
          effectiveUserId: 'uid-1',
          requestedTab: StartupPrimaryTab.short,
        ),
      );

      expect(decision.primaryTab, StartupPrimaryTab.feed);
    });

    test('uses explicit requested tab before route hint', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.authenticated,
          effectiveUserId: ' uid-1 ',
          requestedRouteHint: 'nav_profile',
          requestedTab: StartupPrimaryTab.explore,
          educationEnabled: true,
        ),
      );

      expect(decision.primaryTab, StartupPrimaryTab.explore);
      expect(decision.effectiveUserId, 'uid-1');
    });

    test('normalizes requested education tab when education is disabled', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.authenticated,
          effectiveUserId: 'uid-1',
          requestedRouteHint: 'nav_profile',
          requestedTab: StartupPrimaryTab.education,
          educationEnabled: false,
        ),
      );

      expect(decision.primaryTab, StartupPrimaryTab.feed);
    });

    test('records cold route hint fallback for authenticated startup', () {
      final decision = coordinator.decideStartup(
        const StartupDecisionInput(
          authState: StartupAuthState.authenticated,
          effectiveUserId: 'uid-1',
          requestedRouteHint: 'nav_explore',
          routeHintIsWarm: false,
        ),
      );

      expect(decision.rootTarget, StartupRootTarget.authenticatedHome);
      expect(decision.primaryTab, StartupPrimaryTab.explore);
      expect(decision.degraded, isTrue);
      expect(decision.fallbackReason, 'route_hint_not_warm');
    });

    test('Splash route hint warm checks stay behind typed runtime vocabulary',
        () async {
      final source = await File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsString();
      final splashSource = await File(
        'lib/Modules/Splash/splash_view.dart',
      ).readAsString();

      expect(source, contains('startupRouteHintKind(routeHint)'));
      expect(source, contains('StartupRouteHint.feed.value'));
      expect(source, contains('StartupRouteHint.unknown.value'));
      expect(splashSource, contains('StartupRouteHint.unknown.value'));
      expect(source, isNot(contains("case 'nav_explore'")));
      expect(source, isNot(contains("case 'nav_profile'")));
      expect(source, isNot(contains("case 'nav_education'")));
      expect(source, isNot(contains("case 'nav_feed'")));
      expect(source, isNot(contains("case 'nav_home'")));
      expect(source, isNot(contains("return 'nav_feed'")));
      expect(source, isNot(contains("return 'unknown'")));
      expect(splashSource, isNot(contains("= 'unknown'")));
      expect(source, isNot(contains("== 'nav_")));
      expect(source, isNot(contains("!= 'nav_")));
    });
  });
}
