import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
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

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'story_content_profile_${widget.userID}_${identityHashCode(this)}';
    final existingController =
        maybeFindStoryContentProfileController(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ensureStoryContentProfileController(
        tag: _controllerTag,
      );
      _ownsController = true;
    }
    controller.getUserData(widget.userID);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindStoryContentProfileController(tag: _controllerTag),
          controller,
        )) {
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
                const ProfileNavigationService()
                    .openSocialProfile(widget.userID);
              }
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.withAlpha(1)),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 15, right: 15, top: 4, bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CachedUserAvatar(
                        userId: widget.userID,
                        imageUrl: controller.avatarUrl.value,
                        radius: 20,
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
