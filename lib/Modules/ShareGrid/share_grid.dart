import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'share_grid_controller.dart';

class ShareGrid extends StatelessWidget {
  final String postID;
  final String postType;

  ShareGrid({super.key, required this.postID, required this.postType});
  late final ShareGridController controller;
  @override
  Widget build(BuildContext context) {
    controller =
        Get.put(ShareGridController(postType: postType, postID: postID));
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
                  hintText: "Ara",
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
                          return GestureDetector(
                            onTap: () {
                              if (controller.selectedUser.value != null) {
                                controller.selectedUser.value = null;
                              } else {
                                controller.selectedUser.value = model;
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          controller.selectedUser.value == model
                                              ? Colors.green
                                              : Colors.transparent,
                                      width: 4)),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 55,
                                  height: 55,
                                  child: CachedNetworkImage(
                                    imageUrl: model.pfImage,
                                    fit: BoxFit.cover,
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
        Obx(() {
          return controller.selectedUser.value != null
              ? Padding(
                  padding: const EdgeInsets.all(15),
                  child: TurqAppButton(
                    borderRadiusAll: 50,
                    onTap: () {
                      controller.sendIt();
                    },
                    text: "Gönder",
                  ),
                )
              : SizedBox();
        })
      ],
    );
  }
}
