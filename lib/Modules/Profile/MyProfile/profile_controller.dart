import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_posts_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/profile_render_coordinator.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/posts_model.dart';
import '../../../Models/user_post_reference.dart';
import '../../../Services/user_post_link_service.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

part 'profile_controller_header_part.dart';
part 'profile_controller_account_part.dart';
part 'profile_controller_primary_part.dart';
part 'profile_controller_cache_part.dart';
part 'profile_controller_lifecycle_part.dart';
part 'profile_controller_selection_part.dart';

class ProfileController extends GetxController {
  static ProfileController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileController());
  }

  static ProfileController? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileController>();
    if (!isRegistered) return null;
    return Get.find<ProfileController>();
  }

  // 🎯 Using CurrentUserService for optimized user data access
  final userService = CurrentUserService.instance;
  // Aktif oturum kullanıcısını izleyip veri setlerini dinamik yenilemek için
  String? _activeUid;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<Map<String, dynamic>?>? _counterSub;
  final ProfileRepository _profileRepository = ProfileRepository.ensure();
  final ProfilePostsSnapshotRepository _profileSnapshotRepository =
      ProfilePostsSnapshotRepository.ensure();
  final ProfileRenderCoordinator _profileRenderCoordinator =
      ProfileRenderCoordinator.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();
  final SocialMediaLinksRepository _socialLinksRepository =
      SocialMediaLinksRepository.ensure();
  Timer? _persistCacheTimer;
  Worker? _allPostsWorker;
  Worker? _photosWorker;
  Worker? _videosWorker;
  Worker? _resharesWorker;
  Worker? _scheduledWorker;
  Worker? _mergedPostsWorker;
  Worker? _postSelectionWorker;
  var postSelection = 0.obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredIdentity;
  final Map<int, double> _visibleFractions = <int, double>{};
  Timer? _visibilityDebounce;

  var followerCount = 0.obs;
  var followingCount = 0.obs;
  final RxString headerNickname = ''.obs;
  final RxString headerRozet = ''.obs;
  final RxString headerDisplayName = ''.obs;
  final RxString headerAvatarUrl = ''.obs;
  final RxString headerFirstName = ''.obs;
  final RxString headerLastName = ''.obs;
  final RxString headerMeslek = ''.obs;
  final RxString headerBio = ''.obs;
  final RxString headerAdres = ''.obs;

  final RxList<PostsModel> allPosts = <PostsModel>[].obs;
  final RxList<Map<String, dynamic>> mergedPosts = <Map<String, dynamic>>[].obs;
  DocumentSnapshot? lastPostDoc;
  bool hasMorePosts = true;
  final int postLimit = 10;
  bool isLoadingMore = false;
  DocumentSnapshot<Map<String, dynamic>>? _lastPrimaryDoc;
  bool _hasMorePrimary = true;
  bool _isLoadingPrimary = false;

  // İz Bırak (gelecek tarihli) gönderiler
  final RxList<PostsModel> scheduledPosts = <PostsModel>[].obs;
  DocumentSnapshot? lastScheduledDoc;
  bool hasMoreScheduled = true;
  final int scheduledLimit = 10;
  bool isLoadingScheduled = false;

  final RxList<PostsModel> photos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocPhotos;
  bool hasMorePostsPhotos = true;
  final int postLimitPhotos = 10;
  bool isLoadingMorePhotos = false;

  final RxList<PostsModel> videos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocVideos;
  bool hasMorePostsVideos = true;
  final int postLimitVideos = 10;
  bool isLoadingMoreVideos = false;

  final RxList<PostsModel> reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? _resharesSub;
  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  List<UserPostReference> _latestReshareRefs = const [];
  final Map<String, GlobalKey> _postKeys = {};

  var pausetheall = false.obs;
  final RxBool showScrollToTop = false.obs;
  final Map<int, ScrollController> _scrollControllers =
      <int, ScrollController>{};
  var showPfImage = false.obs;

  String? get _resolvedActiveUid => _performResolvedActiveUid();

  ScrollController scrollControllerForSelection(int selection) =>
      _performScrollControllerForSelection(selection);

  ScrollController get currentScrollController =>
      _performCurrentScrollController();

  ScrollPosition? get currentScrollPosition =>
      _performCurrentScrollPosition();

  double get currentScrollOffset => _performCurrentScrollOffset();

  Future<void> animateCurrentSelectionToTop() =>
      _performAnimateCurrentSelectionToTop();

  void resetSurfaceForTabTransition() =>
      _performResetSurfaceForTabTransition();

  @override
  void onInit() {
    super.onInit();
    _performOnInit();
  }

  int resolveResumeCenteredIndex() => _performResolveResumeCenteredIndex();

  void resumeCenteredPost() => _performResumeCenteredPost();

  void capturePendingCenteredEntry({int? preferredIndex}) =>
      _performCapturePendingCenteredEntry(preferredIndex: preferredIndex);

  @override
  void onClose() {
    _performOnClose();
    super.onClose();
  }

  Future<void> _bootstrapProfileData() => _performBootstrapProfileData();

  Future<void> _bootstrapHeaderFromTypesense() =>
      _performBootstrapHeaderFromTypesense();

  bool _needsHeaderSupplementalData(Map<String, dynamic> data) =>
      _performNeedsHeaderSupplementalData(data);

  void _applyHeaderCard(Map<String, dynamic> data) =>
      _performApplyHeaderCard(data);

  void _bindCacheWorkers() => _performBindCacheWorkers();

  void _rebuildMergedPosts() => _performRebuildMergedPosts();

  int _resolveInitialCenteredIndex() => _performResolveInitialCenteredIndex();

  bool _canAutoplayMergedEntry(Map<String, dynamic> entry) =>
      _performCanAutoplayMergedEntry(entry);

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);

  void _scheduleVisibilityEvaluation() =>
      _performScheduleVisibilityEvaluation();

  void _evaluateCenteredPlayback() => _performEvaluateCenteredPlayback();

  void _schedulePersistPostCaches() => _performSchedulePersistPostCaches();

  Future<void> _persistPostCaches(String uid) => _performPersistPostCaches(uid);

  Future<void> _restoreCachedListsForActiveUser() =>
      _performRestoreCachedListsForActiveUser();

  Future<void> _warmProfileSurfaceCache() => _performWarmProfileSurfaceCache();

  void _clearInMemoryPostLists() => _performClearInMemoryPostLists();

  void _listenToCounterChanges() => _performListenToCounterChanges();

  void _bindResharesRealtime() => _performBindResharesRealtime();

  Future<void> _hydrateReshares(String uid, List<UserPostReference> refs) =>
      _performHydrateReshares(uid, refs);

  int reshareSortTimestampFor(String postId, int fallback) =>
      _performReshareSortTimestampFor(postId, fallback);

  void _onAuthChanged(User? user) => _performOnAuthChanged(user);

  Future<void> getCounters() => _performGetCounters();

  void setPostSelection(int index) => _performSetPostSelection(index);

  GlobalKey getPostKey({
    required String docId,
    required bool isReshare,
  }) =>
      _performGetPostKey(
        docId: docId,
        isReshare: isReshare,
      );

  String mergedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) =>
      _performMergedEntryIdentity(
        docId: docId,
        isReshare: isReshare,
      );

  int indexOfMergedEntry({
    required String docId,
    required bool isReshare,
  }) =>
      _performIndexOfMergedEntry(
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

  void disposeAgendaContentController(String docID) =>
      _performDisposeAgendaContentController(docID);

  Future<void> fetchPosts({bool isInitial = false, bool force = false}) =>
      _performFetchPosts(
        isInitial: isInitial,
        force: force,
      );

  Future<void> fetchPhotos({bool isInitial = false, bool force = false}) =>
      _performFetchPhotos(
        isInitial: isInitial,
        force: force,
      );

  Future<void> fetchVideos({bool isInitial = false, bool force = false}) =>
      _performFetchVideos(
        isInitial: isInitial,
        force: force,
      );

  Future<void> fetchScheduledPosts({
    bool isInitial = false,
    bool force = false,
  }) =>
      _performFetchScheduledPosts(
        isInitial: isInitial,
        force: force,
      );

  Future<void> showSocialMediaLinkDelete(String docID) =>
      _performShowSocialMediaLinkDelete(docID);

  Future<void> getLastPostAndAddToAllPosts() =>
      _performGetLastPostAndAddToAllPosts();

  Future<void> getReshares() => _performGetReshares();

  Future<void> getResharesSingle() => _performGetResharesSingle();

  void removeReshare(String postId) => _performRemoveReshare(postId);

  Future<void> refreshAll({bool forceSync = false}) =>
      _performRefreshAll(forceSync: forceSync);

  Future<void> _loadInitialPrimaryBuckets({
    bool forceSync = false,
  }) =>
      _performLoadInitialPrimaryBuckets(forceSync: forceSync);

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

  bool _applyProfileBuckets(ProfileBuckets? buckets) =>
      _performApplyProfileBuckets(buckets);
}
