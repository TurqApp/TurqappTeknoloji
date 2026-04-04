import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

class _NotificationCandidate {
  const _NotificationCandidate({
    required this.docId,
    required this.routeKind,
  });

  final String docId;
  final String routeKind;
}

String? _routeKindFor({
  required String type,
  required String postType,
  required String postId,
  required String userId,
}) {
  final normalized = normalizeNotificationType(type, postType);
  if ((normalized == 'follow' || normalized == 'user') && userId.isNotEmpty) {
    return 'social_profile';
  }
  if ((normalized == 'message' || normalized == 'chat') && postId.isNotEmpty) {
    return 'chat_conversation';
  }
  if (normalized == 'market_offer' || normalized == 'market_offer_status') {
    return postId.isNotEmpty ? 'market_detail' : null;
  }
  if (normalized == 'job_application') {
    return postId.isNotEmpty ? 'job_detail' : null;
  }
  if (normalized == kNotificationPostTypeCommentLower) {
    return postId.isNotEmpty ? 'single_post_comments' : null;
  }
  if (isNotificationPostType(normalized) && postId.isNotEmpty) {
    return 'single_post';
  }
  return null;
}

_NotificationCandidate? _pickSupportedNotification(
    Map<String, dynamic> payload) {
  final docIds = (payload['docIds'] as List<dynamic>? ?? const <dynamic>[])
      .map((item) => item?.toString() ?? '')
      .toList(growable: false);
  final types = (payload['types'] as List<dynamic>? ?? const <dynamic>[])
      .map((item) => item?.toString() ?? '')
      .toList(growable: false);
  final postTypes =
      (payload['postTypes'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item?.toString() ?? '')
          .toList(growable: false);
  final postIds = (payload['postIds'] as List<dynamic>? ?? const <dynamic>[])
      .map((item) => item?.toString() ?? '')
      .toList(growable: false);
  final userIds = (payload['userIds'] as List<dynamic>? ?? const <dynamic>[])
      .map((item) => item?.toString() ?? '')
      .toList(growable: false);

  final count = <int>[
    docIds.length,
    types.length,
    postTypes.length,
    postIds.length,
    userIds.length,
  ].reduce((value, element) => value < element ? value : element);

  final userFrequency = <String, int>{};
  for (var index = 0; index < count; index++) {
    final userId = userIds[index].trim();
    if (userId.isEmpty) continue;
    userFrequency[userId] = (userFrequency[userId] ?? 0) + 1;
  }

  _NotificationCandidate? fallback;

  for (var index = 0; index < count; index++) {
    final docId = docIds[index].trim();
    if (docId.isEmpty) continue;
    final userId = userIds[index].trim();
    final routeKind = _routeKindFor(
      type: types[index],
      postType: postTypes[index],
      postId: postIds[index],
      userId: userId,
    );
    if (routeKind == null) continue;
    final candidate =
        _NotificationCandidate(docId: docId, routeKind: routeKind);
    if (userId.isNotEmpty && userFrequency[userId] == 1) {
      return candidate;
    }
    fallback ??= candidate;
  }
  return fallback;
}

void _expectRouteSurface(String routeKind) {
  switch (routeKind) {
    case 'social_profile':
      expect(byItKey(IntegrationTestKeys.screenSocialProfile), findsOneWidget);
      return;
    case 'chat_conversation':
      expect(
        byItKey(IntegrationTestKeys.screenChatConversation),
        findsOneWidget,
      );
      return;
    case 'market_detail':
      expect(byItKey(IntegrationTestKeys.screenMarketDetail), findsOneWidget);
      return;
    case 'job_detail':
      expect(byItKey(IntegrationTestKeys.screenJobDetail), findsOneWidget);
      return;
    case 'single_post':
    case 'single_post_comments':
      expect(byItKey(IntegrationTestKeys.screenSinglePost), findsOneWidget);
      return;
    default:
      throw TestFailure('Unsupported notification route kind: $routeKind');
  }
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Notification deeplink opens the expected target route',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'notification_deeplink_route_e2e',
        tester,
        () async {
          await launchTurqApp(
            tester,
            relaxFeedFixtureDocRequirement: true,
          );
          await expectFeedScreen(tester);

          await tapItKey(tester, IntegrationTestKeys.actionOpenNotifications);
          expect(
              byItKey(IntegrationTestKeys.screenNotifications), findsOneWidget);

          final payload = await waitForSurfaceProbe(
            tester,
            'notifications',
            (snapshot) =>
                snapshot['registered'] == true &&
                (snapshot['count'] as num? ?? 0) > 0,
            reason:
                'Notification deeplink test requires at least one inbox item.',
          );

          final candidate = _pickSupportedNotification(payload);
          expect(
            candidate,
            isNotNull,
            reason:
                'No supported notification route type found for deeplink validation.',
          );

          final selected = candidate!;
          await tapItKey(
            tester,
            IntegrationTestKeys.notificationItemOpen(selected.docId),
            settlePumps: 10,
          );

          final afterOpen = await waitForSurfaceProbe(
            tester,
            'notifications',
            (snapshot) =>
                snapshot['lastOpenedNotificationId'] == selected.docId &&
                snapshot['lastOpenedRouteKind'] == selected.routeKind,
            reason:
                'Notification tap did not record the expected route target.',
          );

          expect(afterOpen['lastOpenedRouteKind'], selected.routeKind);
          _expectRouteSurface(selected.routeKind);
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
