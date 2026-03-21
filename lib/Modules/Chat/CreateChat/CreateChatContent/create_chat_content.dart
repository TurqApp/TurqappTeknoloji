import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:turqappv2/Modules/Chat/CreateChat/CreateChatContent/create_chat_content_controller.dart";
import 'package:get/get.dart';
import "package:turqappv2/Modules/Chat/CreateChat/create_chat_controller.dart";

class CreateChatContent extends StatefulWidget {
  final String userID;
  final VoidCallback? onTap;
  const CreateChatContent({super.key, required this.userID, this.onTap});

  @override
  State<CreateChatContent> createState() => _CreateChatContentState();
}

class _CreateChatContentState extends State<CreateChatContent> {
  late final CreateChatContentController controller;
  late final String _controllerTag;
  late final CreateChatController cont;

  @override
  void initState() {
    super.initState();
    cont = CreateChatController.ensure();
    _controllerTag =
        'create_chat_content_${widget.userID}_${identityHashCode(this)}';
    controller = CreateChatContentController.ensure(
      userID: widget.userID,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    final existing = CreateChatContentController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<CreateChatContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              cont.selected.value = widget.userID;
              widget.onTap?.call();
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cont.selected.value == widget.userID
                      ? Colors.blueAccent
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 72,
                  height: 72,
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
              fontFamily: "MontserratMedium",
            ),
          )
        ],
      );
    });
  }
}
