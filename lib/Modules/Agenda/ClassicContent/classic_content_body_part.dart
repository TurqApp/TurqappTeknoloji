part of 'classic_content.dart';

extension ClassicContentBodyPart on _ClassicContentState {
  double get _captionFontSize =>
      Theme.of(context).platform == TargetPlatform.iOS ? 14 : 13;

  Widget textOnlyBody(BuildContext context) {
    final sanitizedCaption =
        _ClassicContentState._ctaNavigationService.sanitizeCaptionText(
      widget.model.metin,
      meta: widget.model.reshareMap,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onDoubleTap: () => controller.like(),
            onTap: () {
              if (widget.model.floodCount > 1) {
                Get.to(() => FloodListing(mainModel: widget.model));
              }
            },
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 0,
                  child: Text(
                    '“',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    sanitizedCaption,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: _captionFontSize,
                      height: 1.5,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 0,
                  child: Text(
                    '"',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                // SharedPostLabel - text içeriğinin sol altına
                if (widget.model.originalUserID.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 15,
                    child: SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      sourceUserID: widget.model.quotedPost
                          ? widget.model.quotedSourceUserID
                          : '',
                      labelSuffix: widget.model.quotedPost ? 'alıntılandı' : '',
                      fontSize: 12,
                      textColor: Colors.red,
                      showBackdrop: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: 58, child: Center(child: commentButton(context))),
              SizedBox(width: 58, child: Center(child: likeButton())),
              SizedBox(width: 58, child: Center(child: saveButton())),
              SizedBox(width: 58, child: Center(child: reshareButton())),
              SizedBox(width: 58, child: Center(child: statButton())),
              SizedBox(width: 58, child: Center(child: sendButton())),
            ],
          ),
        ),
        3.ph,
      ],
    );
  }

  Widget imgBody(BuildContext context) {
    final hasHeaderSubline = _ClassicContentState._ctaNavigationService
        .sanitizeCaptionText(
          widget.model.metin,
          meta: widget.model.reshareMap,
        )
        .isNotEmpty;
    final mediaTopSpacing = hasHeaderSubline ? 4.0 : 0.0;
    final actionTopSpacing = hasHeaderSubline ? 2.0 : 0.0;
    final mediaVisualLift = hasHeaderSubline ? 0.0 : -6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isIzBirakPost)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 0.92,
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      SizedBox.expand(
                        child: CachedNetworkImage(
                          imageUrl: widget.model.img.first,
                          fit: BoxFit.cover,
                          memCacheWidth: _feedCacheWidth,
                          memCacheHeight: _feedCacheHeightForAspectRatio(0.92),
                        ),
                      ),
                      _buildMediaTapOverlay(
                        onTap: _openImageMediaOrFeedCta,
                        onDoubleTap: controller.like,
                      ),
                      _buildIzBirakBlurOverlay(),
                      _buildIzBirakBottomBar(),
                      _buildClassicMediaHeader(),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (widget.model.img.length == 1)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: AspectRatio(
                aspectRatio: _resolvedClassicFrameAspectRatio,
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: widget.model.img.first,
                        fit: BoxFit.cover,
                        memCacheWidth: _feedCacheWidth,
                        memCacheHeight: _feedCacheHeightForAspectRatio(
                          _resolvedClassicFrameAspectRatio,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.model.floodCount > 1)
                              Texts.colorfulFlood,
                          ],
                        ),
                        const SizedBox(),
                      ],
                    ),
                    _buildClassicReshareOverlay(
                      bottom: widget.model.originalUserID.isNotEmpty
                          ? (widget.model.floodCount > 1 ? 52 : 34)
                          : (widget.model.floodCount > 1 ? 26 : 8),
                    ),
                    _buildFeedShareCta(),
                    _buildMediaTapOverlay(
                      onTap: _openImageMediaOrFeedCta,
                      onDoubleTap: controller.like,
                    ),
                    if (widget.model.originalUserID.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: widget.model.floodCount > 1 ? 26 : 8,
                        child: SharedPostLabel(
                          originalUserID: widget.model.originalUserID,
                          sourceUserID: widget.model.quotedPost
                              ? widget.model.quotedSourceUserID
                              : '',
                          labelSuffix:
                              widget.model.quotedPost ? 'alıntılandı' : '',
                          textColor: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    _buildClassicMediaHeader(),
                  ],
                ),
              ),
            ),
          )
        else
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: AspectRatio(
                aspectRatio: 1 / 1.2,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.model.img.length,
                      itemBuilder: (context, index) {
                        final img = widget.model.img[index];
                        return CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          memCacheWidth: _feedCacheWidth,
                          memCacheHeight: _feedCacheHeightForAspectRatio(
                            1 / 1.2,
                          ),
                        );
                      },
                    ),
                    if (widget.model.floodCount > 1)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Texts.colorfulFlood,
                        ),
                      ),
                    _buildClassicReshareOverlay(
                      bottom: widget.model.originalUserID.isNotEmpty
                          ? (widget.model.floodCount > 1 ? 60 : 34)
                          : (widget.model.floodCount > 1 ? 34 : 8),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            List.generate(widget.model.img.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 6 : 5,
                            height: isActive ? 6 : 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),
                    _buildFeedShareCta(),
                    _buildMediaTapOverlay(
                      onTap: _openImageMediaOrFeedCta,
                      onDoubleTap: controller.like,
                    ),
                    if (widget.model.originalUserID.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: widget.model.floodCount > 1 ? 34 : 8,
                        child: SharedPostLabel(
                          originalUserID: widget.model.originalUserID,
                          sourceUserID: widget.model.quotedPost
                              ? widget.model.quotedSourceUserID
                              : '',
                          labelSuffix:
                              widget.model.quotedPost ? 'alıntılandı' : '',
                          textColor: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    _buildClassicMediaHeader(),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: actionTopSpacing),
          child: _buildClassicActionRow(context),
        ),
        _buildClassicMetaSection(),
        3.ph,
      ],
    );
  }

  Widget buildPollCard() {
    return Obx(() {
      final model = controller.currentModel.value ?? widget.model;
      final poll = model.poll;
      if (poll.isEmpty) return const SizedBox.shrink();
      final options = (poll['options'] is List) ? poll['options'] as List : [];
      if (options.isEmpty) return const SizedBox.shrink();

      final totalVotes =
          (poll['totalVotes'] is num) ? poll['totalVotes'] as num : 0;
      final uid = controller.userService.userId;
      final userVotes = poll['userVotes'] is Map
          ? Map<String, dynamic>.from(poll['userVotes'])
          : <String, dynamic>{};
      final userVoteRaw = userVotes[uid];
      final int? userVote = userVoteRaw is num
          ? userVoteRaw.toInt()
          : int.tryParse('${userVoteRaw ?? ''}');

      final createdAt = (poll['createdDate'] ?? model.timeStamp) as num;
      final durationHours = (poll['durationHours'] ?? 24) as num;
      final expiresAt =
          createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
      final expired = DateTime.now().millisecondsSinceEpoch > expiresAt;
      final canVote = !expired && userVote == null;
      final showResults = userVote != null || expired;

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(options.length, (i) {
                final text = (options[i]['text'] ?? '').toString();
                final votes = (options[i]['votes'] ?? 0) as num;
                final pct = totalVotes > 0 ? (votes / totalVotes) : 0.0;
                final label = '${String.fromCharCode(65 + i)}) ';
                final isSelected = userVote == i;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canVote ? () => controller.votePoll(i) : null,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.blue.withAlpha(18) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$label$text',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (showResults)
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Toplam ${totalVotes.toInt()} oy',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _pollRemainingLabel(
                      expired: expired,
                      expiresAtMs: expiresAt,
                    ),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  Widget buildUploadIndicator() {
    final uploadService = Get.isRegistered<UploadQueueService>()
        ? Get.find<UploadQueueService>()
        : Get.put(UploadQueueService());

    return Obx(() {
      QueuedUpload? item;
      for (final q in uploadService.queue) {
        if (q.id == widget.model.docID &&
            (q.status == UploadStatus.pending ||
                q.status == UploadStatus.uploading)) {
          item = q;
          break;
        }
      }

      double? progress;
      if (item != null) {
        progress = item.progress;
      } else {
        final hasVideo = widget.model.hasPlayableVideo ||
            widget.model.video.trim().isNotEmpty ||
            widget.model.hlsMasterUrl.trim().isNotEmpty ||
            widget.model.thumbnail.trim().isNotEmpty;
        final hlsNotReady = widget.model.hlsStatus != 'ready' ||
            widget.model.hlsMasterUrl.trim().isEmpty;
        if (hasVideo && hlsNotReady) {
          final startMs = widget.model.hlsUpdatedAt > 0
              ? widget.model.hlsUpdatedAt.toInt()
              : widget.model.timeStamp.toInt();
          final elapsedMin =
              ((DateTime.now().millisecondsSinceEpoch - startMs) / 60000)
                  .clamp(0, 30);
          progress = 0.9 + (elapsedMin / 30) * 0.09;
        }
      }

      if (progress == null) return const SizedBox.shrink();
      if (progress <= 0) {
        progress = 0.02;
      }
      return RingUploadProgressIndicator(
        isUploading: true,
        progress: progress,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload,
            size: 12,
            color: Colors.black54,
          ),
        ),
      );
    });
  }

  String _pollRemainingLabel(
      {required bool expired, required int expiresAtMs}) {
    if (expired) return 'Süre Doldu';
    final remainingMs = expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 'Süre Doldu';
    final totalMinutes = (remainingMs / 60000).floor();
    final totalHours = (totalMinutes / 60).floor();
    final days = (totalHours / 24).floor();
    if (days >= 1) return '$days g';
    final hours = totalHours;
    final minutes = totalMinutes % 60;
    return '$hours sa $minutes dk';
  }

  Widget videoBody(BuildContext context) {
    final frameAspectRatio =
        _isIzBirakPost ? 0.92 : _resolvedClassicFrameAspectRatio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VisibilityDetector(
          key: Key('classic-media-${widget.model.docID}'),
          onVisibilityChanged: (info) {
            reportMediaVisibility(info.visibleFraction);
          },
          child: AspectRatio(
            aspectRatio: frameAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_shouldBlurIzBirakPost) ...[
                  _buildVideoThumbnail(aspectRatio: frameAspectRatio),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: buildUploadIndicator(),
                  ),
                ] else if (videoController != null) ...[
                  IgnorePointer(
                    ignoring: true,
                    child: _isFullscreen
                        ? const SizedBox.shrink()
                        : videoController!.buildPlayer(
                            key: ValueKey(
                                'classic-${widget.model.docID}-${videoController.hashCode}'),
                            aspectRatio: frameAspectRatio,
                            useAspectRatio: false,
                          ),
                  ),
                  // Thumbnail overlay - video hazır olana kadar göster
                  ValueListenableBuilder<HLSVideoValue>(
                    valueListenable: videoValueNotifier,
                    builder: (_, v, child) {
                      if (v.hasRenderedFirstFrame) {
                        return const SizedBox.shrink();
                      }
                      return child!;
                    },
                    child: AspectRatio(
                      aspectRatio: frameAspectRatio,
                      child: _buildVideoThumbnail(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: buildUploadIndicator(),
                  ),
                ] else
                  widget.model.thumbnail.isEmpty
                      ? const SizedBox.expand()
                      : _buildVideoThumbnail(),
                if (videoController == null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: buildUploadIndicator(),
                  ),

                // Süre göstergesi + Replay — sadece video state değiştiğinde rebuild
                if (videoController != null && !_shouldBlurIzBirakPost)
                  ValueListenableBuilder<HLSVideoValue>(
                    valueListenable: videoValueNotifier,
                    builder: (_, v, __) {
                      if (!v.isInitialized) return const SizedBox.shrink();
                      final remaining = v.duration - v.position;
                      final safeRemaining =
                          remaining.isNegative ? Duration.zero : remaining;
                      return Positioned(
                        top: 50,
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
                            _formatDuration(safeRemaining),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: "Montserrat",
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                if (videoController != null &&
                    !_shouldBlurIzBirakPost &&
                    widget.model.floodCount > 1)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Texts.colorfulFloodForVideo,
                  ),

                _buildClassicReshareOverlay(
                  bottom: widget.model.originalUserID.isNotEmpty
                      ? ((widget.model.floodCount > 1) ? 52 : 34)
                      : ((widget.model.floodCount > 1) ? 26 : 8),
                ),

                _buildMediaTapOverlay(
                  onTap: _openVideoMedia,
                  onDoubleTap: controller.like,
                ),
                if (widget.model.originalUserID.isNotEmpty)
                  Positioned(
                    left: 8,
                    bottom: (widget.model.floodCount > 1) ? 26 : 8,
                    child: SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      sourceUserID: widget.model.quotedPost
                          ? widget.model.quotedSourceUserID
                          : '',
                      labelSuffix: widget.model.quotedPost ? 'alıntılandı' : '',
                      textColor: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                _buildIzBirakBlurOverlay(),
                _buildIzBirakBottomBar(),
                if (!_isIzBirakPost)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        agendaController.isMuted.toggle();
                        final vc = videoController;
                        if (vc != null && vc.value.isInitialized) {
                          vc.setVolume(agendaController.isMuted.value ? 0 : 1);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Obx(() => Icon(
                              agendaController.isMuted.value
                                  ? CupertinoIcons.volume_off
                                  : CupertinoIcons.volume_up,
                              color: Colors.white,
                              size: 16,
                            )),
                      ),
                    ),
                  ),
                _buildClassicMediaHeader(),
              ],
            ),
          ),
        ),
        _buildClassicActionRow(context),
        _buildClassicMetaSection(),
      ],
    );
  }
}
