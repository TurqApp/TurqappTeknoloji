part of 'short_view.dart';

extension ShortViewUiPart on _ShortViewState {
  bool _hasThumbCandidate(PostsModel post, {String? overrideUrl}) {
    final resolvedUrl = (overrideUrl ?? post.thumbnail).trim();
    final fallbackImage = post.img.isNotEmpty ? post.img.first.trim() : '';
    if (resolvedUrl.isNotEmpty || fallbackImage.isNotEmpty) {
      return true;
    }
    return CdnUrlBuilder.buildThumbnailUrlCandidates(post.docID.trim())
        .isNotEmpty;
  }

  Widget _buildRefreshingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(color: Colors.white, radius: 10),
          SizedBox(width: 8),
          Text(
            'Yenileniyor...',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _cachedThumb(PostsModel post, {String? overrideUrl}) {
    final resolvedUrl = (overrideUrl ?? post.thumbnail).trim();
    final fallbackImage = post.img.isNotEmpty ? post.img.first.trim() : '';
    final candidates = <String>[
      if (resolvedUrl.isNotEmpty) resolvedUrl,
      if (fallbackImage.isNotEmpty && fallbackImage != resolvedUrl)
        fallbackImage,
      ...CdnUrlBuilder.buildThumbnailUrlCandidates(post.docID.trim()),
    ];
    if (candidates.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }
    return CacheFirstNetworkImage(
      imageUrl: candidates.first,
      candidateUrls: candidates.skip(1).toList(growable: false),
      cacheManager: TurqImageCacheManager.instance,
      fit: BoxFit.cover,
      fallback: const ColoredBox(color: Colors.black),
    );
  }

  Widget _buildThumbOverlay(int idx, String thumb, double modelAr) {
    if (!_hasThumbCandidate(_cachedShorts[idx], overrideUrl: thumb)) {
      return const ColoredBox(color: Colors.black);
    }
    if (modelAr > 1.2) {
      return Center(
        child: AspectRatio(
          aspectRatio: modelAr,
          child: _cachedThumb(_cachedShorts[idx], overrideUrl: thumb),
        ),
      );
    }
    return SizedBox.expand(
      child: _cachedThumb(_cachedShorts[idx], overrideUrl: thumb),
    );
  }

  void _reportStableShortFrameIfNeeded(
    int idx,
    HLSVideoAdapter adapter,
    bool hasStableVideoFrame,
  ) {
    if (!hasStableVideoFrame || idx != currentPage) return;
    if (_currentScrollToken.isEmpty) return;
    if (idx < 0 || idx >= _cachedShorts.length) return;
    final docId = _cachedShorts[idx].docID.trim();
    if (docId.isEmpty) return;
    final token = '$_currentScrollToken|$docId';
    if (_lastReportedStableFrameToken == token) return;
    _lastReportedStableFrameToken = token;
    final scrollToken = _currentScrollToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || idx != currentPage) return;
      recordQALabScrollEvent(
        surface: 'short',
        phase: 'stable_frame',
        metadata: <String, dynamic>{
          'docId': docId,
          'page': idx,
          'scrollToken': scrollToken,
          'positionMs': adapter.value.position.inMilliseconds,
          'isPlaying': adapter.value.isPlaying,
          'isBuffering': adapter.value.isBuffering,
          'hasRenderedFirstFrame': adapter.value.hasRenderedFirstFrame,
        },
      );
    });
  }

  Widget _buildFullscreenVideoSurface(
    HLSVideoAdapter adapter,
    String keyId, {
    double? modelAspectRatio,
  }) {
    final ar = (modelAspectRatio != null && modelAspectRatio > 0)
        ? modelAspectRatio
        : (9 / 16);

    final player = adapter.buildPlayer(
      key: ValueKey(keyId),
      useAspectRatio: false,
      forceFullscreenOnAndroid: true,
      suppressLoadingOverlay: true,
    );

    if (ar > 1.2) {
      return Center(
        child: AspectRatio(
          aspectRatio: ar,
          child: player,
        ),
      );
    }

    return SizedBox.expand(child: player);
  }

  Widget _buildShortView(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey(IntegrationTestKeys.screenShort),
        backgroundColor: Colors.black,
        body: Obx(() {
          final isRefreshingNow = controller.isRefreshing.value;
          final isLoadingNow = controller.isLoading.value;
          final hasMoreNow = controller.hasMore.value;

          final list = _cachedShorts;

          if (list.isEmpty) {
            if (isLoadingNow || hasMoreNow) {
              return const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'short.empty_title'.tr,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'short.empty_body'.tr,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }
          }

          if (currentPage >= list.length) {
            currentPage = (list.length - 1).clamp(0, list.length - 1);
            if (pageController.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (pageController.hasClients) {
                  pageController.jumpToPage(currentPage);
                }
              });
            }
          }

          if (!_didInitialAttach) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _primeInitialPlayback();
              }
            });
            _didInitialAttach = true;
          }

          final pager = PageView.builder(
            controller: pageController,
            scrollDirection: Axis.vertical,
            physics: const MomentumPageScrollPhysics(),
            itemCount: list.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, idx) {
              final vp = controller.cache[idx];
              final thumb = list[idx].thumbnail;
              final modelAr = list[idx].aspectRatio > 0
                  ? list[idx].aspectRatio.toDouble()
                  : (9 / 16);
              final isActivePage = idx == currentPage;
              final isWarmNeighbor = (idx - currentPage).abs() <= 1;

              if (vp == null) {
                if (isActivePage) {
                  _ensureActivePageAdapterAfterBuild(idx);
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [_buildThumbOverlay(idx, thumb, modelAr)],
                );
              }

              final videoWidget = isActivePage || isWarmNeighbor
                  ? IgnorePointer(
                      ignoring: !isActivePage,
                      child: AnimatedOpacity(
                        opacity: isActivePage ? 1 : 0.001,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: _buildFullscreenVideoSurface(
                          vp,
                          'vp-${list[idx].docID}-${vp.hashCode}',
                          modelAspectRatio: modelAr,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();

              return RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildThumbOverlay(idx, thumb, modelAr),
                    if (isActivePage || isWarmNeighbor) videoWidget,
                    if (isActivePage || isWarmNeighbor)
                      AnimatedBuilder(
                        animation: vp,
                        builder: (_, __) {
                          final value = vp.value;
                          final decision =
                              _shortPlaybackDecisionFor(idx, value);
                          _reportStableShortFrameIfNeeded(
                            idx,
                            vp,
                            decision.hasStableVisualFrame,
                          );
                          if (!_hasThumbCandidate(
                            list[idx],
                            overrideUrl: thumb,
                          )) {
                            return const SizedBox.shrink();
                          }
                          return IgnorePointer(
                            ignoring: true,
                            child: AnimatedOpacity(
                              opacity: decision.shouldHidePoster ? 0 : 1,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: _buildThumbOverlay(idx, thumb, modelAr),
                            ),
                          );
                        },
                      ),
                    if (isActivePage)
                      AnimatedBuilder(
                        animation: vp,
                        builder: (_, __) {
                          return const SizedBox.shrink();
                        },
                      ),
                    if (isActivePage)
                      ShortsContent(
                        model: list[idx],
                        isActive: isActivePage,
                        showOverlayControls: _showOverlayControls,
                        onToggleOverlay: () {
                          if (!mounted) return;
                          _updateShortViewState(() {
                            _showOverlayControls = !_showOverlayControls;
                          });
                        },
                        onDoubleTapLike: () async {
                          await PostRepository.ensure().toggleLike(list[idx]);
                        },
                        onSwipeRight: () async {
                          maybeFindNavBarController()?.changeIndex(0);
                        },
                        volumeOff: (v) {
                          if (v) {
                            vp.play();
                            isManuallyPaused = false;
                          } else {
                            vp.pause();
                            isManuallyPaused = true;
                          }
                          if (idx == currentPage) {
                            VideoTelemetryService.instance.updateRuntimeHints(
                              list[idx].docID,
                              isAudible: volume,
                              hasStableFocus: v,
                            );
                          }
                        },
                        videoPlayerController: vp,
                        onEdited: (updatedDocId) async {
                          await controller.updateShort(updatedDocId);
                          await controller.refreshVideoController(idx);
                          _updateShortViewState(() {});
                        },
                      ),
                    if (_showOverlayControls && isActivePage)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _ShortProgressBar(adapter: vp),
                      ),
                    if (_showOverlayControls)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const AppBackButton(
                                    icon: CupertinoIcons.arrow_left,
                                    key: ValueKey(
                                      IntegrationTestKeys.actionShortBack,
                                    ),
                                    iconColor: Colors.white,
                                    surfaceColor: Color(0x50000000),
                                  ),
                                  _buildCircleButton(
                                    icon: volume
                                        ? CupertinoIcons.volume_up
                                        : CupertinoIcons.volume_off,
                                    onTap: () {
                                      _updateShortViewState(
                                        () => volume = !volume,
                                      );
                                      _applyShortPlaybackPresentation(
                                        idx,
                                        vp,
                                      );
                                      if (idx == currentPage) {
                                        final decision =
                                            _shortPlaybackDecisionFor(
                                          idx,
                                          vp.value,
                                        );
                                        VideoTelemetryService.instance
                                            .updateRuntimeHints(
                                          list[idx].docID,
                                          isAudible: decision.shouldBeAudible,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );

          return Stack(
            children: [
              pager,
              IgnorePointer(
                ignoring: true,
                child: ShortsAdPlacementHook(index: currentPage),
              ),
              if (isRefreshingNow)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildRefreshingBadge(),
                  ),
                ),
              if (kDebugMode)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 60,
                  right: 8,
                  child: const CacheDebugOverlay(),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCircleButton({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(50),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ShortProgressBar extends StatelessWidget {
  final HLSVideoAdapter adapter;
  const _ShortProgressBar({required this.adapter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: adapter,
      builder: (_, __) {
        final v = adapter.value;
        if (!v.isInitialized || v.duration.inMilliseconds <= 0) {
          return const SizedBox.shrink();
        }
        final progress = v.position.inMilliseconds / v.duration.inMilliseconds;
        return LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 2,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        );
      },
    );
  }
}
