import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

import '../../../Models/recommended_user_model.dart';
import 'recommended_user_content_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';

class RecommendedUserContent extends StatefulWidget {
  final RecommendedUserModel model;

  const RecommendedUserContent({super.key, required this.model});

  @override
  State<RecommendedUserContent> createState() => _RecommendedUserContentState();
}

class _RecommendedUserContentState extends State<RecommendedUserContent> {
  late final RecommendedUserContentController controller;
  late final String _controllerTag;

  RecommendedUserModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'recommended_user_${model.userID}_${identityHashCode(this)}';
    controller = ensureRecommendedUserContentController(
      userID: model.userID,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    final existing = maybeFindRecommendedUserContentController(
      tag: _controllerTag,
    );
    if (identical(existing, controller)) {
      Get.delete<RecommendedUserContentController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 165 || constraints.maxHeight < 200;
        final avatarSize = compact ? 82.0 : 100.0;
        final badgeSize = compact ? 24.0 : 28.0;
        final nameSize = compact ? 13.0 : 15.0;
        final handleSize = compact ? 12.0 : 15.0;
        final buttonHeight = compact ? 28.0 : 30.0;
        final buttonTextSize = compact ? 12.0 : 13.0;

        return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: Colors.grey.withAlpha(50))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: compact ? 6 : 4),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(() => SocialProfile(userID: controller.userID))
                            ?.then((_) {
                          controller.getTakipStatus();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.grey.withAlpha(50))),
                        child: ClipOval(
                          child: SizedBox(
                            width: avatarSize,
                            height: avatarSize,
                            child: model.avatarUrl != ""
                                ? CachedNetworkImage(
                                    imageUrl: model.avatarUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Image.asset(
                                      "assets/images/logotrans.webp",
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    RozetContent(size: badgeSize, userID: model.userID)
                  ],
                ),
                SizedBox(height: compact ? 6 : 4),
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: nameSize,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: handleSize,
                        fontFamily: "MontserratMedium"),
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Obx(() {
                  final isLoading = controller.followLoading.value;
                  final isFollowing = controller.isFollowing.value;
                  final buttonLabel = isFollowing
                      ? 'following.following'.tr
                      : 'following.follow'.tr;
                  final textColor = isFollowing ? Colors.black : Colors.white;
                  final backgroundColor =
                      isFollowing ? Colors.grey.withAlpha(30) : Colors.black;
                  return SizedBox(
                    width: double.infinity,
                    child: ScaleTap(
                      enabled: !isLoading,
                      onPressed: isLoading ? null : controller.follow,
                      child: Container(
                        height: buttonHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    textColor,
                                  ),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    buttonLabel,
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: buttonTextSize,
                                        fontFamily: "MontserratMedium"),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: compact ? 6 : 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
