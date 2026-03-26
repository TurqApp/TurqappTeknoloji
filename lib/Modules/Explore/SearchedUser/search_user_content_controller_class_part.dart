part of 'search_user_content_controller.dart';

class SearchUserContentController extends GetxController {
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();
  final String userID;
  var isNavigated = false.obs;
  SearchUserContentController({required this.userID});

  Future<void> goToProfile() async {
    if (isNavigated.value) return;
    if (userID.trim().isEmpty) return;
    isNavigated.value = true;
    try {
      final explore = ExploreController.maybeFind();
      explore?.suspendExplorePreview();
      await Get.to(
        () => SocialProfile(userID: userID),
        preventDuplicates: false,
      );
      explore?.resumeExplorePreview();

      final currentUserID = CurrentUserService.instance.effectiveUserId;
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
      ExploreController.maybeFind()?.resumeExplorePreview();
      isNavigated.value = false;
    }
  }

  Future<void> removeFromLastSearch() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty) return;
    await _userSubcollectionRepository.deleteEntry(
      currentUserID,
      subcollection: 'lastSearches',
      docId: userID,
    );
    await CurrentUserService.instance.forceRefresh();
  }
}
