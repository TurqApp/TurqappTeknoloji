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
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';

import '../../Models/posts_model.dart';

class ExploreController extends GetxController {
  static const double _verticalExploreAspectMax = 0.7;
  static const String _recentSearchUsersCachePrefix =
      'explore_recent_search_users_v1_';
  static const int _recentSearchUsersLimit = 100;
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

      if (exploreScroll.offset > 500) {
        showScrollToTop.value = true;
      } else {
        showScrollToTop.value = false;
      }
    });

    videoScroll.addListener(() {
      if (videoScroll.position.pixels >=
          videoScroll.position.maxScrollExtent - 200) {
        fetchVideo();
      }

      if (videoScroll.offset > 500) {
        showScrollToTop.value = true;
      } else {
        showScrollToTop.value = false;
      }
    });

    photoScroll.addListener(() {
      if (photoScroll.position.pixels >=
          photoScroll.position.maxScrollExtent - 200) {
        fetchPhoto();
      }

      if (photoScroll.offset > 500) {
        showScrollToTop.value = true;
      } else {
        showScrollToTop.value = false;
      }
    });

    floodsScroll.addListener(() {
      if (floodsScroll.position.pixels >=
          floodsScroll.position.maxScrollExtent - 200) {
        fetchFloods();
      }

      if (floodsScroll.offset > 500) {
        showScrollToTop.value = true;
      } else {
        showScrollToTop.value = false;
      }
    });

    searchFocus.addListener(() {
      isKeyboardOpen.value = searchFocus.hasFocus;
      if (searchFocus.hasFocus) {
        isSearchMode.value = true;
      }
    });
  }

  Future<void> _applyUserCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGb = prefs.getInt('offline_cache_quota_gb') ?? 3;
      final quotaGb = savedGb.clamp(2, 5);
      if (Get.isRegistered<SegmentCacheManager>()) {
        await Get.find<SegmentCacheManager>().setUserLimitGB(quotaGb);
      }
    } catch (_) {}
  }

  void _bindRecentSearchUsers() {
    _currentUserWorker?.dispose();
    _currentUserWorker = ever(
      CurrentUserService.instance.currentUserRx,
      (_) => unawaited(_reloadRecentSearchUsers()),
    );
    unawaited(_reloadRecentSearchUsers());
  }

  Future<void> _reloadRecentSearchUsers() async {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserID == null || currentUserID.isEmpty) {
      recentSearchUsers.clear();
      await _saveRecentSearchUsersCache();
      return;
    }

    final ids = await _fetchRecentSearchIds(currentUserID);
    if (ids.isEmpty) {
      recentSearchUsers.clear();
      await _saveRecentSearchUsersCache();
      return;
    }

    final orderedIds = <String>[];
    final seen = <String>{};
    for (final id in ids) {
      final normalized = id.trim();
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized)) continue;
      orderedIds.add(normalized);
    }
    if (orderedIds.isEmpty) {
      recentSearchUsers.clear();
      await _saveRecentSearchUsersCache();
      return;
    }

    final sorted = <OgrenciModel>[];
    final profileMap = await _userCache.getProfiles(
      orderedIds,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    for (final id in orderedIds) {
      final data = profileMap[id];
      if (data == null) continue;
      final nickname = (data['nickname'] ?? '').toString();
      if (nickname.isEmpty) continue;
      sorted.add(
        OgrenciModel(
          userID: id,
          firstName: (data['firstName'] ?? '').toString(),
          lastName: (data['lastName'] ?? '').toString(),
          avatarUrl: (data['avatarUrl'] ?? '').toString(),
          nickname: nickname,
        ),
      );
    }
    final filtered = await _filterPendingOrDeletedUsers(sorted);
    recentSearchUsers.value = filtered;
    await _saveRecentSearchUsersCache();
  }

  Future<List<String>> _fetchRecentSearchIds(String currentUserID) async {
    try {
      final entries = await _subcollectionRepository.getEntries(
        currentUserID,
        subcollection: 'lastSearches',
        preferCache: true,
        forceRefresh: false,
      );
      final docs = entries.toList()
        ..sort((a, b) {
          final aData = a.data;
          final bData = b.data;
          final aTs = (aData['updatedDate'] is num)
              ? (aData['updatedDate'] as num).toInt()
              : ((aData['timeStamp'] is num)
                  ? (aData['timeStamp'] as num).toInt()
                  : 0);
          final bTs = (bData['updatedDate'] is num)
              ? (bData['updatedDate'] as num).toInt()
              : ((bData['timeStamp'] is num)
                  ? (bData['timeStamp'] as num).toInt()
                  : 0);
          return bTs.compareTo(aTs);
        });
      return docs
          .take(_recentSearchUsersLimit)
          .map((d) => d.id.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return CurrentUserService.instance.currentUser?.lastSearchList ??
          const <String>[];
    }
  }

  String? _recentSearchUsersCacheKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return '$_recentSearchUsersCachePrefix$uid';
  }

  Future<void> _loadRecentSearchUsersCache() async {
    try {
      final key = _recentSearchUsersCacheKey();
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return;
      final parsed = jsonDecode(raw);
      if (parsed is! List) return;

      final restored = <OgrenciModel>[];
      for (final item in parsed) {
        if (item is! Map) continue;
        final map = item.map((k, v) => MapEntry(k.toString(), v));
        final userID = (map['userID'] ?? '').toString().trim();
        final nickname = (map['nickname'] ?? '').toString().trim();
        if (userID.isEmpty || nickname.isEmpty) continue;
        restored.add(
          OgrenciModel(
            userID: userID,
            firstName: (map['firstName'] ?? '').toString(),
            lastName: (map['lastName'] ?? '').toString(),
            avatarUrl: (map['avatarUrl'] ?? '').toString(),
            nickname: nickname,
          ),
        );
      }
      if (restored.isNotEmpty) {
        recentSearchUsers.value = restored;
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearchUsersCache() async {
    try {
      final key = _recentSearchUsersCacheKey();
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      final payload = recentSearchUsers
          .take(_recentSearchUsersLimit)
          .map(
            (u) => <String, dynamic>{
              'userID': u.userID,
              'nickname': u.nickname,
              'firstName': u.firstName,
              'lastName': u.lastName,
              'avatarUrl': u.avatarUrl,
            },
          )
          .toList(growable: false);
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> saveRecentSearch(String targetUid) async {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    final cleanTarget = targetUid.trim();
    if (currentUserID == null ||
        currentUserID.isEmpty ||
        cleanTarget.isEmpty ||
        cleanTarget == currentUserID) {
      return;
    }
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _subcollectionRepository.upsertEntry(
        currentUserID,
        subcollection: 'lastSearches',
        docId: cleanTarget,
        data: {
          "userID": cleanTarget,
          "updatedDate": now,
          "timeStamp": now,
        },
      );
      final existing = await _subcollectionRepository.getEntries(
        currentUserID,
        subcollection: 'lastSearches',
        preferCache: true,
      );
      final next = <UserSubcollectionEntry>[
        UserSubcollectionEntry(
          id: cleanTarget,
          data: {
            'userID': cleanTarget,
            'updatedDate': now,
            'timeStamp': now,
          },
        ),
        ...existing.where((e) => e.id != cleanTarget),
      ];
      await _subcollectionRepository.setEntries(
        currentUserID,
        subcollection: 'lastSearches',
        items: next.take(200).toList(growable: false),
      );
    } catch (_) {
    } finally {
      await _reloadRecentSearchUsers();
    }
  }

  Future<void> removeRecentSearch(String targetUid) async {
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    final cleanTarget = targetUid.trim();
    if (currentUserID == null || currentUserID.isEmpty || cleanTarget.isEmpty) {
      return;
    }

    // UI'da çarpı sonrası anında kaldır.
    final before = List<OgrenciModel>.from(recentSearchUsers);
    recentSearchUsers.removeWhere((e) => e.userID == cleanTarget);
    recentSearchUsers.refresh();
    await _saveRecentSearchUsersCache();

    try {
      await _subcollectionRepository.deleteEntry(
        currentUserID,
        subcollection: 'lastSearches',
        docId: cleanTarget,
      );
      final existing = await _subcollectionRepository.getEntries(
        currentUserID,
        subcollection: 'lastSearches',
        preferCache: true,
      );
      await _subcollectionRepository.setEntries(
        currentUserID,
        subcollection: 'lastSearches',
        items:
            existing.where((e) => e.id != cleanTarget).toList(growable: false),
      );
    } catch (_) {
      // Yazma başarısızsa eski listeyi geri yükle.
      recentSearchUsers.value = before;
      await _saveRecentSearchUsersCache();
    } finally {
      await _reloadRecentSearchUsers();
    }
  }

  Future<void> refreshRecentSearchUsers() async {
    await _reloadRecentSearchUsers();
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
      const int maxPages = 10; // daha derin tarama (kök flood azsa)
      const int pageLimit = 20;
      const int targetBatch = 24;
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
      await fetchExplorePosts();
    } else {
      unawaited(fetchExplorePosts());
    }
  }

  Future<void> _tryQuickFillExploreFromPool() async {
    if (!Get.isRegistered<IndexPoolStore>()) return;
    final pool = Get.find<IndexPoolStore>();
    final fromPool = await pool.loadPosts(
      IndexPoolKind.explore,
      limit: ContentPolicy.mobileWarmWindow,
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
      final isDeleted = (profile['isDeleted'] ?? false) == true;
      final status = (profile['accountStatus'] ?? '').toString().toLowerCase();
      final isDeactivated =
          isDeleted || status == 'pending_deletion' || status == 'deleted';
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
    unawaited(_cleanupExplorePoolFill(valid));
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
          // Kök flood ve video içeren gönderiler
          final hasMedia = model.hasPlayableVideo;
          if (model.flood == true) {
            continue;
          }
          if (!hasMedia) {
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
      final deletedAccount = (data['isDeleted'] ?? false) == true;
      final status = (data['accountStatus'] ?? '').toString().toLowerCase();
      final pendingOrDeleted =
          status == 'pending_deletion' || status == 'deleted';
      if (deletedAccount || pendingOrDeleted) {
        blocked.add(entry.key);
      }
    }

    return users.where((u) => !blocked.contains(u.userID)).toList();
  }

  Future<void> search(String query) async {
    final nick = query.trim();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (nick.isEmpty) {
      searchedList.clear();
      searchedHashtags.clear();
      searchedTags.clear();
      showAllRecent.value = false;
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
      searchedList.value = await _filterPendingOrDeletedUsers(users);
    } catch (_) {
      searchedList.clear();
      searchedHashtags.clear();
      searchedTags.clear();
    }
  }

  void resetSearchToDefault() {
    searchFocus.unfocus();
    searchController.clear();
    searchText.value = "";
    searchedList.clear();
    searchedHashtags.clear();
    searchedTags.clear();
    showAllRecent.value = false;
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
