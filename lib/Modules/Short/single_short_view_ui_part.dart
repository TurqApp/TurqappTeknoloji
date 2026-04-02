// ignore_for_file: invalid_use_of_protected_member

part of 'single_short_view.dart';

extension SingleShortViewUiPart on _SingleShortViewState {
  Widget _buildSingleShortView(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _pauseAndPop();
        },
        child: Scaffold(
          key: const ValueKey(IntegrationTestKeys.screenSingleShort),
          backgroundColor: Colors.black,
          body: Obx(() {
            if (shorts.isEmpty) {
              return const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              );
            }
            return PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const MomentumPageScrollPhysics(),
              itemCount: shorts.length,
              onPageChanged: _handlePageChanged,
              itemBuilder: (_, idx) => _buildShortPage(idx),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildShortPage(int idx) {
    if (idx == _initialIndexForSeek &&
        _initialIndexForSeek != null &&
        widget.injectedController != null &&
        widget.injectedController!.value.isInitialized &&
        idx == currentPage) {
      return _buildInjectedShortPage(idx);
    }

    final thumb = shorts[idx].thumbnail;
    if (!_videoControllers.containsKey(idx)) {
      _ensureController(idx);
      return _buildLoadingShortPage(idx, thumb);
    }

    final vp = _videoControllers[idx]!;
    return _buildManagedShortPage(idx, thumb, vp);
  }

  Widget _buildInjectedShortPage(int idx) {
    final injected = widget.injectedController!;
    if (!_videoControllers.containsKey(idx)) {
      _videoControllers[idx] = injected;
      _externallyOwned.add(idx);
      _applySingleShortPlaybackPresentation(idx, injected);
    }
    final injThumb = shorts[idx].thumbnail;
    final injectedWidget = Stack(
      fit: StackFit.expand,
      children: [
        _buildFullscreenVideoSurface(
          injected,
          'injected-${shorts[idx].docID}-${injected.hashCode}',
          overrideAutoPlay: false,
          modelAspectRatio: shorts[idx].aspectRatio.toDouble(),
        ),
        AnimatedBuilder(
          animation: injected,
          builder: (_, __) {
            final v = injected.value;
            final decision = _singleShortPlaybackDecisionFor(idx, v);
            if (!_hasThumbCandidate(shorts[idx], overrideUrl: injThumb)) {
              return const SizedBox.shrink();
            }
            final thumb = shorts[idx].aspectRatio >= 0.8
                ? Align(
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: shorts[idx].aspectRatio > 1.2
                          ? shorts[idx].aspectRatio.toDouble()
                          : 1.0,
                      child: _cachedThumb(shorts[idx], overrideUrl: injThumb),
                    ),
                  )
                : SizedBox.expand(
                    child: _cachedThumb(shorts[idx], overrideUrl: injThumb));
            return IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: decision.shouldHidePoster ? 0 : 1,
                duration: AppDuration.thumbnailFadeOut,
                curve: Curves.easeOut,
                child: thumb,
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: injected,
          builder: (_, __) {
            return const SizedBox.shrink();
          },
        ),
      ],
    );
    return _buildStackForController(idx, injectedWidget, injected);
  }

  Widget _buildLoadingShortPage(int idx, String thumb) {
    final loadingThumbAr = shorts[idx].aspectRatio.toDouble();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasThumbCandidate(shorts[idx], overrideUrl: thumb))
          if (loadingThumbAr >= 0.8)
            Center(
              child: AspectRatio(
                aspectRatio: loadingThumbAr > 1.2 ? loadingThumbAr : 1.0,
                child: _cachedThumb(shorts[idx], overrideUrl: thumb),
              ),
            )
          else
            _cachedThumb(shorts[idx], overrideUrl: thumb)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildManagedShortPage(int idx, String thumb, HLSVideoAdapter vp) {
    final isNear = (idx - currentPage).abs() <= 2;
    final thumbAr = shorts[idx].aspectRatio.toDouble();
    final videoWidget = !isNear
        ? Stack(
            fit: StackFit.expand,
            children: [
              if (_hasThumbCandidate(shorts[idx], overrideUrl: thumb))
                if (thumbAr >= 0.8)
                  Center(
                    child: AspectRatio(
                      aspectRatio: thumbAr > 1.2 ? thumbAr : 1.0,
                      child: _cachedThumb(shorts[idx], overrideUrl: thumb),
                    ),
                  )
                else
                  _cachedThumb(shorts[idx], overrideUrl: thumb),
            ],
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              _buildFullscreenVideoSurface(
                vp,
                'vp-${shorts[idx].docID}-${vp.hashCode}',
                modelAspectRatio: shorts[idx].aspectRatio.toDouble(),
              ),
              AnimatedBuilder(
                animation: vp,
                builder: (_, __) {
                  final v = vp.value;
                  final decision = _singleShortPlaybackDecisionFor(idx, v);
                  if (!_hasThumbCandidate(shorts[idx], overrideUrl: thumb)) {
                    return const SizedBox.shrink();
                  }
                  final overlay = shorts[idx].aspectRatio >= 0.8
                      ? Align(
                          alignment: Alignment.center,
                          child: AspectRatio(
                            aspectRatio: shorts[idx].aspectRatio > 1.2
                                ? shorts[idx].aspectRatio.toDouble()
                                : 1.0,
                            child:
                                _cachedThumb(shorts[idx], overrideUrl: thumb),
                          ),
                        )
                      : SizedBox.expand(
                          child: _cachedThumb(shorts[idx], overrideUrl: thumb));
                  return IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      opacity: decision.shouldHidePoster ? 0 : 1,
                      duration: AppDuration.thumbnailFadeOut,
                      curve: Curves.easeOut,
                      child: overlay,
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: vp,
                builder: (_, __) {
                  return const SizedBox.shrink();
                },
              ),
            ],
          );

    return _buildStackForController(idx, videoWidget, vp);
  }

  Widget _buildStackForController(
    int idx,
    Widget videoWidget,
    HLSVideoAdapter vp,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        videoWidget,
        if (showControls && idx == currentPage)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SingleShortProgressBar(adapter: vp),
          ),
        ShortsContent(
          model: shorts[idx],
          isActive: idx == currentPage,
          showOverlayControls: showControls,
          onToggleOverlay: () {
            if (!mounted) return;
            setState(() {
              showControls = !showControls;
            });
          },
          onDoubleTapLike: () async {
            if (idx < 0 || idx >= shorts.length) return;
            await PostRepository.ensure().toggleLike(shorts[idx]);
          },
          onSwipeRight: () async {
            await _pauseAndPop(preferredIndex: idx, preferredController: vp);
          },
          volumeOff: (volume) {
            if (!volume) {
              _playbackExecutionService.pauseAdapter(vp);
              if (idx == currentPage) {
                _updateTelemetryHintsForCurrentPage(
                  isAudible: this.volume,
                  hasStableFocus: false,
                );
              }
              return;
            }
            if (idx == currentPage && idx < shorts.length) {
              _applySingleShortPlaybackPresentation(idx, vp);
              final decision = _singleShortPlaybackDecisionFor(idx, vp.value);
              _updateTelemetryHintsForCurrentPage(
                isAudible: decision.shouldBeAudible,
                hasStableFocus: true,
              );
              _requestExclusivePlayback(shorts[idx].docID);
            }
          },
          videoPlayerController: vp,
        ),
        if (showControls)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppBackButton(
                        icon: CupertinoIcons.arrow_left,
                        iconColor: Colors.white,
                        surfaceColor: const Color(0x50000000),
                        onTap: () async {
                          await _pauseAndPop();
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTopCircleButton(
                            icon: volume
                                ? CupertinoIcons.volume_up
                                : CupertinoIcons.volume_off,
                            onTap: () => setState(() {
                              volume = !volume;
                              final ctrl = _videoControllers[currentPage];
                              if (ctrl != null) {
                                _applySingleShortPlaybackPresentation(
                                  currentPage,
                                  ctrl,
                                );
                                final decision =
                                    _singleShortPlaybackDecisionFor(
                                  currentPage,
                                  ctrl.value,
                                );
                                _updateTelemetryHintsForCurrentPage(
                                  isAudible: decision.shouldBeAudible,
                                );
                              } else {
                                _updateTelemetryHintsForCurrentPage(
                                  isAudible: false,
                                );
                              }
                            }),
                          ),
                          if (shorts[idx].floodCount > 1)
                            IconButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(36, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.black.withAlpha(50),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  if (vp.value.isInitialized) {
                                    await _playbackExecutionService
                                        .pauseAdapter(
                                      vp,
                                    );
                                  }
                                } catch (_) {}
                                await Get.to(
                                    () => FloodListing(mainModel: shorts[idx]));
                                if (!mounted) return;
                                if (idx == currentPage) {
                                  try {
                                    _applySingleShortPlaybackPresentation(
                                      idx,
                                      vp,
                                    );
                                    final decision =
                                        _singleShortPlaybackDecisionFor(
                                      idx,
                                      vp.value,
                                    );
                                    _updateTelemetryHintsForCurrentPage(
                                      isAudible: decision.shouldBeAudible,
                                      hasStableFocus: false,
                                    );
                                    _requestExclusivePlayback(
                                      shorts[idx].docID,
                                    );
                                  } catch (_) {}
                                }
                              },
                              icon: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [Colors.white, Colors.blue],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(
                                  Rect.fromLTWH(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                ),
                                blendMode: BlendMode.srcIn,
                                child: Text(
                                  "${shorts[idx].floodCount} ${'saved_posts.series_badge'.tr}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pauseAndPop({
    int? preferredIndex,
    HLSVideoAdapter? preferredController,
  }) async {
    final preserveController = _resolveFullscreenReturnPreservedController(
      preferredIndex: preferredIndex,
      preferredController: preferredController,
    );
    _fullscreenReturnPreservedController = preserveController;
    try {
      _playbackRuntimeService.exitExclusiveMode();
    } catch (_) {}
    await _pauseAllControllers(preserveController: preserveController);
    if (!mounted) return;
    Navigator.of(context).pop(
      _buildPopResult(
        preferredIndex: preferredIndex,
        preferredController: preferredController,
      ),
    );
  }

  Map<String, Object?> _buildPopResult({
    int? preferredIndex,
    HLSVideoAdapter? preferredController,
  }) {
    final idx = preferredIndex ??
        (widget.startModel != null
            ? shorts.indexWhere((p) => p.docID == widget.startModel!.docID)
            : currentPage);
    final ctrl =
        preferredController ?? (idx >= 0 ? _videoControllers[idx] : null);
    final docID = widget.startModel?.docID ??
        (shorts.isNotEmpty && currentPage >= 0 && currentPage < shorts.length
            ? shorts[currentPage].docID
            : null);
    final pos = (ctrl != null && ctrl.value.isInitialized)
        ? ctrl.value.position
        : Duration.zero;
    return {
      'docID': docID,
      'positionMs': pos.inMilliseconds,
    };
  }

  Widget _buildTopCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(50),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
