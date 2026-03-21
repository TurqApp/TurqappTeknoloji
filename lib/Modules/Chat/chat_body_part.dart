part of 'chat.dart';

extension ChatBodyPart on ChatView {
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
                                              vertical: 10,
                                            ),
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
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          displayMessages.isEmpty
                                              ? 'chat.no_starred_messages'.tr
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
                                            message.timeStamp.toInt(),
                                          )
                                        : null;

                                return Obx(() {
                                  final isSelection =
                                      controller.isSelectionMode.value;
                                  final isSelected = controller
                                      .selectedMessageIds
                                      .contains(message.rawDocID);
                                  return Dismissible(
                                    key: ValueKey(
                                      "reply_${message.rawDocID}_${message.timeStamp}_${message.userID}",
                                    ),
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
                                          message.rawDocID,
                                        );
                                      }
                                      return false;
                                    },
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: isSelection
                                          ? () => controller.toggleSelection(
                                                message.rawDocID,
                                              )
                                          : null,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (isSelection)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 12,
                                                right: 6,
                                                top: 8,
                                              ),
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
                              onTap: controller.scrollToBottom,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 160),
                                opacity: controller.scrollDownOpacity.value,
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 18,
                                      sigmaY: 18,
                                    ),
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
    final months = [
      '',
      'common.month_short.january'.tr,
      'common.month_short.february'.tr,
      'common.month_short.march'.tr,
      'common.month_short.april'.tr,
      'common.month_short.may'.tr,
      'common.month_short.june'.tr,
      'common.month_short.july'.tr,
      'common.month_short.august'.tr,
      'common.month_short.september'.tr,
      'common.month_short.october'.tr,
      'common.month_short.november'.tr,
      'common.month_short.december'.tr,
    ];
    final weekdaysShort = [
      '',
      'common.weekday_short.monday'.tr,
      'common.weekday_short.tuesday'.tr,
      'common.weekday_short.wednesday'.tr,
      'common.weekday_short.thursday'.tr,
      'common.weekday_short.friday'.tr,
      'common.weekday_short.saturday'.tr,
      'common.weekday_short.sunday'.tr,
    ];
    final weekdaysLong = [
      '',
      'common.weekday.monday'.tr,
      'common.weekday.tuesday'.tr,
      'common.weekday.wednesday'.tr,
      'common.weekday.thursday'.tr,
      'common.weekday.friday'.tr,
      'common.weekday.saturday'.tr,
      'common.weekday.sunday'.tr,
    ];
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'chat.today'.tr;
    if (diffDays == 1) return 'chat.yesterday'.tr;
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
                        child: CupertinoActivityIndicator(color: Colors.grey),
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
            'chat.profile_stats'.trParams({
              'followers': '${controller.followersCount.value}',
              'following': '${controller.followingCount.value}',
              'posts': '${controller.postCount.value}',
            }),
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
                  'chat.selected_messages'.trParams({
                    'count': '${controller.selectedMessageIds.length}',
                  }),
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
            AppBackButton(
              onTap: () {
                _disposeChatControllerIfAny();
                Get.back();
              },
              icon: CupertinoIcons.arrow_left,
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
                            Obx(
                              () => controller.isOtherTyping.value
                                  ? Text(
                                      'chat.typing'.tr,
                                      style: const TextStyle(
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
            Obx(
              () => GestureDetector(
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
              ),
            ),
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
                  AppBackButton(
                    onTap: controller.clearPendingMedia,
                    icon: CupertinoIcons.arrow_left,
                  ),
                ],
              ),
              Text(
                controller.pendingVideo.value != null
                    ? 'chat.video'.tr
                    : 'common.photos'.tr,
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
                      horizontal: 16,
                      vertical: 20,
                    ),
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
}
