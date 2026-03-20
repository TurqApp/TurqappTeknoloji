import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'test_app_bootstrap.dart';
import 'test_state_probe.dart';

Future<void> goToFeedTab(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navFeed);
  await expectFeedScreen(tester);
  expectSelectedNavIndex(0);
  expectSurfaceMatchesFixture('feed', readSurfaceProbe('feed'));
}

Future<void> replayFeedToExploreToFeed(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navExplore);
  expect(byItKey(IntegrationTestKeys.screenExplore), findsOneWidget);
  expectSelectedNavIndex(1);
  await goToFeedTab(tester);
}

Future<void> replayFeedToProfileToFeed(
  WidgetTester tester, {
  Map<String, dynamic>? beforeFeed,
}) async {
  await tapItKey(tester, IntegrationTestKeys.navProfile);
  expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
  expectSurfaceRegistered('profile');
  expectCenteredIndexValid(
    'profile',
    indexField: 'centeredIndex',
    countField: 'count',
  );
  final profileSnapshot = readSurfaceProbe('profile');
  expectSurfaceMatchesFixture('profile', profileSnapshot);
  await goToFeedTab(tester);
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
    'profile',
    before: profileSnapshot,
    after: profileSnapshot,
  );
}

Future<void> replayFeedToShortToFeed(
  WidgetTester tester, {
  Map<String, dynamic>? beforeFeed,
}) async {
  await tapItKey(tester, IntegrationTestKeys.navShort);
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
