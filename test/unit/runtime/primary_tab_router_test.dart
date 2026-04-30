import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Runtime/primary_tab_router.dart';
import 'package:turqappv2/Runtime/startup_decision.dart';

void main() {
  group('PrimaryTabRouter', () {
    test('maps primary tabs with education enabled', () {
      expect(
        PrimaryTabRouter.selectedIndexFor(
          StartupPrimaryTab.feed,
          educationEnabled: true,
        ),
        0,
      );
      expect(
        PrimaryTabRouter.selectedIndexFor(
          StartupPrimaryTab.explore,
          educationEnabled: true,
        ),
        1,
      );
      expect(
        PrimaryTabRouter.selectedIndexFor(
          StartupPrimaryTab.education,
          educationEnabled: true,
        ),
        3,
      );
      expect(
        PrimaryTabRouter.selectedIndexFor(
          StartupPrimaryTab.profile,
          educationEnabled: true,
        ),
        4,
      );
    });

    test('maps profile and education when education is disabled', () {
      expect(
        PrimaryTabRouter.selectedIndexFor(
          StartupPrimaryTab.education,
          educationEnabled: false,
        ),
        0,
      );
      expect(
        PrimaryTabRouter.selectedIndexFor(
          StartupPrimaryTab.profile,
          educationEnabled: false,
        ),
        3,
      );
    });

    test('maps authenticated startup decisions to selected index', () {
      const decision = StartupDecision(
        authState: StartupAuthState.authenticated,
        rootTarget: StartupRootTarget.authenticatedHome,
        primaryTab: StartupPrimaryTab.profile,
      );

      expect(
        PrimaryTabRouter.selectedIndexForDecision(
          decision,
          educationEnabled: true,
        ),
        4,
      );
      expect(
        PrimaryTabRouter.selectedIndexForDecision(
          decision,
          educationEnabled: false,
        ),
        3,
      );
    });

    test('does not map non-home startup decisions to selected index', () {
      const decision = StartupDecision(
        authState: StartupAuthState.unauthenticated,
        rootTarget: StartupRootTarget.signIn,
      );

      expect(
        PrimaryTabRouter.selectedIndexForDecision(
          decision,
          educationEnabled: true,
        ),
        isNull,
      );
    });

    test('does not map authenticated home without a primary tab', () {
      const decision = StartupDecision(
        authState: StartupAuthState.authenticated,
        rootTarget: StartupRootTarget.authenticatedHome,
      );

      expect(
        PrimaryTabRouter.selectedIndexForDecision(
          decision,
          educationEnabled: true,
        ),
        isNull,
      );
    });

    test('maps primary tabs back to route hints', () {
      expect(
        PrimaryTabRouter.routeHintFor(
          StartupPrimaryTab.feed,
          educationEnabled: true,
        ),
        'nav_feed',
      );
      expect(
        PrimaryTabRouter.routeHintFor(
          StartupPrimaryTab.explore,
          educationEnabled: true,
        ),
        'nav_explore',
      );
      expect(
        PrimaryTabRouter.routeHintFor(
          StartupPrimaryTab.education,
          educationEnabled: true,
        ),
        'nav_education',
      );
      expect(
        PrimaryTabRouter.routeHintFor(
          StartupPrimaryTab.education,
          educationEnabled: false,
        ),
        'nav_feed',
      );
      expect(
        PrimaryTabRouter.routeHintFor(
          StartupPrimaryTab.profile,
          educationEnabled: false,
        ),
        'nav_profile',
      );
      expect(
        PrimaryTabRouter.routeHintFor(
          StartupPrimaryTab.short,
          educationEnabled: true,
        ),
        'nav_feed',
      );
    });

    test('maps selected indexes back to route hints with feature awareness',
        () {
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          1,
          educationEnabled: true,
        ),
        'nav_explore',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          3,
          educationEnabled: true,
        ),
        'nav_education',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          3,
          educationEnabled: false,
        ),
        'nav_profile',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          2,
          educationEnabled: true,
        ),
        'nav_feed',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          9,
          educationEnabled: false,
        ),
        'nav_feed',
      );
    });

    test('maps disabled education selected indexes deterministically', () {
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          0,
          educationEnabled: false,
        ),
        'nav_feed',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          1,
          educationEnabled: false,
        ),
        'nav_explore',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          2,
          educationEnabled: false,
        ),
        'nav_feed',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          3,
          educationEnabled: false,
        ),
        'nav_profile',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          4,
          educationEnabled: false,
        ),
        'nav_feed',
      );
    });

    test('normalizes startup selected index edge cases deterministically', () {
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          -4,
          educationEnabled: true,
        ),
        'nav_feed',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          4,
          educationEnabled: true,
        ),
        'nav_profile',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          4,
          educationEnabled: false,
        ),
        'nav_feed',
      );
      expect(
        PrimaryTabRouter.routeHintForSelectedIndex(
          99,
          educationEnabled: true,
        ),
        'nav_profile',
      );
    });

    test('maps disabled education startup decision back to feed index', () {
      const decision = StartupDecision(
        authState: StartupAuthState.authenticated,
        rootTarget: StartupRootTarget.authenticatedHome,
        primaryTab: StartupPrimaryTab.education,
      );

      expect(
        PrimaryTabRouter.selectedIndexForDecision(
          decision,
          educationEnabled: false,
        ),
        0,
      );
    });

    test('opens education tab through feature-aware index', () {
      final changes = <int>[];
      final router = PrimaryTabRouter(
        educationEnabled: () => true,
        changeIndex: changes.add,
      );

      final opened = router.openEducation();

      expect(opened, isTrue);
      expect(changes, <int>[3]);
    });

    test('opens feed tab through semantic helper', () {
      final changes = <int>[];
      final router = PrimaryTabRouter(
        educationEnabled: () => true,
        changeIndex: changes.add,
      );

      final opened = router.openFeed();

      expect(opened, isTrue);
      expect(changes, <int>[0]);
    });

    test('opens persistent primary tabs through feature-aware indexes', () {
      final enabledChanges = <int>[];
      final enabledRouter = PrimaryTabRouter(
        educationEnabled: () => true,
        changeIndex: enabledChanges.add,
      );
      final disabledChanges = <int>[];
      final disabledRouter = PrimaryTabRouter(
        educationEnabled: () => false,
        changeIndex: disabledChanges.add,
      );

      expect(enabledRouter.openPrimaryTab(StartupPrimaryTab.explore), isTrue);
      expect(enabledRouter.openPrimaryTab(StartupPrimaryTab.profile), isTrue);
      expect(disabledRouter.openPrimaryTab(StartupPrimaryTab.explore), isTrue);
      expect(disabledRouter.openPrimaryTab(StartupPrimaryTab.profile), isTrue);
      expect(enabledChanges, <int>[1, 4]);
      expect(disabledChanges, <int>[1, 3]);
    });

    test('falls education open back to feed when education is disabled', () {
      final changes = <int>[];
      final router = PrimaryTabRouter(
        educationEnabled: () => false,
        changeIndex: changes.add,
      );

      final opened = router.openEducation();

      expect(opened, isFalse);
      expect(changes, <int>[0]);
    });

    test('does not open short as a persistent primary tab', () {
      final changes = <int>[];
      final router = PrimaryTabRouter(
        educationEnabled: () => true,
        changeIndex: changes.add,
      );

      final opened = router.openPrimaryTab(StartupPrimaryTab.short);

      expect(opened, isFalse);
      expect(changes, isEmpty);
    });

    test('feature entry tab redirects stay behind PrimaryTabRouter', () {
      final signInSupportSource = File(
        'lib/Modules/SignIn/sign_in_controller_support_part.dart',
      ).readAsStringSync();
      final scholarshipSubmissionSource = File(
        'lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller_submission_part.dart',
      ).readAsStringSync();
      final shortUiSource = File(
        'lib/Modules/Short/short_view_ui_part.dart',
      ).readAsStringSync();

      expect(signInSupportSource, contains('PrimaryTabRouter().openFeed()'));
      expect(signInSupportSource, isNot(contains('selectedIndex.value = 0')));
      expect(
        scholarshipSubmissionSource,
        contains('PrimaryTabRouter().openEducation()'),
      );
      expect(scholarshipSubmissionSource, isNot(contains('changeIndex(3)')));
      expect(shortUiSource, contains('PrimaryTabRouter().openFeed()'));
      expect(shortUiSource, isNot(contains('changeIndex(0)')));
    });

    test('feature surfaces do not mutate primary tab indexes directly', () {
      final directPrimaryTabPatterns = <RegExp>[
        RegExp(r'\bchangeIndex\(\s*\d+\s*\)'),
        RegExp(r'\bselectedIndex\.value\s*=\s*\d+\b'),
      ];
      final approvedLocalStatePrefixes = <String>[
        'lib/Modules/PostCreator/',
      ];
      final violations = <String>[];

      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        final isApprovedLocalState = approvedLocalStatePrefixes.any(
          normalizedPath.startsWith,
        );
        if (isApprovedLocalState) continue;

        final source = file.readAsStringSync();
        for (final pattern in directPrimaryTabPatterns) {
          final match = pattern.firstMatch(source);
          if (match == null) continue;
          violations.add('$normalizedPath: ${match.group(0)}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Primary app tab decisions should go through '
            'PrimaryTabRouter; PostCreator owns a separate local tab state.',
      );
    });

    test('splash startup nav index is computed through one helper', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final directDecisionCalls =
          RegExp(r'PrimaryTabRouter\.selectedIndexForDecision\(')
              .allMatches(source)
              .length;

      expect(source, contains('int? _startupNavSelectedIndex({'));
      expect(source, contains("'navSelectedIndex': startupNavSelectedIndex"));
      expect(
        source,
        contains('selectedIndex.value = startupNavSelectedIndex'),
      );
      expect(directDecisionCalls, 1);
    });

    test('splash applies startup nav index only for authenticated home', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final selectedIndexWrites =
          RegExp(r'selectedIndex\.value\s*=\s*startupNavSelectedIndex')
              .allMatches(source)
              .length;
      final helperGuard = source.indexOf(
        'if (!loggedIn || !startupDecision.shouldOpenAuthenticatedHome) '
        'return null;',
      );
      final authenticatedBranch = source.indexOf(
        'if (startupDecision.shouldOpenAuthenticatedHome) {',
      );
      final selectedIndexWrite = source.indexOf(
        'selectedIndex.value = startupNavSelectedIndex',
      );
      final signInBranch =
          source.indexOf('if (startupDecision.shouldOpenSignIn)');

      expect(helperGuard, isNonNegative);
      expect(selectedIndexWrites, 1);
      expect(authenticatedBranch, isNonNegative);
      expect(selectedIndexWrite, greaterThan(authenticatedBranch));
      expect(signInBranch, greaterThan(selectedIndexWrite));
    });

    test('splash startup route telemetry keys stay centralized', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();

      int literalCount(String literal) =>
          RegExp(RegExp.escape(literal)).allMatches(source).length;

      expect(source,
          contains('Map<String, dynamic> _startupRouteTelemetryFields'));
      expect(
        RegExp(r'\.\.\._startupRouteTelemetryFields\(')
            .allMatches(source)
            .length,
        2,
      );
      expect(literalCount("'requestedStartupRouteHint'"), 1);
      expect(literalCount("'effectiveStartupRouteHint'"), 1);
      expect(literalCount("'resolvedStartupRouteHint'"), 1);
      expect(literalCount("'startupRouteFallbackApplied'"), 1);
    });

    test('splash analytics extras reuse captured startup route values', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final helperStart =
          source.indexOf('Map<String, dynamic> _startupAnalyticsExtra({');
      final helperEnd = source.indexOf(
        'Map<String, dynamic> _startupDecisionTelemetryFields',
        helperStart,
      );
      final helperBody = source.substring(helperStart, helperEnd);
      final runtimeHelperStart =
          source.indexOf('void _trackStartupRuntimeHealthSummary({');
      final runtimeHelperEnd =
          source.indexOf('bool _hasWarmStartupSurface', runtimeHelperStart);
      final runtimeHelperBody =
          source.substring(runtimeHelperStart, runtimeHelperEnd);
      final runtimeSummaryCalls =
          RegExp(r'_trackStartupRuntimeHealthSummary\(\s+playbackKpi:')
              .allMatches(source)
              .length;

      expect(
        source,
        contains('class _StartupRouteTelemetryValues'),
      );
      expect(
        helperBody,
        contains('required _StartupRouteTelemetryValues routeTelemetry'),
      );
      expect(helperBody, isNot(contains('required bool loggedIn')));
      expect(runtimeHelperStart, isNonNegative);
      expect(runtimeHelperEnd, greaterThan(runtimeHelperStart));
      expect(runtimeSummaryCalls, 6);
      expect(
        runtimeHelperBody,
        contains('extra: _startupAnalyticsExtra('),
      );
      expect(runtimeHelperBody, contains('routeTelemetry: routeTelemetry'));
      expect(runtimeHelperBody, isNot(contains('loggedIn: loggedIn')));
      expect(
          runtimeHelperBody, isNot(contains('_requestedStartupRouteHint()')));
      expect(
          runtimeHelperBody, isNot(contains('_effectiveStartupRouteHint()')));
      expect(
        RegExp(r'routeTelemetry: startupRouteTelemetry')
            .allMatches(source)
            .length,
        greaterThanOrEqualTo(6),
      );
    });

    test('splash route telemetry values are captured once', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final navigationStart = source.indexOf(
        'final requestedStartupRouteHint = _requestedStartupRouteHint();',
      );
      final navigationEnd = source.indexOf(
        'final playbackKpi = maybeFindPlaybackKpiService();',
        navigationStart,
      );
      final navigationBody = source.substring(navigationStart, navigationEnd);

      expect(navigationStart, isNonNegative);
      expect(navigationEnd, greaterThan(navigationStart));
      expect(
        navigationBody,
        contains('final startupRouteTelemetry = _StartupRouteTelemetryValues('),
      );
      expect(
        navigationBody,
        contains('requestedStartupRouteHint: requestedStartupRouteHint'),
      );
      expect(
        navigationBody,
        contains('effectiveStartupRouteHint: effectiveStartupRouteHint'),
      );
      expect(
        navigationBody,
        contains('resolvedStartupRouteHint: resolvedStartupRouteHint'),
      );
    });

    test('splash startup decision input uses captured route pair', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final helperStart =
          source.indexOf('StartupDecision _decideStartupRoute({');
      final helperEnd = source.indexOf('int? _startupNavSelectedIndex({');
      final helperBody = source.substring(helperStart, helperEnd);
      final navigationStart = source.indexOf(
        'final requestedStartupRouteHint = _requestedStartupRouteHint();',
      );
      final navigationEnd = source.indexOf(
        'final startupNavSelectedIndex = _startupNavSelectedIndex(',
      );
      final navigationBody = source.substring(navigationStart, navigationEnd);

      expect(helperStart, isNonNegative);
      expect(helperEnd, greaterThan(helperStart));
      expect(
        helperBody,
        contains(
          'final requested = requestedStartupRouteHint ?? '
          '_requestedStartupRouteHint();',
        ),
      );
      expect(
        helperBody,
        contains(
          'final effective = effectiveStartupRouteHint ?? '
          '_effectiveStartupRouteHint();',
        ),
      );
      expect(helperBody, contains('requestedRouteHint: effective'));
      expect(helperBody, contains('routeHintIsWarm: requested == effective'));
      expect(navigationStart, isNonNegative);
      expect(navigationEnd, greaterThan(navigationStart));
      expect(
        navigationBody,
        contains('requestedStartupRouteHint: requestedStartupRouteHint'),
      );
      expect(
        navigationBody,
        contains('effectiveStartupRouteHint: effectiveStartupRouteHint'),
      );
    });

    test('splash resolved route telemetry reuses startup decision', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final helperStart =
          source.indexOf('String _resolvedStartupRouteHintForTelemetry({');
      final helperEnd = source.indexOf(
        'Map<String, dynamic> _startupSurfaceTelemetryFields',
        helperStart,
      );
      final helperBody = source.substring(helperStart, helperEnd);
      final navigationStart = source.indexOf(
        'final resolvedStartupRouteHint = _resolvedStartupRouteHintForTelemetry(',
      );
      final navigationEnd = source.indexOf(
        'final playbackKpi = maybeFindPlaybackKpiService();',
        navigationStart,
      );
      final navigationBody = source.substring(navigationStart, navigationEnd);

      expect(helperStart, isNonNegative);
      expect(helperEnd, greaterThan(helperStart));
      expect(helperBody, contains('required StartupDecision startupDecision'));
      expect(
          helperBody, contains('startupDecision.shouldOpenAuthenticatedHome'));
      expect(helperBody, contains('startupDecision.primaryTab'));
      expect(helperBody, contains('PrimaryTabRouter.routeHintFor('));
      expect(helperBody, isNot(contains('_decideStartupRoute(')));
      expect(helperBody, isNot(contains('_resolvedLoggedInStartupRouteHint')));
      expect(navigationStart, isNonNegative);
      expect(navigationEnd, greaterThan(navigationStart));
      expect(navigationBody, contains('startupDecision: startupDecision'));
      expect(navigationBody, contains('educationEnabled: educationEnabled'));
    });

    test('splash captures education-enabled state once per navigation', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final navigationStart =
          source.indexOf('Future<void> _performNavigateToPrimaryRoute()');
      final navigationEnd = source.indexOf(
        '  Future<void> _ensureAuthenticatedPrimaryRouteReady()',
        navigationStart,
      );
      final navigationBody = source.substring(navigationStart, navigationEnd);
      final educationCapture =
          'final educationEnabled = _startupEducationEnabled();';

      expect(navigationStart, isNonNegative);
      expect(navigationEnd, greaterThan(navigationStart));
      expect(
        RegExp(RegExp.escape(educationCapture))
            .allMatches(navigationBody)
            .length,
        1,
      );
      expect(
        navigationBody,
        contains('educationEnabled: educationEnabled'),
      );
      expect(
        navigationBody,
        isNot(contains('maybeFindSettingsController()')),
      );
    });

    test('splash manifest navigation extras stay behind one helper', () {
      final source = File(
        'lib/Modules/Splash/splash_view_startup_part.dart',
      ).readAsStringSync();
      final helperStart = source
          .indexOf('Map<String, dynamic> _startupNavigationManifestExtra');
      final helperEnd =
          source.indexOf('bool _hasWarmStartupSurface', helperStart);
      final helperBody = source.substring(helperStart, helperEnd);
      final markNavigationStart = source.indexOf(
        'ensureStartupSnapshotManifestStore().markNavigation(',
      );
      final markNavigationEnd = source.indexOf('    _didNavigate = true;');
      final markNavigationBody =
          source.substring(markNavigationStart, markNavigationEnd);

      expect(helperStart, isNonNegative);
      expect(helperEnd, greaterThan(helperStart));
      expect(helperBody, contains('_startupDecisionTelemetryFields('));
      expect(helperBody, contains('_startupWarmReadinessTelemetryFields()'));
      expect(
          helperBody, contains("'navSelectedIndex': startupNavSelectedIndex"));
      expect(markNavigationStart, isNonNegative);
      expect(markNavigationEnd, greaterThan(markNavigationStart));
      expect(
        markNavigationBody,
        contains('extra: _startupNavigationManifestExtra('),
      );
      expect(markNavigationBody,
          contains('routeTelemetry: startupRouteTelemetry'));
      expect(markNavigationBody, contains('startupDecision: startupDecision'));
      expect(
        markNavigationBody,
        contains('startupNavSelectedIndex: startupNavSelectedIndex'),
      );
    });

    test('NavBar startup route hint mapping stays behind PrimaryTabRouter', () {
      final source = File(
        'lib/Modules/NavBar/nav_bar_controller_support_part.dart',
      ).readAsStringSync();

      expect(source, contains('PrimaryTabRouter.routeHintForSelectedIndex('));
      expect(source, isNot(contains("return 'nav_explore'")));
      expect(source, isNot(contains("return 'nav_education'")));
      expect(source, isNot(contains("return 'nav_profile'")));
      expect(source, isNot(contains("return 'nav_feed'")));
    });

    test('NavBar primary tab layout indexes stay behind one helper', () {
      final supportSource = File(
        'lib/Modules/NavBar/nav_bar_controller_support_part.dart',
      ).readAsStringSync();
      final lifecycleSource = File(
        'lib/Modules/NavBar/nav_bar_controller_lifecycle_part.dart',
      ).readAsStringSync();

      expect(supportSource, contains('class _PrimaryTabLayout'));
      expect(
        RegExp(r'_PrimaryTabLayout _primaryTabLayout\(\)')
            .allMatches(supportSource)
            .length,
        1,
      );
      expect(
        RegExp(r'maybeFindSettingsController\(\)\?\.educationScreenIsOn\.value')
            .allMatches(supportSource)
            .length,
        1,
      );
      expect(
        RegExp(r'hasEducation \? 3 : -1').allMatches(supportSource).length,
        1,
      );
      expect(
        RegExp(r'hasEducation \? 4 : 3').allMatches(supportSource).length,
        1,
      );
      expect(
          lifecycleSource, contains('final tabLayout = _primaryTabLayout();'));
      expect(
        lifecycleSource,
        isNot(
          contains('maybeFindSettingsController()?.educationScreenIsOn.value'),
        ),
      );
      expect(lifecycleSource, isNot(contains('hasEducation ? 3 : -1')));
      expect(lifecycleSource, isNot(contains('hasEducation ? 4 : 3')));
    });

    test('PrimaryTabRouter reuses centralized startup route vocabulary', () {
      final source =
          File('lib/Runtime/primary_tab_router.dart').readAsStringSync();

      expect(source, contains('StartupRouteHint.feed.value'));
      expect(source, contains('StartupRouteHint.explore.value'));
      expect(source, contains('StartupRouteHint.education.value'));
      expect(source, contains('StartupRouteHint.profile.value'));
      expect(source, isNot(contains("return 'nav_feed'")));
      expect(source, isNot(contains("return 'nav_explore'")));
      expect(source, isNot(contains("return 'nav_education'")));
      expect(source, isNot(contains("return 'nav_profile'")));
    });

    test('feature code does not own startup route hint literals', () {
      final approvedVocabularyOwners = <String>{
        'lib/Runtime/app_decision_coordinator.dart',
      };
      final routeHintLiteralPattern = RegExp(
        r"""['"]nav_(feed|home|explore|profile|education)['"]""",
      );
      final violations = <String>[];

      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (approvedVocabularyOwners.contains(normalizedPath)) continue;

        final source = file.readAsStringSync();
        final match = routeHintLiteralPattern.firstMatch(source);
        if (match == null) continue;
        violations.add('$normalizedPath: ${match.group(0)}');
      }

      expect(
        violations,
        isEmpty,
        reason: 'Startup route-hint vocabulary should stay behind '
            'StartupRouteHint instead of drifting into feature code.',
      );
    });

    test('Education startup route hint uses centralized vocabulary', () {
      final source = File(
        'lib/Modules/Education/education_controller_pasaj_part.dart',
      ).readAsStringSync();

      expect(source, contains('StartupRouteHint.education.value'));
      expect(source, isNot(contains("routeHint: 'nav_education'")));
    });
  });
}
