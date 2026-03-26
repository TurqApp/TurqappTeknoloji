part of 'search_user_content_controller.dart';

Future<void> _goToSearchUserProfile(
  SearchUserContentController controller,
) async {
  if (controller.isNavigated.value) return;
  if (controller.userID.trim().isEmpty) return;
  controller.isNavigated.value = true;
  try {
    final explore = maybeFindExploreController();
    explore?.suspendExplorePreview();
    await Get.to(
      () => SocialProfile(userID: controller.userID),
      preventDuplicates: false,
    );
    explore?.resumeExplorePreview();

    final currentUserID = CurrentUserService.instance.effectiveUserId;
    if (currentUserID.isEmpty) return;
    await controller._userSubcollectionRepository.upsertEntry(
      currentUserID,
      subcollection: 'lastSearches',
      docId: controller.userID,
      data: {
        'userID': controller.userID,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    await CurrentUserService.instance.forceRefresh();
  } catch (_) {
  } finally {
    maybeFindExploreController()?.resumeExplorePreview();
    controller.isNavigated.value = false;
  }
}

Future<void> _removeFromSearchUserLastSearch(
  SearchUserContentController controller,
) async {
  final currentUserID = CurrentUserService.instance.effectiveUserId;
  if (currentUserID.isEmpty) return;
  await controller._userSubcollectionRepository.deleteEntry(
    currentUserID,
    subcollection: 'lastSearches',
    docId: controller.userID,
  );
  await CurrentUserService.instance.forceRefresh();
}
