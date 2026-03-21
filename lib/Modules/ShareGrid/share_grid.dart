import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'share_grid_controller.dart';

class ShareGrid extends StatefulWidget {
  final String postID;
  final String postType;

  const ShareGrid({super.key, required this.postID, required this.postType});

  @override
  State<ShareGrid> createState() => _ShareGridState();
}

class _ShareGridState extends State<ShareGrid> {
  late final String _tag;
  late final ShareGridController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'ShareGrid_${widget.postType}_${widget.postID}_${identityHashCode(this)}';
    if (Get.isRegistered<ShareGridController>(tag: _tag)) {
      controller = Get.find<ShareGridController>(tag: _tag);
      _ownsController = false;
    } else {
      controller = Get.put(
        ShareGridController(postType: widget.postType, postID: widget.postID),
        tag: _tag,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<ShareGridController>(tag: _tag) &&
        identical(Get.find<ShareGridController>(tag: _tag), controller)) {
      Get.delete<ShareGridController>(tag: _tag);
    }
    super.dispose();
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
