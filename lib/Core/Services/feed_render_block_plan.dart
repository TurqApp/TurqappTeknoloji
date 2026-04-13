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

  static const int postsPerGroup = 3;
  static const int renderSlotsPerGroup = 4;
  static const int groupsPerBlock = 5;
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
    FeedRenderSlotType.recommended,
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
    FeedRenderSlotType.recommended,
  ];
}
