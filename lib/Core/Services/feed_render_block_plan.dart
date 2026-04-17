import 'package:turqappv2/Core/Services/feed_growth_policy.dart';

enum FeedPlannerPostBucket {
  cache,
  live,
  image,
  flood,
  text,
}

enum FeedRenderSlotType {
  post,
  ad,
  recommended,
}

class FeedRenderBlockPlan {
  const FeedRenderBlockPlan._();

  static const int postsPerGroup = FeedGrowthPolicy.postsPerGroup;
  static const int renderSlotsPerGroup = FeedGrowthPolicy.renderSlotsPerGroup;
  static const int groupsPerBlock = FeedGrowthPolicy.groupsPerBlock;
  static const int postSlotsPerBlock = postsPerGroup * groupsPerBlock;
  static const int renderSlotsPerBlock = renderSlotsPerGroup * groupsPerBlock;

  static const List<FeedPlannerPostBucket> postSlotPlan =
      <FeedPlannerPostBucket>[
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
    FeedPlannerPostBucket.live,
  ];

  static const List<FeedRenderSlotType> renderSlotPlan = <FeedRenderSlotType>[
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.ad,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.ad,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.ad,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.ad,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.post,
    FeedRenderSlotType.ad,
  ];
}
