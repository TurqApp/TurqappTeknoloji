part of 'page_line_bar.dart';

PageLineBarController ensurePageLineBarController({
  required String pageName,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindPageLineBarController(tag);
  if (existing != null) return existing;
  return Get.put(
    PageLineBarController(pageName: pageName),
    tag: tag,
    permanent: permanent,
  );
}

extension PageLineBarControllerSupportPart on PageLineBarController {
  bool _matchesTag(String baseTag) {
    return pageName == baseTag || pageName.startsWith('${baseTag}_');
  }

  String? _scopedSuffix(String baseTag) {
    final prefix = '${baseTag}_';
    if (!pageName.startsWith(prefix)) {
      return null;
    }
    return pageName.substring(prefix.length);
  }

  T? _maybeFindController<T>({String? tag}) {
    if (tag != null && Get.isRegistered<T>(tag: tag)) {
      return Get.find<T>(tag: tag);
    }
    final isRegistered = Get.isRegistered<T>();
    if (!isRegistered) return null;
    return Get.find<T>();
  }

  void setSelectionTo(int index) {
    selection.value = index;
    if (_matchesTag(kExplorePageLineBarTag)) {
      _maybeFindController<ExploreController>()?.goToPage(index);
      return;
    }
    if (_matchesTag(kSavedPostsPageLineBarTag)) {
      final controller = _maybeFindController<SavedPostsController>();
      controller?.pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      return;
    }
    if (_matchesTag(kLikedPostsPageLineBarTag)) {
      _maybeFindController<LikedPostControllers>()?.goToPage(index);
      return;
    }
    if (_matchesTag(kNotificationsPageLineBarTag)) {
      _maybeFindController<InAppNotificationsController>()?.goToPage(index);
      return;
    }
    if (_matchesTag(kFollowersPageLineBarTag)) {
      _maybeFindController<FollowingFollowersController>(
        tag: _scopedSuffix(kFollowersPageLineBarTag),
      )?.goToPage(index);
      return;
    }
    if (_matchesTag(kFollowersSocialProfilePageLineBarTag)) {
      _maybeFindController<SocialProfileFollowersController>(
        tag: _scopedSuffix(kFollowersSocialProfilePageLineBarTag),
      )?.goToPage(index);
    }
  }
}
