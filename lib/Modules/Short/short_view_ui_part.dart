part of 'short_view.dart';

extension ShortViewUiPart on _ShortViewState {
  String _resolvePendingShortPreviewUrl(PostsModel model) {
    final candidates = <String>[
      model.thumbnail.trim(),
      ...model.preferredVideoPosterUrls.map((url) => url.trim()),
      ...model.img.map((url) => url.trim()),
    ]..removeWhere((url) => url.isEmpty);
    return candidates.isNotEmpty ? candidates.first : '';
  }

  Widget _buildPendingShortSurface(PostsModel model) {
    final previewUrl = _resolvePendingShortPreviewUrl(model);
    assert(() {
      debugPrint(
        '[ShortPendingSurface] doc=${model.docID} '
        'hasPreview=${previewUrl.isNotEmpty} preview=$previewUrl',
      );
      return true;
    }());
    if (previewUrl.isEmpty) {
      return const SizedBox.expand(
        child: ColoredBox(color: Colors.transparent),
      );
    }
    return SizedBox.expand(
      child: Image.network(
        previewUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox.shrink();
        },
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
    bool preferResumePoster = false,
  }) {
    final ar = (modelAspectRatio != null && modelAspectRatio > 0)
        ? modelAspectRatio
        : (9 / 16);

    final player = adapter.buildPlayer(
      key: ValueKey(keyId),
      useAspectRatio: false,
      forceFullscreenOnAndroid: true,
      suppressLoadingOverlay: true,
      preferResumePoster: preferResumePoster,
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

  Widget _buildShortAdPage(BuildContext context, int adOrdinal) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E12),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(
                    icon: CupertinoIcons.arrow_left,
                    key: ValueKey(
                      IntegrationTestKeys.actionShortBack,
                    ),
                    iconColor: Colors.white,
                    surfaceColor: Color(0x50000000),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: AdmobKare(
                    suggestionPlacementId: 'shorts',
                    showChrome: true,
                    contentPadding: EdgeInsets.zero,
                    onImpression: () {
                      assert(() {
                        debugPrint(
                          '[ShortAdSlots] impression adOrdinal=$adOrdinal placement=shorts',
                        );
                        return true;
                      }());
                    },
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
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

          final list = _renderItems;

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

          if (_currentRenderPage >= list.length) {
            _currentRenderPage = _clampRenderIndex(list.length - 1);
            final organicIndex = _organicIndexForRenderIndex(_currentRenderPage);
            if (organicIndex != null) {
              currentPage = organicIndex;
            }
            if (pageController.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (pageController.hasClients) {
                  pageController.jumpToPage(_currentRenderPage);
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
              final item = list[idx];
              if (item.isAd) {
                return KeyedSubtree(
                  key: ValueKey('short-ad-page-${item.adOrdinal}'),
                  child: _buildShortAdPage(context, item.adOrdinal ?? 0),
                );
              }
              final organicIndex = item.organicIndex!;
              final post = item.post!;
              final vp = controller.cache[organicIndex];
              final modelAr = post.aspectRatio > 0
                  ? post.aspectRatio.toDouble()
                  : (9 / 16);
              final isActivePage = idx == _currentRenderPage;
              final isWarmNeighbor = (idx - _currentRenderPage).abs() <= 1;

              if (vp == null) {
                if (isActivePage) {
                  _ensureActivePageAdapterAfterBuild(organicIndex);
                }
                return _buildPendingShortSurface(post);
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
                          'vp-${post.docID}',
                          modelAspectRatio: modelAr,
                          preferResumePoster: false,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();

              final pendingSurface = _buildPendingShortSurface(post);

              return KeyedSubtree(
                key: ValueKey('short-page-${post.docID}'),
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
                              _shortPlaybackDecisionFor(organicIndex, value);
                          _reportStableShortFrameIfNeeded(
                            organicIndex,
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
                        model: post,
                        isActive: isActivePage,
                        showOverlayControls: _showOverlayControls,
                        onToggleOverlay: () {
                          if (!mounted) return;
                          _updateShortViewState(() {
                            _showOverlayControls = !_showOverlayControls;
                          });
                        },
                        onDoubleTapLike: () async {
                          await PostRepository.ensure().toggleLike(post);
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
                          if (organicIndex == currentPage) {
                            VideoTelemetryService.instance.updateRuntimeHints(
                              post.docID,
                              isAudible: volume,
                              hasStableFocus: v,
                            );
                          }
                        },
                        videoPlayerController: vp,
                        onEdited: (updatedDocId) async {
                          await controller.updateShort(updatedDocId);
                          await controller.refreshVideoController(organicIndex);
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
                                        organicIndex,
                                        vp,
                                      );
                                      if (organicIndex == currentPage) {
                                        final decision =
                                            _shortPlaybackDecisionFor(
                                          organicIndex,
                                          vp.value,
                                        );
                                        VideoTelemetryService.instance
                                            .updateRuntimeHints(
                                          post.docID,
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
                  child: CacheDebugOverlay(totalCount: _cachedShorts.length),
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
