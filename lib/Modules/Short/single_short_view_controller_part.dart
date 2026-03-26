part of 'single_short_view.dart';

extension SingleShortViewControllerPart on _SingleShortViewState {
  void _clearAllControllers() {
    final keys = _videoControllers.keys.toList();
    for (final idx in keys) {
      final c = _videoControllers[idx]!;
      if (_externallyOwned.contains(idx)) {
        continue;
      }
      if (c.isDisposed) {
        _detachCompletionListener(idx, c);
        _videoControllers.remove(idx);
        continue;
      }
      unawaited(_releaseControllerAt(idx));
    }
  }
}
