part of 'story_interaction_optimizer.dart';

class StoryInteractionOptimizer extends _StoryInteractionOptimizerBase {
  static StoryInteractionOptimizer? maybeFind() =>
      _maybeFindStoryInteractionOptimizer();

  static StoryInteractionOptimizer ensure() =>
      _ensureStoryInteractionOptimizer();

  static StoryInteractionOptimizer get to => ensure();

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
