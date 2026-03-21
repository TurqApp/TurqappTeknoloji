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
  static const _commentType = kNotificationPostTypeCommentLower;
  static const _profileTypes = {'follow', 'user'};
  static const _tutoringTypes = {'tutoring_application', 'tutoring_status'};
  static const _chatTypes = {'message', 'chat'};
  static const _marketTypes = {'market_offer', 'market_offer_status'};
  Future<void> openNotification(NotificationModel model) async {
    final normalizedType =
        normalizeNotificationType(model.type, model.postType);
    final targetId = model.postID.trim();

    if (_profileTypes.contains(normalizedType)) {
      if (model.userID.trim().isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.profile_open_failed'.tr);
        return;
      }
      await goToProfile(model.userID);
      return;
    }

    if (normalizedType == "job_application") {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
        return;
      }
      await goToJob(targetId);
      return;
    }

    if (_tutoringTypes.contains(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.tutoring_missing'.tr);
        return;
      }
      await goToTutoring(targetId);
      return;
    }

    if (_chatTypes.contains(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.chat_missing'.tr);
        return;
      }
      await goToChat(targetId);
      return;
    }

    if (_marketTypes.contains(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
        return;
      }
      await goToMarket(targetId);
      return;
    }

    if (normalizedType == _commentType) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
        return;
      }
      await goToPostComments(targetId);
      return;
    }

    if (isNotificationPostType(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
        return;
      }
      await goToPost(targetId);
      return;
    }

    if (model.userID.trim().isNotEmpty) {
      await goToProfile(model.userID);
      return;
    }

    AppSnackbar('common.info'.tr, 'notify_reader.route_missing'.tr);
  }

  /// Post detay sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToPost(String postID) async {
    final lookup = await _lookupRepository.getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
      return toNavbar();
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_removed'.tr);
      return toNavbar();
    }

    final route = (model.floodCount > 1)
        ? Get.to<FloodListing>(() => FloodListing(mainModel: model))
        : Get.to<SinglePost>(
            () => SinglePost(model: model, showComments: false));

    route?.then((_) => toNavbar());
  }

  /// Post yorum sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToPostComments(String postID) async {
    final lookup = await _lookupRepository.getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_missing'.tr);
      return toNavbar();
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('common.info'.tr, 'notify_reader.post_removed'.tr);
      return toNavbar();
    }

    Get.to<SinglePost>(() => SinglePost(model: model, showComments: true))
        ?.then((_) => toNavbar());
  }

  /// Profil sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToProfile(String userID) async {
    Get.to<SocialProfile>(() => SocialProfile(userID: userID))
        ?.then((_) => toNavbar());
  }

  /// Sohbet sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToChat(String chatID) async {
    final lookup = await _lookupRepository.getChatLookup(chatID);
    final otherUser = lookup.otherUser;

    if (otherUser.isEmpty) {
      AppSnackbar('common.info'.tr, 'notify_reader.chat_missing'.tr);
      return toNavbar();
    }

    Get.to<ChatView>(() => ChatView(chatID: chatID, userID: otherUser))
        ?.then((_) => toNavbar());
  }

  Future<void> goToJob(String jobID) async {
    final lookup = await _lookupRepository.getJobLookup(jobID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
      return toNavbar();
    }
    final model = lookup.model!;
    Get.to<JobDetails>(() => JobDetails(model: model))?.then((_) => toNavbar());
  }

  Future<void> goToTutoring(String tutoringID) async {
    final lookup = await _lookupRepository.getTutoringLookup(tutoringID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.tutoring_missing'.tr);
      return toNavbar();
    }
    final model = lookup.model!;
    Get.to<TutoringDetail>(() => TutoringDetail(), arguments: model)
        ?.then((_) => toNavbar());
  }

  Future<void> goToMarket(String itemId) async {
    final lookup = await _lookupRepository.getMarketLookup(itemId);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.info'.tr, 'notify_reader.listing_missing'.tr);
      return toNavbar();
    }
    final model = lookup.model!;
    Get.to(() => MarketDetailView(item: model))?.then((_) => toNavbar());
  }

  /// NavBarView'e geç ve önceki sayfaları stack'ten at
  void toNavbar() {
    Get.offAll<NavBarView>(() => NavBarView());
  }
}
