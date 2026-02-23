import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/Chat/CreateChat/CreateChatContent/create_chat_content.dart';
import 'package:turqappv2/Modules/Chat/CreateChat/create_chat_controller.dart';

import '../../Profile/FollowingFollowers/following_followers_controller.dart';

class CreateChat extends StatelessWidget {
  CreateChat({super.key});
  final followersFollowing = Get.put(
    FollowingFollowersController(
        initialPage: 0, userId: FirebaseAuth.instance.currentUser!.uid),
  );
  final controllerr = Get.put(CreateChatController());
  final chatListingController = Get.find<ChatListingController>();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.95,
      initialChildSize: 0.60,
      minChildSize: 0.50,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: followersFollowing.searchTakipciController,
                      decoration: InputDecoration(
                        icon: Icon(
                          CupertinoIcons.search,
                          color: Colors.black,
                        ),
                        hintText: "Ara",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                      onChanged: (v) => controllerr.query.value = v,
                    ),
                  ),
                ),
              ),
              Expanded(
                  child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: followersFollowing.takipciler.length,
                itemBuilder: (context, index) {
                  return CreateChatContent(
                    userID: followersFollowing.takipciler[index],
                  );
                },
              )),
              if (controllerr.selected.value != "")
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TurqAppButton(
                    onTap: () {
                      //its create new chat or actual chat continue
                      final sohbet =
                          chatListingController.list.firstWhereOrNull(
                        (val) => val.userID == controllerr.selected.value,
                      );

                      if (sohbet != null) {
                        // Sohbet zaten varsa: mevcut chatID'yi kullan
                        Get.to(() => ChatView(
                              chatID: sohbet.chatID,
                              userID: controllerr.selected.value,
                              isNewChat: false,
                            ));
                      } else {
                        final chatId = buildConversationId(
                          FirebaseAuth.instance.currentUser!.uid,
                          controllerr.selected.value,
                        );
                        Get.to(() => ChatView(
                              chatID: chatId,
                              userID: controllerr.selected.value,
                              isNewChat: true,
                            ));
                        chatListingController.getList();
                      }
                    },
                    text: chatListingController.list.firstWhereOrNull(
                              (val) => val.userID == controllerr.selected.value,
                            ) !=
                            null
                        ? "Sohbete Devam Et"
                        : "Yeni Sohbet Oluştur",
                  ),
                )
            ],
          );
        }),
      ),
    );
  }
}
