part of 'classic_content.dart';

extension _ClassicContentMediaPart on _ClassicContentState {
  Widget _buildVideoPosterFallback({double? aspectRatio}) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFE8ECF1),
            Color(0xFFDCE2E8),
            Color(0xFFCDD5DD),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
    if (aspectRatio == null) return fallback;
    return AspectRatio(aspectRatio: aspectRatio, child: fallback);
  }

  Widget _buildVideoThumbnail({double? aspectRatio}) {
    final thumb = widget.model.preferredVideoPosterUrl.trim();
    final fallback = _buildVideoPosterFallback(aspectRatio: aspectRatio);
    final cacheHeight = aspectRatio != null
        ? _feedCacheHeightForAspectRatio(aspectRatio)
        : (_feedCacheWidth * 1.4).round();
    final image = thumb.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: thumb,
            cacheManager: TurqImageCacheManager.instance,
            fit: BoxFit.cover,
            memCacheWidth: _feedCacheWidth,
            memCacheHeight: cacheHeight,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          )
        : fallback;
    if (aspectRatio == null) return image;
    return image;
  }

  void _pauseFeedBeforeFullscreen() {
    try {
      videoController?.pause();
    } catch (_) {}
    try {
      playbackRuntimeService.pauseAll();
    } catch (_) {}
  }

  void _openImageMedia() {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.lastCenteredIndex = modelIndex;
    }
    agendaController.centeredIndex.value = -1;
    _pauseFeedBeforeFullscreen();
    final visibleList = agendaController.agendaList
        .where((val) =>
            val.deletedPost == false &&
            val.arsiv == false &&
            val.gizlendi == false &&
            val.img.isNotEmpty)
        .toList();

    if (widget.isPreview) {
      Get.to(() => PhotoShorts(
            fetchedList: visibleList,
            startModel: widget.model,
          ))?.then((_) => _restoreClassicFeedCenter());
    } else if (widget.model.floodCount > 1) {
      Get.to(() => FloodListing(mainModel: widget.model))
          ?.then((_) => _restoreClassicFeedCenter());
    } else {
      Get.to(() => PhotoShorts(
            fetchedList: visibleList,
            startModel: widget.model,
          ))?.then((_) => _restoreClassicFeedCenter());
    }
  }

  bool _hasEducationFeedCta() {
    final resolved = _ClassicContentState._ctaNavigationService.resolveMeta(
      widget.model.reshareMap,
    );
    return resolved.type.isNotEmpty && resolved.docId.isNotEmpty;
  }

  Future<void> _openImageMediaOrFeedCta() async {
    if (_hasEducationFeedCta()) {
      await _ClassicContentState._ctaNavigationService.openFromPostMeta(
        widget.model.reshareMap,
      );
      return;
    }
    _openImageMedia();
  }

  void _prepareVideoFullscreenTransition() {
    markSkipNextPause();
  }

  Future<Duration> _resolveCurrentVideoPosition() async {
    final vc = videoController;
    if (vc != null) {
      try {
        final pos = vc.value.position;
        if (pos > Duration.zero) return pos;
      } catch (_) {}

      try {
        final seconds = await vc.hlsController.getCurrentTime();
        if (seconds > 0) {
          return Duration(milliseconds: (seconds * 1000).round());
        }
      } catch (_) {}
    }

    final savedState =
        playbackRuntimeService.getSavedPlaybackState(playbackHandleKey);
    return savedState?.position ?? Duration.zero;
  }

  Future<List<PostsModel>> _buildFullscreenStartList() async {
    final candidates = agendaController.agendaList
        .where((p) =>
            p.deletedPost == false &&
            p.arsiv == false &&
            p.gizlendi == false &&
            p.hasPlayableVideo)
        .toList();

    if (candidates.isEmpty) return [widget.model];

    final ids = candidates.map((p) => p.docID).toList();
    final fetched = await _postRepository.fetchPostCardsByIds(ids);
    final freshById = <String, PostsModel>{};
    fetched.forEach((key, model) {
      if (model.deletedPost == false &&
          model.arsiv == false &&
          model.gizlendi == false &&
          model.hasPlayableVideo) {
        freshById[key] = model;
      }
    });

    final List<PostsModel> ordered = candidates
        .map<PostsModel>((p) => freshById[p.docID] ?? p)
        .where((p) => p.hasPlayableVideo)
        .toList();

    if (ordered.any((p) => p.docID == widget.model.docID)) {
      return ordered;
    }
    return [widget.model, ...ordered];
  }

  Future<void> _openVideoMedia() async {
    if (_shouldBlurIzBirakPost) {
      videoController?.pause();
      return;
    }
    if (widget.model.floodCount > 1) {
      final modelIndex = agendaController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (modelIndex >= 0) {
        agendaController.lastCenteredIndex = modelIndex;
      }
      agendaController.centeredIndex.value = -1;
      videoController?.pause();
      await Get.to(() => FloodListing(mainModel: widget.model));
      _restoreClassicFeedCenter();
      return;
    }

    final currentPos = await _resolveCurrentVideoPosition();
    final listForFullscreen = await _buildFullscreenStartList();

    _prepareVideoFullscreenTransition();
    _pauseFeedBeforeFullscreen();
    setPauseBlocked(true);
    if (mounted) {
      _setFullscreen(true);
    }

    final res = await Get.to(() => SingleShortView(
          startModel: widget.model,
          startList: listForFullscreen,
          initialPosition: currentPos,
          injectedController: videoController,
        ));

    setPauseBlocked(false);
    if (mounted) {
      _setFullscreen(false);
    }

    if (!mounted) return;

    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.centeredIndex.value = modelIndex;
      agendaController.lastCenteredIndex = modelIndex;
    }

    final vc = videoController;
    if (vc != null && vc.value.isInitialized) {
      if (res is Map && res['docID'] == widget.model.docID) {
        final int? ms = res['positionMs'] as int?;
        if (ms != null) {
          await vc.seekTo(Duration(milliseconds: ms));
          if (widget.shouldPlay) {
            vc.play();
            vc.setVolume(agendaController.isMuted.value ? 0 : 1);
          }
          return;
        }
      }
      if (widget.shouldPlay) {
        tryAutoPlayWhenBuffered();
      }
    }
  }

  Widget _buildMediaTapOverlay({
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
  }) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildClassicReshareOverlay({required double bottom}) {
    if (!widget.isReshared || widget.model.originalUserID.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 8,
      bottom: bottom,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  ReshareAttribution(
                    controller: controller,
                    model: widget.model,
                    explicitReshareUserId: widget.reshareUserID,
                    style: AppTypography.postAttribution.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedShareCta() {
    if (_isIzBirakPost) {
      return const SizedBox.shrink();
    }
    final resolvedCta = _ClassicContentState._ctaNavigationService.resolveMeta(
      widget.model.reshareMap,
    );
    final label = resolvedCta.label;
    final type = resolvedCta.type;
    final docId = resolvedCta.docId;
    if (label.isEmpty || type.isEmpty || docId.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = _feedCtaPaletteFor(type: type, docId: docId);

    return Positioned(
      right: 10,
      bottom: 10,
      child: GestureDetector(
        onTap: () => _ClassicContentState._ctaNavigationService
            .openFromPostMeta(widget.model.reshareMap),
        child: Container(
          width: 106,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: palette.last.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _feedCtaPaletteFor({
    required String type,
    required String docId,
  }) {
    const palettes = <List<Color>>[
      <Color>[Color(0xFF20D67B), Color(0xFF119D57)],
      <Color>[Color(0xFFFF5CA8), Color(0xFFD81B60)],
      <Color>[Color(0xFFFFB238), Color(0xFFF26B1D)],
      <Color>[Color(0xFF2EC5FF), Color(0xFF0077D9)],
      <Color>[Color(0xFFB56CFF), Color(0xFF7B2CFF)],
    ];
    final seed = '$type:$docId'.codeUnits.fold<int>(0, (a, b) => a + b);
    return palettes[seed % palettes.length];
  }
}
