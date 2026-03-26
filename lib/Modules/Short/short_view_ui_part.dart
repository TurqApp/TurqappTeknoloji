part of 'short_view.dart';

extension ShortViewUiPart on _ShortViewState {
  void _handleManualVerticalDragStart(DragStartDetails details) {
    _manualGestureDragDy = 0.0;
  }

  void _handleManualVerticalDragUpdate(DragUpdateDetails details) {
    _manualGestureDragDy += details.primaryDelta ?? 0.0;
  }

  void _handleManualVerticalDragEnd(DragEndDetails details) {
    final delta = _manualGestureDragDy;
    final velocity = details.primaryVelocity ?? 0.0;
    _manualGestureDragDy = 0.0;

    if (!mounted ||
        _manualSnapInProgress ||
        _isTransitioning ||
        _cachedShorts.isEmpty) {
      return;
    }

    final goForward = velocity < -_shortManualGestureTriggerVelocity ||
        delta < -_shortManualGestureTriggerDistance;
    final goBackward = velocity > _shortManualGestureTriggerVelocity ||
        delta > _shortManualGestureTriggerDistance;
    if (goForward == goBackward) return;

    final targetPage = goForward
        ? (currentPage + 1).clamp(0, _cachedShorts.length - 1)
        : (currentPage - 1).clamp(0, _cachedShorts.length - 1);
    if (targetPage == currentPage) return;

    unawaited(_animateManualPage(targetPage));
  }

  Future<void> _animateManualPage(int targetPage) async {
    if (!mounted || _manualSnapInProgress || !pageController.hasClients) return;
    _manualSnapInProgress = true;
    try {
      await pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
    } finally {
      _manualSnapInProgress = false;
    }
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

  Widget _buildVideoLoadingSurface() {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: CupertinoActivityIndicator(color: Colors.white),
      ),
    );
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

          final pager = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: _handleManualVerticalDragStart,
            onVerticalDragUpdate: _handleManualVerticalDragUpdate,
            onVerticalDragEnd: _handleManualVerticalDragEnd,
            child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, idx) {
                final vp = controller.cache[idx];
                final modelAr = list[idx].aspectRatio > 0
                    ? list[idx].aspectRatio.toDouble()
                    : (9 / 16);

                if (vp == null) {
                  return _buildVideoLoadingSurface();
                }

                final isActivePage = idx == currentPage;
                final videoWidget = isActivePage
                    ? _buildFullscreenVideoSurface(
                        vp,
                        'vp-${list[idx].docID}',
                        modelAspectRatio: modelAr,
                      )
                    : const SizedBox.shrink();

                return RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Colors.black),
                      if (isActivePage) videoWidget,
                      if (isActivePage)
                        AnimatedBuilder(
                          animation: vp,
                          builder: (_, __) {
                            if (vp.value.hasRenderedFirstFrame) {
                              return const SizedBox.shrink();
                            }
                            return _buildVideoLoadingSurface();
                          },
                        ),
                      if (isActivePage)
                        AnimatedBuilder(
                          animation: vp,
                          builder: (_, __) {
                            if (vp.value.hasRenderedFirstFrame) {
                              return const SizedBox.shrink();
                            }
                            return _buildVideoLoadingSurface();
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
                                        vp.setVolume(volume ? 1 : 0);
                                        if (idx == currentPage) {
                                          VideoTelemetryService.instance
                                              .updateRuntimeHints(
                                            list[idx].docID,
                                            isAudible: volume,
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
            ),
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
