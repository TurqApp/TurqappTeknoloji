import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

enum NotifyReaderRouteAction {
  profile,
  job,
  tutoring,
  chat,
  market,
  postComments,
  post,
  missing,
}

class NotifyReaderRouteDecision {
  const NotifyReaderRouteDecision._({
    required this.action,
    required this.normalizedType,
    required this.routeKind,
    required this.targetId,
    required this.messageKey,
  });

  factory NotifyReaderRouteDecision.open({
    required NotifyReaderRouteAction action,
    required String normalizedType,
    required String routeKind,
    required String targetId,
  }) {
    return NotifyReaderRouteDecision._(
      action: action,
      normalizedType: normalizedType,
      routeKind: routeKind,
      targetId: targetId,
      messageKey: '',
    );
  }

  factory NotifyReaderRouteDecision.missing({
    required String normalizedType,
    required String messageKey,
  }) {
    return NotifyReaderRouteDecision._(
      action: NotifyReaderRouteAction.missing,
      normalizedType: normalizedType,
      routeKind: '',
      targetId: '',
      messageKey: messageKey,
    );
  }

  final NotifyReaderRouteAction action;
  final String normalizedType;
  final String routeKind;
  final String targetId;
  final String messageKey;

  bool get canOpen => action != NotifyReaderRouteAction.missing;
}

NotifyReaderRouteDecision resolveNotifyReaderRoute({
  required String type,
  required String postType,
  required String postId,
  required String userId,
}) {
  final normalizedType = normalizeNotificationType(type, postType);
  final targetId = postId.trim();
  final cleanUserId = userId.trim();

  if (normalizedType == 'follow' || normalizedType == 'user') {
    if (cleanUserId.isEmpty) {
      return NotifyReaderRouteDecision.missing(
        normalizedType: normalizedType,
        messageKey: 'notify_reader.profile_open_failed',
      );
    }
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.profile,
      normalizedType: normalizedType,
      routeKind: 'social_profile',
      targetId: cleanUserId,
    );
  }

  if (normalizedType == 'job_application') {
    if (targetId.isEmpty) {
      return NotifyReaderRouteDecision.missing(
        normalizedType: normalizedType,
        messageKey: 'notify_reader.listing_missing',
      );
    }
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.job,
      normalizedType: normalizedType,
      routeKind: 'job_detail',
      targetId: targetId,
    );
  }

  if (isTutoringNotificationType(normalizedType)) {
    if (targetId.isEmpty) {
      return NotifyReaderRouteDecision.missing(
        normalizedType: normalizedType,
        messageKey: 'notify_reader.tutoring_missing',
      );
    }
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.tutoring,
      normalizedType: normalizedType,
      routeKind: 'tutoring_detail',
      targetId: targetId,
    );
  }

  if (normalizedType == 'message' || normalizedType == 'chat') {
    if (targetId.isEmpty) {
      return NotifyReaderRouteDecision.missing(
        normalizedType: normalizedType,
        messageKey: 'notify_reader.chat_missing',
      );
    }
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.chat,
      normalizedType: normalizedType,
      routeKind: 'chat_conversation',
      targetId: targetId,
    );
  }

  if (normalizedType == 'market_offer' ||
      normalizedType == 'market_offer_status') {
    if (targetId.isEmpty) {
      return NotifyReaderRouteDecision.missing(
        normalizedType: normalizedType,
        messageKey: 'notify_reader.listing_missing',
      );
    }
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.market,
      normalizedType: normalizedType,
      routeKind: 'market_detail',
      targetId: targetId,
    );
  }

  if (normalizedType == kNotificationPostTypeCommentLower) {
    if (targetId.isEmpty) {
      return NotifyReaderRouteDecision.missing(
        normalizedType: normalizedType,
        messageKey: 'notify_reader.post_missing',
      );
    }
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.postComments,
      normalizedType: normalizedType,
      routeKind: 'single_post_comments',
      targetId: targetId,
    );
  }

  if (isNotificationPostType(normalizedType)) {
    if (targetId.isEmpty) {
      return NotifyReaderRouteDecision.missing(
        normalizedType: normalizedType,
        messageKey: 'notify_reader.post_missing',
      );
    }
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.post,
      normalizedType: normalizedType,
      routeKind: 'single_post',
      targetId: targetId,
    );
  }

  if (cleanUserId.isNotEmpty) {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.profile,
      normalizedType: normalizedType,
      routeKind: 'social_profile',
      targetId: cleanUserId,
    );
  }

  return NotifyReaderRouteDecision.missing(
    normalizedType: normalizedType,
    messageKey: 'notify_reader.route_missing',
  );
}

NotifyReaderRouteDecision resolveLegacyNotifyReaderRoute({
  required String type,
  required String docId,
}) {
  final normalizedType = normalizeNotificationType(type, '');
  final targetId = docId.trim();
  if (targetId.isEmpty) {
    return NotifyReaderRouteDecision.missing(
      normalizedType: normalizedType,
      messageKey: 'notify_reader.route_missing',
    );
  }

  if (normalizedType == 'user' || normalizedType == 'follow') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.profile,
      normalizedType: normalizedType,
      routeKind: 'social_profile',
      targetId: targetId,
    );
  }

  if (normalizedType == 'posts' ||
      normalizedType == 'like' ||
      normalizedType == 'reshared_posts' ||
      normalizedType == 'shared_as_posts') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.post,
      normalizedType: normalizedType,
      routeKind: 'single_post',
      targetId: targetId,
    );
  }

  if (normalizedType == 'comment') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.postComments,
      normalizedType: normalizedType,
      routeKind: 'single_post_comments',
      targetId: targetId,
    );
  }

  if (normalizedType == 'chat' || normalizedType == 'message') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.chat,
      normalizedType: normalizedType,
      routeKind: 'chat_conversation',
      targetId: targetId,
    );
  }

  if (normalizedType == 'market_offer' ||
      normalizedType == 'market_offer_status') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.market,
      normalizedType: normalizedType,
      routeKind: 'market_detail',
      targetId: targetId,
    );
  }

  return NotifyReaderRouteDecision.missing(
    normalizedType: normalizedType,
    messageKey: 'notify_reader.route_missing',
  );
}

NotifyReaderRouteDecision resolveNotificationTapRoute({
  required String type,
  required String docId,
}) {
  final normalizedType = normalizeNotificationType(type, '');
  final targetId = docId.trim();
  if (targetId.isEmpty) {
    return NotifyReaderRouteDecision.missing(
      normalizedType: normalizedType,
      messageKey: 'notify_reader.route_missing',
    );
  }

  if (normalizedType == 'user' || normalizedType == 'follow') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.profile,
      normalizedType: normalizedType,
      routeKind: 'social_profile',
      targetId: targetId,
    );
  }

  if (normalizedType == 'posts' ||
      normalizedType == 'like' ||
      normalizedType == 'reshared_posts' ||
      normalizedType == 'shared_as_posts') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.post,
      normalizedType: normalizedType,
      routeKind: 'single_post',
      targetId: targetId,
    );
  }

  if (normalizedType == 'comment') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.postComments,
      normalizedType: normalizedType,
      routeKind: 'single_post_comments',
      targetId: targetId,
    );
  }

  if (normalizedType == 'job_application') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.job,
      normalizedType: normalizedType,
      routeKind: 'job_detail',
      targetId: targetId,
    );
  }

  if (isTutoringNotificationType(normalizedType)) {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.tutoring,
      normalizedType: normalizedType,
      routeKind: 'tutoring_detail',
      targetId: targetId,
    );
  }

  if (normalizedType == 'market_offer' ||
      normalizedType == 'market_offer_status') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.market,
      normalizedType: normalizedType,
      routeKind: 'market_detail',
      targetId: targetId,
    );
  }

  if (normalizedType == 'chat' || normalizedType == 'message') {
    return NotifyReaderRouteDecision.open(
      action: NotifyReaderRouteAction.chat,
      normalizedType: normalizedType,
      routeKind: 'chat_conversation',
      targetId: targetId,
    );
  }

  return NotifyReaderRouteDecision.missing(
    normalizedType: normalizedType,
    messageKey: 'notify_reader.route_missing',
  );
}
