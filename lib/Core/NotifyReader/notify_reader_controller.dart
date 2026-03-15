import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_view.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';

import '../../Modules/Agenda/FloodListing/flood_listing.dart';
import '../../Modules/Agenda/SinglePost/single_post.dart';
import '../../Modules/Chat/chat.dart';
import '../../Modules/SocialProfile/social_profile.dart';
import '../../Models/notification_model.dart';

class NotifyReaderController extends GetxController {
  final NotifyLookupRepository _lookupRepository =
      NotifyLookupRepository.ensure();

  Future<void> openNotification(NotificationModel model) async {
    final normalizedType = _normalizedType(model.type, model.postType);
    final targetId = model.postID.trim();

    if (normalizedType == "follow" || normalizedType == "user") {
      if (model.userID.trim().isEmpty) {
        AppSnackbar('Bilgi', 'Profil açılamadı.');
        return;
      }
      await goToProfile(model.userID);
      return;
    }

    if (normalizedType == "job_application") {
      if (targetId.isEmpty) {
        AppSnackbar('Bilgi', 'İlan bulunamadı veya kaldırılmış.');
        return;
      }
      await goToJob(targetId);
      return;
    }

    if (normalizedType == "tutoring_application" ||
        normalizedType == "tutoring_status") {
      if (targetId.isEmpty) {
        AppSnackbar('Bilgi', 'Özel ders ilanı bulunamadı veya kaldırılmış.');
        return;
      }
      await goToTutoring(targetId);
      return;
    }

    if (normalizedType == "message" || normalizedType == "chat") {
      if (targetId.isEmpty) {
        AppSnackbar('Bilgi', 'Sohbet bulunamadı.');
        return;
      }
      await goToChat(targetId);
      return;
    }

    if (normalizedType == "comment") {
      if (targetId.isEmpty) {
        AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
        return;
      }
      await goToPostComments(targetId);
      return;
    }

    if (_isPostType(normalizedType)) {
      if (targetId.isEmpty) {
        AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
        return;
      }
      await goToPost(targetId);
      return;
    }

    if (model.userID.trim().isNotEmpty) {
      await goToProfile(model.userID);
      return;
    }

    AppSnackbar('Bilgi', 'Bu bildirim için yönlendirme bulunamadı.');
  }

  /// Post detay sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToPost(String postID) async {
    final lookup = await _lookupRepository.getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
      return toNavbar();
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('Bilgi', 'Gönderi kaldırılmış.');
      return toNavbar();
    }

    final route = (model.flood == false && model.floodCount > 1)
        ? Get.to<FloodListing>(() => FloodListing(mainModel: model))
        : Get.to<SinglePost>(
            () => SinglePost(model: model, showComments: false));

    route?.then((_) => toNavbar());
  }

  /// Post yorum sayfasına git, geri dönülürse NavBarView'e atla
  Future<void> goToPostComments(String postID) async {
    final lookup = await _lookupRepository.getPostLookup(postID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı veya silinmiş.');
      return toNavbar();
    }
    final model = lookup.model!;
    if (model.deletedPost == true) {
      AppSnackbar('Bilgi', 'Gönderi kaldırılmış.');
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
      AppSnackbar('Bilgi', 'Sohbet bulunamadı.');
      return toNavbar();
    }

    Get.to<ChatView>(() => ChatView(chatID: chatID, userID: otherUser))
        ?.then((_) => toNavbar());
  }

  Future<void> goToJob(String jobID) async {
    final lookup = await _lookupRepository.getJobLookup(jobID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'İlan bulunamadı veya kaldırılmış.');
      return toNavbar();
    }
    final model = lookup.model!;
    Get.to<JobDetails>(() => JobDetails(model: model))?.then((_) => toNavbar());
  }

  Future<void> goToTutoring(String tutoringID) async {
    final lookup = await _lookupRepository.getTutoringLookup(tutoringID);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Bilgi', 'Özel ders ilanı bulunamadı veya kaldırılmış.');
      return toNavbar();
    }
    final model = lookup.model!;
    Get.to<TutoringDetail>(() => TutoringDetail(), arguments: model)
        ?.then((_) => toNavbar());
  }

  /// NavBarView'e geç ve önceki sayfaları stack'ten at
  void toNavbar() {
    Get.offAll<NavBarView>(() => NavBarView());
  }

  String _normalizedType(String type, String postType) {
    final normalized = type.trim().toLowerCase();
    if (normalized.isNotEmpty) return normalized;
    return postType.trim().toLowerCase();
  }

  bool _isPostType(String normalizedType) {
    return normalizedType == "posts" ||
        normalizedType == "like" ||
        normalizedType == "reshared_posts" ||
        normalizedType == "shared_as_posts" ||
        normalizedType == "reshare" ||
        normalizedType == "post";
  }
}
