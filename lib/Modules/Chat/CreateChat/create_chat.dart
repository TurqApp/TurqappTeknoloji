import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/Chat/CreateChat/CreateChatContent/create_chat_content.dart';
import 'package:turqappv2/Modules/Chat/CreateChat/create_chat_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../Profile/FollowingFollowers/following_followers_controller.dart';

class CreateChat extends StatefulWidget {
  const CreateChat({super.key});

  @override
  State<CreateChat> createState() => _CreateChatState();
}

class _CreateChatState extends State<CreateChat> {
  late final FollowingFollowersController followersFollowing;
  late final CreateChatController controllerr;
  late final ChatListingController chatListingController;
  bool _ownsFollowersController = false;
  bool _ownsCreateChatController = false;
  bool _ownsChatListingController = false;

  @override
  void initState() {
    super.initState();
    final existingFollowers = FollowingFollowersController.maybeFind();
    if (existingFollowers != null) {
      followersFollowing = existingFollowers;
    } else {
      followersFollowing = FollowingFollowersController.ensure(
        initialPage: 0,
        userId: CurrentUserService.instance.userId,
      );
      _ownsFollowersController = true;
    }
    final existingCreateChat = CreateChatController.maybeFind();
    if (existingCreateChat != null) {
      controllerr = existingCreateChat;
    } else {
      controllerr = CreateChatController.ensure();
      _ownsCreateChatController = true;
    }
    final existingChatListing = ChatListingController.maybeFind();
    if (existingChatListing != null) {
      chatListingController = existingChatListing;
    } else {
      chatListingController = ChatListingController.ensure();
      _ownsChatListingController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsFollowersController &&
        identical(
            FollowingFollowersController.maybeFind(), followersFollowing)) {
      Get.delete<FollowingFollowersController>(force: true);
    }
    if (_ownsCreateChatController &&
        identical(CreateChatController.maybeFind(), controllerr)) {
      Get.delete<CreateChatController>(force: true);
    }
    if (_ownsChatListingController &&
        identical(ChatListingController.maybeFind(), chatListingController)) {
      Get.delete<ChatListingController>(force: true);
    }
    super.dispose();
  }

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
                      controller:
                          followersFollowing.searchTakipEdilenController,
                      decoration: InputDecoration(
                        icon: Icon(
                          CupertinoIcons.search,
                          color: Colors.black,
                        ),
                        hintText: 'common.search'.tr,
                        hintStyle: const TextStyle(
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
                itemCount: followersFollowing.takipEdilenler.length,
                itemBuilder: (context, index) {
                  final selectedUserId =
                      followersFollowing.takipEdilenler[index];
                  return CreateChatContent(
                    userID: selectedUserId,
                    onTap: () async {
                      final sohbet =
                          chatListingController.list.firstWhereOrNull(
                        (val) => val.userID == selectedUserId,
                      );
                      if (sohbet != null) {
                        await Get.to(() => ChatView(
                              chatID: sohbet.chatID,
                              userID: selectedUserId,
                              isNewChat: false,
                            ));
                      } else {
                        final chatId = buildConversationId(
                          CurrentUserService.instance.userId,
                          selectedUserId,
                        );
                        await Get.to(() => ChatView(
                              chatID: chatId,
                              userID: selectedUserId,
                              isNewChat: true,
                            ));
                      }
                      await chatListingController.getList();
                    },
                  );
                },
              )),
            ],
          );
        }),
      ),
    );
  }
}
