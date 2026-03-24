part of 'social_profile.dart';

extension _SocialProfileHeaderPart on _SocialProfileState {
  Widget header() {
    return Obx(() {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const AppBackButton(),
                    8.pw,
                    GestureDetector(
                      onTap: () {
                        _setCenteredIndex(-1);
                        Get.to(() => AboutProfile(userID: widget.userID))
                            ?.then((_) {
                          controller.resumeCenteredPost();
                        });
                      },
                      child: Text(
                        controller.nickname.value,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: AppFontFamilies.mbold,
                        ),
                      ),
                    ),
                    if (widget.userID.isNotEmpty) ...[
                      RozetContent(
                        size: 15,
                        userID: widget.userID,
                        leftSpacing: 6,
                        rozetValue: controller.rozet.value,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PullDownButton(
                itemBuilder: (context) => [
                  PullDownMenuItem(
                    onTap: () async {
                      final nick =
                          normalizeNicknameInput(controller.nickname.value);
                      final safeSlug = nick.isEmpty ? widget.userID : nick;
                      final result = await _shortLinkService.upsertUser(
                        userId: widget.userID,
                        slug: safeSlug,
                        title: 'profile.profile_link_title'.trParams({
                          'nickname': controller.nickname.value,
                          'app': 'app.name'.tr,
                        }),
                        desc: 'qr.profile_desc'.tr,
                        imageUrl: controller.avatarUrl.value,
                      );
                      final link =
                          (result['url'] ?? '').toString().trim().isNotEmpty
                              ? (result['url'] ?? '').toString().trim()
                              : buildTurqAppProfileUrl(safeSlug);
                      await Clipboard.setData(ClipboardData(text: link));
                      AppSnackbar('common.copied'.tr, 'common.link_copied'.tr);
                    },
                    title: 'profile.copy_profile_link'.tr,
                    icon: CupertinoIcons.doc_on_doc,
                  ),
                  PullDownMenuItem(
                    onTap: () async {
                      await ShareActionGuard.run(() async {
                        final nick =
                            normalizeNicknameInput(controller.nickname.value);
                        final safeSlug = nick.isEmpty ? widget.userID : nick;
                        final result = await _shortLinkService.upsertUser(
                          userId: widget.userID,
                          slug: safeSlug,
                          title: 'profile.profile_link_title'.trParams({
                            'nickname': controller.nickname.value,
                            'app': 'app.name'.tr,
                          }),
                          desc: 'qr.profile_desc'.tr,
                          imageUrl: controller.avatarUrl.value,
                        );
                        final link =
                            (result['url'] ?? '').toString().trim().isNotEmpty
                                ? (result['url'] ?? '').toString().trim()
                                : buildTurqAppProfileUrl(safeSlug);
                        await ShareLinkService.shareUrl(
                          url: link,
                          title: 'profile.profile_link_title'.trParams({
                            'nickname': controller.nickname.value,
                            'app': 'app.name'.tr,
                          }),
                          subject: 'profile.profile_share_title'.tr,
                        );
                      });
                    },
                    title: 'common.share'.tr,
                    icon: CupertinoIcons.share_up,
                  ),
                  if (!controller.isBlockedByCurrentViewer(widget.userID))
                    PullDownMenuItem(
                      onTap: () async {
                        _setCenteredIndex(-1);
                        await controller.block();
                        controller.resumeCenteredPost();
                      },
                      title: 'common.block'.tr,
                      icon: CupertinoIcons.xmark_circle,
                    ),
                  if (controller.isBlockedByCurrentViewer(widget.userID))
                    PullDownMenuItem(
                      onTap: () async {
                        _setCenteredIndex(-1);
                        await controller.unblock();
                        controller.resumeCenteredPost();
                      },
                      title: 'profile.unblock'.tr,
                      icon: CupertinoIcons.xmark_circle,
                    ),
                  PullDownMenuItem(
                    onTap: () {
                      _setCenteredIndex(-1);
                      Get.to(
                        () => ReportUser(
                          userID: widget.userID,
                          postID: "",
                          commentID: "",
                        ),
                      )?.then((_) {
                        controller.resumeCenteredPost();
                        controller.getUserData();
                      });
                    },
                    title: 'common.report'.tr,
                    icon: CupertinoIcons.shield,
                  ),
                ],
                buttonBuilder: (context, showMenu) => AppHeaderActionButton(
                  onTap: showMenu,
                  child: const Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: Colors.black,
                    size: AppIconSurface.kIconSize,
                  ),
                ),
              ),
            ],
          ),
          imageAndFollowButtons(),
          const SizedBox(height: 12),
          textInfoBody(),
          if (!controller.isBlockedByCurrentViewer(widget.userID))
            _buildLinksAndHighlightsRow(),
          Padding(padding: const EdgeInsets.only(top: 0), child: counters()),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: postButtons(context),
          ),
          Divider(
            height: 0,
            color: Colors.grey.withAlpha(50),
          ),
          4.ph,
        ],
      );
    });
  }

  Widget imageAndFollowButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final isPrivateBlocked =
                  controller.isPrivateContentBlockedFor(_myUserId);
              if (isPrivateBlocked) {
                AppSnackbar('profile.private_account_title'.tr,
                    'profile.private_story_follow_required'.tr);
                return;
              }

              if (controller.storyUserModel != null &&
                  controller.storyUserModel!.stories.isNotEmpty) {
                try {
                  _setCenteredIndex(-1);
                  controller.lastCenteredIndex =
                      controller.currentVisibleIndex.value >= 0
                          ? controller.currentVisibleIndex.value
                          : controller.lastCenteredIndex;
                  Get.to(() => StoryViewer(
                          startedUser: controller.storyUserModel!,
                          storyOwnerUsers: [controller.storyUserModel!]))
                      ?.then((_) {
                    controller.resumeCenteredPost();
                  });
                } catch (_) {}
              }
            },
            onLongPress: () {
              HapticFeedback.lightImpact();
              _showProfileImagePreview();
            },
            child: _buildProfileImageWithBorder(),
          ),
          const SizedBox(width: 12),
          if (controller.complatedCheck.value &&
              !controller.isBlockedByCurrentViewer(widget.userID))
            followButtons()
          else if (controller.complatedCheck.value &&
              controller.isBlockedByCurrentViewer(widget.userID))
            unblockButton(),
        ],
      ),
    );
  }

  Widget textInfoBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                controller.displayName.value.trim().isNotEmpty
                    ? controller.displayName.value.trim()
                    : "${controller.firstName.value} ${controller.lastName.value}"
                        .trim(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
          if (controller.meslek.value != "")
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                controller.meslek.value,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          if (controller.bio.value != "")
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                controller.bio.value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "Montserrat",
                ),
              ),
            ),
          if (controller.adres.value != "")
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: GestureDetector(
                onTap: () {
                  showMapsSheetWithAdres(controller.adres.value);
                },
                child: Text(
                  controller.adres.value,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 12,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget followButtons() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextButton(
                    onPressed: controller.followLoading.value
                        ? null
                        : () {
                            if (controller.takipEdiyorum.value == false) {
                              controller.toggleFollowStatus();
                            } else {
                              noYesAlert(
                                title: 'profile.unfollow_title'.tr,
                                message: 'profile.unfollow_body'.trParams({
                                  'nickname': controller.nickname.value,
                                }),
                                yesText: 'profile.unfollow_confirm'.tr,
                                onYesPressed: () {
                                  _setCenteredIndex(-1);
                                  controller.toggleFollowStatus();
                                },
                              );
                            }
                          },
                    style: TextButton.styleFrom(
                      backgroundColor: controller.takipEdiyorum.value
                          ? Colors.grey.withAlpha(50)
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: SizedBox(
                      height: 30,
                      child: Center(
                        child: controller.followLoading.value
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    controller.takipEdiyorum.value
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                controller.takipEdiyorum.value
                                    ? 'profile.following_status'.tr
                                    : 'profile.follow_button'.tr,
                                style: TextStyle(
                                  color: controller.takipEdiyorum.value
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 13,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final sohbet = chatListingController.list.firstWhereOrNull(
                      (val) => val.userID == widget.userID,
                    );
                    final prevIndex = controller.lastCenteredIndex;
                    controller.lastCenteredIndex = prevIndex;
                    controller.centeredIndex.value = -1;

                    if (sohbet != null) {
                      await Get.to(
                        () => ChatView(
                          chatID: sohbet.chatID,
                          userID: widget.userID,
                          isNewChat: false,
                          openKeyboard: true,
                        ),
                      );
                      controller.resumeCenteredPost();
                    } else {
                      final chatId = buildConversationId(
                        _myUserId,
                        widget.userID,
                      );
                      await Get.to(
                        () => ChatView(
                          chatID: chatId,
                          userID: widget.userID,
                          isNewChat: true,
                          openKeyboard: true,
                        ),
                      )?.then((_) {
                        chatListingController.getList();
                      });
                      controller.resumeCenteredPost();
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.withAlpha(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: SizedBox(
                    height: 30,
                    child: Center(
                      child: Text(
                        'common.message'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Obx(() {
                final showEmail = controller.mailIzin.value &&
                    controller.email.value.isNotEmpty;
                final showCall = controller.aramaIzin.value &&
                    controller.phoneNumber.value.isNotEmpty;
                final canContact = showEmail || showCall;
                return canContact
                    ? const SizedBox(width: 12)
                    : const SizedBox.shrink();
              }),
              Obx(() {
                final showEmail = controller.mailIzin.value &&
                    controller.email.value.isNotEmpty;
                final showCall = controller.aramaIzin.value &&
                    controller.phoneNumber.value.isNotEmpty;
                final canContact = showEmail || showCall;
                if (!canContact) return const SizedBox.shrink();
                return Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Get.bottomSheet(
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(100),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'profile.contact_options'.tr,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                                if (showEmail)
                                  TextButton(
                                    onPressed: () async {
                                      final mail = controller.email.value;
                                      final uri = Uri.parse('mailto:$mail');
                                      await launchUrl(uri);
                                      Get.back();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 12,
                                      ),
                                      backgroundColor:
                                          Colors.grey.withAlpha(50),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.mail,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            controller.email.value,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'MontserratBold',
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (showEmail && showCall)
                                  const SizedBox(height: 10),
                                if (showCall)
                                  TextButton(
                                    onPressed: () async {
                                      final tel = controller.phoneNumber.value;
                                      final uri = Uri.parse('tel:0$tel');
                                      await launchUrl(uri);
                                      Get.back();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 12,
                                      ),
                                      backgroundColor:
                                          Colors.grey.withAlpha(50),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.phone,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            '+90${controller.phoneNumber.value}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'MontserratBold',
                                              fontSize: 15,
                                              color: Colors.black,
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
                        isScrollControlled: true,
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.withAlpha(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: SizedBox(
                      height: 30,
                      child: Center(
                        child: Text(
                          'common.contact'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget unblockButton() {
    return Expanded(
      child: TextButton(
        onPressed: () {
          controller.unblock();
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.withAlpha(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              'profile.unblock'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageWithBorder() {
    final hasStories = controller.storyUserModel != null &&
        controller.storyUserModel!.stories.isNotEmpty;

    if (hasStories) {
      return Container(
        width: 91,
        height: 91,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00BCD4),
              Color(0xFF0097A7),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: SizedBox(
              width: 85,
              height: 85,
              child: CachedNetworkImage(
                imageUrl: controller.avatarUrl.value,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                    child: CupertinoActivityIndicator(color: Colors.black)),
              ),
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 85,
        height: 85,
        child: CachedNetworkImage(
          imageUrl: controller.avatarUrl.value,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => const Center(
              child: CupertinoActivityIndicator(color: Colors.black)),
        ),
      ),
    );
  }
}
