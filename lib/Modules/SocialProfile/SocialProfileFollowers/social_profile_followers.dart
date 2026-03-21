import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Buttons/back_buttons.dart';
import '../../../Core/page_line_bar.dart';
import '../../Profile/FollowingFollowers/follower_content.dart';
import 'social_profile_followers_controller.dart';

class SocialProfileFollowers extends StatelessWidget {
  final int selection;
  final String userID;
  final String nickname;
  SocialProfileFollowers(
      {super.key,
      required this.selection,
      required this.nickname,
      required this.userID});
  String get _pageLineBarTag =>
      '${kFollowersSocialProfilePageLineBarTag}_$userID';
  late final controller = Get.put(
      SocialProfileFollowersController(initialPage: selection, userID: userID));

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
              child: Row(
                children: [
                  BackButtons(text: nickname),
                ],
              ),
            ),
            PageLineBar(
              barList: ['profile.followers'.tr, 'profile.following'.tr],
              pageName: _pageLineBarTag,
              initialIndex: selection,
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
