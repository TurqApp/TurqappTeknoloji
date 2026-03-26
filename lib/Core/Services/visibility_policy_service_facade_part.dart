part of 'visibility_policy_service.dart';

extension VisibilityPolicyServiceFacadePart on VisibilityPolicyService {
  Future<Set<String>> loadViewerFollowingIds({
    String? viewerUserId,
    bool preferCache = true,
    bool forceRefresh = false,
  }) =>
      _loadViewerFollowingIdsImpl(
        viewerUserId: viewerUserId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
      );

  Future<bool> canViewerSeeAuthor({
    required String authorUserId,
    required Set<String> followingIds,
    bool preferCache = true,
  }) =>
      _canViewerSeeAuthorImpl(
        authorUserId: authorUserId,
        followingIds: followingIds,
        preferCache: preferCache,
      );

  Future<bool> canViewerSeeDiscoveryAuthor({
    required String authorUserId,
    required Set<String> followingIds,
    bool preferCache = true,
  }) =>
      _canViewerSeeDiscoveryAuthorImpl(
        authorUserId: authorUserId,
        followingIds: followingIds,
        preferCache: preferCache,
      );

  bool canViewerSeeAuthorFromSummary({
    required String authorUserId,
    required Set<String> followingIds,
    required bool isPrivate,
    required bool isDeleted,
  }) =>
      _canViewerSeeAuthorFromSummaryImpl(
        authorUserId: authorUserId,
        followingIds: followingIds,
        isPrivate: isPrivate,
        isDeleted: isDeleted,
      );

  bool canViewerSeeDiscoveryAuthorFromSummary({
    required String authorUserId,
    required Set<String> followingIds,
    required String rozet,
    required bool isApproved,
    required bool isDeleted,
    String? viewerUserId,
  }) =>
      _canViewerSeeDiscoveryAuthorFromSummaryImpl(
        authorUserId: authorUserId,
        followingIds: followingIds,
        rozet: rozet,
        isApproved: isApproved,
        isDeleted: isDeleted,
        viewerUserId: viewerUserId,
      );
}
