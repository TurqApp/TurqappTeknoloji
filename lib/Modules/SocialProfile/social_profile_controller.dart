import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Models/posts_model.dart';
import '../../Models/user_post_reference.dart';
import '../../Services/user_post_link_service.dart';
import '../../Services/user_analytics_service.dart';
import 'package:turqappv2/Core/notification_service.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';
import '../Profile/SocialMediaLinks/social_media_links_controller.dart';
import '../Story/StoryRow/story_user_model.dart';

part 'social_profile_controller_profile_part.dart';
part 'social_profile_controller_actions_part.dart';
part 'social_profile_controller_feed_part.dart';
part 'social_profile_controller_feed_selection_part.dart';

class SocialProfileController extends GetxController {
  static SocialProfileController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SocialProfileController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static SocialProfileController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SocialProfileController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SocialProfileController>(tag: tag);
  }

  var totalMarket = 0.obs;
  var totalPosts = 0.obs;
  var totalLikes = 0.obs;
  var totalFollower = 0.obs;
  var totalFollowing = 0.obs;
  var postSelection = 0.obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredIdentity;

  final ScrollController scrollController = ScrollController();
  final RxList<SocialMediaModel> socialMediaList = <SocialMediaModel>[].obs;
  final RxList<PostsModel> reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? _resharesSub;
  final UserRepository _userRepository = UserRepository.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final SocialMediaLinksRepository _socialLinksRepository =
      SocialMediaLinksRepository.ensure();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();
  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  final Map<String, GlobalKey> _postKeys = {};
  var showPfImage = false.obs;

  String userID;
  SocialProfileController({required this.userID});
  var nickname = "".obs;
  var displayName = "".obs;
  var avatarUrl = "".obs;
  var firstName = "".obs;
  var lastName = "".obs;
  var token = "".obs;
  var email = "".obs;
  var rozet = "".obs;
  var bio = "".obs;

  var adres = "".obs;
  var phoneNumber = "".obs;
  var mailIzin = false.obs;
  var aramaIzin = false.obs;
  var ban = false.obs;
  var gizliHesap = false.obs;
  var hesapOnayi = false.obs;
  var meslek = "".obs;
  var blockedUsers = <String>[].obs;
  var complatedCheck = false.obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;
  static const Duration _followCheckCacheTtl = Duration(seconds: 20);
  static const Duration _counterCacheTtl = Duration(seconds: 30);
  static const Duration _cacheStaleRetention = Duration(minutes: 3);
  static const int _maxCacheEntries = 500;
  static final Map<String, _SocialFollowCheckCacheEntry> _followCheckCache =
      <String, _SocialFollowCheckCacheEntry>{};
  static final Map<String, _SocialCounterCacheEntry> _counterCache =
      <String, _SocialCounterCacheEntry>{};

  final RxList<PostsModel> allPosts = <PostsModel>[].obs;

  final RxList<PostsModel> photos = <PostsModel>[].obs;
  final RxList<PostsModel> scheduledPosts = <PostsModel>[].obs;

  final RxBool isLoadingPosts = false.obs;
  final RxBool hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;
  final int pageSize = 12;
  final ProfileRepository _profileRepository = ProfileRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  DocumentSnapshot<Map<String, dynamic>>? _lastPrimaryDoc;
  bool _hasMorePrimary = true;
  bool _isLoadingPrimary = false;

  final RxBool isLoadingPhoto = false.obs;
  final RxBool hasMorePhoto = true.obs;
  DocumentSnapshot? lastPostDocPhoto;
  final int pageSizePhoto = 12;

  // Scheduled (İz Bırak)
  final RxBool isLoadingScheduled = false.obs;
  final RxBool hasMoreScheduled = true.obs;
  DocumentSnapshot? lastScheduledDoc;
  final int pageSizeScheduled = 12;
  StoryUserModel? storyUserModel;
  // Yukarı butonu
  final RxBool showScrollToTop = false.obs;
  StreamSubscription<Map<String, dynamic>?>? _userDocSub;

  String _resolveNickname(
    Map<String, dynamic> raw,
    Map<String, dynamic> profile,
  ) =>
      _performResolveNickname(raw, profile);

  int resolveResumeCenteredIndex() => _performResolveResumeCenteredIndex();

  void resumeCenteredPost() => _performResumeCenteredPost();

  void capturePendingCenteredEntry({
    int? preferredIndex,
    PostsModel? model,
    bool isReshare = false,
  }) =>
      _performCapturePendingCenteredEntry(
        preferredIndex: preferredIndex,
        model: model,
        isReshare: isReshare,
      );

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }

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

class _SocialFollowCheckCacheEntry {
  final bool isFollowing;
  final DateTime cachedAt;

  const _SocialFollowCheckCacheEntry({
    required this.isFollowing,
    required this.cachedAt,
  });
}

class _SocialCounterCacheEntry {
  final int followers;
  final int followings;
  final DateTime cachedAt;

  const _SocialCounterCacheEntry({
    required this.followers,
    required this.followings,
    required this.cachedAt,
  });
}

final VisibilityPolicyService _visibilityPolicy =
    VisibilityPolicyService.ensure();
