import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

import '../core/helpers/native_exoplayer_probe.dart';
import '../core/helpers/route_replay.dart';
import '../core/bootstrap/test_app_bootstrap.dart';

void _phase(String label) {
  // ignore: avoid_print
  print('[audio-ownership-e2e] phase=$label');
}

Future<void> _backgroundAndResume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  await tester.pump(const Duration(milliseconds: 150));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  await tester.pump(const Duration(milliseconds: 150));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump(const Duration(milliseconds: 250));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  await tester.pump(const Duration(milliseconds: 150));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  await tester.pump(const Duration(milliseconds: 150));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await pumpForAppStartup(
    tester,
    step: const Duration(milliseconds: 200),
    maxPumps: 8,
  );
}

Future<void> _assertNoAudibleFeedLeak(
  WidgetTester tester, {
  required String label,
}) async {
  if (!supportsNativeExoSmoke) return;
  await expectNoAudibleNativeFeedPlayback(
    tester,
    label: label,
    timeout: const Duration(seconds: 2),
  );
}

Future<void> _tapAndAssertQuiet(
  WidgetTester tester,
  String key, {
  required String label,
  int settlePumps = 8,
}) async {
  await tapItKey(tester, key, settlePumps: settlePumps);
  await _assertNoAudibleFeedLeak(tester, label: label);
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'TurqApp audio ownership stays exclusive off-feed surfaces',
    (tester) async {
      _phase('launch');
      await launchTurqApp(tester);
      await expectFeedScreen(tester);

      _phase('explore');
      await _tapAndAssertQuiet(
        tester,
        IntegrationTestKeys.navExplore,
        label: 'explore',
      );

      _phase('profile');
      prepareProfileShellRouteReplay();
      await _tapAndAssertQuiet(
        tester,
        IntegrationTestKeys.navProfile,
        label: 'profile',
      );

      _phase('resume_profile');
      await _backgroundAndResume(tester);
      await _assertNoAudibleFeedLeak(tester, label: 'profile_resume');

      _phase('feed_return_1');
      await tapItKey(tester, IntegrationTestKeys.navFeed);
      await expectFeedScreen(tester);

      if (byItKey(IntegrationTestKeys.navEducation).evaluate().isNotEmpty) {
        _phase('education');
        await _tapAndAssertQuiet(
          tester,
          IntegrationTestKeys.navEducation,
          label: 'education',
        );
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
          final finder = byItKey(IntegrationTestKeys.educationTab(tabId));
          if (finder.evaluate().isEmpty) continue;
          _phase('education_tab_$tabId');
          await tester.ensureVisible(finder);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(finder);
          await pumpForAppStartup(
            tester,
            step: const Duration(milliseconds: 200),
            maxPumps: 8,
          );
          await _assertNoAudibleFeedLeak(
            tester,
            label: 'education_tab_$tabId',
          );
        }

        _phase('resume_education');
        await _backgroundAndResume(tester);
        await _assertNoAudibleFeedLeak(tester, label: 'education_resume');

        _phase('feed_return_2');
        await tapItKey(tester, IntegrationTestKeys.navFeed);
        await expectFeedScreen(tester);
      }

      _phase('chat');
      await _tapAndAssertQuiet(
        tester,
        IntegrationTestKeys.navChat,
        label: 'chat',
      );
      _phase('resume_chat');
      await _backgroundAndResume(tester);
      await _assertNoAudibleFeedLeak(tester, label: 'chat_resume');
      await popRouteAndSettle(tester);

      _phase('notifications');
      await _tapAndAssertQuiet(
        tester,
        IntegrationTestKeys.actionOpenNotifications,
        label: 'notifications',
      );
      final notificationsTab0 = byItKey(
        IntegrationTestKeys.pageLineBarItem(kNotificationsPageLineBarTag, 0),
      );
      final notificationsTab1 = byItKey(
        IntegrationTestKeys.pageLineBarItem(kNotificationsPageLineBarTag, 1),
      );
      if (notificationsTab0.evaluate().isNotEmpty) {
        await tester.tap(notificationsTab0);
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 6,
        );
        await _assertNoAudibleFeedLeak(
          tester,
          label: 'notifications_tab_0',
        );
      }
      if (notificationsTab1.evaluate().isNotEmpty) {
        await tester.tap(notificationsTab1);
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 6,
        );
        await _assertNoAudibleFeedLeak(
          tester,
          label: 'notifications_tab_1',
        );
      }
      _phase('resume_notifications');
      await _backgroundAndResume(tester);
      await _assertNoAudibleFeedLeak(tester, label: 'notifications_resume');
      await popRouteAndSettle(tester);

      _phase('short');
      await _tapAndAssertQuiet(
        tester,
        IntegrationTestKeys.navShort,
        label: 'short',
        settlePumps: 12,
      );
      _phase('resume_short');
      await _backgroundAndResume(tester);
      await _assertNoAudibleFeedLeak(tester, label: 'short_resume');
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
