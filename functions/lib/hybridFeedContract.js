"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HYBRID_FEED_REFERENCE_FIELD_NAMES = exports.HYBRID_FEED_CONTRACT = void 0;
exports.HYBRID_FEED_CONTRACT = {
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
};
exports.HYBRID_FEED_REFERENCE_FIELD_NAMES = [
    exports.HYBRID_FEED_CONTRACT.referenceFields.postId,
    exports.HYBRID_FEED_CONTRACT.referenceFields.authorId,
    exports.HYBRID_FEED_CONTRACT.referenceFields.timeStamp,
    exports.HYBRID_FEED_CONTRACT.referenceFields.isCelebrity,
    exports.HYBRID_FEED_CONTRACT.referenceFields.expiresAt,
];
//# sourceMappingURL=hybridFeedContract.js.map