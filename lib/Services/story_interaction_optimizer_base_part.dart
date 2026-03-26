part of 'story_interaction_optimizer_library.dart';

abstract class _StoryInteractionOptimizerBase extends GetxService {
  final _state = _StoryInteractionOptimizerState();

  @override
  void onInit() {
    super.onInit();
    _handleStoryInteractionOptimizerInit(this as StoryInteractionOptimizer);
  }

  @override
  void onClose() {
    _handleStoryInteractionOptimizerClose(this as StoryInteractionOptimizer);
    super.onClose();
  }
}
