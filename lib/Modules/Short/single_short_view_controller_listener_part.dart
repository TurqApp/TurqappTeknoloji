part of 'single_short_view.dart';

extension SingleShortViewControllerListenerPart on _SingleShortViewState {
  void _addVideoCompletionListener(HLSVideoAdapter ctrl, int index) {
    _detachCompletionListener(index, ctrl);
    void listener() {
      if (!mounted) return;
      if (index != currentPage) return;

      final value = ctrl.value;
      if (!value.isInitialized) return;
      if (_completionTriggered[index] == true) return;

      final position = value.position;
      final duration = value.duration;
      final justActivated =
          DateTime.now().difference(_pageActivatedAt).inMilliseconds < 1200;
      if (justActivated) return;
      if (duration.inMilliseconds > 0 &&
          position >= duration - const Duration(milliseconds: 300) &&
          position.inMilliseconds > 0) {
        _completionTriggered[index] = true;
        if (index >= 0 && index < shorts.length) {
          VideoTelemetryService.instance.onCompleted(shorts[index].docID);
        }

        final nextIndex = currentPage + 1;
        if (nextIndex < shorts.length) {
          if (pageController.hasClients) {
            pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          Future.delayed(const Duration(milliseconds: 100), () {
            final sameController = _videoControllers[index] == ctrl;
            if (mounted && sameController && !ctrl.isDisposed) {
              ctrl.seekTo(Duration.zero);
              if (index >= 0 && index < shorts.length) {
                _requestExclusivePlayback(shorts[index].docID);
              }
              _completionTriggered[index] = false;
            }
          });
        }
      }
    }

    _completionListeners[index] = listener;
    ctrl.addListener(listener);
  }

  void _disposeOutsideRange(int center) {
    final len = shorts.length;
    final start = (center - 10).clamp(0, len - 1);
    final end = (center + 10).clamp(0, len - 1);
    final keys = _videoControllers.keys.toList();
    for (var idx in keys) {
      if (idx < start || idx > end) {
        if (!_externallyOwned.contains(idx)) {
          unawaited(_releaseControllerAt(idx));
        }
      }
    }
  }
}
