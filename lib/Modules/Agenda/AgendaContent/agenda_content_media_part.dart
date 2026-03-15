part of 'agenda_content.dart';

extension _AgendaContentMediaPart on _AgendaContentState {
  Widget _buildVideoThumbnail({double? aspectRatio}) {
    final thumb = widget.model.thumbnail.trim();
    final fallback = const ColoredBox(
      color: _AgendaContentState._videoFallbackColor,
    );
    final cacheHeight = aspectRatio != null
        ? _feedCacheHeightForAspectRatio(aspectRatio)
        : (_feedCacheWidth * 1.4).round();
    final image = thumb.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: thumb,
            fit: BoxFit.cover,
            memCacheWidth: _feedCacheWidth,
            memCacheHeight: cacheHeight,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          )
        : fallback;
    if (aspectRatio == null) return image;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: image,
    );
  }

  void _pauseFeedBeforeFullscreen() {
    try {
      videoController?.pause();
    } catch (_) {}
    try {
      videoStateManager.pauseAllVideos();
    } catch (_) {}
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

    final savedState = videoStateManager.getVideoState(widget.model.docID);
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

    if (candidates.isEmpty) {
      return [widget.model];
    }

    final ids = candidates.map((p) => p.docID).toSet().toList();
    final freshById = await PostRepository.ensure().fetchPostsByIds(
      ids,
      preferCache: true,
    );

    final refreshed = candidates
        .map((p) => freshById[p.docID] ?? p)
        .where((p) =>
            p.deletedPost == false &&
            p.arsiv == false &&
            p.gizlendi == false &&
            p.hasPlayableVideo)
        .toList();

    final tapped = freshById[widget.model.docID] ?? widget.model;
    final rest = refreshed.where((p) => p.docID != tapped.docID).toList()
      ..shuffle();

    return [tapped, ...rest];
  }

  bool _hasEducationFeedCta() {
    final resolved = _AgendaContentState._ctaNavigationService.resolveMeta(
      widget.model.reshareMap,
    );
    return resolved.type.isNotEmpty && resolved.docId.isNotEmpty;
  }

  Future<void> _openImageMediaOrFeedCta() async {
    if (_hasEducationFeedCta()) {
      await _AgendaContentState._ctaNavigationService.openFromPostMeta(
        widget.model.reshareMap,
      );
      return;
    }

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
          ));
    } else {
      if (widget.model.floodCount > 1) {
        Get.to(FloodListing(mainModel: widget.model));
      } else {
        Get.to(() => PhotoShorts(
              fetchedList: visibleList,
              startModel: widget.model,
            ));
      }
    }
  }

  Widget _buildImageContent(List<String> images) {
    if (_isIzBirakPost) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 0.92,
          child: _buildImage(
            images.first,
            radius: BorderRadius.circular(12),
            showShareCta: false,
          ),
        ),
      );
    }
    final type = _AgendaContentState._ctaNavigationService
        .resolveMeta(widget.model.reshareMap)
        .type;
    final preserveScholarshipFrame =
        type == 'scholarship' && widget.model.img.length == 1;
    final singleImageAspectRatio = preserveScholarshipFrame
        ? widget.model.aspectRatio.toDouble().clamp(0.65, 1.8)
        : 0.80;

    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: singleImageAspectRatio,
          child: _buildImage(images[0], radius: BorderRadius.circular(12)),
        );
      case 2:
        return _buildTwoImageGrid(images);
      case 3:
        return _buildThreeImageGrid(images);
      case 4:
      default:
        return buildFourImageGrid(widget.model.img);
    }
  }

  Widget buildFourImageGrid(List<String> images) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[0], radius: _getGridRadius(0)))),
            const SizedBox(width: 2),
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[1], radius: _getGridRadius(1)))),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[2], radius: _getGridRadius(2)))),
            const SizedBox(width: 2),
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[3], radius: _getGridRadius(3)))),
          ],
        ),
      ],
    );
  }

  Widget _buildThreeImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildImage(
                        images[1],
                        radius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: _buildImage(
                        images[2],
                        radius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTwoImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImage(
                  images[1],
                  radius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(
    String url, {
    required BorderRadius radius,
    bool showShareCta = true,
  }) {
    final safeUrl = url.trim();
    if (safeUrl.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: CachedNetworkImage(
              imageUrl: safeUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: _feedCacheWidth,
              memCacheHeight: (_feedCacheWidth * 1.4).round(),
              placeholder: (_, __) => const SizedBox.shrink(),
            ),
          ),
          if (widget.model.img.length == 1 && showShareCta)
            _buildFeedShareCta(),
        ],
      ),
    );
  }

  Widget _buildFeedShareCta() {
    if (_isIzBirakPost) {
      return const SizedBox.shrink();
    }
    final resolvedCta = _AgendaContentState._ctaNavigationService.resolveMeta(
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
        onTap: () => _AgendaContentState._ctaNavigationService
            .openFromPostMeta(widget.model.reshareMap),
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
            borderRadius: BorderRadius.circular(12),
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
              fontSize: 16,
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

  Future<void> _handleFeedUrlTap(String url) async {
    final handled = await _AgendaContentState._ctaNavigationService
        .openFromInternalUrl(url);
    if (handled) {
      return;
    }

    final uniqueKey = DateTime.now().millisecondsSinceEpoch.toString();
    await RedirectionLink().goToLink(url, uniqueKey: uniqueKey);
  }

  BorderRadius _getGridRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
      default:
        return BorderRadius.zero;
    }
  }
}
