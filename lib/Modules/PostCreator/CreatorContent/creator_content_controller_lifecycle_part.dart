part of 'creator_content_controller.dart';

const List<String> kCreatorSupportedVideoLookPresets = <String>[
  'original',
  'clear',
  'cinema',
  'vibe',
  'bright',
];

class _CreatorContentControllerLifecyclePart {
  final CreatorContentController _controller;

  const _CreatorContentControllerLifecyclePart(this._controller);

  void handleTextEditingChanged() {
    _controller.refreshHashtagSuggestionsFromCursor();
  }

  void handleOnInit() {
    WidgetsBinding.instance.addObserver(_controller);
    _controller.textEdit
        .addListener(_controller.refreshHashtagSuggestionsFromCursor);
  }

  void handleOnClose() {
    WidgetsBinding.instance.removeObserver(_controller);
    _controller.textEdit
        .removeListener(_controller.refreshHashtagSuggestionsFromCursor);
    unawaited(_controller._releaseVideoController());
    _controller.isPlaying.value = false;
    _controller.focus.dispose();
    _controller.textEdit.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.forcePauseVideo());
    }
  }
}
