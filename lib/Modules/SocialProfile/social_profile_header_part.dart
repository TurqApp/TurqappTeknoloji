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
              buildPostNotificationHeaderButton(),
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
                      const ReportUserNavigationService()
                          .openReportUser(
                        userId: widget.userID,
                        postId: "",
                      )
                          .then((_) {
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
          const SizedBox(height: 8),
          textInfoBody(),
          if (!controller.isBlockedByCurrentViewer(widget.userID))
            _buildLinksAndHighlightsRow(),
          Padding(padding: const EdgeInsets.only(top: 0), child: counters()),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
    final storyUser = controller.storyUserModel;
    final hasStories = storyUser?.stories.isNotEmpty ?? false;
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

              if (hasStories && storyUser != null) {
                try {
                  _setCenteredIndex(-1);
                  controller.lastCenteredIndex =
                      controller.currentVisibleIndex.value >= 0
                          ? controller.currentVisibleIndex.value
                          : controller.lastCenteredIndex;
                  Get.to(() => StoryViewer(
                      startedUser: storyUser,
                      storyOwnerUsers: [storyUser]))?.then((_) {
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
                  fontSize: 14,
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

  Widget _buildProfileImageWithBorder() {
    final hasStories = controller.storyUserModel?.stories.isNotEmpty ?? false;

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
          child: SizedBox(
            width: 85,
            height: 85,
            child: CachedUserAvatar(
              userId: widget.userID,
              imageUrl: controller.avatarUrl.value,
              radius: 42.5,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 85,
      height: 85,
      child: CachedUserAvatar(
        userId: widget.userID,
        imageUrl: controller.avatarUrl.value,
        radius: 42.5,
      ),
    );
  }
}
