import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';

import '../bootstrap/test_app_bootstrap.dart';
import 'test_state_probe.dart';

void prepareProfileShellRouteReplay() {
  final profile = ProfileController.ensure();
  profile.postSelection.value = kProfileIntegrationSmokeShellSelection;
  profile.centeredIndex.value = -1;
  profile.currentVisibleIndex.value = -1;
  profile.lastCenteredIndex = null;
  profile.showPfImage.value = false;
  profile.showScrollToTop.value = false;
}

Future<void> goToProfileTab(WidgetTester tester) async {
  print('[integration-smoke] route_replay: tapping profile nav');
  await pressItKey(
    tester,
    IntegrationTestKeys.navProfile,
  );
  await pumpUntilVisible(
    tester,
    byItKey(IntegrationTestKeys.screenProfile),
  );
  print('[integration-smoke] route_replay: profile nav tapped');
}

Future<void> goToFeedTab(WidgetTester tester) async {
  await pressItKey(
    tester,
    IntegrationTestKeys.navFeed,
  );
  await pumpUntilVisible(
    tester,
    byItKey(IntegrationTestKeys.screenFeed),
  );
  await expectFeedScreen(tester);
  await settleSmokeShell(
    tester,
    context: 'feed tab replay settle',
  );
  expectSurfaceMatchesFixture('feed', readSurfaceProbe('feed'));
}

Future<void> replayFeedToExploreToFeed(WidgetTester tester) async {
  await _changePrimaryTab(
    tester,
    1,
    context: 'explore route replay tab change',
  );
  expect(byItKey(IntegrationTestKeys.screenExplore), findsOneWidget);
  expectSelectedNavIndex(1);
  await goToFeedTab(tester);
}

Future<void> replayFeedToProfileToFeed(
  WidgetTester tester, {
  Map<String, dynamic>? beforeFeed,
}) async {
  prepareProfileShellRouteReplay();
  await goToProfileTab(tester);
  expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
  final profileSnapshot = maybeReadSurfaceProbe('profile');
  final profileRegistered = profileSnapshot?['registered'] == true;
  if (profileRegistered) {
    final profileCount = (profileSnapshot!['count'] as num?)?.toInt() ?? 0;
    final profileIndex =
        (profileSnapshot['centeredIndex'] as num?)?.toInt() ?? -1;
    if (profileCount <= 0 || profileIndex >= 0) {
      expectCenteredIndexValid(
        'profile',
        indexField: 'centeredIndex',
        countField: 'count',
      );
    }
    expectSurfaceMatchesFixture('profile', profileSnapshot);
  }
  await goToFeedTab(tester);
  final feedSnapshot = readSurfaceProbe('feed');
  final profileAfterReplay = maybeReadSurfaceProbe('profile');
  if (beforeFeed != null) {
    expectCountNeverDropsToZeroAfterReplay(
      'feed',
      before: beforeFeed,
      after: feedSnapshot,
    );
  }
  if (profileRegistered && profileAfterReplay?['registered'] == true) {
    expectCountNeverDropsToZeroAfterReplay(
      'profile',
      before: profileSnapshot!,
      after: profileAfterReplay!,
    );
    expectDocPreservedIfStillPresent(
      'profile',
      before: profileSnapshot,
      after: profileAfterReplay,
      activeDocField: 'centeredDocId',
    );
  }
}

Future<void> _changePrimaryTab(
  WidgetTester tester,
  int index, {
  required String context,
}) async {
  final navBar = maybeFindNavBarController() ?? ensureNavBarController();
  navBar.changeIndex(index);
  await settleSmokeShell(
    tester,
    context: context,
  );
}

Future<void> replayFeedToShortToFeed(
  WidgetTester tester, {
  Map<String, dynamic>? beforeFeed,
}) async {
  await pressItKey(
    tester,
    IntegrationTestKeys.navShort,
  );
  expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
  expectSurfaceRegistered('short');
  expectCenteredIndexValid(
    'short',
    indexField: 'activeIndex',
    countField: 'count',
  );
  final shortSnapshot = readSurfaceProbe('short');
  expectSurfaceMatchesFixture('short', shortSnapshot);
  await popRouteAndSettle(tester);
  await expectFeedScreen(tester);
  expectSelectedNavIndex(0);
  final feedSnapshot = readSurfaceProbe('feed');
  if (beforeFeed != null) {
    expectCountNeverDropsToZeroAfterReplay(
      'feed',
      before: beforeFeed,
      after: feedSnapshot,
    );
    expectDocPreservedIfStillPresent(
      'feed',
      before: beforeFeed,
      after: feedSnapshot,
      activeDocField: 'centeredDocId',
    );
  }
  expectCountNeverDropsToZeroAfterReplay(
    'short',
    before: shortSnapshot,
    after: shortSnapshot,
  );
}

Future<void> replayFeedToNotificationsToFeed(
  WidgetTester tester, {
  Map<String, dynamic>? beforeFeed,
}) async {
  await tapItKey(tester, IntegrationTestKeys.actionOpenNotifications);
  expect(byItKey(IntegrationTestKeys.screenNotifications), findsOneWidget);
  expectSurfaceRegistered('notifications');
  final notificationsSnapshot = readSurfaceProbe('notifications');
  expectNonNegativeCounter(
    'notifications',
    notificationsSnapshot,
    field: 'unreadTotal',
  );
  expectSurfaceMatchesFixture('notifications', notificationsSnapshot);
  await popRouteAndSettle(tester);
  await expectFeedScreen(tester);
  expectSelectedNavIndex(0);
  final feedSnapshot = readSurfaceProbe('feed');
  if (beforeFeed != null) {
    expectCountNeverDropsToZeroAfterReplay(
      'feed',
      before: beforeFeed,
      after: feedSnapshot,
    );
  }
}
