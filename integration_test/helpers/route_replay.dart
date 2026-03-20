import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import 'test_app_bootstrap.dart';
import 'test_state_probe.dart';

Future<void> goToFeedTab(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navFeed);
  await expectFeedScreen(tester);
  expectSelectedNavIndex(0);
}

Future<void> replayFeedToExploreToFeed(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navExplore);
  expect(byItKey(IntegrationTestKeys.screenExplore), findsOneWidget);
  expectSelectedNavIndex(1);
  await goToFeedTab(tester);
}

Future<void> replayFeedToProfileToFeed(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navProfile);
  expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
  expectSurfaceRegistered('profile');
  expectCenteredIndexValid(
    'profile',
    indexField: 'centeredIndex',
    countField: 'count',
  );
  await goToFeedTab(tester);
}

Future<void> replayFeedToShortToFeed(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.navShort);
  expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
  expectSurfaceRegistered('short');
  expectCenteredIndexValid(
    'short',
    indexField: 'activeIndex',
    countField: 'count',
  );
  await pageBackAndSettle(tester);
  await expectFeedScreen(tester);
  expectSelectedNavIndex(0);
}

Future<void> replayFeedToNotificationsToFeed(WidgetTester tester) async {
  await tapItKey(tester, IntegrationTestKeys.actionOpenNotifications);
  expect(byItKey(IntegrationTestKeys.screenNotifications), findsOneWidget);
  expectSurfaceRegistered('notifications');
  await pageBackAndSettle(tester);
  await expectFeedScreen(tester);
  expectSelectedNavIndex(0);
}
