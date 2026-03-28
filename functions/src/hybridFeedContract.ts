export const HYBRID_FEED_CONTRACT = {
  contractId: "feed_home_primary_hybrid_v1",
  primaryCollection: "userFeeds",
  primaryItemsSubcollection: "items",
  celebrityCollection: "celebAccounts",
  referenceFields: {
    postId: "postId",
    authorId: "authorId",
    timeStamp: "timeStamp",
    isVideo: "isVideo",
    isCelebrity: "isCelebrity",
    expiresAt: "expiresAt",
  },
  usesPrimaryFeedPaging: true,
} as const;

export const HYBRID_FEED_REFERENCE_FIELD_NAMES = [
  HYBRID_FEED_CONTRACT.referenceFields.postId,
  HYBRID_FEED_CONTRACT.referenceFields.authorId,
  HYBRID_FEED_CONTRACT.referenceFields.timeStamp,
  HYBRID_FEED_CONTRACT.referenceFields.isCelebrity,
  HYBRID_FEED_CONTRACT.referenceFields.expiresAt,
] as const;
