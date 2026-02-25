import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:turqappv2/Modules/Chat/CreateChat/CreateChatContent/create_chat_content_controller.dart";
import 'package:get/get.dart';
import "package:turqappv2/Modules/Chat/CreateChat/create_chat_controller.dart";

class CreateChatContent extends StatelessWidget {
  final String userID;
  final VoidCallback? onTap;
  CreateChatContent({super.key, required this.userID, this.onTap});

  late final CreateChatContentController controller;
  final cont = Get.find<CreateChatController>();

  @override
  Widget build(BuildContext context) {
    controller =
        Get.put(CreateChatContentController(userID: userID), tag: userID);
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              cont.selected.value = userID;
              onTap?.call();
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: cont.selected.value == userID
                          ? Colors.blueAccent
                          : Colors.transparent,
                      width: 3)),
              child: ClipOval(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: controller.pfImage.value != ""
                      ? CachedNetworkImage(
                          imageUrl: controller.pfImage.value,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 7,
          ),
          Text(
            controller.nickname.value,
            style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: "MontserratMedium"),
          )
        ],
      );
    });
  }
}
