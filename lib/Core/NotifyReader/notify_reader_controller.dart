import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

import '../../Modules/Agenda/FloodListing/flood_listing.dart';
import '../../Modules/Agenda/SinglePost/single_post.dart';
import '../../Modules/Chat/chat.dart';
import '../../Modules/SocialProfile/social_profile.dart';
import '../../Models/notification_model.dart';

part 'notify_reader_controller_navigation_part.dart';

class NotifyReaderController extends GetxController {
  static NotifyReaderController ensure({String? tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(NotifyReaderController(), tag: tag);
  }

  static NotifyReaderController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<NotifyReaderController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<NotifyReaderController>(tag: tag);
  }

  final NotifyLookupRepository _lookupRepository =
      NotifyLookupRepository.ensure();
  final RxString lastOpenedNotificationId = ''.obs;
  final RxString lastOpenedNotificationType = ''.obs;
  final RxString lastOpenedRouteKind = ''.obs;
  final RxString lastOpenedTargetId = ''.obs;
  static const _commentType = kNotificationPostTypeCommentLower;
  static const _profileTypes = {'follow', 'user'};
  static const _tutoringTypes = {'tutoring_application', 'tutoring_status'};
  static const _chatTypes = {'message', 'chat'};
  static const _marketTypes = {'market_offer', 'market_offer_status'};

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

    if (_profileTypes.contains(normalizedType)) {
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

    if (_tutoringTypes.contains(normalizedType)) {
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

    if (_chatTypes.contains(normalizedType)) {
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

    if (_marketTypes.contains(normalizedType)) {
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

    if (normalizedType == _commentType) {
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
