import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Models/HashtagModel.dart';
import 'package:turqappv2/Models/OgrenciModel.dart';
import 'package:turqappv2/Core/Services/PerformanceService.dart';
import 'package:turqappv2/Services/user_analytics_service.dart';

import '../../Models/PostsModel.dart';

class ExploreController extends GetxController {
  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  RxString searchText = "".obs;
  RxList<OgrenciModel> searchedList = <OgrenciModel>[].obs;
  RxList<HashtagModel> searchedHashtags = <HashtagModel>[].obs;
  RxList<HashtagModel> searchedTags = <HashtagModel>[].obs;
  RxBool showAllRecent = false.obs;
  RxBool isKeyboardOpen = false.obs;
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

  @override
  void onInit() {
    super.onInit();
    _applyUserCacheQuota();
    UserAnalyticsService.instance.trackFeatureUsage('explore_open');
    fetchTrendingTags();
    fetchExplorePosts(); // İlk sekme hızlı açılsın
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

      if (isKeyboardOpen.value == false) {
        searchController.clear();
        searchText.value = "";
        searchedList.clear();
        searchedHashtags.clear();
        searchedTags.clear();
        showAllRecent.value = false;
      }

      if (searchFocus.hasFocus == false) {
        searchController.clear();
        searchText.value = "";
        searchedList.clear();
        searchedHashtags.clear();
        searchedTags.clear();
        showAllRecent.value = false;
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
          .collection('TakipEdilenler')
          .get(); // ✅ get() instead of snapshots()

      followingIDs.value = snap.docs.map((d) => d.id).toSet();
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
        // Sana Özel ekranı: sadece oynatılabilir video gönderileri
        newPosts = newPosts.where((p) => p.hasPlayableVideo).toList();
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
        final uniqueAccumulated = <PostsModel>[];
        final seen = <String>{};
        for (final p in accumulated) {
          if (existingIds.contains(p.docID)) continue;
          if (!seen.add(p.docID)) continue;
          uniqueAccumulated.add(p);
        }

        final prioritized = _prioritizeCachedVideos(uniqueAccumulated);
        explorePosts.addAll(prioritized);
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

  Future<void> fetchTrendingTags() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tags')
          .orderBy('count', descending: true)
          .limit(30)
          .get();

      final list = snap.docs
          .map((doc) {
            final data = doc.data();
            final raw = doc.id.trim();
            return HashtagModel(
              hashtag: raw.replaceFirst('#', ''),
              count: ((data['count'] ?? 0) as num),
              hasHashtag: raw.startsWith('#') ||
                  (((data['hashtagCount'] ?? 0) as num) > 0),
              lastSeenTs: ((data['lastSeenTs'] as num?)?.toInt()),
            );
          })
          .where((e) => e.hashtag.isNotEmpty && e.count > 0)
          .toList();

      trendingTags.assignAll(list);
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
        // Not: Firestore'da isNotEqualTo ile sıralama cursor uyumsuzlukları yaşanıyor.
        // Bu yüzden video filtrelemesini istemci tarafında yapıyoruz.
        const int pageLimit = 60;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        Query query = FirebaseFirestore.instance
            .collection('Posts')
            .where("arsiv", isEqualTo: false)
            .where('timeStamp', isLessThanOrEqualTo: nowMs)
            .orderBy("timeStamp", descending: true)
            .limit(pageLimit);

        if (lastVideoDoc != null) {
          query = query.startAfterDocument(lastVideoDoc!);
        }

        final snap = await PerformanceService.traceFeedLoad(
          () => query.get(),
          postCount: exploreVideos.length,
          feedMode: 'explore_video',
        );
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
            .limit(20); // ✅ Optimized: 30 → 20

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
        if (snap.docs.length < 30) photoHasMore.value = false;
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
    Map<String, bool> userPrivacy = {};
    final initial = items.length;
    // Firestore whereIn sınırı 10, bu yüzden parçalara böl
    for (var i = 0; i < uniqueUserIDs.length; i += 10) {
      final chunk = uniqueUserIDs.sublist(
          i, i + 10 > uniqueUserIDs.length ? uniqueUserIDs.length : i + 10);
      try {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in usersSnap.docs) {
          userPrivacy[d.id] = (d.data()['gizliHesap'] ?? false) == true;
        }
      } catch (_) {}
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
      searchedTags.value = allTagHits.where((e) => !e.hasHashtag).take(3).toList();

      final users = <OgrenciModel>[];
      for (final row in rawUserHits.whereType<Map>()) {
        final uid = (row['id'] ?? '').toString();
        if (uid.isEmpty || uid == currentUserId) continue;
        users.add(OgrenciModel(
          userID: uid,
          nickname: (row['nickname'] ?? '').toString(),
          firstName: (row['firstName'] ?? '').toString(),
          lastName: (row['lastName'] ?? '').toString(),
          pfImage: (row['pfImage'] ?? '').toString(),
        ));
      }
      searchedList.value = users;
    } catch (e) {
      print("❌ Typesense arama hatası: $e");
      searchedList.clear();
      searchedHashtags.clear();
      searchedTags.clear();
    }
  }

  @override
  void onClose() {
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
