part of 'agenda_content.dart';

extension _AgendaContentQuotePart on _AgendaContentState {
  void _refreshQuotedSourceFuture() {
    final sourceUserId = widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.originalUserID.trim();
    final sourcePostId = widget.model.originalPostID.trim();

    _quotedSourceFutureUserId = sourceUserId;
    _quotedSourceFuturePostId = sourcePostId;

    if (sourceUserId.isEmpty) {
      _quotedSourceFuture = null;
      return;
    }

    final profileCache = ensureUserProfileCacheService();
    final postRepository = PostRepository.ensure();

    _quotedSourceFuture = Future.wait<dynamic>([
      profileCache.getProfile(
        sourceUserId,
        preferCache: true,
        cacheOnly: false,
      ),
      if (sourcePostId.isNotEmpty)
        postRepository.fetchPostCardsByIds([sourcePostId])
      else
        Future.value(null),
    ]);
  }

  Widget _buildQuotedMainBody({required double actionTopSpacing}) {
    final hasOwnCaption = widget.model.metin.trim().isNotEmpty;
    final quoteCardTopSpacing = hasOwnCaption ? 8.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        if (widget.model.konum != "")
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 40),
            child: Row(
              children: [
                Icon(CupertinoIcons.map_pin, color: Colors.red, size: 20),
                const SizedBox(width: 3),
                Text(
                  widget.model.konum,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding:
              EdgeInsets.only(top: quoteCardTopSpacing, left: 45, right: 8),
          child: _buildAgendaQuoteCard(),
        ),
        Padding(
          padding: EdgeInsets.only(top: actionTopSpacing),
          child: Obx(() {
            final currentUser = controller.userService.currentUserRx.value;
            final me = currentUser?.userID.trim().isNotEmpty == true
                ? currentUser!.userID.trim()
                : controller.userService.effectiveUserId.trim();
            if (me.isEmpty) return const SizedBox.shrink();
            return Transform.translate(
              offset: const Offset(17, 0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionSlot(
                      commentButton(context),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      likeButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      reshareButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      statButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      saveButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(sendButton()),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAgendaQuoteCard() {
    final quotedText = widget.model.quotedOriginalText.trim();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openQuotedOriginalPost,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9DEE5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAgendaQuotedSourceHeader(),
                  if (quotedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      quotedText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3A434D),
                        fontSize: 13,
                        height: 1.35,
                        fontFamily: "Montserrat",
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.model.hasPlayableVideo)
              _buildAgendaQuotedVideoPreview()
            else if (widget.model.img.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildQuotedImageContent(widget.model.img),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaQuotedSourceHeader() {
    final sourceUserId = _quotedSourceFutureUserId;
    final sourcePostId = _quotedSourceFuturePostId;
    final future = _quotedSourceFuture;
    if (sourceUserId.isEmpty || future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final profile = (snapshot.data != null && snapshot.data!.isNotEmpty
                ? snapshot.data!.first
                : null) as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final sourcePostMap = snapshot.data != null && snapshot.data!.length > 1
            ? snapshot.data![1] as Map<String, PostsModel>?
            : null;
        final sourcePostData =
            sourcePostMap?[sourcePostId]?.toMap() ?? const <String, dynamic>{};
        String firstNonEmpty(List<dynamic> values, [String fallback = '']) {
          for (final value in values) {
            final text = (value ?? '').toString().trim();
            if (text.isNotEmpty) return text;
          }
          return fallback;
        }

        final username = firstNonEmpty([
          widget.model.quotedSourceUsername,
          profile['username'],
          sourcePostData['username'],
          sourcePostData['authorNickname'],
          profile['nickname'],
        ]);
        final displayName = firstNonEmpty([
          widget.model.quotedSourceDisplayName,
          profile['displayName'],
          profile['fullName'],
          profile['name'],
          sourcePostData['displayName'],
          sourcePostData['authorDisplayName'],
          sourcePostData['fullName'],
          sourcePostData['authorNickname'],
          sourcePostData['nickname'],
          profile['nickname'],
          profile['username'],
        ], username.isNotEmpty ? username : 'common.user'.tr);
        final avatarUrl = (widget.model.quotedSourceAvatarUrl.isNotEmpty
                ? widget.model.quotedSourceAvatarUrl
                : (profile['avatarUrl'] ??
                    sourcePostData['authorAvatarUrl'] ??
                    ''))
            .toString()
            .trim();
        final quotedTime = ((sourcePostData['izBirakYayinTarihi'] ??
                    sourcePostData['timeStamp']) ??
                0)
            .toString();
        final timeStamp =
            num.tryParse(quotedTime) ?? (sourcePostData['timeStamp'] ?? 0);
        final displayTime =
            timeStamp == 0 ? '' : timeAgoMetin(timeStamp).toString();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CachedUserAvatar(
              userId: sourceUserId,
              imageUrl: avatarUrl,
              radius: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName.isEmpty ? 'common.user'.tr : displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  RozetContent(size: 13, userID: sourceUserId),
                  if (displayTime.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        displayTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuotedImageContent(List<String> images) {
    final outerRadius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: outerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildQuotedImageGrid(images),
    );
  }

  Widget _buildQuotedImageGrid(List<String> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 0.80,
          child: _buildImage(
            images[0],
            radius: BorderRadius.circular(12),
            showShareCta: false,
          ),
        );
      case 2:
        return _buildTwoImageGrid(images);
      case 3:
        return _buildThreeImageGrid(images);
      case 4:
      default:
        return buildFourImageGrid(images);
    }
  }

  Widget _buildAgendaQuotedVideoPreview() {
    final thumb = widget.model.thumbnail.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 0.80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(
                    color: _AgendaContentState._videoFallbackColor,
                  ),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: _AgendaContentState._videoFallbackColor,
                  ),
                )
              else
                const ColoredBox(
                  color: _AgendaContentState._videoFallbackColor,
                ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(
                      videoController?.value.duration ?? Duration.zero,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQuotedOriginalPost() async {
    final originalPostId = widget.model.originalPostID.trim();
    if (originalPostId.isEmpty) {
      AppSnackbar('common.info'.tr, 'post.source_unavailable'.tr);
      return;
    }

    try {
      final model = await PostRepository.ensure().fetchPostById(
        originalPostId,
        preferCache: true,
      );

      if (model == null) {
        AppSnackbar('common.info'.tr, 'post.source_unavailable'.tr);
        return;
      }
      if (model.deletedPost) {
        AppSnackbar('common.info'.tr, 'post.source_deleted'.tr);
        return;
      }

      if (model.floodCount > 1) {
        _suspendAgendaFeedForRoute();
        await Get.to(() => FloodListing(mainModel: model));
        _restoreAgendaFeedCenter();
        return;
      }

      _suspendAgendaFeedForRoute();
      try {
        videoStateManager.pauseAllVideos(force: true);
      } catch (_) {}
      try {
        agendaController.pauseAll.value = false;
      } catch (_) {}
      await Get.to(() => SinglePost(model: model, showComments: false));
      _restoreAgendaFeedCenter();
    } catch (_) {
      AppSnackbar('common.info'.tr, 'post.source_unavailable'.tr);
    }
  }

  Future<
      ({
        String userId,
        String displayName,
        String username,
        String avatarUrl
      })> _resolveQuotedSourceSnapshot() async {
    String pick(List<dynamic> values, [String fallback = '']) {
      for (final value in values) {
        final text = (value ?? '').toString().trim();
        if (text.isNotEmpty) return text;
      }
      return fallback;
    }

    final sourceUserId = widget.model.quotedPost &&
            widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.userID.trim();

    String displayName = widget.model.quotedPost &&
            widget.model.quotedSourceDisplayName.trim().isNotEmpty
        ? widget.model.quotedSourceDisplayName.trim()
        : pick([
            controller.fullName.value,
            controller.nickname.value,
            controller.username.value,
            widget.model.authorNickname,
          ]);
    String username = widget.model.quotedPost &&
            widget.model.quotedSourceUsername.trim().isNotEmpty
        ? widget.model.quotedSourceUsername.trim()
        : pick([
            controller.username.value,
            controller.nickname.value,
            widget.model.authorNickname,
          ]);
    String avatarUrl = widget.model.quotedPost &&
            widget.model.quotedSourceAvatarUrl.trim().isNotEmpty
        ? widget.model.quotedSourceAvatarUrl.trim()
        : controller.avatarUrl.value.trim();

    if (sourceUserId.isNotEmpty) {
      try {
        final profileCache = ensureUserProfileCacheService();
        final profile = (await profileCache.getProfile(
              sourceUserId,
              preferCache: true,
              cacheOnly: false,
            )) ??
            const <String, dynamic>{};
        displayName = pick([
          displayName,
          profile['displayName'],
          profile['fullName'],
          profile['name'],
          profile['nickname'],
          profile['username'],
        ], displayName);
        username = pick([
          username,
          profile['username'],
          profile['nickname'],
        ], username);
        final resolvedAvatar = resolveAvatarUrl(profile).trim();
        if (resolvedAvatar.isNotEmpty &&
            resolvedAvatar != kDefaultAvatarUrl &&
            avatarUrl.trim().isEmpty) {
          avatarUrl = resolvedAvatar;
        }
      } catch (_) {}
    }

    return (
      userId: sourceUserId,
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
    );
  }
}
