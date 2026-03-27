part of 'post_repository.dart';

extension PostRepositoryFacadePart on PostRepository {
  PostRepositoryState attachPost(
    PostsModel model, {
    bool loadInteraction = true,
    bool loadCommentMembership = true,
  }) =>
      _performAttachPost(
        model,
        loadInteraction: loadInteraction,
        loadCommentMembership: loadCommentMembership,
      );

  void releasePost(String postId) => _performReleasePost(postId);

  Future<bool> toggleLike(PostsModel model) => _performToggleLike(model);

  Future<bool> toggleSave(PostsModel model) => _performToggleSave(model);

  Future<bool> toggleReshare(PostsModel model) => _performToggleReshare(model);

  Future<void> refreshInteraction(String postId) =>
      _performRefreshInteraction(postId);

  Future<void> setArchived(PostsModel model, bool archived) =>
      _performSetArchived(model, archived);

  Map<String, dynamic>? buildVotedPoll({
    required Map<String, dynamic> poll,
    required int optionIndex,
    required int fallbackTimestampMs,
    required String currentUid,
  }) =>
      _performBuildVotedPoll(
        poll: poll,
        optionIndex: optionIndex,
        fallbackTimestampMs: fallbackTimestampMs,
        currentUid: currentUid,
      );

  Future<Map<String, dynamic>?> commitPollVote({
    required String postId,
    required int optionIndex,
    required int fallbackTimestampMs,
    required String currentUid,
  }) =>
      _performCommitPollVote(
        postId: postId,
        optionIndex: optionIndex,
        fallbackTimestampMs: fallbackTimestampMs,
        currentUid: currentUid,
      );

  Future<Map<String, PostsModel>> fetchPostsByIds(
    List<String> postIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchPostsByIds(
        postIds,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<Map<String, PostsModel>> fetchPostCardsByIds(
    List<String> postIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchPostCardsByIds(
        postIds,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<PostQueryPage> fetchAgendaWindowPage({
    required int cutoffMs,
    required int nowMs,
    required int limit,
    DocumentSnapshot? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchAgendaWindowPage(
        cutoffMs: cutoffMs,
        nowMs: nowMs,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<UserFeedReferencePage> fetchUserFeedReferences({
    required String uid,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchUserFeedReferences(
        uid: uid,
        limit: limit,
        startAfter: startAfter,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<String>> fetchCelebrityAuthorIds(
    List<String> authorIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchCelebrityAuthorIds(
        authorIds,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchRecentPostsForAuthors(
    List<String> authorIds, {
    required int nowMs,
    required int cutoffMs,
    int perAuthorLimit = 3,
    int maxConcurrent = 12,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchRecentPostsForAuthors(
        authorIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        perAuthorLimit: perAuthorLimit,
        maxConcurrent: maxConcurrent,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchPublicScheduledIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchPublicScheduledIzBirakPosts(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<List<PostsModel>> fetchRecentGlobalPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    int? maxTimeExclusive,
    bool preferCache = true,
    bool cacheOnly = false,
  }) =>
      _performFetchRecentGlobalPosts(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        maxTimeExclusive: maxTimeExclusive,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<PostsModel?> fetchPostById(
    String postId, {
    bool preferCache = true,
  }) =>
      _performFetchPostById(postId, preferCache: preferCache);

  void mergeCachedPostData(String postId, Map<String, dynamic> patch) =>
      _performMergeCachedPostData(postId, patch);

  Future<Map<String, dynamic>?> fetchPostRawById(
    String postId, {
    bool preferCache = true,
  }) =>
      _performFetchPostRawById(postId, preferCache: preferCache);

  Future<QuerySnapshot<Map<String, dynamic>>> _getQueryWithSource(
    Query<Map<String, dynamic>> query, {
    required bool preferCache,
    required bool cacheOnly,
  }) =>
      _performGetQueryWithSource(
        query,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );

  Future<String?> resolveDocumentIdByLegacyId(
    String legacyId, {
    bool preferCache = true,
  }) =>
      _performResolveDocumentIdByLegacyId(
        legacyId,
        preferCache: preferCache,
      );
}
