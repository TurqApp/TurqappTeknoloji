import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../bootstrap/test_app_bootstrap.dart';
import 'test_state_probe.dart';

Finder findItKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
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

Future<Map<String, dynamic>> waitForSurfaceProbe(
  WidgetTester tester,
  String surface,
  bool Function(Map<String, dynamic>) predicate, {
  int maxPumps = 16,
  Duration step = const Duration(milliseconds: 250),
  String? reason,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    final payload = readSurfaceProbe(surface);
    if (predicate(payload)) {
      return payload;
    }
    await tester.pump(step);
  }
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
      final docIds = payload['docIds'];
      return docIds is List && docIds.isNotEmpty;
    },
    reason: 'Feed did not expose any docIds for comments flow.',
  );
  final docIds = (feedPayload['docIds'] as List<dynamic>)
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  final firstPostId = docIds.first;
  await tapItKey(
    tester,
    IntegrationTestKeys.feedCommentButton(firstPostId),
    settlePumps: 10,
  );
  expect(byItKey(IntegrationTestKeys.screenComments), findsOneWidget);
  return firstPostId;
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
