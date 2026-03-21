import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'story_content_profile_controller.dart';

class StoryContentProfiles extends StatefulWidget {
  final String userID;

  const StoryContentProfiles({super.key, required this.userID});

  @override
  State<StoryContentProfiles> createState() => _StoryContentProfilesState();
}

class _StoryContentProfilesState extends State<StoryContentProfiles> {
  late final StoryContentProfileController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  String get _currentUserId {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'story_content_profile_${widget.userID}_${identityHashCode(this)}';
    if (Get.isRegistered<StoryContentProfileController>(tag: _controllerTag)) {
      controller =
          Get.find<StoryContentProfileController>(tag: _controllerTag);
      _ownsController = false;
    } else {
      controller = Get.put(
        StoryContentProfileController(),
        tag: _controllerTag,
      );
      _ownsController = true;
    }
    controller.getUserData(widget.userID);
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<StoryContentProfileController>(tag: _controllerTag)) {
      Get.delete<StoryContentProfileController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.userID != _currentUserId) {
                Get.to(() => SocialProfile(userID: widget.userID));
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
                              RozetContent(size: 13, userID: widget.userID)
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
