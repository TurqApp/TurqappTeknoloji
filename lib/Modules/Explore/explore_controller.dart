import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/explore_repository.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';

import '../../Models/posts_model.dart';

part 'explore_controller_recent_search_part.dart';

class ExploreController extends GetxController {
  static const double _verticalExploreAspectMax = 0.7;
  static const String _recentSearchUsersCachePrefix =
      'explore_recent_search_users_v1_';
  static const int _recentSearchUsersLimit = 100;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);
  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  RxString searchText = "".obs;
  RxList<OgrenciModel> searchedList = <OgrenciModel>[].obs;
  RxList<OgrenciModel> recentSearchUsers = <OgrenciModel>[].obs;
  RxList<HashtagModel> searchedHashtags = <HashtagModel>[].obs;
  RxList<HashtagModel> searchedTags = <HashtagModel>[].obs;
  RxBool showAllRecent = false.obs;
  RxBool isKeyboardOpen = false.obs;
  RxBool isSearchMode = false.obs;
  final scrollController = ScrollController();
  RxList<HashtagModel> trendingTags = <HashtagModel>[].obs;

  // -------------- Sana Özel (explorePosts) --------------
  final ScrollController exploreScroll = ScrollController();
  RxList<PostsModel> explorePosts = <PostsModel>[].obs;
  DocumentSnapshot? lastExploreDoc;
  RxBool exploreHasMore = true.obs;
  RxBool exploreIsLoading = false.obs;
  final RxBool explorePreviewSuspended = false.obs;
  final RxInt explorePreviewFocusIndex = (-1).obs;

  // -------------- Videolar --------------
  final ScrollController videoScroll = ScrollController();
  RxList<PostsModel> exploreVideos = <PostsModel>[].obs;
  DocumentSnapshot? lastVideoDoc;
  RxBool videoHasMore = true.obs;
  RxBool videoIsLoading = false.obs;

  // -------------- Fotoğraflar --------------
  final ScrollController photoScroll = ScrollController();
  RxList<PostsModel> explorePhotos = <PostsModel>[].obs;
  DocumentSnapshot? lastPhotoDoc;
  RxBool photoHasMore = true.obs;
  RxBool photoIsLoading = false.obs;

  // -------------- FLOODS --------------
  final ScrollController floodsScroll = ScrollController();
  RxList<PostsModel> exploreFloods = <PostsModel>[].obs;
  DocumentSnapshot? lastFloodsDoc;
  RxBool floodsHasMore = true.obs;
  RxBool floodsIsLoading = false.obs;
  RxBool showScrollToTop = false.obs;
  final RxSet<String> followingIDs = <String>{}.obs;
  // Boş sayfa tespit sayaçları (filtre sonrası görünür içerik çıkmadığında)
  int _exploreEmptyScans = 0;
  int _videoEmptyScans = 0;
  int _photoEmptyScans = 0;
  int _floodsEmptyScans = 0;
  // ... diğer kodlar
  UserProfileCacheService get _userCache => Get.find<UserProfileCacheService>();
  UserSubcollectionRepository get _subcollectionRepository =>
      UserSubcollectionRepository.ensure();
  TopTagsRepository get _topTagsRepository => TopTagsRepository.ensure();
  ExploreRepository get _exploreRepository => ExploreRepository.ensure();
  Worker? _currentUserWorker;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  String _recentSearchReloadKey = '';

  @override
  void onInit() {
    super.onInit();
    _applyUserCacheQuota();
    unawaited(_loadRecentSearchUsersCache());
    UserAnalyticsService.instance.trackFeatureUsage('explore_open');
    fetchTrendingTags();
    unawaited(_quickFillExploreFromPoolAndBootstrap());
    _bindRecentSearchUsers();
    _bindFollowingListener();
    exploreScroll.addListener(() {
      if (exploreScroll.position.pixels >=
          exploreScroll.position.maxScrollExtent - 200) {
        fetchExplorePosts();
      }

      _syncScrollToTopVisibility(exploreScroll.offset);
    });

    videoScroll.addListener(() {
      if (videoScroll.position.pixels >=
          videoScroll.position.maxScrollExtent - 200) {
        fetchVideo();
      }

      _syncScrollToTopVisibility(videoScroll.offset);
    });

    photoScroll.addListener(() {
      if (photoScroll.position.pixels >=
          photoScroll.position.maxScrollExtent - 200) {
        fetchPhoto();
      }

      _syncScrollToTopVisibility(photoScroll.offset);
    });

    floodsScroll.addListener(() {
      if (floodsScroll.position.pixels >=
          floodsScroll.position.maxScrollExtent - 200) {
        fetchFloods();
      }

      _syncScrollToTopVisibility(floodsScroll.offset);
    });

    searchFocus.addListener(() {
      isKeyboardOpen.value = searchFocus.hasFocus;
      if (searchFocus.hasFocus) {
        isSearchMode.value = true;
      }
    });
  }

  void _syncScrollToTopVisibility(double offset) {
    final shouldShow = offset > 500;
    if (showScrollToTop.value == shouldShow) {
      return;
    }
    showScrollToTop.value = shouldShow;
  }

  void suspendExplorePreview({int focusIndex = -1}) {
    explorePreviewSuspended.value = true;
    explorePreviewFocusIndex.value = focusIndex;
  }

  void resumeExplorePreview() {
    explorePreviewSuspended.value = false;
  }

  void _bindFollowingListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ OPTIMIZED: One-time fetch instead of real-time listener
    _fetchFollowingIDs(uid);
  }

  Future<void> _fetchFollowingIDs(String uid) async {
    try {
      final ids = await FollowRepository.ensure().getFollowingIds(
        uid,
        preferCache: true,
      );
      followingIDs.assignAll(ids);
    } catch (_) {}
  }

  Future<void> fetchExplorePosts() async {
    if (exploreIsLoading.value || !exploreHasMore.value) return;
    exploreIsLoading.value = true;
    try {
      // İlk çağrıda (veya yenilemede) sayaç sıfırla
      if (lastExploreDoc == null) _exploreEmptyScans = 0;
      int pagesFetched = 0;
      const int pageLimit = 20;
      final isBootstrapTopUp =
          lastExploreDoc == null && explorePosts.isNotEmpty;
      final int maxPages = isBootstrapTopUp ? 4 : 10;
      final int targetBatch = isBootstrapTopUp ? 12 : 24;
      List<PostsModel> accumulated = [];
      while (pagesFetched < maxPages && exploreHasMore.value) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final page = await _exploreRepository.fetchExplorePostsPage(
          startAfter: lastExploreDoc,
          pageLimit: pageLimit,
          nowMs: nowMs,
        );
        if (page.items.isEmpty) {
          exploreHasMore.value = false;
          break;
        }
        if (!page.hasMore) exploreHasMore.value = false;
        lastExploreDoc = page.lastDoc;

        var newPosts = page.items;
        // Sana Özel ekranı: sadece dikey oranli oynatilabilir videolar
        newPosts = newPosts.where(_isEligibleExplorePost).toList();
        // nowMs already computed above in this loop
        newPosts = newPosts
            .where((p) => (p.timeStamp) <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        newPosts = await _filterByPrivacy(newPosts);

        if (newPosts.isNotEmpty) {
          newPosts.shuffle();
          accumulated.addAll(newPosts);
          if (accumulated.length >= targetBatch) {
            break;
          }
        }

        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        final existingIds = explorePosts.map((e) => e.docID).toSet();
        final existingCanonicalIds =
            explorePosts.map(_exploreCanonicalId).toSet();
        final uniqueAccumulated = <PostsModel>[];
        final seen = <String>{};
        for (final p in accumulated) {
          if (existingIds.contains(p.docID)) continue;
          final canonicalId = _exploreCanonicalId(p);
          if (existingCanonicalIds.contains(canonicalId)) continue;
          if (!seen.add(canonicalId)) continue;
          uniqueAccumulated.add(p);
        }

        final prioritized = _prioritizeCachedVideos(uniqueAccumulated);
        explorePosts.addAll(prioritized);
        _scheduleExplorePrefetchFromPosts(explorePosts);
        unawaited(_saveExplorePostsToPool(prioritized));
        _exploreEmptyScans = 0;
      } else if (pagesFetched >= maxPages && exploreHasMore.value) {
        exploreHasMore.value = false;
      } else {
        _exploreEmptyScans++;
        if (_exploreEmptyScans >= 3) {
          exploreHasMore.value = false;
        }
      }
    } catch (_) {}
    exploreIsLoading.value = false;
  }

  Future<void> _quickFillExploreFromPoolAndBootstrap() async {
    await _tryQuickFillExploreFromPool();
    _scheduleExplorePrefetchFromPosts(explorePosts);
    if (explorePosts.isEmpty) {
      if (ContentPolicy.shouldBootstrapNetwork(
        ContentScreenKind.explore,
        hasLocalContent: false,
      )) {
        await fetchExplorePosts();
      }
    } else if (ContentPolicy.allowBackgroundRefresh(ContentScreenKind.explore)) {
      unawaited(fetchExplorePosts());
    }
  }

  Future<void> _tryQuickFillExploreFromPool() async {
    if (!Get.isRegistered<IndexPoolStore>()) return;
    final pool = Get.find<IndexPoolStore>();
    final fromPool = await pool.loadPosts(
      IndexPoolKind.explore,
      limit: ContentPolicy.initialPoolLimit(ContentScreenKind.explore),
      allowStale: true,
    );
    if (fromPool.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final profiles = await _userCache.getProfiles(
      fromPool.map((e) => e.userID).toSet().toList(),
      preferCache: true,
      cacheOnly: true,
    );
    final filtered = fromPool
        .where(_isEligibleExplorePost)
        .where((p) => p.deletedPost != true)
        .where((p) {
      final profile = profiles[p.userID];
      if (profile == null) return false;
      final isPrivate = (profile['isPrivate'] ?? false) == true;
      final isDeactivated = isDeactivatedAccount(
        accountStatus: profile['accountStatus'],
        isDeleted: profile['isDeleted'],
      );
      if (isDeactivated) return false;
      if (!isPrivate) return true;
      final isMine = me != null && p.userID == me;
      final follows = followingIDs.contains(p.userID);
      return isMine || follows;
    }).toList();
    if (filtered.isEmpty) return;
    final valid = _dedupeExplorePosts(filtered);
    if (valid.isEmpty) return;
    explorePosts.assignAll(valid);
    _scheduleExplorePrefetchFromPosts(explorePosts);
    if (ContentPolicy.allowBackgroundRefresh(ContentScreenKind.explore)) {
      unawaited(_cleanupExplorePoolFill(valid));
    }
  }

  Future<void> _cleanupExplorePoolFill(List<PostsModel> shown) async {
    try {
      final valid =
          _dedupeExplorePosts(await _validatePoolPostsAndPrune(shown));
      if (valid.length == shown.length) return;
      final validIds = valid.map((e) => e.docID).toSet();
      final shownIds = shown.map((e) => e.docID).toSet();
      explorePosts.removeWhere(
        (p) => shownIds.contains(p.docID) && !validIds.contains(p.docID),
      );
    } catch (_) {}
  }

  Future<void> _saveExplorePostsToPool(List<PostsModel> posts) async {
    if (posts.isEmpty) return;
    if (!Get.isRegistered<IndexPoolStore>()) return;
    await Get.find<IndexPoolStore>().savePosts(IndexPoolKind.explore, posts);
  }

  bool _isEligibleExplorePost(PostsModel post) {
    return post.hasPlayableVideo &&
        post.originalPostID.trim().isEmpty &&
        post.aspectRatio.toDouble() < _verticalExploreAspectMax;
  }

  String _exploreCanonicalId(PostsModel post) {
    final original = post.originalPostID.trim();
    if (original.isNotEmpty) return original;
    return post.docID;
  }

  List<PostsModel> _dedupeExplorePosts(List<PostsModel> posts) {
    final seen = <String>{};
    final out = <PostsModel>[];
    for (final post in posts) {
      final canonicalId = _exploreCanonicalId(post);
      if (!seen.add(canonicalId)) continue;
      out.add(post);
    }
    return out;
  }

  Future<List<PostsModel>> _validatePoolPostsAndPrune(
      List<PostsModel> posts) async {
    if (posts.isEmpty) return const <PostsModel>[];
    if (!Get.isRegistered<IndexPoolStore>()) return posts;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final postIds =
        posts.map((e) => e.docID).where((e) => e.isNotEmpty).toSet().toList();
    final userIds =
        posts.map((e) => e.userID).where((e) => e.isNotEmpty).toSet();

    final validPostIds = <String>{};
    final postMap = await _exploreRepository.fetchPostsByIds(
      postIds,
      preferCache: true,
    );
    for (final entry in postMap.entries) {
      final post = entry.value;
      if (post.deletedPost == true) continue;
      if (post.arsiv == true) continue;
      if (post.timeStamp > nowMs) continue;
      validPostIds.add(entry.key);
    }

    final profiles = await _userCache.getProfiles(
      userIds.toList(),
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    final validUserIds = profiles.keys.toSet();

    final valid = posts
        .where((p) =>
            validPostIds.contains(p.docID) && validUserIds.contains(p.userID))
        .toList();

    if (valid.length != posts.length) {
      final invalidIds = posts
          .where((p) =>
              !validPostIds.contains(p.docID) ||
              !validUserIds.contains(p.userID))
          .map((p) => p.docID)
          .toList();
      if (invalidIds.isNotEmpty) {
        await Get.find<IndexPoolStore>()
            .removePosts(IndexPoolKind.explore, invalidIds);
      }
    }
    return valid;
  }

  Future<void> fetchTrendingTags() async {
    try {
      final tags = await _topTagsRepository.fetchTrendingTags(
        resultLimit: 30,
        preferCache: true,
      );
      trendingTags.assignAll(tags);
    } catch (_) {
      trendingTags.clear();
    }
  }

  // ------ VİDEOLAR ------
  Future<void> fetchVideo() async {
    if (videoIsLoading.value || !videoHasMore.value) return;
    videoIsLoading.value = true;
    try {
      if (lastVideoDoc == null) _videoEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = 10;
      const int targetBatch = 24; // videolar için hedef sayfa boyutu
      List<PostsModel> accumulated = [];
      while (pagesFetched < maxPages && videoHasMore.value) {
        const int pageLimit = 30;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        ExploreQueryPage page;
        try {
          page = await _exploreRepository.fetchVideoReadyPage(
            startAfter: lastVideoDoc,
            pageLimit: pageLimit,
            nowMs: nowMs,
          );
        } catch (e) {
          final isIndexError = e is FirebaseException
              ? e.code == 'failed-precondition'
              : e.toString().contains('requires an index');
          if (!isIndexError) rethrow;

          try {
            page = await _exploreRepository.fetchVideoFallbackPage(
              startAfter: lastVideoDoc,
              pageLimit: pageLimit,
              nowMs: nowMs,
            );
          } catch (_) {
            page = await _exploreRepository.fetchVideoBroadPage(
              startAfter: lastVideoDoc,
              pageLimit: pageLimit,
              nowMs: nowMs,
            );
          }
        }
        if (page.items.isEmpty) {
          videoHasMore.value = false;
          break;
        }
        if (!page.hasMore) videoHasMore.value = false;
        lastVideoDoc = page.lastDoc;

        var newVideos = page.items;
        // İstemci tarafında video içerenleri seç ve sadece kök flood videolarını göster
        newVideos = newVideos
            .where((p) => p.hasPlayableVideo)
            .where((p) => p.flood == false)
            .toList();
        // nowMs already computed above in this loop
        newVideos = newVideos
            .where((p) => (p.timeStamp) <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        newVideos = await _filterByPrivacy(newVideos);
        if (newVideos.isNotEmpty) {
          newVideos.shuffle();
          accumulated.addAll(newVideos);
          // Yeterli sayıda toplanana kadar devam et
          if (accumulated.length >= targetBatch) {
            break;
          }
        }
        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        final prioritized = _prioritizeCachedVideos(accumulated);
        exploreVideos.addAll(prioritized);
        _scheduleExplorePrefetchFromPosts(exploreVideos);
        _videoEmptyScans = 0;
        // Eğer bu turda sayfa sınırına ulaştıysak, spinner'ı kapat
        if (pagesFetched >= maxPages && videoHasMore.value) {
          videoHasMore.value = false;
        }
      } else if (pagesFetched >= maxPages && videoHasMore.value) {
        videoHasMore.value = false;
      } else {
        _videoEmptyScans++;
        if (_videoEmptyScans >= 3) {
          videoHasMore.value = false;
        }
      }
    } catch (_) {}
    videoIsLoading.value = false;
  }

  // ------ FOTOĞRAFLAR ------
  Future<void> fetchPhoto() async {
    if (photoIsLoading.value || !photoHasMore.value) return;
    photoIsLoading.value = true;
    try {
      if (lastPhotoDoc == null) _photoEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = 5;
      const int pageLimit = 20;
      List<PostsModel> accumulated = [];
      while (pagesFetched < maxPages && photoHasMore.value) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final page = await _exploreRepository.fetchPhotoPage(
          startAfter: lastPhotoDoc,
          pageLimit: pageLimit,
          nowMs: nowMs,
        );
        if (page.items.isEmpty) {
          photoHasMore.value = false;
          break;
        }
        if (!page.hasMore) photoHasMore.value = false;
        lastPhotoDoc = page.lastDoc;

        List<PostsModel> newPhotos = [];
        for (final model in page.items) {
          if (model.metin != "" && model.img.isNotEmpty) {
            newPhotos.add(model);
          }
        }
        // nowMs computed above in this loop
        newPhotos = newPhotos
            .where((p) => (p.timeStamp) <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        newPhotos = await _filterByPrivacy(newPhotos);
        if (newPhotos.isNotEmpty) {
          newPhotos.shuffle();
          accumulated.addAll(newPhotos);
          // En az bir ekranlık içerik toplayana kadar taramaya devam et
          if (accumulated.length >= 30) {
            break;
          }
        }
        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        explorePhotos.addAll(accumulated);
        _photoEmptyScans = 0;
        // Eğer bu turda sayfa sınırına ulaştıysak, spinner'ı kapat
        if (pagesFetched >= maxPages && photoHasMore.value) {
          photoHasMore.value = false;
        }
      } else if (pagesFetched >= maxPages && photoHasMore.value) {
        photoHasMore.value = false;
      } else {
        _photoEmptyScans++;
        if (_photoEmptyScans >= 3) {
          photoHasMore.value = false;
        }
      }
    } catch (_) {}
    photoIsLoading.value = false;
  }

  // ------ FLOODS ------
  Future<void> fetchFloods() async {
    if (floodsIsLoading.value || !floodsHasMore.value) return;
    floodsIsLoading.value = true;
    try {
      if (lastFloodsDoc == null) _floodsEmptyScans = 0;
      int pagesFetched = 0;
      const int maxPages = 10; // güvenlik limiti - daha derin tarama
      const int pageLimit = 60;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      List<PostsModel> accumulated = [];
      bool noMoreServerPages = false;
      final existingIDs = exploreFloods.map((e) => e.docID).toSet();

      while (pagesFetched < maxPages && !noMoreServerPages) {
        ExploreQueryPage page;
        try {
          page = await _exploreRepository.fetchFloodServerPage(
            startAfter: lastFloodsDoc,
            pageLimit: pageLimit,
          );
        } catch (_) {
          // Fallback: client-side filtre
          page = await _exploreRepository.fetchFloodFallbackPage(
            startAfter: lastFloodsDoc,
            pageLimit: pageLimit,
            nowMs: nowMs,
          );
        }
        if (page.items.isEmpty) {
          noMoreServerPages = true;
          break;
        }
        if (!page.hasMore) noMoreServerPages = true;
        lastFloodsDoc = page.lastDoc;

        List<PostsModel> batch = [];
        for (final model in page.items) {
          if (model.flood == true) {
            continue;
          }
          if ((model.floodCount) <= 1) {
            continue;
          }
          if (existingIDs.contains(model.docID)) {
            continue;
          }
          batch.add(model);
        }
        batch = batch
            .where((p) => (p.timeStamp) <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        batch = await _filterByPrivacy(batch);
        if (batch.isNotEmpty) {
          batch.shuffle();
          accumulated.addAll(batch);
          if (accumulated.length >= 30) {
            // İlk yüklemede ekranda yeterince içerik olsun
            break;
          }
        }
        pagesFetched++;
      }

      if (accumulated.isNotEmpty) {
        final prioritized = _prioritizeCachedVideos(accumulated);
        exploreFloods.addAll(prioritized);
        _floodsEmptyScans = 0;
        floodsHasMore.value = !noMoreServerPages; // sunucu bitti mi?
      } else {
        _floodsEmptyScans++;
        if (_floodsEmptyScans >= 2 || noMoreServerPages) {
          floodsHasMore.value = false;
        }
      }
    } catch (_) {}
    floodsIsLoading.value = false;
  }

  Future<List<PostsModel>> _filterByPrivacy(List<PostsModel> items) async {
    if (items.isEmpty) return items;
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    final me = FirebaseAuth.instance.currentUser?.uid;
    final userProfiles = await _userCache.getProfiles(
      uniqueUserIDs,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    final userPrivacy = <String, bool>{};
    for (final uid in uniqueUserIDs) {
      final data = userProfiles[uid];
      userPrivacy[uid] = (data?['isPrivate'] ?? false) == true;
    }

    final filtered = items.where((post) {
      final isPrivate = userPrivacy[post.userID] ?? false;
      if (!isPrivate) return true;
      final isMine = me != null && post.userID == me;
      final follows = followingIDs.contains(post.userID);
      return isMine || follows;
    }).toList();
    return filtered;
  }

  List<PostsModel> _prioritizeCachedVideos(List<PostsModel> items) {
    if (items.isEmpty || !Get.isRegistered<SegmentCacheManager>()) {
      return items;
    }

    final cache = Get.find<SegmentCacheManager>();
    final sorted = List<PostsModel>.from(items);

    int cacheScore(PostsModel post) {
      if (!post.hasPlayableVideo) return -1;
      final entry = cache.getEntry(post.docID);
      if (entry == null || entry.cachedSegmentCount <= 0) return 0;
      if (entry.isFullyCached) return 3;
      if (entry.cachedSegmentCount >= 2) return 2;
      return 1;
    }

    int cachedSegments(PostsModel post) {
      if (!post.hasPlayableVideo) return 0;
      return cache.getEntry(post.docID)?.cachedSegmentCount ?? 0;
    }

    sorted.sort((a, b) {
      final scoreCompare = cacheScore(b).compareTo(cacheScore(a));
      if (scoreCompare != 0) return scoreCompare;

      final segCompare = cachedSegments(b).compareTo(cachedSegments(a));
      if (segCompare != 0) return segCompare;

      return (b.timeStamp).compareTo(a.timeStamp);
    });

    return sorted;
  }

  void _scheduleExplorePrefetchFromPosts(List<PostsModel> source) {
    if (source.isEmpty) return;
    if (!Get.isRegistered<PrefetchScheduler>()) return;

    final docIds = source
        .where((p) => p.hasPlayableVideo)
        .map((p) => p.docID)
        .where((id) => id.isNotEmpty)
        .take(20)
        .toList();
    if (docIds.isEmpty) return;

    unawaited(Get.find<PrefetchScheduler>().updateQueue(docIds, 0));
  }

  Future<dynamic> _callTypesenseCallable(
      String callableName, Map<String, dynamic> payload) async {
    final targets = <FirebaseFunctions>[
      FirebaseFunctions.instance,
      FirebaseFunctions.instanceFor(region: 'us-central1'),
      FirebaseFunctions.instanceFor(region: 'europe-west1'),
    ];

    Object? lastError;
    for (final fn in targets) {
      try {
        final result = await fn.httpsCallable(callableName).call(payload);
        return result.data;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('typesense_callable_failed');
  }

  Future<List<OgrenciModel>> _filterPendingOrDeletedUsers(
      List<OgrenciModel> users) async {
    if (users.isEmpty) return users;
    final blocked = <String>{};
    final ids = users.map((e) => e.userID).where((e) => e.isNotEmpty).toList();

    final profiles = await _userCache.getProfiles(
      ids,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    for (final entry in profiles.entries) {
      final data = entry.value;
      if (isDeactivatedAccount(
        accountStatus: data['accountStatus'],
        isDeleted: data['isDeleted'],
      )) {
        blocked.add(entry.key);
      }
    }

    return users.where((u) => !blocked.contains(u.userID)).toList();
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    _searchDebounce?.cancel();

    final normalized = value.trim();
    if (normalized.isEmpty) {
      _searchRequestId++;
      _clearSearchResults();
      return;
    }

    isSearchMode.value = true;
    _searchDebounce = Timer(_searchDebounceDuration, () {
      unawaited(search(normalized));
    });
  }

  void _clearSearchResults() {
    searchedList.clear();
    searchedHashtags.clear();
    searchedTags.clear();
    showAllRecent.value = false;
  }

  Future<void> search(String query) async {
    final nick = query.trim();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final requestId = ++_searchRequestId;
    if (nick.isEmpty) {
      _clearSearchResults();
      return;
    }

    try {
      final results = await Future.wait([
        _callTypesenseCallable('f15_searchTagsCallable', {
          'q': nick,
          'limit': 20,
          'page': 1,
        }),
        if (nick.length >= 2)
          _callTypesenseCallable('f15_searchUsersCallable', {
            'q': nick,
            'limit': 20,
            'page': 1,
          })
        else
          Future.value({'hits': []}),
      ]);

      if (requestId != _searchRequestId || searchText.value.trim() != nick) {
        return;
      }

      final tagData = (results[0] as Map?) ?? {};
      final userData = (results[1] as Map?) ?? {};

      final rawTagHits = (tagData['hits'] as List?) ?? const [];
      final rawUserHits = (userData['hits'] as List?) ?? const [];

      final allTagHits = rawTagHits
          .whereType<Map>()
          .map((e) {
            final tag = (e['tag'] ?? '').toString().trim();
            final count = (e['count'] as num?) ?? 0;
            final hasHashtag = e['hasHashtag'] == true;
            return HashtagModel(
              hashtag: tag,
              count: count,
              hasHashtag: hasHashtag,
            );
          })
          .where((e) => e.hashtag.isNotEmpty)
          .toList();

      searchedHashtags.value =
          allTagHits.where((e) => e.hasHashtag).take(3).toList();
      searchedTags.value =
          allTagHits.where((e) => !e.hasHashtag).take(3).toList();

      final users = <OgrenciModel>[];
      for (final row in rawUserHits.whereType<Map>()) {
        final uid = (row['id'] ??
                row['userID'] ??
                row['uid'] ??
                row['docID'] ??
                row['userId'] ??
                '')
            .toString()
            .trim();
        if (uid.isEmpty || uid == currentUserId) continue;
        users.add(OgrenciModel(
          userID: uid,
          nickname: (row['nickname'] ?? '').toString(),
          firstName: (row['firstName'] ?? '').toString(),
          lastName: (row['lastName'] ?? '').toString(),
          avatarUrl: (row['avatarUrl'] ?? '').toString(),
        ));
      }

      final filteredUsers = await _filterPendingOrDeletedUsers(users);
      if (requestId != _searchRequestId || searchText.value.trim() != nick) {
        return;
      }
      searchedList.value = filteredUsers;
    } catch (_) {
      if (requestId != _searchRequestId || searchText.value.trim() != nick) {
        return;
      }
      _clearSearchResults();
    }
  }

  void resetSearchToDefault() {
    _searchDebounce?.cancel();
    _searchRequestId++;
    searchFocus.unfocus();
    searchController.clear();
    searchText.value = "";
    _clearSearchResults();
    isKeyboardOpen.value = false;
    isSearchMode.value = false;
    selection.value = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
  }

  @override
  void onClose() {
    _currentUserWorker?.dispose();
    _currentUserWorker = null;
    _searchDebounce?.cancel();
    exploreScroll.dispose();
    videoScroll.dispose();
    photoScroll.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
    super.onClose();
  }

  void goToPage(int index) {
    selection.value = index;
    if (index == 0 && trendingTags.isEmpty) {
      fetchTrendingTags();
    } else if (index == 1 && explorePosts.isEmpty && !exploreIsLoading.value) {
      fetchExplorePosts();
    } else if (index == 2 && exploreFloods.isEmpty && !floodsIsLoading.value) {
      fetchFloods();
    }

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
