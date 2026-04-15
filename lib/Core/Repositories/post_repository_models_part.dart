part of 'post_repository.dart';

class PostRepositoryState {
  PostRepositoryState(this.postId);

  final String postId;
  final RxBool liked = false.obs;
  final RxBool saved = false.obs;
  final RxBool reshared = false.obs;
  final RxBool reported = false.obs;
  final RxBool commented = false.obs;
  final RxnInt localPollSelection = RxnInt();
  final Rxn<Map<String, dynamic>> latestPostData = Rxn<Map<String, dynamic>>();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? postSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? commentsSub;
  DateTime? interactionFetchedAt;
  bool interactionLoading = false;
  int interactionEpoch = 0;
  int retainCount = 0;
}

class PostSubcollectionPage {
  const PostSubcollectionPage({
    required this.userIds,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<String> userIds;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class PostSharersPage {
  const PostSharersPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<PostSharersModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class PostReshareEntry {
  const PostReshareEntry({
    required this.userId,
    required this.timeStamp,
    required this.quotedPost,
  });

  final String userId;
  final int timeStamp;
  final bool quotedPost;
}

class PostQueryPage {
  const PostQueryPage({
    required this.items,
    required this.lastDoc,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
}

class TypesenseMotorCandidatesPage {
  const TypesenseMotorCandidatesPage({
    required this.surface,
    required this.ownedMinutes,
    required this.items,
    required this.limit,
    required this.page,
    required this.found,
    required this.outOf,
    required this.searchTimeMs,
  });

  final String surface;
  final List<int> ownedMinutes;
  final List<PostsModel> items;
  final int limit;
  final int page;
  final int found;
  final int outOf;
  final int searchTimeMs;
}

class UserFeedReference {
  const UserFeedReference({
    required this.postId,
    required this.authorId,
    required this.timeStamp,
    required this.isCelebrity,
    required this.expiresAt,
  });

  final String postId;
  final String authorId;
  final int timeStamp;
  final bool isCelebrity;
  final int expiresAt;
}

class UserFeedReferencePage {
  const UserFeedReferencePage({
    required this.items,
    required this.lastDoc,
  });

  final List<UserFeedReference> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
}
