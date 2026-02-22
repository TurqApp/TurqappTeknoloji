import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Modules/Chat/ChatController.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Chat/MessageContent/MessageContent.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

import 'LocationShareView/LocationShareViewChat.dart';

class ChatView extends StatelessWidget {
  final String chatID;
  final String userID;
  final bool? isNewChat;
  final bool? openKeyboard;

  ChatView({
    super.key,
    required this.chatID,
    required this.userID,
    this.isNewChat,
    this.openKeyboard,
  });
  late final ChatController controller;

  @override
  Widget build(BuildContext context) {
    controller = Get.put(
      ChatController(chatID: chatID, userID: userID),
      tag: chatID,
    );

    // 🔥 Ekran çizildikten sonra odakla
    if (openKeyboard == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.focus.requestFocus();
      });
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Stack(
            children: [
              if (controller.selection.value == 0)
                buildChat()
              else if (controller.selection.value == 1)
                buildImagePreview(),
            ],
          );
        }),
      ),
    );
  }

  Widget buildChat() {
    return Column(
      children: [
        _buildTopBar(),
        Obx(() {
          return Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: NotificationListener<ScrollEndNotification>(
                        onNotification: (_) => false,
                        child: ListView.builder(
                          reverse: true,
                          controller: controller.scrollController,
                          padding: const EdgeInsets.only(bottom: 10),
                          itemCount: controller.messages.isEmpty
                              ? 1
                              : controller.messages.length + 1,
                          itemBuilder: (context, index) {
                            final isIntroItem = controller.messages.isEmpty ||
                                index == controller.messages.length;
                            if (isIntroItem) {
                              return _buildProfileIntro(
                                bottomSpacing: const SizedBox(height: 24),
                              );
                            }
                            final message = controller.messages[index];
                            final isLast = index == 0;

                            return MessageContent(
                              mainID: controller.chatID,
                              model: message,
                              isLastMessage: isLast,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => controller.showScrollDownButton.value
                      ? Positioned(
                          bottom: 15,
                          right: 15,
                          child: GestureDetector(
                            onTap: () {
                              controller.scrollToBottom();
                            },
                            child: Opacity(
                              opacity: 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }),
        buildInputRow(),
      ],
    );
  }

  Widget _buildProfileIntro({Widget? bottomSpacing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipOval(
              child: SizedBox(
                width: 70,
                height: 70,
                child: controller.pfImage.value != ""
                    ? CachedNetworkImage(
                        imageUrl: controller.pfImage.value,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: CupertinoActivityIndicator(
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            RozetContent(size: 20, userID: userID),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          controller.fullName.value.trimRight(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratBold",
          ),
        ),
        Text(
          controller.nickname.value,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontFamily: "MontserratMedium",
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Text(
            controller.bio.value,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (userID != FirebaseAuth.instance.currentUser!.uid) {
              Get.to(() => SocialProfile(userID: userID));
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
              ),
              child: Text(
                "Profili Görüntüle",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        ),
        bottomSpacing ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
          ),
          Expanded(
            child: Obx(
              () => GestureDetector(
                onTap: () {
                  Get.to(() => SocialProfile(userID: userID));
                },
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: controller.pfImage.value != ""
                            ? CachedNetworkImage(
                                imageUrl: controller.pfImage.value,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    8.pw,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  controller.fullName.value.trim().isEmpty
                                      ? controller.nickname.value
                                      : controller.fullName.value.trim(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ),
                              RozetContent(size: 16, userID: userID),
                            ],
                          ),
                          Text(
                            "@${controller.nickname.value}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.phone, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.video_camera, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget buildImagePreview() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      controller.selection.value = 0;
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_left,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.uploadImageToStorage();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Gönder",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "Fotoğraflar",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          return Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              onPageChanged: (v) {
                controller.currentPage.value = v;
              },
              itemCount: controller.images.length,
              itemBuilder: (context, index) {
                return Image.file(controller.images[index]);
              },
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.images.length,
              itemBuilder: (context, index) {
                return Obx(
                  () => GestureDetector(
                    onTap: () {
                      controller.pageController.animateToPage(
                        index,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                      controller.currentPage.value =
                          index; // bunu da mutlaka ekle
                    },
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: 4,
                        left: index == 0 ? 15 : 0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          border: Border.all(
                            color: controller.currentPage.value == index
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          child: SizedBox(
                            width: 45,
                            height: 45,
                            child: Image.file(
                              controller.images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        buildInputRow(),
      ],
    );
  }

  Widget buildInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final editing = controller.editingMessage.value;
              final replying = controller.replyingTo.value;
              if (editing == null && replying == null) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        editing != null
                            ? "Düzenleniyor: ${editing.metin}"
                            : "Yanıtlanıyor: ${replying?.metin ?? ''}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.clearComposerAction,
                      child: const Icon(CupertinoIcons.xmark, size: 16),
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                PullDownButton(
                  itemBuilder: (context) => [
                    PullDownMenuItem(
                      onTap: () {
                        controller.pickCameraImage();
                      },
                      title: 'Fotoğraf Çek',
                      icon: CupertinoIcons.camera,
                    ),
                    PullDownMenuItem(
                      onTap: () {
                        controller.pickImage();
                      },
                      title: 'Fotoğraf Yükle',
                      icon: CupertinoIcons.photo_on_rectangle,
                    ),
                    PullDownMenuItem(
                      onTap: () {
                        Get.to(() => LocationShareViewChat(
                              chatID: controller.chatID,
                            ));
                      },
                      title: 'Konum Paylaş',
                      icon: CupertinoIcons.location,
                    ),
                    PullDownMenuItem(
                      onTap: () {
                        controller.selectContact();
                      },
                      title: 'Kişi Seç',
                      icon: CupertinoIcons.person_2,
                    ),
                  ],
                  buttonBuilder: (context, showMenu) => CupertinoButton(
                    onPressed: showMenu,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 35,
                      height: 35,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                      child: const Icon(CupertinoIcons.camera_fill,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 70,
                      minHeight: 35,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50)),
                        border: Border.all(color: Colors.grey.withAlpha(70)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Obx(
                        () => TextField(
                          focusNode: controller.focus,
                          controller: controller.textEditingController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: controller.editingMessage.value != null
                                ? "Mesajı düzenle"
                                : "Mesaj",
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontFamily: "Montserrat",
                            ),
                            isCollapsed: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 5),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                          onChanged: (val) {
                            controller.textMesage.value = val;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 7),
                Obx(() {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (controller.textMesage.value != "" ||
                          controller.images.isNotEmpty ||
                          controller.editingMessage.value != null)
                        if (controller.uploadPercent.value != 0 &&
                            controller.uploadPercent.value != 100)
                          SizedBox(
                            width: 35,
                            height: 35,
                            child: Center(
                              child: CupertinoActivityIndicator(
                                color: Colors.black,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              if (controller.selection.value == 0) {
                                controller.sendMessage();
                              } else if (controller.selection.value == 1) {
                                controller.uploadImageToStorage();
                              }
                            },
                            child: Container(
                              width: 35,
                              height: 35,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50),
                                ),
                              ),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                      else
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(CupertinoIcons.mic,
                                  color: Colors.black, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 26, minHeight: 26),
                            ),
                            IconButton(
                              onPressed: controller.pickImage,
                              icon: const Icon(CupertinoIcons.photo,
                                  color: Colors.black, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 26, minHeight: 26),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(CupertinoIcons.smiley,
                                  color: Colors.black, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 26, minHeight: 26),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(CupertinoIcons.plus_circle,
                                  color: Colors.black, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 26, minHeight: 26),
                            ),
                          ],
                        ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
