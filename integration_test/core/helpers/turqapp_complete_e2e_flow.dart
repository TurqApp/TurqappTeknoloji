import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

import 'e2e_progress_tracker.dart';
import 'native_exoplayer_probe.dart';
import 'route_replay.dart';
import 'smoke_artifact_collector.dart';
import '../bootstrap/test_app_bootstrap.dart';
import 'deep_flow_helpers.dart';

const String kTurqAppMasterE2EScenario = 'turqapp_master_e2e';
const Duration _kE2EStepTimeout = Duration(seconds: 45);

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
        await openCommentsForFirstFeedPost(tester);
        expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
        await pumpUntilVisible(
          tester,
          byItKey(IntegrationTestKeys.inputComment),
          maxPumps: 20,
        );
        final commentText = uniqueTestText('TurqApp master e2e comment');
        await tester.enterText(
          byItKey(IntegrationTestKeys.inputComment),
          commentText,
        );
        await tester.pump(const Duration(milliseconds: 250));
        await pumpUntilVisible(
          tester,
          byItKey(IntegrationTestKeys.actionCommentSend),
          maxPumps: 20,
        );
        await tapItKey(
          tester,
          IntegrationTestKeys.actionCommentSend,
          settlePumps: 8,
        );
        expect(
          await _waitForAnyKeyPrefix(
            tester,
            'it-comment-item-',
            maxPumps: 20,
          ),
          isTrue,
          reason: 'Comments route should expose at least one comment item key.',
        );
        await expectNoFlutterException(tester);
        await popRouteAndSettle(tester);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'profile', () async {
        prepareProfileShellRouteReplay();
        await pressItKey(tester, IntegrationTestKeys.navProfile);
        await _ensureProfileScreen(tester);
        expect(
          byItKey(IntegrationTestKeys.profileFollowersCounter),
          findsOneWidget,
        );
        expect(
          byItKey(IntegrationTestKeys.profileFollowingCounter),
          findsOneWidget,
        );
        await _assertNoFeedLeakIfSupported(tester, 'profile');
      });

      await _step(tester, scenario, 'profile_followers', () async {
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.profileFollowersCounter),
        );
        expect(
          byItKey(IntegrationTestKeys.screenFollowingFollowers),
          findsOneWidget,
        );
        await popRouteAndSettle(tester);
        await _ensureProfileScreen(tester);
      });

      await _step(tester, scenario, 'profile_following', () async {
        await _tapIfPresent(
          tester,
          byItKey(IntegrationTestKeys.profileFollowingCounter),
        );
        expect(
          byItKey(IntegrationTestKeys.screenFollowingFollowers),
          findsOneWidget,
        );
        await popRouteAndSettle(tester);
        await _ensureProfileScreen(tester);
      });

      await _step(tester, scenario, 'profile_edit', () async {
        await tapItKey(tester, IntegrationTestKeys.actionProfileEdit);
        expect(
          byItKey(IntegrationTestKeys.screenEditProfile),
          findsOneWidget,
        );
        await _fillEditProfileFields(tester);
        await popRouteAndSettle(tester);
        await _ensureProfileScreen(tester);
      });

      await _step(tester, scenario, 'profile_settings', () async {
        await tapItKey(
          tester,
          IntegrationTestKeys.actionProfileOpenSettings,
        );
        expect(byItKey(IntegrationTestKeys.screenSettings), findsOneWidget);
        expect(
          byItKey(IntegrationTestKeys.actionSettingsSignOut),
          findsOneWidget,
        );
        await popRouteAndSettle(tester);
        await _ensureProfileScreen(tester);
      });

      await _step(tester, scenario, 'profile_qr', () async {
        await tapItKey(
          tester,
          IntegrationTestKeys.actionProfileOpenQr,
        );
        expect(byItKey(IntegrationTestKeys.screenMyQr), findsOneWidget);
        await popRouteAndSettle(tester);
        await _ensureProfileScreen(tester);
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
        await ensureFeedTabVisibleForSmoke(tester);
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
        expect(
          byItKey(IntegrationTestKeys.actionPostCreatorPublish),
          findsOneWidget,
        );
        await popRouteAndSettle(tester);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'explore', () async {
        await pressItKey(tester, IntegrationTestKeys.navExplore);
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
          await pressItKey(tester, IntegrationTestKeys.navEducation);
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
            if (tabId == PasajTabIds.market) {
              await _exerciseMarketTopActions(tester);
            } else if (tabId == PasajTabIds.questionBank) {
              await _exerciseQuestionBankSurface(tester);
            } else if (tabId == PasajTabIds.practiceExams) {
              await _exercisePracticeExamSurface(tester);
            }
            await _assertNoFeedLeakIfSupported(tester, currentStep);
          });
        }

        await _step(tester, scenario, 'education_resume', () async {
          await pumpForAppStartup(
            tester,
            step: const Duration(milliseconds: 200),
            maxPumps: 8,
          );
          expect(
            byItKey(IntegrationTestKeys.screenEducation),
            findsOneWidget,
          );
          await _assertNoFeedLeakIfSupported(tester, 'education_resume');
        });
      }

      await _step(tester, scenario, 'chat', () async {
        await pressItKey(tester, IntegrationTestKeys.navFeed);
        await expectFeedScreen(tester);
        await pressItKey(tester, IntegrationTestKeys.navChat);
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
        expect(
          await _waitForAnyKeyPrefix(
            tester,
            'it-chat-tile-',
            maxPumps: 6,
          ),
          isTrue,
          reason: 'Chat route should expose at least one chat tile key.',
        );
      });

      await _step(tester, scenario, 'chat_tile_surface', () async {
        await _tapFirstKeyPrefixIfPresent(
          tester,
          'it-chat-tile-',
          afterTap: () async {
            await popRouteAndSettle(tester, settlePumps: 6);
            expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);
          },
        );
      }, allowNoOp: true);

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
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 8,
        );
        expect(byItKey(IntegrationTestKeys.screenChat), findsOneWidget);
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
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 8,
        );
        final notificationsScreen =
            byItKey(IntegrationTestKeys.screenNotifications);
        if (notificationsScreen.evaluate().isNotEmpty) {
          expect(notificationsScreen, findsOneWidget);
        } else {
          await expectFeedScreen(tester);
          return;
        }
        await _assertNoFeedLeakIfSupported(
          tester,
          'notifications_resume',
        );
        await popRouteAndSettle(tester);
        await expectFeedScreen(tester);
      });

      await _step(tester, scenario, 'short', () async {
        await pressItKey(
          tester,
          IntegrationTestKeys.navShort,
          settlePumps: 12,
        );
        expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
        await _assertNoFeedLeakIfSupported(tester, 'short');
      });

      await _step(tester, scenario, 'short_resume', () async {
        await pumpForAppStartup(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 8,
        );
        expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
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
        final openedViewer = await openAnyStoryViewerIfAvailable(
          tester,
          step: const Duration(milliseconds: 200),
          maxPumps: 10,
        );
        if (!openedViewer) return;
        expect(
          byItKey(IntegrationTestKeys.screenStoryViewer),
          findsOneWidget,
        );
        await popRouteAndSettle(tester);
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
  try {
    await body().timeout(_kE2EStepTimeout);
  } on TimeoutException {
    throw TestFailure(
      'TurqApp complete E2E step timed out: $label '
      'after ${_kE2EStepTimeout.inSeconds}s.',
    );
  }
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
  final T result;
  try {
    result = await body().timeout(_kE2EStepTimeout);
  } on TimeoutException {
    throw TestFailure(
      'TurqApp complete E2E step timed out: $label '
      'after ${_kE2EStepTimeout.inSeconds}s.',
    );
  }
  await expectNoFlutterException(tester);
  return result;
}

Future<String> _waitForFirstFeedPostId(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    final commentKey = firstValueKeyString(_findItKeyPrefix('it-feed-comment-'));
    if (commentKey != null && commentKey.startsWith('it-feed-comment-')) {
      final docId = commentKey.replaceFirst('it-feed-comment-', '').trim();
      if (docId.isNotEmpty) {
        return docId;
      }
    }
  }

  final controller = ensureAgendaController();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    String? first;
    for (final post in controller.agendaList) {
      final docId = post.docID.trim();
      if (docId.isEmpty) continue;
      first = docId;
      break;
    }
    if (first != null) {
      return first;
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

Future<void> _tapByExactItKey(WidgetTester tester, String key) async {
  final finder = byItKey(key);
  for (var i = 0; i < 16; i++) {
    if (finder.evaluate().isNotEmpty) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
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
  final target = firstInteractable(finder);
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(target);
  for (var i = 0; i < settlePumps; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<bool> _waitForAnyKeyPrefix(
  WidgetTester tester,
  String prefix, {
  int maxPumps = 10,
  Duration step = const Duration(milliseconds: 200),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (_findItKeyPrefix(prefix).evaluate().isNotEmpty) {
      return true;
    }
    await tester.pump(step);
  }
  return _findItKeyPrefix(prefix).evaluate().isNotEmpty;
}

Future<void> _exerciseMarketTopActions(WidgetTester tester) async {
  final viewMode = byItKey(IntegrationTestKeys.marketTopActionViewMode);
  final sort = byItKey(IntegrationTestKeys.marketTopActionSort);
  final filter = byItKey(IntegrationTestKeys.marketTopActionFilter);

  expect(
    viewMode,
    findsOneWidget,
    reason: 'Market tab should expose view-mode action key.',
  );
  expect(
    sort,
    findsOneWidget,
    reason: 'Market tab should expose sort action key.',
  );
  expect(
    filter,
    findsOneWidget,
    reason: 'Market tab should expose filter action key.',
  );

  await _tapIfPresent(tester, viewMode, settlePumps: 4);
  await _tapIfPresent(tester, sort, settlePumps: 4);
  await popRouteAndSettle(tester, settlePumps: 4);
  await _tapIfPresent(tester, filter, settlePumps: 4);
  await popRouteAndSettle(tester, settlePumps: 4);
}

Future<void> _exerciseQuestionBankSurface(WidgetTester tester) async {
  final found = await _waitForAnyKeyPrefix(
    tester,
    'it-question-bank-category-',
    maxPumps: 8,
  );
  if (!found) return;

  await _tapFirstKeyPrefixIfPresent(
    tester,
    'it-question-bank-category-',
    afterTap: () async {
      if (byItKey(IntegrationTestKeys.screenEducation).evaluate().isEmpty) {
        await popRouteAndSettle(tester, settlePumps: 6);
      }
      expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
    },
  );
}

Future<void> _exercisePracticeExamSurface(WidgetTester tester) async {
  final found = await _waitForAnyKeyPrefix(
    tester,
    'it-practice-exam-open-',
    maxPumps: 8,
  );
  if (!found) return;

  await _tapFirstKeyPrefixIfPresent(
    tester,
    'it-practice-exam-open-',
    afterTap: () async {
      if (byItKey(IntegrationTestKeys.screenEducation).evaluate().isEmpty) {
        await popRouteAndSettle(tester, settlePumps: 6);
      }
      expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
    },
  );
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

Future<void> _ensureProfileScreen(WidgetTester tester) async {
  final profileScreen = byItKey(IntegrationTestKeys.screenProfile);
  if (profileScreen.evaluate().isEmpty) {
    await pressItKey(tester, IntegrationTestKeys.navProfile);
  }
  expect(profileScreen, findsOneWidget);
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
