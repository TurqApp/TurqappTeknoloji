import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SearchUserContentController extends GetxController {
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();
  final String userID;
  var isNavigated = false.obs;
  SearchUserContentController({required this.userID});
  Future<void> goToProfile() async {
    if (isNavigated.value) return; // tekrar giriş engeli
    if (userID.trim().isEmpty) return;
    isNavigated.value = true;
    try {
      final explore = Get.isRegistered<ExploreController>()
          ? Get.find<ExploreController>()
          : null;
      explore?.suspendExplorePreview();
      // Sayfa kapandığında isNavigated sıfırlanır (finally)
      await Get.to(
        () => SocialProfile(userID: userID),
        preventDuplicates: false,
      );
      explore?.resumeExplorePreview();

      final currentUserID = CurrentUserService.instance.userId;
      if (currentUserID.isEmpty) return;
      await _userSubcollectionRepository.upsertEntry(
        currentUserID,
        subcollection: 'lastSearches',
        docId: userID,
        data: {
          'userID': userID,
          'updatedDate': DateTime.now().millisecondsSinceEpoch,
          'timeStamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await CurrentUserService.instance.forceRefresh();
    } catch (_) {
    } finally {
      if (Get.isRegistered<ExploreController>()) {
        Get.find<ExploreController>().resumeExplorePreview();
      }
      isNavigated.value = false;
    }
  }

  Future<void> removeFromLastSearch() async {
    final currentUserID = CurrentUserService.instance.userId;
    if (currentUserID.isEmpty) return;
    await _userSubcollectionRepository.deleteEntry(
      currentUserID,
      subcollection: 'lastSearches',
      docId: userID,
    );
    await CurrentUserService.instance.forceRefresh();
  }
}
