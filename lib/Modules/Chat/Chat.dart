import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Chat/MessageContent/message_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:video_player/video_player.dart';

import 'LocationShareView/location_share_view_chat.dart';

const List<Color> _chatBackgroundPalette = [
  Color(0xFFEFF5FB),
  Color(0xFFE7F7F1),
  Color(0xFFFBEFE8),
  Color(0xFFF9ECF5),
  Color(0xFFF1ECFB),
  Color(0xFFE6F5F1),
];

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
  ChatController get controller => Get.isRegistered<ChatController>(tag: chatID)
      ? Get.find<ChatController>(tag: chatID)
      : Get.put(
          ChatController(chatID: chatID, userID: userID),
          tag: chatID,
        );

  void _disposeChatControllerIfAny() {
    if (Get.isRegistered<ChatController>(tag: chatID)) {
      Get.delete<ChatController>(tag: chatID, force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // İlk açılışta sadece bir kez odakla (her rebuild'de klavye zıplamasını engeller)
    if (openKeyboard == true && controller.didAutoFocusOnce == false) {
      controller.didAutoFocusOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.focus.requestFocus();
      });
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _disposeChatControllerIfAny();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            return Stack(
              children: [
                if (controller.selection.value == 0)
                  buildChat(context)
                else if (controller.selection.value == 1)
                  buildImagePreview(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget buildChat(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Obx(() {
          final bgColor =
              _chatBackgroundPalette[controller.chatBgPaletteIndex.value];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onLongPress: () {
                if (controller.focus.hasFocus) return;
                FocusScope.of(context).unfocus();
                _showBackgroundPalette(context);
              },
              child: Stack(
                children: [
                  Container(
                    color: bgColor,
                    child: Column(
                      children: [
                        Expanded(
                          child: NotificationListener<ScrollEndNotification>(
                            onNotification: (_) => false,
                            child: ListView.builder(
                              reverse: true,
                              controller: controller.scrollController,
                              padding: const EdgeInsets.only(bottom: 10),
                              itemCount: controller.filteredMessages.isEmpty
                                  ? 1
                                  : controller.filteredMessages.length +
                                      1 +
                                      ((!controller.showStarredOnly.value &&
                                              (controller.hasMoreOlder.value ||
                                                  controller
                                                      .isLoadingOlder.value))
                                          ? 1
                                          : 0),
                              itemBuilder: (context, index) {
                                final displayMessages =
                                    controller.filteredMessages;
                                if (displayMessages.isNotEmpty &&
                                    index == displayMessages.length) {
                                  return Obx(
                                    () => controller.isLoadingOlder.value
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: Center(
                                              child: CupertinoActivityIndicator(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : const SizedBox(height: 6),
                                  );
                                }

                                final introIndex = displayMessages.isEmpty
                                    ? 0
                                    : displayMessages.length +
                                        ((!controller.showStarredOnly.value &&
                                                (controller
                                                        .hasMoreOlder.value ||
                                                    controller
                                                        .isLoadingOlder.value))
                                            ? 1
                                            : 0);
                                final isIntroItem = index == introIndex;
                                if (isIntroItem) {
                                  if (controller.showStarredOnly.value) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Center(
                                        child: Text(
                                          displayMessages.isEmpty
                                              ? "Yıldızlı mesaj yok"
                                              : "",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return _buildProfileIntro(
                                    bottomSpacing: const SizedBox(height: 24),
                                  );
                                }
                                final message = displayMessages[index];
                                final isLast = index == 0;
                                final shouldShowDateSeparator =
                                    index == displayMessages.length - 1 ||
                                        !_isSameDay(
                                          message.timeStamp.toInt(),
                                          displayMessages[index + 1]
                                              .timeStamp
                                              .toInt(),
                                        );
                                final dateSeparatorText =
                                    shouldShowDateSeparator
                                        ? _formatDateSeparator(
                                            message.timeStamp.toInt())
                                        : null;

                                return Obx(() {
                                  final isSelection =
                                      controller.isSelectionMode.value;
                                  final isSelected = controller
                                      .selectedMessageIds
                                      .contains(message.rawDocID);
                                  return Dismissible(
                                    key: ValueKey(
                                        "reply_${message.rawDocID}_${message.timeStamp}_${message.userID}"),
                                    direction: isSelection
                                        ? DismissDirection.none
                                        : DismissDirection.horizontal,
                                    dismissThresholds: const {
                                      DismissDirection.startToEnd: 0.22,
                                      DismissDirection.endToStart: 0.22,
                                    },
                                    background: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 12),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.07),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.reply_thick_solid,
                                            color: Colors.black54,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    secondaryBackground: Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 12),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.07),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.check_mark_circled,
                                            color: Colors.black54,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        controller.startReply(message);
                                      } else if (direction ==
                                          DismissDirection.endToStart) {
                                        controller.startSelectionMode(
                                            message.rawDocID);
                                      }
                                      return false;
                                    },
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: isSelection
                                          ? () => controller
                                              .toggleSelection(message.rawDocID)
                                          : null,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (isSelection)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 12, right: 6, top: 8),
                                              child: Icon(
                                                isSelected
                                                    ? CupertinoIcons
                                                        .checkmark_circle_fill
                                                    : CupertinoIcons.circle,
                                                size: 22,
                                                color: isSelected
                                                    ? Colors.black
                                                    : Colors.black38,
                                              ),
                                            ),
                                          Expanded(
                                            child: IgnorePointer(
                                              ignoring: isSelection,
                                              child: MessageContent(
                                                mainID: controller.chatID,
                                                model: message,
                                                isLastMessage: isLast,
                                                dateSeparatorText:
                                                    dateSeparatorText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 160),
                                opacity: controller.scrollDownOpacity.value,
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 18, sigmaY: 18),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.88),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x22000000),
                                            blurRadius: 16,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        CupertinoIcons.arrow_down,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }),
        buildInputRow(),
      ],
    );
  }

  Future<void> _showBackgroundPalette(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_chatBackgroundPalette.length, (index) {
                final color = _chatBackgroundPalette[index];
                final isSelected = controller.chatBgPaletteIndex.value == index;
                return GestureDetector(
                  onTap: () async {
                    await controller.setChatBackgroundPreference(index);
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(int aMs, int bMs) {
    final a = DateTime.fromMillisecondsSinceEpoch(aMs);
    final b = DateTime.fromMillisecondsSinceEpoch(bMs);
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateSeparator(int ms) {
    const months = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    const weekdaysShort = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    const weekdaysLong = [
      '',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Bugün';
    if (diffDays == 1) return 'Dün';
    if (diffDays > 1 && diffDays <= 6) return weekdaysLong[d.weekday];

    return '${d.day} ${months[d.month]} ${weekdaysShort[d.weekday]}';
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
                child: controller.avatarUrl.value != ""
                    ? CachedNetworkImage(
                        imageUrl: controller.avatarUrl.value,
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
        const SizedBox(height: 10),
        Text(
          controller.fullName.value.trim().isEmpty
              ? controller.nickname.value
              : controller.fullName.value.trim(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 29,
            fontFamily: "MontserratBold",
          ),
        ),
        const SizedBox(height: 2),
        Text(
          controller.nickname.value.startsWith("@")
              ? controller.nickname.value
              : "@${controller.nickname.value}",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            "${controller.followersCount.value} takipçi · ${controller.followingCount.value} takip · ${controller.postCount.value} gönderi",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
        if (controller.bio.value.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              controller.bio.value.trim(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontFamily: "Montserrat",
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (userID != FirebaseAuth.instance.currentUser!.uid) {
                      Get.to(() => SocialProfile(userID: userID));
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xffF1F3F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(36),
                  ),
                  child: const Text(
                    "Profili gör",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (userID != FirebaseAuth.instance.currentUser!.uid) {
                      Get.to(() => SocialProfile(userID: userID));
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xffF1F3F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(36),
                  ),
                  child: const Text(
                    "Topluluğu görüntüle",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomSpacing ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Obx(() {
      if (controller.isSelectionMode.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: controller.stopSelectionMode,
                icon: const Icon(CupertinoIcons.xmark, color: Colors.black),
              ),
              Expanded(
                child: Text(
                  "${controller.selectedMessageIds.length} Mesaj Seçildi",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                _disposeChatControllerIfAny();
                Get.back();
              },
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
                          child: controller.avatarUrl.value != ""
                              ? CachedNetworkImage(
                                  imageUrl: controller.avatarUrl.value,
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
                            Obx(() => controller.isOtherTyping.value
                                ? const Text(
                                    "yazıyor...",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  )
                                : Text(
                                    "@${controller.nickname.value}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Obx(() => GestureDetector(
                  onTap: controller.toggleStarredFilter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      controller.showStarredOnly.value
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      color: controller.showStarredOnly.value
                          ? Colors.amber
                          : Colors.black,
                      size: 22,
                    ),
                  ),
                )),
          ],
        ),
      );
    });
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
                      controller.clearPendingMedia();
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
                ],
              ),
              Text(
                controller.pendingVideo.value != null ? "Video" : "Fotoğraflar",
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
          final pendingVideo = controller.pendingVideo.value;
          if (pendingVideo != null) {
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PendingVideoPreview(file: pendingVideo),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
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
            child: Obx(() {
              if (controller.pendingVideo.value != null) {
                return const SizedBox.shrink();
              }
              return ListView.builder(
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
                        controller.currentPage.value = index;
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
              );
            }),
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
            // Selection mode bar
            Obx(() {
              if (!controller.isSelectionMode.value) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: controller.selectedMessageIds.isEmpty
                          ? null
                          : controller.deleteSelectedMessages,
                      icon:
                          const Icon(CupertinoIcons.trash, color: Colors.black),
                    ),
                    const Spacer(),
                    Text(
                      "${controller.selectedMessageIds.length} Mesaj Seçildi",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Recording bar
            Obx(() {
              if (!controller.isRecording.value) {
                return const SizedBox.shrink();
              }
              return _buildRecordingRow();
            }),
            // Reply/edit preview
            Obx(() {
              if (controller.isSelectionMode.value ||
                  controller.isRecording.value) {
                return const SizedBox.shrink();
              }
              final editing = controller.editingMessage.value;
              final replying = controller.replyingTo.value;
              if (editing == null && replying == null) {
                return const SizedBox.shrink();
              }
              late final bool previewIsVideo;
              late final bool previewIsImage;
              late final bool previewIsAudio;
              late final bool previewIsLocation;
              late final bool previewIsPost;
              late final bool previewIsContact;
              late final String previewThumb;
              late final String previewLabel;
              late final String previewText;

              if (editing != null) {
                previewIsVideo = false;
                previewIsImage = false;
                previewIsAudio = false;
                previewIsLocation = false;
                previewIsPost = false;
                previewIsContact = false;
                previewThumb = "";
                previewLabel = "Mesaj düzenleniyor";
                previewText = editing.metin;
              } else {
                final replyModel = replying!;
                previewIsVideo = replyModel.video.isNotEmpty;
                previewIsImage =
                    replyModel.video.isEmpty && replyModel.imgs.isNotEmpty;
                previewIsAudio = replyModel.sesliMesaj.isNotEmpty;
                previewIsLocation = replyModel.lat != 0 || replyModel.long != 0;
                previewIsPost = replyModel.postID.trim().isNotEmpty;
                previewIsContact = replyModel.kisiAdSoyad.trim().isNotEmpty;
                previewThumb = previewIsImage
                    ? replyModel.imgs.first
                    : (previewIsVideo ? replyModel.videoThumbnail : "");
                previewLabel = previewIsVideo
                    ? "Video"
                    : previewIsImage
                        ? "Fotoğraf"
                        : previewIsAudio
                            ? "Ses"
                            : previewIsLocation
                                ? "Konum"
                                : previewIsPost
                                    ? "Gönderi"
                                    : previewIsContact
                                        ? "Kişi"
                                        : "Yanıt";
                previewText = replyModel.metin.trim().isNotEmpty
                    ? replyModel.metin
                    : previewLabel;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (previewThumb.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CachedNetworkImage(
                              imageUrl: previewThumb,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    else if (previewIsVideo)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsAudio)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.mic_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsLocation)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.location_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsPost)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.doc_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      )
                    else if (previewIsContact)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.person_crop_circle_fill,
                          color: Colors.black54,
                          size: 16,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            previewLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontFamily: "MontserratSemiBold",
                            ),
                          ),
                          Text(
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
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
            // TextField satırı - Offstage ile gizlenir ama ASLA tree'den çıkmaz
            Obx(() => Offstage(
                  offstage: controller.isSelectionMode.value ||
                      controller.isRecording.value,
                  child: _ChatTextField(
                    key: const ValueKey('chat_text_field'),
                    focusNode: controller.focus,
                    textController: controller.textEditingController,
                    controller: controller,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            controller.cancelVoiceRecording();
          },
          child: Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(50),
            ),
            child:
                const Icon(CupertinoIcons.xmark, color: Colors.black, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() {
            final secs = controller.recordingDuration.value;
            final m = (secs ~/ 60).toString().padLeft(1, '0');
            final s = (secs % 60).toString().padLeft(2, '0');
            return Text(
              "Kayıt yapılıyor... $m:$s",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontFamily: "MontserratMedium",
              ),
            );
          }),
        ),
        GestureDetector(
          onTap: () {
            controller.stopVoiceRecording();
          },
          child: Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

/// TextField'i tüm Obx/reactive state'ten tamamen izole eden StatefulWidget.
class _ChatTextField extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController textController;
  final ChatController controller;

  const _ChatTextField({
    super.key,
    required this.focusNode,
    required this.textController,
    required this.controller,
  });

  @override
  State<_ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<_ChatTextField> {
  final GlobalKey _plusButtonKey = GlobalKey();

  Future<void> _showAttachmentMenu() async {
    final box = _plusButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final buttonRect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final position = Rect.fromCenter(
      center: buttonRect.center.translate(0, -4),
      width: 2,
      height: 2,
    );

    await showPullDownMenu(
      context: context,
      position: position,
      items: [
        PullDownMenuItem(
          title: "Fotoğraflar",
          icon: CupertinoIcons.photo_on_rectangle,
          onTap: widget.controller.pickImage,
        ),
        PullDownMenuItem(
          title: "Videolar",
          icon: AppIcons.playFilled,
          onTap: widget.controller.pickVideo,
        ),
        PullDownMenuItem(
          title: "Konum",
          icon: AppIcons.locationSolid,
          onTap: () {
            Get.to(
                () => LocationShareViewChat(chatID: widget.controller.chatID));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // + butonu (attachment menü)
          GestureDetector(
            onTap: _showAttachmentMenu,
            child: Container(
              key: _plusButtonKey,
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.add,
                  color: Colors.black87, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          // TextField (pill shape)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: widget.focusNode,
                      controller: widget.textController,
                      textCapitalization: TextCapitalization.sentences,
                      enableInteractiveSelection: true,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Mesaj",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Kamera butonu
          GestureDetector(
            onTap: widget.controller.openCustomCameraCapture,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 2),
              alignment: Alignment.center,
              child: const Icon(CupertinoIcons.camera,
                  color: Colors.black87, size: 22),
            ),
          ),
          const SizedBox(width: 2),
          // Mic / Send butonu
          _ChatTrailingButton(controller: widget.controller),
        ],
      ),
    );
  }
}

/// Sağ taraftaki buton: Mic veya Send
class _ChatTrailingButton extends StatelessWidget {
  final ChatController controller;
  const _ChatTrailingButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isUploading.value) {
        return Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(bottom: 2),
          alignment: Alignment.center,
          child: const CupertinoActivityIndicator(color: Colors.black),
        );
      }

      final hasContent = controller.textMesage.value != "" ||
          controller.images.isNotEmpty ||
          controller.pendingVideo.value != null ||
          controller.editingMessage.value != null;

      if (hasContent) {
        if (controller.uploadPercent.value != 0 &&
            controller.uploadPercent.value != 100) {
          return Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 2),
            alignment: Alignment.center,
            child: const CupertinoActivityIndicator(color: Colors.black),
          );
        }
        return GestureDetector(
          onTap: () {
            if (controller.pendingVideo.value != null) {
              controller.uploadPendingVideoToStorage();
            } else if (controller.images.isNotEmpty ||
                controller.selection.value == 1) {
              controller.uploadImageToStorage();
            } else {
              controller.sendMessage();
            }
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 2),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        );
      }

      return GestureDetector(
        onTap: controller.startVoiceRecording,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(bottom: 2),
          alignment: Alignment.center,
          child:
              const Icon(CupertinoIcons.mic, color: Colors.black87, size: 22),
        ),
      );
    });
  }
}

class _PendingVideoPreview extends StatefulWidget {
  final File file;
  const _PendingVideoPreview({required this.file});

  @override
  State<_PendingVideoPreview> createState() => _PendingVideoPreviewState();
}

class _PendingVideoPreviewState extends State<_PendingVideoPreview> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.play();
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return SizedBox(
        height: (MediaQuery.of(context).size.height * 0.26).clamp(160.0, 200.0),
        child: Center(
          child: const CupertinoActivityIndicator(color: Colors.black),
        ),
      );
    }

    final ratio = _controller.value.aspectRatio == 0
        ? (9 / 16)
        : _controller.value.aspectRatio;

    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
        setState(() {});
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width - 72;
          const maxHeight = 220.0;
          final computedHeight = availableWidth / ratio;
          final targetHeight = math.min(computedHeight, maxHeight);
          final targetWidth = targetHeight * ratio;

          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: VideoPlayer(_controller),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller.value.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
