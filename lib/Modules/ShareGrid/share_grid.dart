import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'share_grid_controller.dart';

class ShareGrid extends StatelessWidget {
  final String postID;
  final String postType;
  final String _tag;

  ShareGrid({super.key, required this.postID, required this.postType})
      : _tag = 'ShareGrid_${postType}_$postID';

  ShareGridController get controller {
    if (Get.isRegistered<ShareGridController>(tag: _tag)) {
      return Get.find<ShareGridController>(tag: _tag);
    }
    return Get.put(
      ShareGridController(postType: postType, postID: postID),
      tag: _tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
          child: Container(
            height: 45,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: controller.search,
                decoration: InputDecoration(
                  hintText: 'common.search'.tr,
                  icon: Icon(
                    CupertinoIcons.search,
                    color: Colors.black,
                  ),
                  hintStyle: TextStyle(
                      color: Colors.grey, fontFamily: "MontserratMedium"),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  controller.searchUser(value);
                },
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: 1),
                  itemCount: controller.followings.length,
                  itemBuilder: (context, index) {
                    final model = controller.followings[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(() {
                          final isSelected =
                              controller.selectedUser.value?.userID ==
                                  model.userID;
                          return GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                controller.selectedUser.value = null;
                              } else {
                                controller.selectedUser.value = model;
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.transparent,
                                      width: 4)),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 55,
                                  height: 55,
                                  child: CachedNetworkImage(
                                    imageUrl: model.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        CupertinoIcons.person_fill,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        SizedBox(
                          height: 7,
                        ),
                        Text(
                          model.nickname,
                          style: TextStyle(
                              overflow: TextOverflow.ellipsis,
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: "MontserratMedium"),
                        )
                      ],
                    );
                  }),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Obx(() {
            final hasSelection = controller.selectedUser.value != null;
            return TurqAppButton(
              borderRadiusAll: 50,
              bgColor: hasSelection ? Colors.black : Colors.grey.shade400,
              onTap: () {
                controller.sendIt();
              },
              text: 'common.send'.tr,
            );
          }),
        )
      ],
    );
  }
}
