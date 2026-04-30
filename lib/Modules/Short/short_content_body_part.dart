part of 'short_content.dart';

extension ShortsContentBodyPart on _ShortsContentState {
  String _formatShortProgressLabel(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  EdgeInsets _actionSurfaceOuterPadding(BuildContext context) {
    final viewBottom = MediaQuery.of(context).viewPadding.bottom;
    final safeBase = viewBottom > 8.0 ? viewBottom : 8.0;
    final adjustment = GetPlatform.isIOS ? 20.0 : 10.0;
    final bottomInset = safeBase > adjustment ? safeBase - adjustment : 0.0;
    return EdgeInsets.fromLTRB(12, 0, 12, bottomInset);
  }

  Widget _buildActionSurface({required Widget child}) {
    final surface = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.22),
          Colors.black.withValues(alpha: 0.36),
        ],
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.10),
      ),
    );
    final frameOffsetY = GetPlatform.isIOS ? -2.0 : 0.0;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: frameOffsetY,
            bottom: -frameOffsetY,
            child: IgnorePointer(
              child: DecoratedBox(decoration: surface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget userInfoBar(BuildContext context) {
    return Obx(() {
      return Container(
        color: Colors.white.withAlpha(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (videoPlayerController.value.isPlaying) {
                        videoPlayerController.pause();
                        volumeOff(false); // Manual pause bildirimi
                      } else {
                        resumeIfActive();
                        volumeOff(true); // Manual play bildirimi
                      }
                    },
                    child: ListenableBuilder(
                      listenable: videoPlayerController,
                      builder: (_, __) => Icon(
                        videoPlayerController.value.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: videoPlayerController,
                      builder: (_, __) {
                        final val = videoPlayerController.value;
                        final total = val.duration;
                        final progress =
                            val.position > total && total > Duration.zero
                                ? total
                                : val.position;
                        final buffered = val.buffered.isNotEmpty
                            ? val.buffered.last.end
                            : Duration.zero;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatShortProgressLabel(progress),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: AppFontFamilies.mmedium,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatShortProgressLabel(total),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: AppFontFamilies.mmedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ProgressBar(
                              thumbRadius: 3,
                              timeLabelLocation: TimeLabelLocation.none,
                              progress: progress,
                              total: total,
                              buffered: buffered,
                              onSeek: videoPlayerController.seekTo,
                              thumbColor: Colors.white,
                              progressBarColor: Colors.white,
                              baseBarColor: Colors.grey,
                              bufferedBarColor: Colors.white38,
                              barHeight: 2,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _openAvatarStoryOrProfile,
                            child: SizedBox(
                              width: 35,
                              height: 35,
                              child: CachedUserAvatar(
                                userId: model.userID,
                                imageUrl: controller.avatarUrl.value,
                                radius: 17.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _openAuthorProfile,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          controller.fullName.value,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: AppFontFamilies.mbold,
                                          ),
                                        ),
                                      ),
                                      RozetContent(
                                        size: 14,
                                        userID: model.userID,
                                        rozetValue: model.rozet,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    controller.nickname.value.trim().isEmpty
                                        ? ''
                                        : '@${controller.nickname.value.trim()}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: AppFontFamilies.mregular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 7),
                          if (!controller.takipEdiyorum.value &&
                              model.userID != _currentUserId)
                            Transform.translate(
                              offset: Offset(20, 0),
                              child: Obx(() {
                                final isLoading =
                                    controller.followLoading.value;
                                return ScaleTap(
                                  enabled: !isLoading,
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          controller.onlyFollowUserOneTime();
                                        },
                                  child: Container(
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(12)),
                                        border:
                                            Border.all(color: Colors.white)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CupertinoActivityIndicator(
                                                color: Colors.white,
                                                radius: 7,
                                              ),
                                            )
                                          : Text(
                                              'following.follow'.tr,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily:
                                                      AppFontFamilies.mmedium,
                                                  fontSize: FontSizes.size12),
                                            ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          Transform.translate(
                              offset: Offset(15, -12),
                              child: pulldownmenu(context))
                        ],
                      ),
                      ClickableTextContent(
                        fontSize: 13,
                        text: model.metin,
                        toggleExpandOnTextTap: true,
                        fontColor: Colors.white,
                        hashtagColor: Colors.white,
                        mentionColor: Colors.white,
                        urlColor: Colors.blue,
                        expandButtonColor: Colors.white,
                        expandButtonFontSize: 13,
                        onHashtagTap: (tag) {
                          videoPlayerController.pause();
                          Get.to(() => TagPosts(tag: tag))?.then((_) {
                            resumeIfActive();
                          });
                        },
                        onUrlTap: (v) async {
                          volumeOff(false);
                          final uniqueKey =
                              DateTime.now().millisecondsSinceEpoch.toString();
                          await RedirectionLink()
                              .goToLink(v, uniqueKey: uniqueKey);
                          volumeOff(true);
                        },
                        onMentionTap: (mention) {
                          (() async {
                            final targetUid =
                                await UsernameLookupRepository.ensure()
                                        .findUidForHandle(mention) ??
                                    "";
                            if (targetUid.isNotEmpty &&
                                targetUid != _currentUserId) {
                              volumeOff(false);
                              await const ProfileNavigationService()
                                  .openSocialProfile(targetUid);
                              volumeOff(true);
                            }
                          })();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: _actionSurfaceOuterPadding(context),
                  child: _buildActionSurface(child: butonlar(context)),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget gonderiGizlendi(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'post_state.hidden_title'.tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(
                    color: Colors.white,
                  ),
                ),
                7.ph,
                Text(
                  'post_state.hidden_body'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    controller.gizlemeyiGeriAl();
                    resumeIfActive();
                  },
                  child: Text(
                    'common.undo'.tr,
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                )
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'short.next_post'.tr,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'post_state.archived_title'.tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(color: Colors.white),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  'post_state.archived_body'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    controller.arsivdenCikart();
                    resumeIfActive();
                  },
                  child: Text(
                    'common.undo'.tr,
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                )
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'short.next_post'.tr,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'post_state.deleted_title'.tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(color: Colors.white),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  'post_state.deleted_body'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'short.next_post'.tr,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
