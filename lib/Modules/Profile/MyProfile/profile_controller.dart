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
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../../Models/posts_model.dart';
import '../../../Models/user_post_reference.dart';
import '../../../Services/user_post_link_service.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

class ProfileController extends GetxController {
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

  String _preserveNonEmpty(
    RxString target,
    dynamic raw,
  ) {
    final next = (raw ?? '').toString().trim();
    if (next.isNotEmpty) return next;
    return target.value.trim();
  }

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
  final UserPostLinkService _linkService = Get.put(UserPostLinkService());
  List<UserPostReference> _latestReshareRefs = const [];
  final Map<int, GlobalKey> _postKeys = {};

  var pausetheall = false.obs;
  final RxBool showScrollToTop = false.obs;
  final Map<int, ScrollController> _scrollControllers =
      <int, ScrollController>{};
  var showPfImage = false.obs;

  ScrollController scrollControllerForSelection(int selection) {
    return _scrollControllers.putIfAbsent(
      selection,
      () => _buildTrackedScrollController(selection),
    );
  }

  ScrollController get currentScrollController =>
      scrollControllerForSelection(postSelection.value);

  @override
  void onInit() {
    super.onInit();
    // Aktif kullanıcıyı kaydet ve auth değişimini dinle
    _activeUid = FirebaseAuth.instance.currentUser?.uid;
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);

    _bindCacheWorkers();
    unawaited(_bootstrapProfileData());
    for (final selection in const <int>[0, 1, 2, 3, 4, 5]) {
      scrollControllerForSelection(selection);
    }
    _postSelectionWorker = ever<int>(postSelection, (selection) {
      final controller = scrollControllerForSelection(selection);
      _syncScrollToTopVisibility(
        controller.hasClients ? controller.offset : 0,
      );
      if (selection == 5 &&
          (scheduledPosts.isEmpty || lastScheduledDoc == null)) {
        unawaited(fetchScheduledPosts(isInitial: true));
      }
    });
  }

  ScrollController _buildTrackedScrollController(int selection) {
    final controller = ScrollController();
    controller.addListener(() {
      if (postSelection.value != selection) return;
      _syncScrollToTopVisibility(controller.offset);
    });
    return controller;
  }

  void _syncScrollToTopVisibility(double offset) {
    final shouldShow = offset > 500;
    if (showScrollToTop.value == shouldShow) {
      return;
    }
    showScrollToTop.value = shouldShow;
  }

  int resolveResumeCenteredIndex() {
    if (mergedPosts.isEmpty) return -1;
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < mergedPosts.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < mergedPosts.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final expectedDocId = (lastCenteredIndex != null &&
            lastCenteredIndex! >= 0 &&
            lastCenteredIndex! < mergedPosts.length)
        ? (mergedPosts[lastCenteredIndex!]['docID'] as String?)
        : null;
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= mergedPosts.length) return;
    lastCenteredIndex = target;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    pausetheall.value = false;
    _invariantGuard.assertCenteredSelection(
      surface: 'profile',
      invariantKey: 'resume_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: mergedPosts
          .map((post) => (post['docID'] as String?) ?? '')
          .toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );
  }

  @override
  void onClose() {
    // Bellek sızıntısını önlemek için dinleyiciyi kapat
    _authSub?.cancel();
    _resharesSub?.cancel();
    _counterSub?.cancel();
    _persistCacheTimer?.cancel();
    _allPostsWorker?.dispose();
    _photosWorker?.dispose();
    _videosWorker?.dispose();
    _resharesWorker?.dispose();
    _scheduledWorker?.dispose();
    _mergedPostsWorker?.dispose();
    _postSelectionWorker?.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> _bootstrapProfileData() async {
    await _restoreCachedListsForActiveUser();
    await _bootstrapHeaderFromTypesense();
    getCounters();
    _listenToCounterChanges();
    _bindResharesRealtime();
    await _loadInitialPrimaryBuckets();
    getReshares();
  }

  Future<void> _bootstrapHeaderFromTypesense() async {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final summary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
        cacheOnly: false,
      );
      final cachedRaw = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final bootstrapData = cachedRaw ??
          (summary != null ? summary.toMap() : const <String, dynamic>{});
      if (bootstrapData.isEmpty) return;
      _applyHeaderCard(bootstrapData);
      if (_needsHeaderSupplementalData(bootstrapData)) {
        final raw = await _userRepository.getUserRaw(
          uid,
          preferCache: false,
          forceServer: true,
        );
        if (raw != null && raw.isNotEmpty) {
          await _userRepository.putUserRaw(uid, raw);
          _applyHeaderCard(raw);
        }
      }
    } catch (e) {
      print('_bootstrapHeaderFromTypesense error: $e');
    }
  }

  bool _needsHeaderSupplementalData(Map<String, dynamic> data) {
    final bioText = (data['bio'] ?? '').toString().trim();
    final addressText = (data['adres'] ?? '').toString().trim();
    final meslekText = (data['meslekKategori'] ?? '').toString().trim();
    return bioText.isEmpty || addressText.isEmpty || meslekText.isEmpty;
  }

  void _applyHeaderCard(Map<String, dynamic> data) {
    headerNickname.value =
        (data['nickname'] ?? data['username'] ?? '').toString().trim();
    headerRozet.value =
        (data['rozet'] ?? data['badge'] ?? '').toString().trim();
    headerDisplayName.value = (data['displayName'] ?? '').toString().trim();
    headerAvatarUrl.value = (data['avatarUrl'] ?? '').toString().trim();

    final display = headerDisplayName.value.trim();
    if (display.isNotEmpty) {
      headerFirstName.value = display;
      headerLastName.value = '';
    } else {
      headerFirstName.value =
          _preserveNonEmpty(headerFirstName, data['firstName']);
      headerLastName.value =
          _preserveNonEmpty(headerLastName, data['lastName']);
    }
    headerMeslek.value =
        _preserveNonEmpty(headerMeslek, data['meslekKategori']);
    headerBio.value = _preserveNonEmpty(headerBio, data['bio']);
    headerAdres.value = _preserveNonEmpty(headerAdres, data['adres']);
  }

  void _bindCacheWorkers() {
    _allPostsWorker = ever(allPosts, (_) => _schedulePersistPostCaches());
    _photosWorker = ever(photos, (_) => _schedulePersistPostCaches());
    _videosWorker = ever(videos, (_) => _schedulePersistPostCaches());
    _resharesWorker = ever(reshares, (_) => _schedulePersistPostCaches());
    _scheduledWorker =
        ever(scheduledPosts, (_) => _schedulePersistPostCaches());
    _mergedPostsWorker = everAll(
      [allPosts, reshares],
      (_) => _rebuildMergedPosts(),
    );
    _rebuildMergedPosts();
  }

  void _rebuildMergedPosts() {
    if (allPosts.isEmpty && reshares.isEmpty) {
      mergedPosts.clear();
      return;
    }

    final combined = _profileRenderCoordinator.buildMergedEntries(
      allPosts: allPosts.toList(growable: false),
      reshares: reshares.toList(growable: false),
      reshareSortTimestampFor: reshareSortTimestampFor,
    );
    final patch = _profileRenderCoordinator.buildPatch(
      previous: mergedPosts.toList(growable: false),
      next: combined,
    );
    _profileRenderCoordinator.applyPatch(mergedPosts, patch);
  }

  void _schedulePersistPostCaches() {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _persistCacheTimer?.cancel();
    _persistCacheTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistPostCaches(uid));
    });
  }

  Future<void> _persistPostCaches(String uid) async {
    await _profileSnapshotRepository.persistBuckets(
      userId: uid,
      buckets: ProfileBuckets(
        all: allPosts,
        photos: photos,
        videos: videos,
        scheduled: scheduledPosts,
      ),
      limit: postLimit,
      source: CachedResourceSource.server,
    );
  }

  Future<void> _restoreCachedListsForActiveUser() async {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final resource = await _profileSnapshotRepository.bootstrapProfile(
      userId: uid,
      limit: postLimit,
    );
    _applyProfileBuckets(resource.data);
    unawaited(_warmProfileSurfaceCache());
  }

  Future<void> _warmProfileSurfaceCache() async {
    final urls = <String>{
      userService.avatarUrl,
    };

    void collectFrom(Iterable<PostsModel> posts) {
      for (final post in posts.take(18)) {
        if (post.thumbnail.trim().isNotEmpty) {
          urls.add(post.thumbnail.trim());
        }
        if (post.authorAvatarUrl.trim().isNotEmpty) {
          urls.add(post.authorAvatarUrl.trim());
        }
        for (final img in post.img.take(2)) {
          final normalized = img.trim();
          if (normalized.isNotEmpty) {
            urls.add(normalized);
          }
        }
      }
    }

    collectFrom(allPosts);
    collectFrom(photos);
    collectFrom(videos);
    collectFrom(scheduledPosts);

    for (final url in urls.where((e) => e.isNotEmpty).take(32)) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
  }

  void _clearInMemoryPostLists() {
    allPosts.clear();
    photos.clear();
    videos.clear();
    reshares.clear();
    scheduledPosts.clear();
    _lastPrimaryDoc = null;
    _hasMorePrimary = true;
  }

  void _listenToCounterChanges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _counterSub?.cancel();

    // ⚠️ REAL-TIME FIX: Listen to user document changes for instant counter updates
    _counterSub = _userRepository.watchUserRaw(uid).listen((snapshot) {
      final data = snapshot;
      if (data != null) {
        followerCount.value = (data['counterOfFollowers'] as num?)?.toInt() ??
            (data['followersCount'] as num?)?.toInt() ??
            (data['takipci'] as num?)?.toInt() ??
            (data['followerCount'] as num?)?.toInt() ??
            0;
        followingCount.value = (data['counterOfFollowings'] as num?)?.toInt() ??
            (data['followingCount'] as num?)?.toInt() ??
            (data['takip'] as num?)?.toInt() ??
            (data['followCount'] as num?)?.toInt() ??
            0;
      }
    });
  }

  void _bindResharesRealtime() {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _resharesSub?.cancel();
    _resharesSub = _linkService.listenResharedPosts(uid).listen((refs) {
      _latestReshareRefs = refs;
      _hydrateReshares(uid, refs);
    });
  }

  Future<void> _hydrateReshares(
      String uid, List<UserPostReference> refs) async {
    try {
      final posts = await _linkService.fetchResharedPosts(uid, refs);
      if (posts.isNotEmpty || reshares.isEmpty) {
        // fetchResharedPosts bazı akışlarda unmodifiable liste döndürebiliyor.
        // RxList'e modifiable kopya atarak insert/remove hatalarını engelle.
        reshares.assignAll(List<PostsModel>.from(posts));
      }
    } catch (e) {
      print('ProfileController hydrate reshares error: $e');
    }
  }

  int reshareSortTimestampFor(String postId, int fallback) {
    for (final ref in _latestReshareRefs) {
      if (ref.postId == postId) return ref.timeStamp.toInt();
    }
    return fallback;
  }

  void _onAuthChanged(User? user) {
    final newUid = user?.uid;
    // Oturum kapandıysa tüm verileri sıfırla
    if (newUid == null) {
      _activeUid = null;
      _counterSub?.cancel();
      _counterSub = null;
      // ⚠️ CRITICAL FIX: Safely clear RxLists
      try {
        allPosts.clear();
      } catch (e) {
        allPosts.value = [];
      }
      try {
        photos.clear();
      } catch (e) {
        photos.value = [];
      }
      try {
        videos.clear();
      } catch (e) {
        videos.value = [];
      }
      try {
        reshares.clear();
      } catch (e) {
        reshares.value = [];
      }
      try {
        scheduledPosts.clear();
      } catch (e) {
        scheduledPosts.value = [];
      }

      followerCount.value = 0;
      followingCount.value = 0;
      // Pagination göstergelerini de sıfırla
      lastPostDoc = null;
      lastPostDocPhotos = null;
      lastPostDocVideos = null;
      lastScheduledDoc = null;
      hasMorePosts = true;
      hasMorePostsPhotos = true;
      hasMorePostsVideos = true;
      hasMoreScheduled = true;
      return;
    }

    // Kullanıcı değiştiyse (logout/login) verileri taze çek
    if (newUid != _activeUid) {
      _activeUid = newUid;
      _clearInMemoryPostLists();
      _listenToCounterChanges();
      unawaited(_restoreCachedListsForActiveUser());
      refreshAll();
    }
  }

  Future<void> getCounters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final data = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
      );
      followerCount.value = (data?['counterOfFollowers'] as num?)?.toInt() ??
          (data?['followersCount'] as num?)?.toInt() ??
          (data?['takipci'] as num?)?.toInt() ??
          (data?['followerCount'] as num?)?.toInt() ??
          0;
      followingCount.value = (data?['counterOfFollowings'] as num?)?.toInt() ??
          (data?['followingCount'] as num?)?.toInt() ??
          (data?['takip'] as num?)?.toInt() ??
          (data?['followCount'] as num?)?.toInt() ??
          0;

      if (followerCount.value == 0 || followingCount.value == 0) {
        final followers = await _followRepository.getFollowerIds(
          uid,
          preferCache: true,
          forceRefresh: false,
        );
        final followings = await _followRepository.getFollowingIds(
          uid,
          preferCache: true,
          forceRefresh: false,
        );
        followerCount.value = followers.length;
        followingCount.value = followings.length;
      }
    } catch (e) {
      print("⚠️ getCounters error: $e");
    }
  }

  void setPostSelection(int index) {
    postSelection.value = index;
  }

  GlobalKey getPostKey(int index) {
    return _postKeys.putIfAbsent(index, () => GlobalObjectKey('post_$index'));
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
    }
  }

  Future<void> fetchPosts({bool isInitial = false, bool force = false}) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> fetchPhotos({bool isInitial = false, bool force = false}) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> fetchVideos({bool isInitial = false, bool force = false}) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> fetchScheduledPosts(
      {bool isInitial = false, bool force = false}) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> showSocialMediaLinkDelete(String docID) async {
    await noYesAlert(
      title: "profile.link_remove_title".tr,
      message: "profile.link_remove_body".tr,
      cancelText: "common.cancel".tr,
      yesText: "common.remove".tr,
      onYesPressed: () async {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await _socialLinksRepository.deleteLink(uid, docID);
        final links = Get.find<SocialMediaController>();
        links.getData();
      },
    );
  }

  Future<void> getLastPostAndAddToAllPosts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final lastPost = await _profileRepository.fetchLatestProfilePost(uid);
    if (lastPost == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (lastPost.timeStamp > nowMs || lastPost.deletedPost == true) {
      return;
    }
    if (lastPost.video.trim().isNotEmpty && !lastPost.hasPlayableVideo) {
      return;
    }

    final existsIndex = allPosts.indexWhere((p) => p.docID == lastPost.docID);
    if (existsIndex == -1) {
      final List<PostsModel> currentPosts = List<PostsModel>.from(allPosts);
      currentPosts.insert(0, lastPost);
      allPosts.value = currentPosts;
    } else if (existsIndex > 0) {
      final List<PostsModel> currentPosts = List<PostsModel>.from(allPosts);
      final existing = currentPosts.removeAt(existsIndex);
      currentPosts.insert(0, existing);
      allPosts.value = currentPosts;
    }
  }

  Future<void> getReshares() async {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _hydrateReshares(uid, _latestReshareRefs);
  }

  Future<void> getResharesSingle() async {
    final uid = _activeUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final post = await _profileRepository.fetchLatestResharePost(uid);
    if (post == null) {
      reshares.clear();
      return;
    }

    if (post.timeStamp > DateTime.now().millisecondsSinceEpoch ||
        post.deletedPost == true) {
      return;
    }

    final exists = reshares.any((p) => p.docID == post.docID);
    if (!exists) {
      reshares.insert(0, post);
    }
  }

  void removeReshare(String postId) {
    reshares.removeWhere((post) => post.docID == postId);
  }

  Future<void> refreshAll() async {
    try {
      await _bootstrapHeaderFromTypesense();
      // Sayaçlar
      await getCounters();

      await Future.wait([
        _loadInitialPrimaryBuckets(forceSync: true),
        getReshares(),
      ]);
    } catch (e) {
      print('refreshAll error: $e');
    }
  }

  Future<void> _loadInitialPrimaryBuckets({
    bool forceSync = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final resource = await _profileSnapshotRepository.loadProfile(
      userId: uid,
      limit: postLimit,
      forceSync: forceSync,
    );
    final applied = _applyProfileBuckets(resource.data);
    if (!applied) {
      await _fetchPrimaryBuckets(initial: true, force: forceSync);
      return;
    }
    _lastPrimaryDoc = null;
    _hasMorePrimary = true;
    lastPostDoc = null;
    lastPostDocPhotos = null;
    lastPostDocVideos = null;
    lastScheduledDoc = null;
    hasMorePosts = true;
    hasMorePostsPhotos = true;
    hasMorePostsVideos = true;
    hasMoreScheduled = true;
    unawaited(_warmProfileSurfaceCache());
  }

  Future<void> _fetchPrimaryBuckets({
    required bool initial,
    bool force = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_isLoadingPrimary && !force) return;
    if (!initial && !_hasMorePrimary) return;

    _isLoadingPrimary = true;
    isLoadingMore = true;
    isLoadingMorePhotos = true;
    isLoadingMoreVideos = true;
    isLoadingScheduled = true;

    try {
      if (initial) {
        _lastPrimaryDoc = null;
        _hasMorePrimary = true;
      }

      final page = await _profileRepository.fetchPrimaryPage(
        uid: uid,
        startAfter: initial ? null : _lastPrimaryDoc,
        limit: postLimit,
      );

      if (initial) {
        allPosts.assignAll(page.all);
        photos.assignAll(page.photos);
        videos.assignAll(page.videos);
        scheduledPosts.assignAll(page.scheduled);
      } else {
        allPosts.addAll(_dedupePosts(allPosts, page.all));
        photos.addAll(_dedupePosts(photos, page.photos));
        videos.addAll(_dedupePosts(videos, page.videos));
        scheduledPosts.addAll(_dedupePosts(scheduledPosts, page.scheduled));
      }

      _lastPrimaryDoc = page.lastDoc;
      _hasMorePrimary = page.hasMore;
      lastPostDoc = _lastPrimaryDoc;
      lastPostDocPhotos = _lastPrimaryDoc;
      lastPostDocVideos = _lastPrimaryDoc;
      lastScheduledDoc = _lastPrimaryDoc;
      hasMorePosts = _hasMorePrimary;
      hasMorePostsPhotos = _hasMorePrimary;
      hasMorePostsVideos = _hasMorePrimary;
      hasMoreScheduled = _hasMorePrimary;
      unawaited(_warmProfileSurfaceCache());
    } catch (e) {
      print('_fetchPrimaryBuckets error: $e');
    } finally {
      _isLoadingPrimary = false;
      isLoadingMore = false;
      isLoadingMorePhotos = false;
      isLoadingMoreVideos = false;
      isLoadingScheduled = false;
    }
  }

  List<PostsModel> _dedupePosts(
    List<PostsModel> existing,
    List<PostsModel> incoming,
  ) {
    final known = existing.map((e) => e.docID).toSet();
    return incoming.where((post) => known.add(post.docID)).toList();
  }

  bool _applyProfileBuckets(ProfileBuckets? buckets) {
    if (buckets == null) return false;
    if (buckets.all.isEmpty &&
        buckets.photos.isEmpty &&
        buckets.videos.isEmpty &&
        buckets.scheduled.isEmpty) {
      return false;
    }
    if (buckets.all.isNotEmpty) allPosts.assignAll(buckets.all);
    if (buckets.photos.isNotEmpty) photos.assignAll(buckets.photos);
    if (buckets.videos.isNotEmpty) videos.assignAll(buckets.videos);
    if (buckets.scheduled.isNotEmpty) {
      scheduledPosts.assignAll(buckets.scheduled);
    }
    return true;
  }
}
