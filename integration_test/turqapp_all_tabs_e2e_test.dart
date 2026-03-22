import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

import 'helpers/test_app_bootstrap.dart';

void _phase(String label) {
  // Short, explicit phase logs so long-running device sessions are diagnosable.
  // ignore: avoid_print
  print('[all-tabs-e2e] phase=$label');
}

Future<void> _tapIfPresent(
  WidgetTester tester,
  Finder finder, {
  int settlePumps = 8,
}) async {
  if (finder.evaluate().isEmpty) return;
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await expectNoFlutterException(tester);
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'TurqApp all main surfaces are reachable from primary navigation',
    (tester) async {
      _phase('launch');
      await launchTurqApp(tester);
      _phase('feed');
      await expectFeedScreen(tester);

      _phase('explore');
      await tapItKey(tester, IntegrationTestKeys.navExplore);
      expect(byItKey(IntegrationTestKeys.screenExplore), findsOneWidget);
      for (var index = 0; index < 3; index++) {
        _phase('explore_tab_$index');
        await _tapIfPresent(
          tester,
          byItKey(
            IntegrationTestKeys.pageLineBarItem(kExplorePageLineBarTag, index),
          ),
          settlePumps: 6,
        );
      }

      _phase('profile');
      await tapItKey(tester, IntegrationTestKeys.navProfile);
      expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);

      _phase('feed_return_1');
      await tapItKey(tester, IntegrationTestKeys.navFeed);
      await expectFeedScreen(tester);

      if (byItKey(IntegrationTestKeys.navEducation).evaluate().isNotEmpty) {
        _phase('education');
        await tapItKey(tester, IntegrationTestKeys.navEducation);
        expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
        for (final tabId in <String>[
          PasajTabIds.market,
          PasajTabIds.jobFinder,
          PasajTabIds.scholarships,
          PasajTabIds.questionBank,
          PasajTabIds.practiceExams,
          PasajTabIds.onlineExam,
          PasajTabIds.answerKey,
          PasajTabIds.tutoring,
        ]) {
          _phase('education_tab_$tabId');
          await _tapIfPresent(
            tester,
            byItKey(IntegrationTestKeys.educationTab(tabId)),
            settlePumps: 6,
          );
        }
        _phase('feed_return_2');
        await tapItKey(tester, IntegrationTestKeys.navFeed);
        await expectFeedScreen(tester);
      }

      _phase('chat');
      await tapItKey(tester, IntegrationTestKeys.navChat);
      expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);
      await popRouteAndSettle(tester);
      _phase('feed_return_3');
      await expectFeedScreen(tester);

      _phase('notifications');
      await tapItKey(tester, IntegrationTestKeys.actionOpenNotifications);
      expect(byItKey(IntegrationTestKeys.screenNotifications), findsOneWidget);
      await popRouteAndSettle(tester);
      _phase('feed_return_4');
      await expectFeedScreen(tester);

      _phase('short');
      await tapItKey(tester, IntegrationTestKeys.navShort, settlePumps: 12);
      expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
      final shortBack = byItKey(IntegrationTestKeys.actionShortBack).first;
      await tester.ensureVisible(shortBack);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(shortBack);
      await pumpForAppStartup(
        tester,
        step: const Duration(milliseconds: 250),
        maxPumps: 10,
      );
      _phase('final_feed');
      await expectFeedScreen(tester);
      _phase('done');
    },
    skip: !kRunIntegrationSmoke,
  );
}
