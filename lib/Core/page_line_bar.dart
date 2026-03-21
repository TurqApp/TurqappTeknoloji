import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/liked_posts_controller.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfileFollowers/social_profile_followers_controller.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

const String kExplorePageLineBarTag = 'explore_page_line_bar';
const String kSavedPostsPageLineBarTag = 'saved_posts_page_line_bar';
const String kLikedPostsPageLineBarTag = 'liked_posts_page_line_bar';
const String kNotificationsPageLineBarTag = 'notifications_page_line_bar';
const String kDeletedStoriesPageLineBarTag = 'deleted_stories_page_line_bar';
const String kFollowersPageLineBarTag = 'followers_page_line_bar';
const String kFollowersSocialProfilePageLineBarTag =
    'followers_social_profile_page_line_bar';

PageLineBarController? maybeFindPageLineBarController(String tag) {
  if (!Get.isRegistered<PageLineBarController>(tag: tag)) {
    return null;
  }
  return Get.find<PageLineBarController>(tag: tag);
}

void syncPageLineBarSelection(String tag, int index) {
  maybeFindPageLineBarController(tag)?.selection.value = index;
}

class PageLineBar extends StatefulWidget {
  final List<String> barList;
  final String pageName;
  final int initialIndex;
  final double fontSize;
  final PageController? pageController; // optional: direct control of PageView

  const PageLineBar({
    super.key,
    required this.barList,
    required this.pageName,
    this.initialIndex = 0,
    this.fontSize = 15,
    this.pageController,
  });

  @override
  State<PageLineBar> createState() => _PageLineBarState();
}

class _PageLineBarState extends State<PageLineBar> {
  late PageLineBarController controller;
  bool _didInit = false;
  bool _ownsController = false;

  void _syncExternalPageController(
    int index, {
    required bool animate,
  }) {
    final pageController = widget.pageController;
    if (pageController == null) {
      controller.setSelectionTo(index);
      return;
    }

    void syncAfterFrame() {
      if (!mounted) return;
      if (!pageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => syncAfterFrame());
        return;
      }
      if (animate) {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        pageController.jumpToPage(index);
      }
    }

    syncAfterFrame();
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PageLineBarController>(tag: widget.pageName)) {
      controller = Get.find<PageLineBarController>(tag: widget.pageName);
      _ownsController = false;
    } else {
      controller = Get.put(
        PageLineBarController(pageName: widget.pageName),
        tag: widget.pageName,
      );
      _ownsController = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didInit) return;
      _didInit = true;
      if (widget.initialIndex != controller.selection.value) {
        controller.selection.value = widget.initialIndex;
        _syncExternalPageController(
          widget.initialIndex,
          animate: false,
        );
      }
    });
  }

  @override
  void dispose() {
    if (_ownsController &&
        maybeFindPageLineBarController(widget.pageName) == controller) {
      Get.delete<PageLineBarController>(
        tag: widget.pageName,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: List.generate(widget.barList.length, (index) {
          final item = widget.barList[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                controller.selection.value = index;
                _syncExternalPageController(index, animate: true);
              },
              child: Container(
                height: 40,
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: widget.fontSize,
                              fontFamily: controller.selection.value == index
                                  ? AppFontFamilies.mbold
                                  : AppFontFamilies.mmedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (controller.selection.value == index)
                      Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PageLineBarController extends GetxController {
  final String pageName;
  PageLineBarController({required this.pageName});

  var selection = 0.obs;
  final PageController pageController = PageController();

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
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    }
    return null;
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
      return;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
