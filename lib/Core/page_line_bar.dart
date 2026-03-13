import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings_controller.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads_controller.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/liked_posts_controller.dart';
import 'package:turqappv2/Modules/Profile/Policies/policies_controller.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts_controller.dart';
import 'package:turqappv2/Modules/SpotifySelector/spotify_selector_controller.dart';
import 'package:turqappv2/Themes/app_fonts.dart';

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

  bool get _hasAttachedPageController {
    final pageController = widget.pageController;
    return pageController != null && pageController.hasClients;
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PageLineBarController>(tag: widget.pageName)) {
      controller = Get.find<PageLineBarController>(tag: widget.pageName);
    } else {
      controller = Get.put(
        PageLineBarController(pageName: widget.pageName),
        tag: widget.pageName,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didInit) return;
      _didInit = true;
      if (widget.initialIndex != controller.selection.value) {
        controller.selection.value = widget.initialIndex;
        if (_hasAttachedPageController) {
          widget.pageController!.jumpToPage(widget.initialIndex);
        } else {
          controller.setSelectionTo(widget.initialIndex);
        }
      }
    });
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
                if (_hasAttachedPageController) {
                  widget.pageController!.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  controller.setSelectionTo(index);
                }
              },
              child: Container(
                height: 40,
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Center(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: widget.fontSize,
                          fontFamily: controller.selection.value == index
                              ? AppFontFamilies.mbold
                              : AppFontFamilies.mmedium,
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

  void setSelectionTo(int index) {
    selection.value = index;
    switch (pageName) {
      case 'Explore':
        Get.find<ExploreController>().goToPage(index);
        break;
      case 'SavedPosts':
        Get.find<SavedPostsController>().goToPage(index);
        break;
      case 'LikedPosts':
        Get.find<LikedPostControllers>().goToPage(index);
        break;
      case 'Policies':
        Get.find<PoliciesController>().goToPage(index);
        break;
      case 'Notifications':
        Get.find<InAppNotificationsController>().goToPage(index);
        break;
      case 'Spotify':
        Get.find<SpotifySelectorController>().goToPage(index);
        break;
      case 'MyTutorings':
        Get.find<MyTutoringsController>().goToPage(index);
        break;
      case 'MyJobAds':
        Get.find<MyJobAdsController>().goToPage(index);
        break;
      case 'Followers':
        Get.find<FollowingFollowersController>().goToPage(index);
        break;
      default:
        break;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
