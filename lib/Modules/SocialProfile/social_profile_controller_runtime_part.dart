part of 'social_profile_controller.dart';

extension SocialProfileControllerRuntimePart on SocialProfileController {
  void _handleLifecycleInit() {
    UserAnalyticsService.instance.trackFeatureUsage('social_profile_open');
    getUserData();
    getCounters();
    getUserStoryUserModelAndPrint(userID);
    getSocialMediaLinks();
    isFollowingCheck();
    _performLogProfileVisitIfNeeded();
    unawaited(_restoreCachedBuckets());
    _fetchPrimaryBuckets(initial: true);
    getReshares();
  }

  void _handleLifecycleClose() {
    scrollController.dispose();
    _userDocSub?.cancel();
    _resharesSub?.cancel();
    _visibilityDebounce?.cancel();
  }

  bool _performIsPrivateContentBlockedFor(String? viewerUserId) {
    return gizliHesap.value &&
        takipEdiyorum.value == false &&
        viewerUserId != userID;
  }

  bool _performIsBlockedByCurrentViewer(String? otherUserId) {
    final other = (otherUserId ?? '').trim();
    if (other.isEmpty) return false;
    final currentBlocked = CurrentUserService.instance.blockedUserIds;
    return currentBlocked.contains(other);
  }

  String _performDisplayCounterValue({
    required String? viewerUserId,
    required num value,
  }) {
    if (isBlockedByCurrentViewer(viewerUserId)) {
      return "0";
    }
    return NumberFormatter.format(value.toInt());
  }

  bool isPrivateContentBlockedFor(String? viewerUserId) =>
      _performIsPrivateContentBlockedFor(viewerUserId);

  bool isBlockedByCurrentViewer(String? otherUserId) =>
      _performIsBlockedByCurrentViewer(otherUserId);

  String displayCounterValue({
    required String? viewerUserId,
    required num value,
  }) =>
      _performDisplayCounterValue(
        viewerUserId: viewerUserId,
        value: value,
      );

  Future<void> getCounters() => _performGetCounters();

  Future<void> getReshares() => _performGetReshares();

  Future<void> _hydrateReshares(List<UserPostReference> refs) =>
      _performHydrateReshares(refs);

  Future<void> getPosts({bool initial = false}) =>
      _performGetPosts(initial: initial);

  Future<void> getPhotos({bool initial = false}) =>
      _performGetPhotos(initial: initial);

  Future<void> isFollowingCheck() => _performIsFollowingCheck();

  Future<void> setPostSelection(int index) => _performSetPostSelection(index);

  GlobalKey getPostKey({
    required String docId,
    required bool isReshare,
  }) {
    final identity = combinedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return _postKeys.putIfAbsent(
      identity,
      () => GlobalObjectKey('social_$identity'),
    );
  }

  String combinedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) =>
      _performCombinedEntryIdentity(
        docId: docId,
        isReshare: isReshare,
      );

  List<Map<String, dynamic>> get combinedFeedEntries =>
      _performCombinedFeedEntries();

  int indexOfCombinedEntry({
    required String docId,
    required bool isReshare,
  }) =>
      _performIndexOfCombinedEntry(
        docId: docId,
        isReshare: isReshare,
      );

  String agendaInstanceTag({
    required String docId,
    required bool isReshare,
  }) =>
      _performAgendaInstanceTag(
        docId: docId,
        isReshare: isReshare,
      );

  Future<void> fetchScheduledPosts({bool initial = false}) =>
      _performFetchScheduledPosts(initial: initial);

  Future<void> refreshAll() => _performRefreshAll();

  Future<void> disposeAgendaContentController(String docID) =>
      _performDisposeAgendaContentController(docID);

  Future<void> getSocialMediaLinks() => _performGetSocialMediaLinks();

  Future<void> showSocialMediaLinkDelete(String docID) =>
      _performShowSocialMediaLinkDelete(docID);

  Future<void> getUserData() => _performGetUserData();

  bool _needsHeaderSupplementalData(Map<String, dynamic> raw) =>
      _performNeedsHeaderSupplementalData(raw);

  void _applyUserData(Map<String, dynamic> raw) => _performApplyUserData(raw);

  void _applySupplementalUserData(Map<String, dynamic> raw) =>
      _performApplySupplementalUserData(raw);

  Future<void> toggleFollowStatus() => _performToggleFollowStatus();

  Future<void> block() => _performBlock();

  Future<void> unblock() => _performUnblock();

  Future<void> getUserStoryUserModelAndPrint(String userId) =>
      _performGetUserStoryUserModelAndPrint(userId);

  Future<void> refreshPostNotificationSubscription() =>
      _performRefreshPostNotificationSubscription();

  Future<void> togglePostNotifications() => _performTogglePostNotifications();

  void _pruneCaches() => _performPruneCaches();

  void _trimMap<T>(Map<String, T> map, DateTime Function(T value) cachedAt) =>
      _performTrimMap(map, cachedAt);

  Future<void> _restoreCachedBuckets() => _performRestoreCachedBuckets();

  Future<void> _fetchPrimaryBuckets({
    required bool initial,
    bool force = false,
  }) =>
      _performFetchPrimaryBuckets(
        initial: initial,
        force: force,
      );

  List<PostsModel> _dedupePosts(
    List<PostsModel> existing,
    List<PostsModel> incoming,
  ) =>
      _performDedupePosts(existing, incoming);
}
