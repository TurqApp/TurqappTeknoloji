import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'visibility_policy_service_support_part.dart';

class VisibilityPolicyService extends GetxService {
  static VisibilityPolicyService? maybeFind() {
    final isRegistered = Get.isRegistered<VisibilityPolicyService>();
    if (!isRegistered) return null;
    return Get.find<VisibilityPolicyService>();
  }

  static VisibilityPolicyService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(VisibilityPolicyService(), permanent: true);
  }

  final UserSummaryResolver _resolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();

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
