
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Models/ChatListingModel.dart';
import 'package:turqappv2/Modules/Chat/Chat.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';

import 'ChatListingContentController.dart';

class ChatListingContent extends StatelessWidget {
  final ChatListingModel model;
  ChatListingContent({super.key, required this.model});
  late final ChatListingContentController controller;
  @override
  Widget build(BuildContext context) {
    controller = Get.put(ChatListingContentController(userID: model.userID, model: model), tag: model.userID);
    return Column(
      children: [
        Obx((){
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: (){
                    Get.to(() => SocialProfile(userID: model.userID));
                  },
                  child: ClipOval(
                    child: SizedBox(
                      width: 45,
                      height: 45,
                      child: model.pfImage != "" ? CachedNetworkImage(
                        imageUrl: model.pfImage,
                        fit: BoxFit.cover,
                      ) : Center(child: CupertinoActivityIndicator(color: Colors.grey,),),
                    ),
                  ),
                ),

                SizedBox(width: 7,),

                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      Get.to(() => ChatView(chatID: model.chatID, userID: model.userID));
                    },
                    child: Container(
                      height: 50,
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    model.nickname,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratBold"
                                    ),
                                  ),

                                  RozetContent(size: 15, userID: controller.userID)
                                ],
                              ),

                              Text(
                                timeAgoMetin(num.parse(model.timeStamp)),
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontFamily: "MontserratMedium"
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              if (controller.lastMessage.isNotEmpty)
                              Expanded(
                                child: Text(
                                  controller.lastMessage.last.metin != "" ? controller.lastMessage.last.metin : controller.lastMessage.last.postID != "" ? "Bir gönderi paylaşıldı" : controller.lastMessage.last.imgs.isNotEmpty ? "Fotoğraf paylaşıldı" : "",
                                  maxLines: 2,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontFamily: "Montserrat"
                                  ),
                                ),
                              ),

                              if (controller.notReadCounter.value >= 1)
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle
                                  ),
                                  child: Text(
                                    controller.notReadCounter.value.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: "MontserratBold"
                                    ),
                                  ),
                                )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        }),

        SizedBox(
          height: 1,
          child: Divider(color: Colors.grey.withAlpha(50),),
        )
      ],
    );
  }
}
