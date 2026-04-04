import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_fixture_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../bootstrap/test_app_bootstrap.dart';
import 'test_state_probe.dart';
import 'transient_error_policy.dart';

Finder findItKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

List<String> _valueKeysWithPrefix(String prefix) {
  return findItKeyPrefix(prefix)
      .evaluate()
      .map((element) => element.widget.key)
      .whereType<ValueKey<String>>()
      .map((key) => key.value)
      .toList(growable: false);
}

Future<String> _waitForVisibleFeedCommentKey(
  WidgetTester tester, {
  int maxScrolls = 8,
  Duration step = const Duration(milliseconds: 250),
}) async {
  final feedScrollable = find.descendant(
    of: byItKey(IntegrationTestKeys.screenFeed),
    matching: find.byType(Scrollable),
  );

  for (var i = 0; i <= maxScrolls; i++) {
    final value = firstValueKeyString(findItKeyPrefix('it-feed-comment-'));
    if (value != null && value.isNotEmpty) {
      return value;
    }
    if (i == maxScrolls || feedScrollable.evaluate().isEmpty) {
      break;
    }
    await tester.drag(feedScrollable.first, const Offset(0, -260));
    await tester.pump(step);
  }

  throw TestFailure('No integration key found with prefix: it-feed-comment-');
}

String? firstValueKeyString(Finder finder) {
  final matches = finder.evaluate();
  if (matches.isEmpty) return null;
  final key = matches.first.widget.key;
  if (key is! ValueKey<String>) return null;
  return key.value;
}

Future<String> waitForKeyPrefix(
  WidgetTester tester,
  String prefix, {
  int maxPumps = 16,
  Duration step = const Duration(milliseconds: 250),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    final value = firstValueKeyString(findItKeyPrefix(prefix));
    if (value != null && value.isNotEmpty) {
      return value;
    }
    await tester.pump(step);
  }
  final value = firstValueKeyString(findItKeyPrefix(prefix));
  if (value != null && value.isNotEmpty) {
    return value;
  }
  throw TestFailure('No integration key found with prefix: $prefix');
}

Future<void> tapFirstKeyPrefix(
  WidgetTester tester,
  String prefix, {
  int settlePumps = 8,
}) async {
  final key = await waitForKeyPrefix(tester, prefix);
  await tapItKey(tester, key, settlePumps: settlePumps);
}

Future<bool> openAnyStoryViewerIfAvailable(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 200),
  int maxPumps = 10,
}) async {
  if (byItKey(IntegrationTestKeys.storyRow).evaluate().isEmpty) {
    return false;
  }

  final storyCircleKeys = _valueKeysWithPrefix('circle_');
  if (storyCircleKeys.isEmpty) {
    return false;
  }

  final orderedKeys = storyCircleKeys.length <= 1
      ? storyCircleKeys
      : <String>[
          ...storyCircleKeys.skip(1),
          storyCircleKeys.first,
        ];

  for (final key in orderedKeys) {
    final finder = find.byKey(ValueKey<String>(key));
    if (finder.evaluate().isEmpty) continue;
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(finder.first);
    await pumpForAppStartup(tester, step: step, maxPumps: maxPumps);

    if (byItKey(IntegrationTestKeys.screenStoryViewer).evaluate().isNotEmpty) {
      return true;
    }

    final route =
        (readIntegrationProbe()['currentRoute'] as String? ?? '').trim();
    final shouldPop = route.isNotEmpty && route != '/NavBarView';
    if (shouldPop) {
      await popRouteAndSettle(tester, settlePumps: 6);
      await pumpForAppStartup(tester, step: step, maxPumps: 4);
    }
  }

  return false;
}

Future<Map<String, dynamic>> waitForSurfaceProbe(
  WidgetTester tester,
  String surface,
  bool Function(Map<String, dynamic>) predicate, {
  int maxPumps = 16,
  Duration step = const Duration(milliseconds: 250),
  String? reason,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    drainExpectedTesterExceptions(tester, context: reason ?? surface);
    final payload = readSurfaceProbe(surface);
    if (predicate(payload)) {
      return payload;
    }
    await tester.pump(step);
    drainExpectedTesterExceptions(tester, context: reason ?? surface);
  }
  drainExpectedTesterExceptions(tester, context: reason ?? surface);
  final payload = readSurfaceProbe(surface);
  if (predicate(payload)) {
    return payload;
  }
  final detail =
      reason ?? 'Surface probe did not reach expected state: $surface';
  throw TestFailure('$detail Last payload: $payload');
}

Future<String> openCommentsForFirstFeedPost(WidgetTester tester) async {
  final feedPayload = await waitForSurfaceProbe(
    tester,
    'feed',
    (payload) {
      final centeredDocId = (payload['centeredDocId'] as String? ?? '').trim();
      final docIds = payload['docIds'];
      return centeredDocId.isNotEmpty || (docIds is List && docIds.isNotEmpty);
    },
    reason: 'Feed did not expose any docIds for comments flow.',
  );
  final requiredFeedDocIds =
      IntegrationTestFixtureContract.current.surface('feed')?.requiredDocIds ??
          const <String>[];
  for (final docId in requiredFeedDocIds) {
    final opened = await _tryOpenCommentsForFeedPost(tester, docId);
    if (opened) {
      return docId;
    }
  }
  final centeredDocId = (feedPayload['centeredDocId'] as String? ?? '').trim();
  if (centeredDocId.isNotEmpty &&
      await _tryOpenCommentsForFeedPost(tester, centeredDocId)) {
    return centeredDocId;
  }

  final visibleCommentKey = await _waitForVisibleFeedCommentKey(tester);
  final postId = visibleCommentKey.replaceFirst('it-feed-comment-', '');
  await tapItKey(tester, visibleCommentKey, settlePumps: 10);
  expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
  return postId;
}

Future<String> ensureCommentTargetForSmoke(
  WidgetTester tester, {
  String preferredCommentId = '',
  bool createIfMissing = true,
}) async {
  final initial = await waitForSurfaceProbe(
    tester,
    'comments',
    (payload) => payload['registered'] == true,
    maxPumps: 20,
    reason: 'Comments surface did not register.',
  );
  final preferred = preferredCommentId.trim();
  final initialDocIds = (initial['docIds'] as List<dynamic>? ?? const [])
      .map((item) => item?.toString().trim() ?? '')
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
  if (preferred.isNotEmpty && initialDocIds.contains(preferred)) {
    return preferred;
  }
  if (initialDocIds.isNotEmpty) {
    return initialDocIds.first;
  }
  if (!createIfMissing) {
    throw TestFailure('Comments surface has no actionable comment target.');
  }

  final fallbackText = uniqueTestText('turqapp e2e fallback comment');
  await sendCommentFromComposer(tester, fallbackText);

  final payload = await waitForSurfaceProbe(
    tester,
    'comments',
    (nextPayload) =>
        nextPayload['registered'] == true &&
        nextPayload['lastSuccessfulSendText'] == fallbackText &&
        (nextPayload['lastSuccessfulCommentId'] as String? ?? '').isNotEmpty,
    reason: 'Comments fallback creation did not expose a usable comment id.',
  );
  return (payload['lastSuccessfulCommentId'] as String).trim();
}

Future<void> sendCommentFromComposer(
  WidgetTester tester,
  String text, {
  int maxPumps = 20,
  int settlePumps = 8,
}) async {
  await tester.enterText(
    byItKey(IntegrationTestKeys.inputComment),
    text,
  );
  await tester.pump(const Duration(milliseconds: 250));
  await pumpUntilVisible(
    tester,
    byItKey(IntegrationTestKeys.actionCommentSend),
    maxPumps: maxPumps,
  );
  await tapItKey(
    tester,
    IntegrationTestKeys.actionCommentSend,
    settlePumps: settlePumps,
  );
}

Future<bool> _tryOpenCommentsForFeedPost(
  WidgetTester tester,
  String docId, {
  int maxScrolls = 8,
  Duration step = const Duration(milliseconds: 250),
}) async {
  final targetKey = IntegrationTestKeys.feedCommentButton(docId);
  final targetFinder = byItKey(targetKey);
  if (targetFinder.evaluate().isNotEmpty) {
    await tapItKey(tester, targetKey, settlePumps: 10);
    expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
    return true;
  }

  final feedScrollable = find.descendant(
    of: byItKey(IntegrationTestKeys.screenFeed),
    matching: find.byType(Scrollable),
  );
  if (feedScrollable.evaluate().isEmpty) {
    return false;
  }

  for (var i = 0; i < maxScrolls; i++) {
    await tester.drag(feedScrollable.first, const Offset(0, -260));
    await tester.pump(step);
    if (targetFinder.evaluate().isNotEmpty) {
      await tapItKey(tester, targetKey, settlePumps: 10);
      expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
      return true;
    }
  }

  return false;
}

Future<void> confirmCupertinoDialog(WidgetTester tester) async {
  final actions = find.byType(CupertinoDialogAction);
  if (actions.evaluate().isEmpty) {
    throw TestFailure('Expected a Cupertino dialog action to confirm.');
  }
  await tester.tap(actions.last);
  await pumpForAppStartup(
    tester,
    step: const Duration(milliseconds: 200),
    maxPumps: 8,
  );
  await expectNoFlutterException(tester);
}

String uniqueTestText(String prefix) {
  return '$prefix ${DateTime.now().millisecondsSinceEpoch}';
}
