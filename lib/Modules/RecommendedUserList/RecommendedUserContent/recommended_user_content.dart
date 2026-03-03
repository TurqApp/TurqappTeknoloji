import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import '../../../Models/recommended_user_model.dart';
import 'recommended_user_content_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';

class RecommendedUserContent extends StatelessWidget {
  final RecommendedUserModel model;

  RecommendedUserContent({super.key, required this.model});
  late final RecommendedUserContentController controller;

  @override
  Widget build(BuildContext context) {
    controller = Get.put(RecommendedUserContentController(userID: model.userID),
        tag: model.userID);
    controller.getTakipStatus();
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: Colors.grey.withAlpha(50))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            4.ph,
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(() => SocialProfile(userID: controller.userID))
                        ?.then((_) {
                      // Profilden dönüşte takip durumunu yenile
                      controller.getTakipStatus();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withAlpha(50))),
                    child: ClipOval(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: model.pfImage != ""
                            ? CachedNetworkImage(
                                imageUrl: model.pfImage,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child:
                                    Image.asset("assets/images/logotrans.webp"),
                              ),
                      ),
                    ),
                  ),
                ),
                RozetContent(size: 28, userID: model.userID)
              ],
            ),
            4.ph,
            GestureDetector(
              onTap: () {
                Get.to(() => SocialProfile(userID: controller.userID))
                    ?.then((_) {
                  controller.getTakipStatus();
                });
              },
              child: Text(
                "${model.firstName.trim()} ${model.lastName.trim()}",
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
                maxLines: 1,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold"),
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.to(() => SocialProfile(userID: controller.userID))
                    ?.then((_) {
                  controller.getTakipStatus();
                });
              },
              child: Text(
                "@${model.nickname}",
                overflow: TextOverflow.fade,
                maxLines: 1,
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            ),
            // Text(
            //   model.bio,
            //   textAlign: TextAlign.center,
            //   overflow: TextOverflow.clip,
            //   maxLines: 2,
            //   style: TextStyle(
            //       color: Colors.black.withAlpha(120),
            //       fontSize: 15,
            //       fontFamily: "Montserrat"),
            // ),
            6.ph,
            Obx(() {
              final isLoading = controller.followLoading.value;
              return Stack(
                children: [
                  if (controller.isFollowing.value)
                    ScaleTap(
                      enabled: !isLoading,
                      onPressed: isLoading ? null : controller.follow,
                      child: Container(
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(30),
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Text(
                                "Takibi Bırak",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontFamily: "MontserratMedium"),
                              ),
                      ),
                    )
                  else
                    ScaleTap(
                      enabled: !isLoading,
                      onPressed: isLoading ? null : controller.follow,
                      child: Container(
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                "Takip Et",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: "MontserratMedium"),
                              ),
                      ),
                    )
                ],
              );
            }),
            4.ph,
          ],
        ),
      ),
    );
  }
}
