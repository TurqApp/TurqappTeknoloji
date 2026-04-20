part of 'short_view.dart';

extension ShortViewUiPart on _ShortViewState {
  List<String> _resolvePendingShortPreviewUrls(PostsModel model) {
    final candidates = <String>[
      model.thumbnail.trim(),
      ...model.preferredVideoPosterUrls.map((url) => url.trim()),
      ...model.img.map((url) => url.trim()),
      ...CdnUrlBuilder.buildThumbnailUrlCandidates(model.docID),
    ]
        .map(CdnUrlBuilder.toCdnUrl)
        .where((url) => url.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    return candidates;
  }

  Widget _buildPendingShortSurface(PostsModel model) {
    final previewUrls = _resolvePendingShortPreviewUrls(model);
    assert(() {
      debugPrint(
        '[ShortPendingSurface] doc=${model.docID} '
        'previewCount=${previewUrls.length} '
        'preview=${previewUrls.isEmpty ? '' : previewUrls.first}',
      );
      return true;
    }());
    if (previewUrls.isEmpty) {
      return const SizedBox.expand(
        child: ColoredBox(color: Colors.black),
      );
    }
    return SizedBox.expand(
      child: CacheFirstNetworkImage(
        imageUrl: previewUrls.first,
        candidateUrls: previewUrls.skip(1).toList(growable: false),
        cacheManager: TurqImageCacheManager.instance,
        fit: BoxFit.cover,
        fallback: const ColoredBox(color: Colors.black),
      ),
    );
  }

  void _reportStableShortFrameIfNeeded(
    int idx,
    HLSVideoAdapter adapter,
    bool hasStableVideoFrame,
  ) {
    if (!hasStableVideoFrame || idx != currentPage) return;
    _forceResumePosterOnReturn = false;
    if (_currentScrollToken.isEmpty) return;
    if (idx < 0 || idx >= _cachedShorts.length) return;
    final docId = _cachedShorts[idx].docID.trim();
    if (docId.isEmpty) return;
    final token = '$_currentScrollToken|$docId';
    if (_lastReportedStableFrameToken == token) return;
    _lastReportedStableFrameToken = token;
    recordQALabScrollEvent(
      surface: 'short',
      phase: 'stable_frame',
      metadata: <String, dynamic>{
        'docId': docId,
        'page': idx,
        'scrollToken': _currentScrollToken,
        'positionMs': adapter.value.position.inMilliseconds,
        'isPlaying': adapter.value.isPlaying,
        'isBuffering': adapter.value.isBuffering,
        'hasRenderedFirstFrame': adapter.value.hasRenderedFirstFrame,
      },
    );
  }

  Widget _buildFullscreenVideoSurface(
    HLSVideoAdapter adapter,
    String keyId, {
    double? modelAspectRatio,
    bool preferResumePoster = false,
  }) {
    final ar = (modelAspectRatio != null && modelAspectRatio > 0)
        ? modelAspectRatio
        : (9 / 16);

    final player = adapter.buildPlayer(
      key: ValueKey(keyId),
      useAspectRatio: false,
      forceFullscreenOnAndroid: true,
      preferWarmPoolPauseOnAndroid: true,
      suppressLoadingOverlay: true,
      preferResumePoster: preferResumePoster,
      preferStableStartupBuffer: defaultTargetPlatform == TargetPlatform.iOS,
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
          final isLoadingNow = controller.isLoading.value;
          final hasMoreNow = controller.hasMore.value;

          final list = _cachedShorts;

          if (list.isEmpty) {
            if (isLoadingNow || hasMoreNow) {
              return const SizedBox.expand(
                child: ColoredBox(color: Colors.black),
              );
            }
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
            physics: const PageScrollPhysics(),
            itemCount: list.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, idx) {
              final vp = controller.cache[idx];
              final modelAr = list[idx].aspectRatio > 0
                  ? list[idx].aspectRatio.toDouble()
                  : (9 / 16);
              final isActivePage = idx == currentPage;
              final isWarmNeighbor = (idx - currentPage).abs() <= 1;

              if (vp == null) {
                if (isActivePage) {
                  _ensureActivePageAdapterAfterBuild(idx);
                } else if (isWarmNeighbor) {
                  _ensureWarmNeighborAdapterAfterBuild(currentPage, idx);
                }
                return _buildPendingShortSurface(list[idx]);
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
                          'vp-${list[idx].docID}',
                          modelAspectRatio: modelAr,
                          preferResumePoster: false,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();

              final pendingSurface = _buildPendingShortSurface(list[idx]);

              return KeyedSubtree(
                key: ValueKey('short-page-${list[idx].docID}'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isActivePage || isWarmNeighbor) videoWidget,
                    if (isActivePage)
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
                          return IgnorePointer(
                            ignoring: true,
                            child: AnimatedOpacity(
                              opacity: decision.shouldHidePoster ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 90),
                              curve: Curves.easeOut,
                              child: pendingSurface,
                            ),
                          );
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
                            _playbackExecutionService.playAdapter(vp);
                            isManuallyPaused = false;
                          } else {
                            _playbackExecutionService.pauseAdapter(vp);
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
              if (kDebugMode)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 60,
                  right: 8,
                  child: CacheDebugOverlay(totalCount: list.length),
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
