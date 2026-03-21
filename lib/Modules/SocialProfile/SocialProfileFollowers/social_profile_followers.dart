import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Buttons/back_buttons.dart';
import '../../../Core/page_line_bar.dart';
import '../../Profile/FollowingFollowers/follower_content.dart';
import 'social_profile_followers_controller.dart';

class SocialProfileFollowers extends StatefulWidget {
  final int selection;
  final String userID;
  final String nickname;
  const SocialProfileFollowers(
      {super.key,
      required this.selection,
      required this.nickname,
      required this.userID});

  @override
  State<SocialProfileFollowers> createState() => _SocialProfileFollowersState();
}

class _SocialProfileFollowersState extends State<SocialProfileFollowers> {
  late final SocialProfileFollowersController controller;
  bool _ownsController = false;

  String get _pageLineBarTag =>
      '${kFollowersSocialProfilePageLineBarTag}_${widget.userID}';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SocialProfileFollowersController>(
        tag: widget.userID)) {
      controller =
          Get.find<SocialProfileFollowersController>(tag: widget.userID);
    } else {
      controller = Get.put(
        SocialProfileFollowersController(
          initialPage: widget.selection,
          userID: widget.userID,
        ),
        tag: widget.userID,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<SocialProfileFollowersController>(
            tag: widget.userID) &&
        identical(
          Get.find<SocialProfileFollowersController>(tag: widget.userID),
          controller,
        )) {
      Get.delete<SocialProfileFollowersController>(
        tag: widget.userID,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initial index is passed to PageLineBar; PageView already has initialPage.

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: BackButtons(text: widget.nickname),
            ),
            PageLineBar(
              barList: ['profile.followers'.tr, 'profile.following'.tr],
              pageName: _pageLineBarTag,
              initialIndex: widget.selection,
              pageController: controller.pageController,
            ),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (v) {
                  syncPageLineBarSelection(
                    _pageLineBarTag,
                    v,
                  );
                },
                children: [
                  Obx(() {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 300) {
                          controller.getFollowers();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: controller.takipciler.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 15 : 0),
                            child: FollowerContent(
                              userID: controller.takipciler[index],
                              key: ValueKey(controller.takipciler[index]),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  Obx(() {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 300) {
                          controller.getFollowing();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: controller.takipEdilenler.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 15 : 0),
                            child: FollowerContent(
                              userID: controller.takipEdilenler[index],
                              key: ValueKey(controller.takipEdilenler[index]),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
