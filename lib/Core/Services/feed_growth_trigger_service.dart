import 'dart:math' as math;

import 'package:turqappv2/Core/Services/feed_render_block_plan.dart';

class FeedGrowthTriggerService {
  const FeedGrowthTriggerService._();

  static int estimateViewedCountAtPromo({
    required int renderBlockIndex,
    required int renderGroupNumber,
  }) {
    final normalizedBlockIndex = renderBlockIndex < 0 ? 0 : renderBlockIndex;
    final normalizedGroupNumber = renderGroupNumber < 0 ? 0 : renderGroupNumber;
    final blockOffset =
        normalizedBlockIndex * FeedRenderBlockPlan.postSlotsPerBlock;
    final postsWithinBlock = math.min(
      FeedRenderBlockPlan.postSlotsPerBlock,
      normalizedGroupNumber * FeedRenderBlockPlan.postsPerGroup,
    );
    return blockOffset + postsWithinBlock;
  }

  static bool shouldTriggerFallback({
    required int viewedCount,
    required int nextTriggerCount,
  }) {
    if (nextTriggerCount <= 0) return false;
    return viewedCount >= nextTriggerCount;
  }
}
