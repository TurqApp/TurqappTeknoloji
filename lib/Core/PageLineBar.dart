import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/MyTutoringsController.dart';
import 'package:turqappv2/Modules/Explore/ExploreController.dart';
import 'package:turqappv2/Modules/InAppNotifications/InAppNotificationsController.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/MyJobAdsController.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/FollowingFollowersController.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/LikedPostsController.dart';
import 'package:turqappv2/Modules/Profile/Policies/PoliciesController.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/SavedPostsController.dart';
import 'package:turqappv2/Modules/SpotifySelector/SpotifySelectorController.dart';
import 'package:turqappv2/Themes/AppFonts.dart';

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
        if (widget.pageController != null) {
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
                if (widget.pageController != null) {
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
