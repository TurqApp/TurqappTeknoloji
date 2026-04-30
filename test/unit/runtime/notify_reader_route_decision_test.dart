import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_route_decision.dart';

void main() {
  test('resolves profile notifications to social profile targets', () {
    final decision = resolveNotifyReaderRoute(
      type: 'follow',
      postType: '',
      postId: '',
      userId: ' user-1 ',
    );

    expect(decision.action, NotifyReaderRouteAction.profile);
    expect(decision.routeKind, 'social_profile');
    expect(decision.targetId, 'user-1');
    expect(decision.normalizedType, 'follow');
  });

  test('keeps missing target snackbar decisions explicit', () {
    final profile = resolveNotifyReaderRoute(
      type: 'user',
      postType: '',
      postId: '',
      userId: '',
    );
    final chat = resolveNotifyReaderRoute(
      type: 'message',
      postType: '',
      postId: '',
      userId: '',
    );
    final tutoring = resolveNotifyReaderRoute(
      type: 'tutoring_status',
      postType: '',
      postId: '',
      userId: '',
    );

    expect(profile.action, NotifyReaderRouteAction.missing);
    expect(profile.messageKey, 'notify_reader.profile_open_failed');
    expect(chat.messageKey, 'notify_reader.chat_missing');
    expect(tutoring.messageKey, 'notify_reader.tutoring_missing');
  });

  test('resolves listing notifications to their detail route kinds', () {
    final job = resolveNotifyReaderRoute(
      type: 'job_application',
      postType: '',
      postId: 'job-1',
      userId: '',
    );
    final tutoring = resolveNotifyReaderRoute(
      type: 'tutoring_application',
      postType: '',
      postId: 'tutoring-1',
      userId: '',
    );
    final market = resolveNotifyReaderRoute(
      type: 'market_offer',
      postType: '',
      postId: 'market-1',
      userId: '',
    );

    expect(job.action, NotifyReaderRouteAction.job);
    expect(job.routeKind, 'job_detail');
    expect(tutoring.action, NotifyReaderRouteAction.tutoring);
    expect(tutoring.routeKind, 'tutoring_detail');
    expect(market.action, NotifyReaderRouteAction.market);
    expect(market.routeKind, 'market_detail');
  });

  test('resolves comments and post notifications separately', () {
    final comment = resolveNotifyReaderRoute(
      type: 'comment',
      postType: '',
      postId: 'post-1',
      userId: '',
    );
    final post = resolveNotifyReaderRoute(
      type: 'like',
      postType: '',
      postId: 'post-2',
      userId: '',
    );

    expect(comment.action, NotifyReaderRouteAction.postComments);
    expect(comment.routeKind, 'single_post_comments');
    expect(post.action, NotifyReaderRouteAction.post);
    expect(post.routeKind, 'single_post');
  });

  test('falls back to postType and finally user profile when needed', () {
    final postTypeFallback = resolveNotifyReaderRoute(
      type: '',
      postType: 'Posts',
      postId: 'post-1',
      userId: '',
    );
    final userFallback = resolveNotifyReaderRoute(
      type: 'unknown',
      postType: '',
      postId: '',
      userId: 'user-2',
    );

    expect(postTypeFallback.action, NotifyReaderRouteAction.post);
    expect(postTypeFallback.normalizedType, 'posts');
    expect(userFallback.action, NotifyReaderRouteAction.profile);
    expect(userFallback.targetId, 'user-2');
  });

  test('resolves legacy NotifyReader routes without expanding behavior', () {
    final profile = resolveLegacyNotifyReaderRoute(
      type: 'follow',
      docId: 'user-1',
    );
    final post = resolveLegacyNotifyReaderRoute(
      type: 'shared_as_posts',
      docId: 'post-1',
    );
    final market = resolveLegacyNotifyReaderRoute(
      type: 'market_offer',
      docId: 'market-1',
    );
    final unsupportedJob = resolveLegacyNotifyReaderRoute(
      type: 'job_application',
      docId: 'job-1',
    );

    expect(profile.action, NotifyReaderRouteAction.profile);
    expect(post.action, NotifyReaderRouteAction.post);
    expect(market.action, NotifyReaderRouteAction.market);
    expect(unsupportedJob.action, NotifyReaderRouteAction.missing);
  });

  test('resolves notification tap routes with FCM supported type set', () {
    final job = resolveNotificationTapRoute(
      type: 'job_application',
      docId: 'job-1',
    );
    final tutoring = resolveNotificationTapRoute(
      type: 'tutoring_status',
      docId: 'tutoring-1',
    );
    final unknown = resolveNotificationTapRoute(
      type: 'unknown',
      docId: 'target-1',
    );

    expect(job.action, NotifyReaderRouteAction.job);
    expect(job.targetId, 'job-1');
    expect(tutoring.action, NotifyReaderRouteAction.tutoring);
    expect(unknown.action, NotifyReaderRouteAction.missing);
  });

  test('NotifyReaderController delegates route decisions to resolver',
      () async {
    final controllerSource = await File(
      'lib/Core/NotifyReader/notify_reader_controller.dart',
    ).readAsString();
    final navigationSource = await File(
      'lib/Core/NotifyReader/notify_reader_controller_navigation_part.dart',
    ).readAsString();
    final runtimeSource = await File(
      'lib/Core/NotifyReader/notify_reader_controller_runtime_part.dart',
    ).readAsString();
    final fieldsSource = await File(
      'lib/Core/NotifyReader/notify_reader_controller_fields_part.dart',
    ).readAsString();

    expect(runtimeSource, contains('resolveNotifyReaderRoute('));
    expect(runtimeSource, isNot(contains('normalizeNotificationType(')));
    expect(runtimeSource, isNot(contains('isNotificationPostType(')));
    expect(fieldsSource, isNot(contains('_notifyReaderProfileTypes')));
    expect(fieldsSource, isNot(contains('_notifyReaderMarketTypes')));
    expect(controllerSource, contains('profile_navigation_service.dart'));
    expect(navigationSource, contains('ProfileNavigationService'));
    expect(navigationSource, contains('openSocialProfile(userID)'));
    expect(navigationSource, isNot(contains('Get.to<SocialProfile>')));
    expect(
      controllerSource,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
  });

  test('NotifyReader widget delegates legacy route decisions to resolver',
      () async {
    final source = await File(
      'lib/Core/NotifyReader/notify_reader.dart',
    ).readAsString();

    expect(source, contains('resolveLegacyNotifyReaderRoute('));
    expect(source, isNot(contains('normalizeSearchText(')));
    expect(source, isNot(contains('_profileTypes')));
    expect(source, isNot(contains('_marketTypes')));
  });

  test('NotificationService tap handling delegates route decisions to resolver',
      () async {
    final serviceSource = await File(
      'lib/Core/notification_service.dart',
    ).readAsString();
    final messageSource = await File(
      'lib/Core/notification_service_message_part.dart',
    ).readAsString();

    expect(messageSource, contains('resolveNotificationTapRoute('));
    expect(messageSource, isNot(contains('normalizeSearchText(')));
    expect(serviceSource, isNot(contains('_profileTypes')));
    expect(serviceSource, isNot(contains('_tutoringTypes')));
    expect(serviceSource, isNot(contains('_marketTypes')));
  });
}
