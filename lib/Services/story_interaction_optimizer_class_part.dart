part of 'story_interaction_optimizer_library.dart';

class StoryInteractionOptimizer extends _StoryInteractionOptimizerBase {
  @override
  void onInit() {
    super.onInit();
    _handleStoryInteractionOptimizerInit(this);
  }

  @override
  void onClose() {
    _handleStoryInteractionOptimizerClose(this);
    super.onClose();
  }
}
