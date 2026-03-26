part of 'story_interaction_optimizer.dart';

StoryInteractionOptimizer? _maybeFindStoryInteractionOptimizer() =>
    Get.isRegistered<StoryInteractionOptimizer>()
        ? Get.find<StoryInteractionOptimizer>()
        : null;

StoryInteractionOptimizer _ensureStoryInteractionOptimizer() =>
    _maybeFindStoryInteractionOptimizer() ??
    Get.put(StoryInteractionOptimizer(), permanent: true);

void _handleStoryInteractionOptimizerInit(
  StoryInteractionOptimizer service,
) {
  _StoryInteractionOptimizerRuntimePart(service).handleOnInit();
}

void _handleStoryInteractionOptimizerClose(
  StoryInteractionOptimizer service,
) {
  _StoryInteractionOptimizerRuntimePart(service).handleOnClose();
}

Future<void> _markStoryInteractionViewed(
  StoryInteractionOptimizer service,
  String storyOwnerId,
  String storyId,
  int storyTime,
) =>
    _StoryInteractionOptimizerRuntimePart(service)
        .markStoryViewed(storyOwnerId, storyId, storyTime);

bool _readAllStoriesSeenCached(
  StoryInteractionOptimizer service,
  String storyOwnerId,
  List<dynamic> stories,
) =>
    _StoryInteractionOptimizerRuntimePart(service)
        .areAllStoriesSeenCached(storyOwnerId, stories);

Future<void> _forceFlushStoryInteraction(StoryInteractionOptimizer service) =>
    _StoryInteractionOptimizerRuntimePart(service).forceFlush();

Future<void> _cleanupStoryInteraction(StoryInteractionOptimizer service) =>
    _StoryInteractionOptimizerRuntimePart(service).cleanup();

extension StoryInteractionOptimizerFacadePart on StoryInteractionOptimizer {
  Future<void> markStoryViewed(
    String storyOwnerId,
    String storyId,
    int storyTime,
  ) =>
      _markStoryInteractionViewed(
        this,
        storyOwnerId,
        storyId,
        storyTime,
      );

  bool areAllStoriesSeenCached(String storyOwnerId, List<dynamic> stories) =>
      _readAllStoriesSeenCached(
        this,
        storyOwnerId,
        stories,
      );

  Future<void> forceFlush() => _forceFlushStoryInteraction(this);

  Future<void> cleanup() => _cleanupStoryInteraction(this);
}
