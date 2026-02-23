import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

import 'post_like_content_controller.dart';

class PostLikeContent extends StatelessWidget {
  final String userID;
  PostLikeContent({super.key, required this.userID});
  late final PostLikeContentController controller;
  @override
  Widget build(BuildContext context) {
    controller = Get.put(PostLikeContentController(), tag: userID);
    controller.getUserData(userID);
    return Column(
      children: [
        Obx(() {
          return GestureDetector(
            onTap: () {
              if (userID != FirebaseAuth.instance.currentUser!.uid) {
                Get.to(() => SocialProfile(userID: userID));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Container(
                color: Colors.grey.withAlpha(1),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: controller.pfImage.value != ""
                            ? CachedNetworkImage(
                                imageUrl: controller.pfImage.value,
                              )
                            : CupertinoActivityIndicator(
                                color: Colors.grey,
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
                                controller.fullName.value,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              ),
                              RozetContent(size: 15, userID: userID)
                            ],
                          ),
                          Text(
                            controller.nickname.value,
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontFamily: "MontserratMedium"),
                          )
                        ],
                      ),
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
          );
        }),
        SizedBox(
          height: 2,
          child: Divider(
            color: Colors.grey.withAlpha(50),
          ),
        )
      ],
    );
  }
}
