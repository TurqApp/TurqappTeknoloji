import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

import 'e2e_progress_tracker.dart';
import 'native_exoplayer_probe.dart';
import 'smoke_artifact_collector.dart';
import '../bootstrap/test_app_bootstrap.dart';

const String kTurqAppMasterE2EScenario = 'turqapp_master_e2e';

Future<void> runTurqAppMasterE2EScenario(
  WidgetTester tester, {
  required String scenario,
}) async {
  await SmokeArtifactCollector.runScenario(scenario, tester, () async {
    var currentStep = 'bootstrap';
    try {
      await _step(tester, scenario, 'launch', () async {
        await launchTurqApp(tester);
        await expectFeedScreen(tester);
      });

      final firstPostId = await _stepWithResult<String>(
        tester,
        scenario,
        'feed_prepare',
        () => _waitForFirstFeedPostId(tester),
      );

      await _step(tester, scenario, 'feed_like', () async {
        await _tapByExactItKey(
          tester,
          IntegrationTestKeys.feedLikeButton(firstPostId),
        );
      });

      await _step(tester, scenario, 'feed_comments', () async {
        await _tapByExactItKey(
          tester,
          IntegrationTestKeys.feedCommentButton(firstPostId),
        );
        expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
        await tester.enterText(
          byItKey(IntegrationTestKeys.inputComment),
          'TurqApp master e2e comment ${DateTime.now().millisecondsSinceEpoch}',
        );
        await tester.pump(const Duration(milliseconds: 250));
        await _tapByExactItKey(
          tester,
          IntegrationTestKeys.actionCommentSend,
        );
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 8,
        );
        await _tapFirstKeyPrefixIfPresent(tester, 'it-comment-like-');
        await _tapFirstKeyPrefixIfPresent(tester, 'it-comment-reply-');
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.actionCommentClearReply),
        );
        await popRouteAndSettle(tester);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'profile', () async {
        await tapItKey(tester, IntegrationTestKeys.navProfile);
        expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
        await _assertNoFeedLeakIfSupported(tester, 'profile');
      });

      await _step(tester, scenario, 'profile_edit', () async {
        await tapItKey(tester, IntegrationTestKeys.actionProfileEdit);
        expect(
          byItKey(IntegrationTestKeys.screenEditProfile),
          findsOneWidget,
        );
        await _fillEditProfileFields(tester);
        await popRouteAndSettle(tester);
        expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
      });

      await _step(tester, scenario, 'profile_settings', () async {
        await tapItKey(
          tester,
          IntegrationTestKeys.actionProfileOpenSettings,
        );
        expect(byItKey(IntegrationTestKeys.screenSettings), findsOneWidget);
        await pageBackAndSettle(tester);
        expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
      });

      await _step(tester, scenario, 'profile_qr', () async {
        await tapItKey(
          tester,
          IntegrationTestKeys.actionProfileOpenQr,
        );
        expect(byItKey(IntegrationTestKeys.screenMyQr), findsOneWidget);
        await pageBackAndSettle(tester);
        expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
      });

      await _step(tester, scenario, 'profile_chat', () async {
        await tapItKey(
          tester,
          IntegrationTestKeys.actionProfileOpenChat,
        );
        expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);
        await _assertNoFeedLeakIfSupported(tester, 'profile_chat');
        await popRouteAndSettle(tester);
        expect(byItKey(IntegrationTestKeys.screenProfile), findsOneWidget);
      });

      await _step(tester, scenario, 'feed_return_1', () async {
        await tapItKey(tester, IntegrationTestKeys.navFeed);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'composer', () async {
        await tapItKey(tester, IntegrationTestKeys.actionFeedCreate);
        expect(
          byItKey(IntegrationTestKeys.screenPostCreator),
          findsOneWidget,
        );
        await tester.enterText(
          byItKey(IntegrationTestKeys.composerText(0)),
          'TurqApp master draft ${DateTime.now().millisecondsSinceEpoch}',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await pageBackAndSettle(tester);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'explore', () async {
        await tapItKey(tester, IntegrationTestKeys.navExplore);
        expect(byItKey(IntegrationTestKeys.screenExplore), findsOneWidget);
        await _assertNoFeedLeakIfSupported(tester, 'explore');
      });

      for (var index = 0; index < 3; index++) {
        currentStep = 'explore_tab_$index';
        await _step(tester, scenario, currentStep, () async {
          await _tapIfPresent(
            tester,
            byItKey(
              IntegrationTestKeys.pageLineBarItem(
                kExplorePageLineBarTag,
                index,
              ),
            ),
          );
          await _assertNoFeedLeakIfSupported(tester, currentStep);
        });
      }

      if (byItKey(IntegrationTestKeys.navEducation).evaluate().isNotEmpty) {
        await _step(tester, scenario, 'education', () async {
          await tapItKey(tester, IntegrationTestKeys.navEducation);
          expect(
            byItKey(IntegrationTestKeys.screenEducation),
            findsOneWidget,
          );
          await _assertNoFeedLeakIfSupported(tester, 'education');
        });

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
          currentStep = 'education_tab_$tabId';
          await _step(tester, scenario, currentStep, () async {
            await _tapIfPresent(
              tester,
              byItKey(IntegrationTestKeys.educationTab(tabId)),
            );
            await _assertNoFeedLeakIfSupported(tester, currentStep);
          });
        }

        await _step(tester, scenario, 'education_resume', () async {
          await _backgroundAndResume(tester);
          await _assertNoFeedLeakIfSupported(tester, 'education_resume');
        });
      }

      await _step(tester, scenario, 'chat', () async {
        await tapItKey(tester, IntegrationTestKeys.navChat);
        expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);
        await _assertNoFeedLeakIfSupported(tester, 'chat');
      });

      await _step(tester, scenario, 'chat_search', () async {
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.inputChatSearch),
        );
        await tester.enterText(
          byItKey(IntegrationTestKeys.inputChatSearch),
          'turq',
        );
        await tester.pump(const Duration(milliseconds: 300));
      });

      await _step(tester, scenario, 'chat_create', () async {
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.actionChatCreate),
        );
        await popRouteAndSettle(tester, settlePumps: 6);
        expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);
      }, allowNoOp: true);

      for (final tabKey in <String>[
        IntegrationTestKeys.chatTabAll,
        IntegrationTestKeys.chatTabUnread,
        IntegrationTestKeys.chatTabArchive,
      ]) {
        currentStep = tabKey;
        await _step(tester, scenario, currentStep, () async {
          await _tapIfPresent(tester, byItKey(tabKey));
          await _assertNoFeedLeakIfSupported(tester, currentStep);
        });
      }

      await _step(tester, scenario, 'chat_resume', () async {
        await _backgroundAndResume(tester);
        await _assertNoFeedLeakIfSupported(tester, 'chat_resume');
        await popRouteAndSettle(tester);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'notifications', () async {
        await tapItKey(tester, IntegrationTestKeys.actionOpenNotifications);
        expect(
          byItKey(IntegrationTestKeys.screenNotifications),
          findsOneWidget,
        );
        await _assertNoFeedLeakIfSupported(tester, 'notifications');
      });

      for (var index = 0; index < 5; index++) {
        currentStep = 'notifications_tab_$index';
        await _step(tester, scenario, currentStep, () async {
          await _tapIfPresent(
            tester,
            _findPageLineBarTab(kNotificationsPageLineBarTag, index),
          );
          await _assertNoFeedLeakIfSupported(tester, currentStep);
        }, allowNoOp: true);
      }

      await _step(tester, scenario, 'notifications_more', () async {
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.actionNotificationsMore),
        );
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.actionNotificationsMarkAllRead),
        );
        if (byItKey(IntegrationTestKeys.actionNotificationsMore)
            .evaluate()
            .isNotEmpty) {
          await _tapIfPresent(
            tester,
            byItKey(IntegrationTestKeys.actionNotificationsMore),
          );
        }
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.actionNotificationsDeleteAll),
        );
        await popRouteAndSettle(tester, settlePumps: 4);
        await _assertNoFeedLeakIfSupported(tester, 'notifications_more');
      });

      await _step(tester, scenario, 'notifications_resume', () async {
        await _backgroundAndResume(tester);
        await _assertNoFeedLeakIfSupported(
          tester,
          'notifications_resume',
        );
        await popRouteAndSettle(tester);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'short', () async {
        await tapItKey(tester, IntegrationTestKeys.navShort,
            settlePumps: 12);
        expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
        await _assertNoFeedLeakIfSupported(tester, 'short');
      });

      await _step(tester, scenario, 'short_resume', () async {
        await _backgroundAndResume(tester);
        await _assertNoFeedLeakIfSupported(tester, 'short_resume');
        final shortBack = byItKey(IntegrationTestKeys.actionShortBack).first;
        await tester.ensureVisible(shortBack);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(shortBack);
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 250),
          maxPumps: 10,
        );
      });

      await _step(tester, scenario, 'final_feed', () async {
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'story_viewer', () async {
        final storyRow = byItKey(IntegrationTestKeys.storyRow);
        if (storyRow.evaluate().isEmpty) return;
        final circle = _findStoryCircle();
        if (circle.evaluate().isEmpty) return;
        await tester.ensureVisible(circle.first);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(circle.first);
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 10,
        );
        expect(byItKey(IntegrationTestKeys.screenStoryViewer), findsOneWidget);
        await pageBackAndSettle(tester);
        await expectFeedScreen(tester);
      }, allowNoOp: true);

      await E2EProgressTracker.markDone(tester, scenario: scenario);
    } catch (error) {
      await E2EProgressTracker.markFailure(
        tester,
        scenario: scenario,
        step: currentStep,
        error: error,
      );
      rethrow;
    }
  });
}

Future<void> _step(
  WidgetTester tester,
  String scenario,
  String label,
  Future<void> Function() body, {
  bool allowNoOp = false,
}) async {
  await E2EProgressTracker.recordStep(
    tester,
    scenario: scenario,
    step: label,
  );
  await body();
  if (!allowNoOp) {
    await expectNoFlutterException(tester);
  }
}

Future<T> _stepWithResult<T>(
  WidgetTester tester,
  String scenario,
  String label,
  Future<T> Function() body,
) async {
  await E2EProgressTracker.recordStep(
    tester,
    scenario: scenario,
    step: label,
  );
  final result = await body();
  await expectNoFlutterException(tester);
  return result;
}

Future<String> _waitForFirstFeedPostId(WidgetTester tester) async {
  final controller = AgendaController.ensure();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    final first = controller.agendaList.firstWhereOrNull(
      (post) => post.docID.trim().isNotEmpty,
    );
    if (first != null) {
      return first.docID;
    }
  }
  throw TestFailure('Feed did not expose a usable first post for master E2E.');
}

Finder _findItKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is! ValueKey<String>) return false;
    return key.value.startsWith(prefix);
  });
}

Finder _findPageLineBarTab(String baseTag, int index) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is! ValueKey<String>) return false;
    final value = key.value;
    return value == IntegrationTestKeys.pageLineBarItem(baseTag, index) ||
        (value.startsWith('it-page-line-bar-${baseTag}_') &&
            value.endsWith('-$index'));
  });
}

Finder _findStoryCircle() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('circle_');
  });
}

Future<void> _tapByExactItKey(WidgetTester tester, String key) async {
  final finder = byItKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await pumpForAppStartup(
    tester,
    step: const Duration(milliseconds: 180),
    maxPumps: 6,
  );
}

Future<void> _tapFirstKeyPrefixIfPresent(
  WidgetTester tester,
  String prefix, {
  Future<void> Function()? afterTap,
}) async {
  final finder = _findItKeyPrefix(prefix);
  if (finder.evaluate().isEmpty) return;
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(target);
  await pumpForAppStartup(
    tester,
    step: const Duration(milliseconds: 180),
    maxPumps: 6,
  );
  if (afterTap != null) {
    await afterTap();
  }
}

Future<void> _tapIfPresent(
  WidgetTester tester,
  Finder finder, {
  int settlePumps = 6,
}) async {
  if (finder.evaluate().isEmpty) return;
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder.first);
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _fillEditProfileFields(WidgetTester tester) async {
  await tester.enterText(
    byItKey(IntegrationTestKeys.inputEditProfileFirstName),
    'Turq',
  );
  await tester.enterText(
    byItKey(IntegrationTestKeys.inputEditProfileLastName),
    'App',
  );
  await tester.pump(const Duration(milliseconds: 250));
  if (tester.testTextInput.isRegistered) {
    tester.testTextInput.hide();
  }
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tapAt(const Offset(24, 24));
  await tester.pump(const Duration(milliseconds: 250));
  final updateButton = byItKey(IntegrationTestKeys.actionEditProfileUpdate);
  await tester.dragUntilVisible(
    updateButton,
    byItKey(IntegrationTestKeys.screenEditProfile),
    const Offset(0, -320),
    maxIteration: 8,
  );
  await tester.ensureVisible(updateButton);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(updateButton, warnIfMissed: false);
  await pumpForAppStartup(
    tester,
    step: const Duration(milliseconds: 250),
    maxPumps: 16,
  );
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

Future<void> _assertNoFeedLeakIfSupported(
  WidgetTester tester,
  String label,
) async {
  if (!supportsNativeExoSmoke) return;
  await expectNoAudibleNativeFeedPlayback(
    tester,
    label: label,
    timeout: const Duration(seconds: 2),
  );
}
