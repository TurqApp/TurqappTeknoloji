part of 'classic_content.dart';

extension ClassicContentHeaderActionsPart on _ClassicContentState {
  Widget _buildClassicHeaderBackdrop({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: child,
        ),
      ),
    );
  }

  Widget headerUserInfoBar() {
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.nickname.value.trim();
    final handle = controller.nickname.value.trim().isNotEmpty
        ? controller.nickname.value.trim()
        : controller.username.value.trim();
    if (_avatarSyncLoggedHeaderDocIds.add(widget.model.docID)) {
      debugPrint(
        '[AvatarSync][feed_card_shell][${widget.model.docID}] '
        'stage=header_build elapsedMs=0 source=classic_header_user_info_bar '
        'metadata=${<String, dynamic>{
          'hasPrimaryName': primaryName.trim().isNotEmpty,
          'hasHandle': handle.trim().isNotEmpty,
          'hasAvatarUrl': controller.avatarUrl.value.trim().isNotEmpty,
          'userId': widget.model.userID,
        }}',
      );
    }
    String buildDisplayTime() => controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} ${'common.edited'.tr}"
        : timeAgoMetin(widget.model.timeStamp);
    void openProfile() {
      if (widget.model.userID != _currentUid) {
        final modelIndex = agendaController.agendaList
            .indexWhere((p) => p.docID == widget.model.docID);
        if (modelIndex >= 0) {
          agendaController.lastCenteredIndex = modelIndex;
        }
        agendaController.centeredIndex.value = -1;
        videoController?.pause();
        Get.to(() => SocialProfile(userID: widget.model.userID))?.then((v) {
          _restoreClassicFeedCenter();
        });
      }
    }

    return Transform.translate(
      offset: const Offset(0, -8),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _openAvatarStoryOrProfile,
              child: Obx(() => _buildClassicAvatar(
                    userId: widget.model.userID,
                    imageUrl: controller.avatarUrl.value,
                    radius: 20, // 40px diameter / 2
                  )),
            ),
            7.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: openProfile,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 24,
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          primaryName,
                                          overflow: TextOverflow.ellipsis,
                                          style: _classicPostNameStyle.copyWith(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      RozetContent(
                                        size: 13,
                                        userID: widget.model.userID,
                                        rozetValue: widget.model.rozet,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 6, right: 12),
                                        child: Obx(
                                          () {
                                            _relativeTimeTickService.tick.value;
                                            return Text(
                                              buildDisplayTime(),
                                              style: _classicPostMetaStyle
                                                  .copyWith(
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '@$handle',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _classicPostHandleStyle.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )),
                      ),
                      if (widget.model.userID != _currentUid)
                        Obx(() {
                          if (controller.isFollowing.value) {
                            return const SizedBox.shrink();
                          }
                          return Transform.translate(
                            offset: const Offset(0, -5),
                            child: SizedBox(
                              height: 24,
                              child: Center(
                                child: TextButton(
                                  onPressed: controller.followLoading.value
                                      ? null
                                      : () {
                                          controller.followUser();
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: controller.followLoading.value
                                      ? Container(
                                          height: 20,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(12)),
                                              border: Border.all(
                                                  color: Colors.black)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 15),
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.black),
                                              ),
                                            ),
                                          ),
                                        )
                                      : _buildClassicFollowButtonBlack(),
                                ),
                              ),
                            ),
                          );
                        }),
                      7.pw,
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: SizedBox(
                          height: 24,
                          child: Center(
                            child: pulldownmenu(Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.model.konum != "")
                    Text(
                      widget.model.konum,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _classicPostMetaStyle.copyWith(
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerUserInfoWhite() {
    final compact = Get.width < 380;
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.username.value.trim();
    final handle = controller.username.value.trim().isNotEmpty
        ? controller.username.value.trim()
        : controller.nickname.value.trim();
    String buildDisplayTime() => controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} ${'common.edited'.tr}"
        : timeAgoMetin(widget.model.timeStamp);
    void openProfile() {
      if (widget.model.userID != _currentUid) {
        final modelIndex = agendaController.agendaList
            .indexWhere((p) => p.docID == widget.model.docID);
        if (modelIndex >= 0) {
          agendaController.lastCenteredIndex = modelIndex;
        }
        agendaController.centeredIndex.value = -1;
        videoController?.pause();
        Get.to(() => SocialProfile(userID: widget.model.userID))?.then((v) {
          _restoreClassicFeedCenter();
        });
      }
    }

    final textShadow = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 10,
        offset: const Offset(0, 1),
      ),
    ];
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 8, bottom: 18),
        child: _buildClassicHeaderBackdrop(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _openAvatarStoryOrProfile,
                child: Obx(() => _buildClassicAvatar(
                      userId: widget.model.userID,
                      imageUrl: controller.avatarUrl.value,
                    )),
              ),
              7.pw,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: openProfile,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            primaryName,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                _classicPostNameStyle.copyWith(
                                              color: Colors.white,
                                              shadows: textShadow,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        _buildClassicWhiteBadge(13),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '@$handle',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _classicPostHandleStyle.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.92),
                                          shadows: textShadow,
                                        ),
                                      ),
                                      Obx(
                                        () {
                                          _relativeTimeTickService.tick.value;
                                          return Text(
                                            buildDisplayTime(),
                                            style:
                                                _classicPostMetaStyle.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                              shadows: textShadow,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        ),
                        if (widget.model.userID != _currentUid)
                          Obx(() {
                            if (controller.isFollowing.value) {
                              return const SizedBox.shrink();
                            }
                            if (compact) {
                              return const SizedBox.shrink();
                            }
                            return Transform.translate(
                              offset: const Offset(0, -5),
                              child: SizedBox(
                                height: 24,
                                child: Center(
                                  child: TextButton(
                                    onPressed: controller.followLoading.value
                                        ? null
                                        : () {
                                            controller.followUser();
                                          },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: _buildClassicOverlayFollowButton(
                                      loading: controller.followLoading.value,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        7.pw,
                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: SizedBox(
                            height: 24,
                            child: Center(
                              child: pulldownmenu(Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.model.konum != "")
                      Text(
                        widget.model.konum,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _classicPostMetaStyle.copyWith(
                          color: Colors.white,
                          shadows: textShadow,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
