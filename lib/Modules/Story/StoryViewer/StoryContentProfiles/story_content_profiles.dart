import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'story_content_profile_controller.dart';

class StoryContentProfiles extends StatelessWidget {
  final String userID;

  StoryContentProfiles({super.key, required this.userID});

  String get _currentUserId => CurrentUserService.instance.userId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoryContentProfileController(), tag: userID);
    controller.getUserData(userID);
    return Obx(() {
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              if (userID != _currentUserId) {
                Get.to(() => SocialProfile(userID: userID));
              }
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.withAlpha(1)),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 15, right: 15, top: 4, bottom: 4),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: controller.avatarUrl.value != ""
                            ? CachedNetworkImage(
                                imageUrl: controller.avatarUrl.value,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(
                      width: 7,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                controller.nickname.value,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium"),
                              ),
                              RozetContent(size: 13, userID: userID)
                            ],
                          ),
                          Text(
                            controller.fullName.value,
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: "MontserratMedium"),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 3,
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.blueAccent,
                      size: 15,
                    )
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: SizedBox(
                height: 2,
                child: Divider(
                  color: Colors.grey.withAlpha(20),
                )),
          )
        ],
      );
    });
  }
}
