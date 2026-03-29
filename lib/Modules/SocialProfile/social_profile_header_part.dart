part of 'social_profile.dart';

extension _SocialProfileHeaderPart on _SocialProfileState {
  Widget header() {
    return Obx(() {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final isCompactHeader =
          MediaQuery.sizeOf(context).width < 390 || textScale > 1.2;
      return Column(
        children: [
          if (isCompactHeader) ...[
            Row(
              children: [
                Expanded(child: _buildHeaderIdentity()),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildHeaderActionsWrap(),
            ),
          ] else
            Row(
              children: [
                Expanded(child: _buildHeaderIdentity()),
                const SizedBox(width: 8),
                _buildHeaderActionsWrap(),
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

  Widget _buildHeaderIdentity() {
    return Row(
      children: [
        const AppBackButton(),
        8.pw,
        Expanded(
          child: GestureDetector(
            onTap: () {
              _setCenteredIndex(-1);
              Get.to(() => AboutProfile(userID: widget.userID))?.then((_) {
                controller.resumeCenteredPost();
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    controller.nickname.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: AppFontFamilies.mbold,
                    ),
                  ),
                ),
                if (widget.userID.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  RozetContent(
                    size: 15,
                    userID: widget.userID,
                    leftSpacing: 0,
                    rozetValue: controller.rozet.value,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionsWrap() {
    return Wrap(
      spacing: AppIconSurface.kGap,
      runSpacing: AppIconSurface.kGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        buildPostNotificationHeaderButton(),
        _buildHeaderOverflowButton(),
      ],
    );
  }

  Widget _buildHeaderOverflowButton() {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            final nick = normalizeNicknameInput(controller.nickname.value);
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
            final link = (result['url'] ?? '').toString().trim().isNotEmpty
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
              final nick = normalizeNicknameInput(controller.nickname.value);
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
              final link = (result['url'] ?? '').toString().trim().isNotEmpty
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
    );
  }

  Widget imageAndFollowButtons() {
    final storyUser = controller.storyUserModel;
    final hasStories = storyUser?.stories.isNotEmpty ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final isCompact =
            constraints.maxWidth < 390 || textScale > 1.2;
        final showActions = controller.complatedCheck.value;
        final profileImage = GestureDetector(
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
        );
        final actions = controller.complatedCheck.value &&
                !controller.isBlockedByCurrentViewer(widget.userID)
            ? followButtons()
            : controller.complatedCheck.value &&
                    controller.isBlockedByCurrentViewer(widget.userID)
                ? unblockButton()
                : const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileImage,
              if (showActions) ...[
                const SizedBox(width: 12),
                Expanded(child: actions),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplayName() {
    final name = controller.displayName.value.trim().isNotEmpty
        ? controller.displayName.value.trim()
        : "${controller.firstName.value} ${controller.lastName.value}".trim();
    if (name.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontFamily: "MontserratBold",
      ),
    );
  }

  Widget textInfoBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDisplayName(),
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
