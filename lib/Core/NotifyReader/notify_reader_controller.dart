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

class NotifyReaderController extends GetxController {
  final NotifyLookupRepository _lookupRepository =
      NotifyLookupRepository.ensure();

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
}
