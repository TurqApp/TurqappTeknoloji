import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
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
  final centeredDocId = (feedPayload['centeredDocId'] as String? ?? '').trim();
  if (centeredDocId.isNotEmpty) {
    final centeredKey = IntegrationTestKeys.feedCommentButton(centeredDocId);
    if (byItKey(centeredKey).evaluate().isNotEmpty) {
      await tapItKey(tester, centeredKey, settlePumps: 10);
      expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
      return centeredDocId;
    }
  }

  final visibleCommentKey = await _waitForVisibleFeedCommentKey(tester);
  final postId = visibleCommentKey.replaceFirst('it-feed-comment-', '');
  await tapItKey(tester, visibleCommentKey, settlePumps: 10);
  expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
  return postId;
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
