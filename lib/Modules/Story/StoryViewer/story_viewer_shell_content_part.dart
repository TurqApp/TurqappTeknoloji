part of 'story_viewer.dart';

extension StoryViewerShellContentPart on _StoryViewerState {
  Widget _buildStoryViewerPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenStoryViewer),
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragStart: (details) {
          _dragStartY = details.localPosition.dy;
        },
        onVerticalDragUpdate: (details) {
          final delta = details.localPosition.dy - _dragStartY;
          _updateDragTransform(
            dragOffsetY: delta.clamp(-200.0, 300.0),
            dragOffsetX: _dragOffsetX,
            opacityMultiplier: 0.5,
            scaleMultiplier: 0.05,
          );
        },
        onVerticalDragEnd: _handleVerticalDragEnd,
        onHorizontalDragStart: (details) {
          _dragStartX = details.localPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          final delta = details.localPosition.dx - _dragStartX;
          _updateDragTransform(
            dragOffsetY: _dragOffsetY,
            dragOffsetX: delta.clamp(-200.0, 200.0),
            opacityMultiplier: 0.08,
            scaleMultiplier: 0.03,
          );
        },
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Transform.translate(
            offset: Offset(_dragOffsetX, _dragOffsetY),
            child: Transform.scale(
              scale: _dragScale,
              child: Opacity(
                opacity: _dragOpacity,
                child: PageView.builder(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.storyOwnerUsers.length,
                  onPageChanged: (index) {
                    if (index == currentPageIndex) {
                      _prefetchNext(index);
                      return;
                    }
                    _updateViewState(() {
                      currentPageIndex = index;
                    });
                    _prefetchNext(index);
                  },
                  itemBuilder: (context, pageIndex) =>
                      _buildStoryPage(pageIndex),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPage(int pageIndex) {
    final currentUser = widget.storyOwnerUsers[pageIndex];
    final startIdx = _computeStartIndex(currentUser);
    final key = _pageKeys.putIfAbsent(pageIndex, () => GlobalKey());

    return UserStoryContent(
      key: key,
      user: currentUser,
      initialStoryIndex: startIdx,
      onUserStoryFinished: () => _onUserStoryFinished(pageIndex),
      onPrevUserRequested: () => _onPrevUserRequested(pageIndex),
      onSwipeNextUser: () => _goToAdjacentUser(pageIndex + 1),
      onSwipePrevUser: () => _goToAdjacentUser(pageIndex - 1),
      onCloseRequested: () => unawaited(_refreshStoryRowAndExit()),
    );
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final deltaY = _dragOffsetY;
    if (deltaY > dismissDeltaPx ||
        (deltaY > (dismissDeltaPx / 2) && velocity > dismissVelocityPx)) {
      _refreshStoryRowAndExit();
      return;
    }

    if (deltaY < openCommentDeltaPx ||
        (deltaY < (openCommentDeltaPx / 2) &&
            velocity < openCommentVelocityPx)) {
      _updateViewState(() {
        _dragOffsetY = 0.0;
        _dragOffsetX = 0.0;
        _dragOpacity = 1.0;
        _dragScale = 1.0;
      });
      HapticFeedback.lightImpact();
      try {
        final key = _pageKeys[currentPageIndex];
        final st = key?.currentState;
        (st as dynamic)?.openCommentsFromParent?.call();
      } catch (_) {}
      return;
    }

    _animateBack();
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    final dx = _dragOffsetX;
    final pass = dx.abs() > 120 || vx.abs() > 800;

    if (pass) {
      if (dx < 0) {
        _goToAdjacentUser(currentPageIndex + 1);
      } else {
        _goToAdjacentUser(currentPageIndex - 1);
      }
    }

    _updateViewState(() {
      _dragOffsetX = 0.0;
      _dragScale = 1.0;
      _dragOpacity = 1.0;
    });
  }

  void _updateDragTransform({
    required double dragOffsetY,
    required double dragOffsetX,
    required double opacityMultiplier,
    required double scaleMultiplier,
  }) {
    _updateViewState(() {
      _dragOffsetY = dragOffsetY;
      _dragOffsetX = dragOffsetX;
      final ratioY = (_dragOffsetY.abs() / 300.0).clamp(0.0, 1.0);
      final ratioX = (_dragOffsetX.abs() / 300.0).clamp(0.0, 1.0);
      final ratio = ratioX > ratioY ? ratioX : ratioY;
      _dragOpacity = 1.0 - (opacityMultiplier * ratio);
      _dragScale = 1.0 - (scaleMultiplier * ratio);
    });
  }

  Future<void> _goToAdjacentUser(int targetIndex,
      {int durationMs = 0}) async {
    if (targetIndex < 0) {
      await _stopCurrentUserStoryPlayback(reason: 'story_page_back');
      _refreshStoryRowAndExit();
      return;
    }
    if (targetIndex >= widget.storyOwnerUsers.length) {
      await _stopCurrentUserStoryPlayback(reason: 'story_page_finish');
      _refreshStoryRowAndExit();
      return;
    }

    final sourceIndex = currentPageIndex;
    final reason = targetIndex > sourceIndex
        ? 'story_user_swipe_next'
        : 'story_user_swipe_prev';

    unawaited(_stopUserStoryPlaybackAt(sourceIndex, reason: reason));
    unawaited(_prefetchNext(targetIndex));

    if (durationMs <= 0) {
      _updateViewState(() {
        currentPageIndex = targetIndex;
      });
      debugPrint(
        '[StoryTransition] action=instant_delegate from=$sourceIndex '
        'to=$targetIndex reason=$reason',
      );
      pageController.jumpToPage(targetIndex);
    } else if (targetIndex > sourceIndex) {
      pageController.nextPage(
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeInOut,
      );
    } else if (targetIndex < sourceIndex) {
      pageController.previousPage(
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _stopCurrentUserStoryPlayback({required String reason}) async {
    await _stopUserStoryPlaybackAt(currentPageIndex, reason: reason);
  }

  Future<void> _stopUserStoryPlaybackAt(
    int pageIndex, {
    required String reason,
  }) async {
    try {
      final dynamic state = _pageKeys[pageIndex]?.currentState;
      if (state == null) return;
      await state.stopPlaybackFromParent(reason: reason);
    } catch (_) {}
  }

  void _animateBack() {
    _returnController.reset();
    final startOffset = _dragOffsetY;
    final startOpacity = _dragOpacity;
    final startScale = _dragScale;
    _offsetAnim = Tween<double>(begin: startOffset, end: 0).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: startOpacity, end: 1).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: startScale, end: 1).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.easeOut),
    );
    _returnController.forward();
  }
}
