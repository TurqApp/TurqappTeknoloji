part of 'notify_reader_controller.dart';

extension _NotifyReaderControllerRuntimeX on NotifyReaderController {
  void _recordOpen(
    NotificationModel model, {
    required String routeKind,
    required String targetId,
    required String normalizedType,
  }) {
    lastOpenedNotificationId.value = model.docID;
    lastOpenedNotificationType.value = normalizedType;
    lastOpenedRouteKind.value = routeKind;
    lastOpenedTargetId.value = targetId;
  }

  Future<void> openNotification(
    NotificationModel model, {
    bool returnToNavbarOnClose = true,
  }) async {
    final decision = resolveNotifyReaderRoute(
      type: model.type,
      postType: model.postType,
      postId: model.postID,
      userId: model.userID,
    );

    if (!decision.canOpen) {
      AppSnackbar('common.info'.tr, decision.messageKey.tr);
      return;
    }

    _recordOpen(
      model,
      routeKind: decision.routeKind,
      targetId: decision.targetId,
      normalizedType: decision.normalizedType,
    );

    switch (decision.action) {
      case NotifyReaderRouteAction.profile:
        await goToProfile(
          decision.targetId,
          returnToNavbarOnClose: returnToNavbarOnClose,
        );
      case NotifyReaderRouteAction.job:
        await goToJob(
          decision.targetId,
          returnToNavbarOnClose: returnToNavbarOnClose,
        );
      case NotifyReaderRouteAction.tutoring:
        await goToTutoring(
          decision.targetId,
          returnToNavbarOnClose: returnToNavbarOnClose,
        );
      case NotifyReaderRouteAction.chat:
        await goToChat(
          decision.targetId,
          returnToNavbarOnClose: returnToNavbarOnClose,
        );
      case NotifyReaderRouteAction.market:
        await goToMarket(
          decision.targetId,
          returnToNavbarOnClose: returnToNavbarOnClose,
        );
      case NotifyReaderRouteAction.postComments:
        await goToPostComments(
          decision.targetId,
          returnToNavbarOnClose: returnToNavbarOnClose,
        );
      case NotifyReaderRouteAction.post:
        await goToPost(
          decision.targetId,
          returnToNavbarOnClose: returnToNavbarOnClose,
        );
      case NotifyReaderRouteAction.missing:
        break;
    }
  }
}
