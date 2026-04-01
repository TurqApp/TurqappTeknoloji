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
    final normalizedType =
        normalizeNotificationType(model.type, model.postType);
    final targetId = model.postID.trim();

    if (_notifyReaderProfileTypes.contains(normalizedType)) {
      if (model.userID.trim().isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.profile_open_failed'.tr);
        return;
      }
      _recordOpen(
        model,
        routeKind: 'social_profile',
        targetId: model.userID.trim(),
        normalizedType: normalizedType,
      );
      await goToProfile(
        model.userID,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    if (normalizedType == "job_application") {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
        return;
      }
      _recordOpen(
        model,
        routeKind: 'job_detail',
        targetId: targetId,
        normalizedType: normalizedType,
      );
      await goToJob(
        targetId,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    if (_notifyReaderTutoringTypes.contains(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.tutoring_missing'.tr);
        return;
      }
      _recordOpen(
        model,
        routeKind: 'tutoring_detail',
        targetId: targetId,
        normalizedType: normalizedType,
      );
      await goToTutoring(
        targetId,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    if (_notifyReaderChatTypes.contains(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.chat_missing'.tr);
        return;
      }
      _recordOpen(
        model,
        routeKind: 'chat_conversation',
        targetId: targetId,
        normalizedType: normalizedType,
      );
      await goToChat(
        targetId,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    if (_notifyReaderMarketTypes.contains(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
        return;
      }
      _recordOpen(
        model,
        routeKind: 'market_detail',
        targetId: targetId,
        normalizedType: normalizedType,
      );
      await goToMarket(
        targetId,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    if (normalizedType == _notifyReaderCommentType) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
        return;
      }
      _recordOpen(
        model,
        routeKind: 'single_post_comments',
        targetId: targetId,
        normalizedType: normalizedType,
      );
      await goToPostComments(
        targetId,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    if (isNotificationPostType(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
        return;
      }
      _recordOpen(
        model,
        routeKind: 'single_post',
        targetId: targetId,
        normalizedType: normalizedType,
      );
      await goToPost(
        targetId,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    if (model.userID.trim().isNotEmpty) {
      _recordOpen(
        model,
        routeKind: 'social_profile',
        targetId: model.userID.trim(),
        normalizedType: normalizedType,
      );
      await goToProfile(
        model.userID,
        returnToNavbarOnClose: returnToNavbarOnClose,
      );
      return;
    }

    AppSnackbar('common.info'.tr, 'notify_reader.route_missing'.tr);
  }
}
