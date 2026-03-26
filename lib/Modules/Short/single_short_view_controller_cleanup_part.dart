part of 'single_short_view.dart';

void _clearSingleShortViewControllers(_SingleShortViewState state) {
  final keys = state._videoControllers.keys.toList();
  for (final idx in keys) {
    final controller = state._videoControllers[idx]!;
    if (state._externallyOwned.contains(idx)) {
      continue;
    }
    if (controller.isDisposed) {
      state._detachCompletionListener(idx, controller);
      state._videoControllers.remove(idx);
      continue;
    }
    unawaited(state._releaseControllerAt(idx));
  }
}
