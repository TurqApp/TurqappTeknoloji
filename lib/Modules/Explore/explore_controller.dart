import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';

import '../../Models/posts_model.dart';

class ExploreController extends GetxController {
  static const double _verticalExploreAspectMax = 0.7;
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
  Worker? _currentUserWorker;

  @override
  void onInit() {
    super.onInit();
    _applyUserCacheQuota();
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
    } catch (e) {
      print('Explore cache quota apply error: $e');
    }
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
    final ids = CurrentUserService.instance.currentUser?.lastSearchList ??
        const <String>[];
    if (ids.isEmpty) {
      recentSearchUsers.clear();
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
      return;
    }

    final byId = <String, OgrenciModel>{};
    for (final chunk in _chunkList(orderedIds, 10)) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        byId[doc.id] = OgrenciModel.fromDocument(doc);
      }
    }

    final sorted = <OgrenciModel>[];
    for (final id in orderedIds) {
      final model = byId[id];
      if (model != null) {
        sorted.add(model);
      }
    }
    recentSearchUsers.value = await _filterPendingOrDeletedUsers(sorted);
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
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('followings')
          .get(); // ✅ get() instead of snapshots()

      followingIDs.assignAll(snap.docs.map((d) => d.id).toSet());
    } catch (e) {
      print('Error fetching following IDs: $e');
    }
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
        // Sadece kök flood gönderileri (flood == false) listelensin
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        Query query = FirebaseFirestore.instance
            .collection('Posts')
            .where("arsiv", isEqualTo: false)
            .where("flood", isEqualTo: false)
            .where('timeStamp', isLessThanOrEqualTo: nowMs)
            .orderBy("timeStamp", descending: true)
            .limit(pageLimit); // ✅ Optimized: 60 → 20

        if (lastExploreDoc != null) {
          query = query.startAfterDocument(lastExploreDoc!);
        }

        final snap = await PerformanceService.traceFeedLoad(
          () => query.get(),
          postCount: explorePosts.length,
          feedMode: 'explore_posts',
        );
        if (snap.docs.isEmpty) {
          exploreHasMore.value = false;
          break;
        }
        if (snap.docs.length < pageLimit) exploreHasMore.value = false;
        lastExploreDoc = snap.docs.last;

        // 1. Al, filtrele
        var newPosts = snap.docs
            .map((doc) =>
                PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
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
    } catch (e) {
      print("fetchExplorePosts error: $e");
    }
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
      allowStale: false,
    );
    if (fromPool.isEmpty) return;
    final filtered = fromPool
        .where(_isEligibleExplorePost)
        .where((p) => p.deletedPost != true)
        .toList();
    if (filtered.isEmpty) return;
    final valid =
        _dedupeExplorePosts(await _validatePoolPostsAndPrune(filtered));
    if (valid.isEmpty) return;
    explorePosts.assignAll(valid);
    _scheduleExplorePrefetchFromPosts(explorePosts);
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
        posts.map((e) => e.docID).where((e) => e.isNotEmpty).toSet();
    final userIds =
        posts.map((e) => e.userID).where((e) => e.isNotEmpty).toSet();

    final validPostIds = <String>{};
    for (final chunk in _chunkList(postIds.toList(), 10)) {
      final snap = await FirebaseFirestore.instance
          .collection('Posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        final data = d.data();
        final deleted = (data['deletedPost'] ?? false) == true;
        final archived = (data['arsiv'] ?? false) == true;
        final ts =
            (data['timeStamp'] is num) ? (data['timeStamp'] as num).toInt() : 0;
        if (!deleted && !archived && ts <= nowMs) {
          validPostIds.add(d.id);
        }
      }
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

  List<List<T>> _chunkList<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

  Future<void> fetchTrendingTags() async {
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final snap = await FirebaseFirestore.instance
          .collection('tags')
          .orderBy('count', descending: true)
          .limit(200)
          .get();

      final list = <HashtagModel>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final raw = doc.id.trim();
        final hashtag = raw.replaceFirst('#', '');
        if (hashtag.isEmpty) continue;

        final count = ((data['count'] ?? data['counter'] ?? 0) as num).toInt();
        final trendThreshold = ((data['trendThreshold'] ?? 1) as num).toInt();
        if (count <= 0 || count < trendThreshold) continue;

        final trendWindowHours =
            ((data['trendWindowHours'] ?? 24) as num).toInt();
        final safeWindowHours = trendWindowHours <= 0 ? 24 : trendWindowHours;
        final windowMs = Duration(hours: safeWindowHours).inMilliseconds;

        final rawLastSeen =
            ((data['lastSeenTs'] ?? data['lastSeenAt'] ?? 0) as num).toInt();
        if (rawLastSeen <= 0) continue;

        // Backward compatibility: eski data'da lastSeenAt expiry olarak tutulmuş olabilir.
        final effectiveLastSeen =
            rawLastSeen > nowMs ? (rawLastSeen - windowMs) : rawLastSeen;
        if (effectiveLastSeen <= 0) continue;
        if ((nowMs - effectiveLastSeen) > windowMs) continue;

        list.add(
          HashtagModel(
            hashtag: hashtag,
            count: count,
            hasHashtag: raw.startsWith('#') ||
                (((data['hashtagCount'] ?? 0) as num) > 0),
            lastSeenTs: effectiveLastSeen,
          ),
        );
      }

      list.sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0);
      });

      trendingTags.assignAll(list.take(30));
    } catch (e) {
      print('fetchTrendingTags error: $e');
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
      print("[Explore] fetchVideo:start lastDoc=${lastVideoDoc != null}");
      while (pagesFetched < maxPages && videoHasMore.value) {
        const int pageLimit = 30;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        Query query = FirebaseFirestore.instance
            .collection('Posts')
            .where("arsiv", isEqualTo: false)
            .where("flood", isEqualTo: false)
            .where("hlsStatus", isEqualTo: "ready")
            .where('timeStamp', isLessThanOrEqualTo: nowMs)
            .orderBy("timeStamp", descending: true)
            .limit(pageLimit);
        if (lastVideoDoc != null)
          query = query.startAfterDocument(lastVideoDoc!);

        QuerySnapshot snap;
        try {
          snap = await PerformanceService.traceFeedLoad(
            () => query.get(),
            postCount: exploreVideos.length,
            feedMode: 'explore_video',
          );
        } catch (e) {
          final isIndexError = e is FirebaseException
              ? e.code == 'failed-precondition'
              : e.toString().contains('requires an index');
          if (!isIndexError) rethrow;

          Query fallback = FirebaseFirestore.instance
              .collection('Posts')
              .where("arsiv", isEqualTo: false)
              .where("flood", isEqualTo: false)
              .where('timeStamp', isLessThanOrEqualTo: nowMs)
              .orderBy("timeStamp", descending: true)
              .limit(pageLimit);
          if (lastVideoDoc != null) {
            fallback = fallback.startAfterDocument(lastVideoDoc!);
          }

          try {
            snap = await PerformanceService.traceFeedLoad(
              () => fallback.get(),
              postCount: exploreVideos.length,
              feedMode: 'explore_video_fallback',
            );
          } catch (_) {
            Query broad = FirebaseFirestore.instance
                .collection('Posts')
                .where("arsiv", isEqualTo: false)
                .where('timeStamp', isLessThanOrEqualTo: nowMs)
                .orderBy("timeStamp", descending: true)
                .limit(pageLimit);
            if (lastVideoDoc != null) {
              broad = broad.startAfterDocument(lastVideoDoc!);
            }
            snap = await PerformanceService.traceFeedLoad(
              () => broad.get(),
              postCount: exploreVideos.length,
              feedMode: 'explore_video_broad',
            );
          }
        }
        print(
            "[Explore] fetchVideo:page=${pagesFetched + 1} serverDocs=${snap.docs.length}");
        if (snap.docs.isEmpty) {
          videoHasMore.value = false;
          break;
        }
        if (snap.docs.length < pageLimit) videoHasMore.value = false;
        lastVideoDoc = snap.docs.last;

        var newVideos = snap.docs
            .map((doc) =>
                PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        // İstemci tarafında video içerenleri seç ve sadece kök flood videolarını göster
        final beforeType = newVideos.length;
        newVideos = newVideos
            .where((p) => p.hasPlayableVideo)
            .where((p) => p.flood == false)
            .toList();
        final afterType = newVideos.length;
        // nowMs already computed above in this loop
        newVideos = newVideos
            .where((p) => (p.timeStamp) <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        final afterTime = newVideos.length;
        newVideos = await _filterByPrivacy(newVideos);
        final afterPrivacy = newVideos.length;
        print(
            "[Explore] fetchVideo: filter type $beforeType->$afterType, time/deleted -> $afterTime, privacy -> $afterPrivacy");
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
        print(
            "[Explore] fetchVideo:added ${accumulated.length} total=${exploreVideos.length} hasMore=${videoHasMore.value}");
      } else if (pagesFetched >= maxPages && videoHasMore.value) {
        videoHasMore.value = false;
        print("[Explore] fetchVideo:maxPages reached; set hasMore=false");
      } else {
        _videoEmptyScans++;
        if (_videoEmptyScans >= 3) {
          videoHasMore.value = false;
        }
        print(
            "[Explore] fetchVideo:emptyScan=$_videoEmptyScans hasMore=${videoHasMore.value}");
      }
    } catch (e) {
      print("fetchVideo error: $e");
    }
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
      print("[Explore] fetchPhoto:start lastDoc=${lastPhotoDoc != null}");
      while (pagesFetched < maxPages && photoHasMore.value) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        Query query = FirebaseFirestore.instance
            .collection('Posts')
            .where("arsiv", isEqualTo: false)
            .where("flood", isEqualTo: false)
            .where("video", isEqualTo: "")
            .where('timeStamp', isLessThanOrEqualTo: nowMs)
            .orderBy('timeStamp', descending: true)
            .limit(pageLimit); // ✅ Optimized: 30 → 20

        if (lastPhotoDoc != null) {
          query = query.startAfterDocument(lastPhotoDoc!);
        }

        final snap = await PerformanceService.traceFeedLoad(
          () => query.get(),
          postCount: explorePhotos.length,
          feedMode: 'explore_photo',
        );
        print(
            "[Explore] fetchPhoto:page=${pagesFetched + 1} serverDocs=${snap.docs.length}");
        if (snap.docs.isEmpty) {
          photoHasMore.value = false;
          break;
        }
        if (snap.docs.length < pageLimit) photoHasMore.value = false;
        lastPhotoDoc = snap.docs.last;

        List<PostsModel> newPhotos = [];
        for (var doc in snap.docs) {
          final model = PostsModel.fromFirestore(doc);
          if (model.metin != "" && model.img.isNotEmpty) {
            newPhotos.add(model);
          }
        }
        final afterTextImg = newPhotos.length;
        // nowMs computed above in this loop
        newPhotos = newPhotos
            .where((p) => (p.timeStamp) <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        final afterTime = newPhotos.length;
        newPhotos = await _filterByPrivacy(newPhotos);
        final afterPrivacy = newPhotos.length;
        print(
            "[Explore] fetchPhoto: filter text+img -> $afterTextImg, time/deleted -> $afterTime, privacy -> $afterPrivacy");
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
        print(
            "[Explore] fetchPhoto:added ${accumulated.length} total=${explorePhotos.length} hasMore=${photoHasMore.value}");
      } else if (pagesFetched >= maxPages && photoHasMore.value) {
        photoHasMore.value = false;
        print("[Explore] fetchPhoto:maxPages reached; set hasMore=false");
      } else {
        _photoEmptyScans++;
        if (_photoEmptyScans >= 3) {
          photoHasMore.value = false;
        }
        print(
            "[Explore] fetchPhoto:emptyScan=$_photoEmptyScans hasMore=${photoHasMore.value}");
      }
    } catch (e) {
      print("fetchPhoto error: $e");
    }
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
        QuerySnapshot snap;
        try {
          Query serverQuery = FirebaseFirestore.instance
              .collection('Posts')
              .where('arsiv', isEqualTo: false)
              .where('flood', isEqualTo: false)
              .where('floodCount', isGreaterThan: 1)
              .orderBy('floodCount')
              .orderBy('timeStamp', descending: true)
              .limit(pageLimit);
          if (lastFloodsDoc != null) {
            serverQuery = serverQuery.startAfterDocument(lastFloodsDoc!);
          }
          snap = await PerformanceService.traceFeedLoad(
            () => serverQuery.get(),
            postCount: exploreFloods.length,
            feedMode: 'explore_flood',
          );
          print(
              '[FLOODS] serverQuery page=${pagesFetched + 1} fetched=${snap.docs.length}');
        } catch (e) {
          // Fallback: client-side filtre
          print('[FLOODS] server filter failed; fallback. err=$e');
          Query fallbackQuery = FirebaseFirestore.instance
              .collection('Posts')
              .where('arsiv', isEqualTo: false)
              .where('flood', isEqualTo: false)
              .where('timeStamp', isLessThanOrEqualTo: nowMs)
              .orderBy('timeStamp', descending: true)
              .limit(pageLimit);
          if (lastFloodsDoc != null) {
            fallbackQuery = fallbackQuery.startAfterDocument(lastFloodsDoc!);
          }
          snap = await PerformanceService.traceFeedLoad(
            () => fallbackQuery.get(),
            postCount: exploreFloods.length,
            feedMode: 'explore_flood_fallback',
          );
          print(
              '[FLOODS] fallback page=${pagesFetched + 1} fetched=${snap.docs.length}');
        }
        if (snap.docs.isEmpty) {
          noMoreServerPages = true;
          break;
        }
        if (snap.docs.length < pageLimit) noMoreServerPages = true;
        lastFloodsDoc = snap.docs.last;

        int notRoot = 0;
        int noMedia = 0;
        int notSeries = 0;
        int duplicates = 0;
        int keptPreTimeDel = 0;
        List<PostsModel> batch = [];
        for (var doc in snap.docs) {
          final model = PostsModel.fromFirestore(doc);
          // Kök flood ve video içeren gönderiler
          final hasMedia = model.hasPlayableVideo;
          if (model.flood == true) {
            notRoot++;
            continue;
          }
          if (!hasMedia) {
            noMedia++;
            continue;
          }
          if ((model.floodCount) <= 1) {
            notSeries++;
            continue;
          }
          if (existingIDs.contains(model.docID)) {
            duplicates++;
            continue;
          }
          batch.add(model);
        }
        keptPreTimeDel = batch.length;
        batch = batch
            .where((p) => (p.timeStamp) <= nowMs)
            .where((p) => p.deletedPost != true)
            .toList();
        final removedByTimeOrDeleted = keptPreTimeDel - batch.length;
        final beforePrivacy = batch.length;
        batch = await _filterByPrivacy(batch);
        final removedByPrivacy = beforePrivacy - batch.length;
        print(
            '[FLOODS] keptAfterFilters=${batch.length} notRoot=$notRoot noMedia=$noMedia notSeries=$notSeries dup=$duplicates removedByTimeOrDeleted=$removedByTimeOrDeleted removedByPrivacy=$removedByPrivacy');
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
        print(
            '[FLOODS] appended=${accumulated.length} total=${exploreFloods.length} hasMore=${floodsHasMore.value}');
      } else {
        _floodsEmptyScans++;
        if (_floodsEmptyScans >= 2 || noMoreServerPages) {
          floodsHasMore.value = false;
        }
        print(
            '[FLOODS] no new items. emptyScans=$_floodsEmptyScans hasMore=${floodsHasMore.value}');
      }
    } catch (e) {
      print("fetchfloods error: $e");
    }
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
    final initial = items.length;
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
    final removed = initial - filtered.length;
    print('[FLOODS] privacyFilter removed=$removed kept=${filtered.length}');
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
    } catch (e) {
      print("❌ Typesense arama hatası: $e");
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
