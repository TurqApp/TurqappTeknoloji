part of 'visibility_policy_service.dart';

bool isDiscoveryPublicAuthor({
  required String rozet,
  required bool isApproved,
}) {
  return rozet.trim().isNotEmpty || isApproved;
}

bool canViewerSeeDiscoverySurfaceAuthor({
  required String authorUserId,
  required Set<String> followingIds,
  required String rozet,
  required bool isApproved,
  required bool isDeleted,
  String? viewerUserId,
}) {
  final uid = authorUserId.trim();
  if (uid.isEmpty) return false;
  if (isDeleted) return false;

  final me =
      (viewerUserId ?? CurrentUserService.instance.effectiveUserId).trim();
  if (me.isNotEmpty && me == uid) return true;
  if (isDiscoveryPublicAuthor(rozet: rozet, isApproved: isApproved)) {
    return true;
  }
  return followingIds.contains(uid);
}

extension VisibilityPolicyServiceSupportPart on VisibilityPolicyService {
  Future<bool> _canViewerSeeAuthorImpl({
    required String authorUserId,
    required Set<String> followingIds,
    required bool preferCache,
  }) async {
    final uid = authorUserId.trim();
    if (uid.isEmpty) return false;

    final me = CurrentUserService.instance.effectiveUserId;
    if (me.isNotEmpty && me == uid) return true;

    final summary = await _resolver.resolve(
      uid,
      preferCache: preferCache,
    );
    if (summary == null) return false;
    if (summary.isDeleted) return false;
    if (!summary.isPrivate) return true;
    return followingIds.contains(uid);
  }

  Future<bool> _canViewerSeeDiscoveryAuthorImpl({
    required String authorUserId,
    required Set<String> followingIds,
    required bool preferCache,
  }) async {
    final uid = authorUserId.trim();
    if (uid.isEmpty) return false;

    final me = CurrentUserService.instance.effectiveUserId.trim();
    if (me.isNotEmpty && me == uid) return true;

    final summary = await _resolver.resolve(
      uid,
      preferCache: preferCache,
    );
    if (summary == null) return false;
    return canViewerSeeDiscoverySurfaceAuthor(
      authorUserId: uid,
      followingIds: followingIds,
      rozet: summary.rozet,
      isApproved: summary.isApproved,
      isDeleted: summary.isDeleted,
      viewerUserId: me,
    );
  }

  Future<Set<String>> _loadViewerFollowingIdsImpl({
    String? viewerUserId,
    required bool preferCache,
    required bool forceRefresh,
  }) async {
    final viewerUid =
        (viewerUserId ?? CurrentUserService.instance.effectiveUserId).trim();
    if (viewerUid.isEmpty) return <String>{};
    return _followRepository.getFollowingIds(
      viewerUid,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  bool _canViewerSeeAuthorFromSummaryImpl({
    required String authorUserId,
    required Set<String> followingIds,
    required bool isPrivate,
    required bool isDeleted,
  }) {
    final uid = authorUserId.trim();
    if (uid.isEmpty) return false;
    if (isDeleted) return false;

    final me = CurrentUserService.instance.effectiveUserId;
    if (me.isNotEmpty && me == uid) return true;
    if (!isPrivate) return true;
    return followingIds.contains(uid);
  }

  bool _canViewerSeeDiscoveryAuthorFromSummaryImpl({
    required String authorUserId,
    required Set<String> followingIds,
    required String rozet,
    required bool isApproved,
    required bool isDeleted,
    String? viewerUserId,
  }) {
    return canViewerSeeDiscoverySurfaceAuthor(
      authorUserId: authorUserId,
      followingIds: followingIds,
      rozet: rozet,
      isApproved: isApproved,
      isDeleted: isDeleted,
      viewerUserId: viewerUserId,
    );
  }
}
