import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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

  Future<bool> canViewerSeeAuthor({
    required String authorUserId,
    required Set<String> followingIds,
    bool preferCache = true,
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

  Future<bool> canViewerSeeDiscoveryAuthor({
    required String authorUserId,
    required Set<String> followingIds,
    bool preferCache = true,
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

  bool canViewerSeeAuthorFromSummary({
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

  bool canViewerSeeDiscoveryAuthorFromSummary({
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
