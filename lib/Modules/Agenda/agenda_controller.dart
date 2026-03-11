import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/IndexPool/index_pool_store.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../NavBar/nav_bar_controller.dart';
import 'AgendaContent/agenda_content_controller.dart';
import '../../Services/current_user_service.dart';

enum FeedViewMode { forYou, following, city }

class AgendaController extends GetxController {
  final scrollController = ScrollController();
  UserProfileCacheService get _profileCache =>
      Get.isRegistered<UserProfileCacheService>()
          ? Get.find<UserProfileCacheService>()
          : Get.put(UserProfileCacheService(), permanent: true);

  final RxList<PostsModel> agendaList = <PostsModel>[].obs;
  final Map<String, GlobalKey> _agendaKeys = {};

  /// FAB gösterimi için kullanılır. Her frame'de reactive güncelleme yapmak yerine
  /// sadece eşik aşıldığında güncellenir (scroll jank'ı engeller).
  final RxBool showFAB = true.obs;
  final RxInt centeredIndex = 0.obs;
  int? lastCenteredIndex;
  var isMuted = false.obs;
  DocumentSnapshot? lastDoc;
  final RxBool hasMore = true.obs;
  final RxBool isLoading = false.obs;
  final int fetchLimit = 50;
  final pauseAll = false.obs;
  late NavBarController navBarController;
  final RxSet<String> highlightDocIDs = <String>{}.obs;
  Timer? _visibilityDebounce;
  Timer? _feedPrefetchDebounce;
  final Map<int, double> _visibleFractions = <int, double>{};
  final Map<int, DateTime> _visibleUpdatedAt = <int, DateTime>{};

  // Video içerik ekrana sadece HLS hazır olduğunda düşsün.
  bool _isRenderablePost(PostsModel post) {
    if (post.video.trim().isEmpty) return true; // text/photo post
    return post.hasPlayableVideo; // HLS ready + playbackUrl var
  }

  Future<bool> _canViewerSeePost(PostsModel post) async {
    if (hiddenPosts.contains(post.docID)) return false;
    if (post.deletedPost == true) return false;
    if (!_isRenderablePost(post)) return false;
    if (await _isUserDeactivated(post.userID)) return false;

    final isPrivate = await _isUserPrivate(post.userID);
    if (!isPrivate) return true;

    final me = FirebaseAuth.instance.currentUser?.uid;
    final isMine = me != null && post.userID == me;
    final follows = followingIDs.contains(post.userID);
    return isMine || follows;
  }

  final RxSet<String> followingIDs = <String>{}.obs;
  final Rx<FeedViewMode> feedViewMode = FeedViewMode.forYou.obs;
  final RxMap<String, int> myReshares =
      <String, int>{}.obs; // postID -> reshare timestamp
  final RxList<Map<String, dynamic>> publicReshareEvents =
      <Map<String, dynamic>>[].obs; // {postID,userID,timeStamp}
  final RxList<Map<String, dynamic>> feedReshareEntries =
      <Map<String, dynamic>>[].obs; // Feed'de görünecek reshare entry'leri
  final Map<String, bool> _userPrivacyCache = {};
  final Map<String, bool> _userDeactivatedCache = {};

  List<String> hiddenPosts = [];
  double lastOffset = 0.0;
  List<PostsModel> _shuffledPosts = []; // Refresh sonrası karışık postlar
  int _shuffledIndex = 0; // Karışık postlardaki mevcut index
  DateTime? _lastCacheTime; // Son cache zamanı
  final int _cacheValidMinutes = 5; // Cache geçerlilik süresi (dakika)
  final int _initialShuffleSize = 60; // İlk karışık yükleme miktarı
  final int _backgroundShuffleFetchSize = 300; // Arka plan tarama üst sınırı
  bool _ensureInitialLoadInFlight = false;
  DateTime? _lastEnsureInitialLoadAt;
  // null => no time window limit
  static const Duration? _agendaWindow = null;
  static const int _reshareScanPostLimit = 12;

  bool get isFollowingMode => feedViewMode.value == FeedViewMode.following;
  bool get isCityMode => feedViewMode.value == FeedViewMode.city;

  String get feedTitle {
    if (isFollowingMode) return 'Takip Ettiklerin';
    if (isCityMode) return 'Şehrim';
    return 'TurqApp';
  }

  String get currentUserLocationCity {
    final user = CurrentUserService.instance.currentUserRx.value;
    final candidates = [
      user?.locationSehir,
      user?.city,
      user?.ikametSehir,
      user?.il,
      user?.ulke,
    ];
    for (final raw in candidates) {
      final value = (raw ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return 'Türkiye';
  }

  void setFeedViewMode(FeedViewMode mode) {
    if (feedViewMode.value == mode) return;
    feedViewMode.value = mode;
  }

  int _agendaCutoffMs(int nowMs) {
    if (_agendaWindow == null) return 0;
    return nowMs - _agendaWindow!.inMilliseconds;
  }

  bool _isInAgendaWindow(num ts, int nowMs) {
    if (_agendaWindow == null) return true;
    final v = ts.toInt();
    return v >= _agendaCutoffMs(nowMs) && v <= nowMs;
  }

  @override
  void onInit() {
    super.onInit();
    // Liste boşsa ilk yüklemeyi geciktirmeden başlat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (agendaList.isEmpty && !isLoading.value) {
        unawaited(fetchAgendaBigData(initial: true));
      }
    });
    scrollController.addListener(_onScroll);
    navBarController = Get.isRegistered<NavBarController>()
        ? Get.find<NavBarController>()
        : Get.put(NavBarController());
    _bindFollowingListener();
    _bindCenteredIndexListener();
  }

  @override
  void onReady() {
    super.onReady();

    // 🎯 CRITICAL FIX: İlk açılışta video manuel trigger
    // centeredIndex zaten 0 olduğu için listener tetiklenmiyor
    // Manual olarak ilk videoyu oynatmalıyız
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (agendaList.isNotEmpty && centeredIndex.value == 0) {
        final videoManager = VideoStateManager.instance;
        final firstPost = agendaList[0];
        if (firstPost.video.isNotEmpty) {
          print('🎬 İlk video manuel trigger: ${firstPost.docID}');
          videoManager.playOnlyThis(firstPost.docID);
        }
      }
      _scheduleFeedPrefetch();
    });
  }

  /// 🎯 INSTAGRAM STYLE: centeredIndex değiştiğinde INSTANT video kontrolü
  void _bindCenteredIndexListener() {
    ever<int>(centeredIndex, (newIndex) {
      final videoManager = VideoStateManager.instance;

      // Eğer -1 ise (hiçbir post centered değil), tüm videoları durdur
      if (newIndex == -1) {
        videoManager.pauseAllVideos();
        return;
      }

      // Yeni centered post var
      if (newIndex >= 0 && newIndex < agendaList.length) {
        final centeredPost = agendaList[newIndex];

        // Eğer centered post VIDEO içeriyorsa, SADECE o videoyu oynat
        if (centeredPost.video.isNotEmpty) {
          // 🎯 CRITICAL FIX: pauseAllExcept yerine playOnlyThis kullan
          // playOnlyThis = diğerlerini durdur + bu videoyu OYNAT
          videoManager.playOnlyThis(centeredPost.docID);
        } else {
          // Centered post video değilse, TÜM videoları durdur
          // (Resim, metin gönderisi centered olduğunda)
          videoManager.pauseAllVideos();
        }
      }

      _scheduleFeedPrefetch();
    });
  }

  void _scheduleFeedPrefetch() {
    _feedPrefetchDebounce?.cancel();
    _feedPrefetchDebounce = Timer(const Duration(milliseconds: 500), () {
      _updateFeedPrefetchQueue();
    });
  }

  void _updateFeedPrefetchQueue() {
    if (agendaList.isEmpty) return;

    // C-006: Sonraki 5 post'un görsellerini prefetch et
    _prefetchUpcomingImages();

    final videoPosts = agendaList.where((p) => p.hasPlayableVideo).toList();
    if (videoPosts.isEmpty) return;

    int safeCurrent = 0;
    final centered = centeredIndex.value;
    if (centered >= 0 && centered < agendaList.length) {
      final centeredDocID = agendaList[centered].docID;
      final mapped = videoPosts.indexWhere((p) => p.docID == centeredDocID);
      if (mapped >= 0) {
        safeCurrent = mapped;
      } else {
        int beforeCount = 0;
        for (int i = 0; i < centered; i++) {
          if (agendaList[i].hasPlayableVideo) beforeCount++;
        }
        safeCurrent = beforeCount.clamp(0, videoPosts.length - 1);
      }
    }
    final docIds = videoPosts.map((p) => p.docID).toList();

    try {
      Get.find<PrefetchScheduler>().updateFeedQueue(docIds, safeCurrent);
    } catch (_) {}
  }

  int _resolveResumeIndex() {
    if (agendaList.isEmpty) return -1;

    int bestIndex = -1;
    double bestFraction = 0.0;
    _visibleFractions.forEach((idx, fraction) {
      if (idx < 0 || idx >= agendaList.length) return;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = idx;
      }
    });

    if (bestIndex >= 0) return bestIndex;
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < agendaList.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeFeedPlayback() {
    if (agendaList.isEmpty) return;

    pauseAll.value = false;
    int target = _resolveResumeIndex();
    if (target < 0 || target >= agendaList.length) {
      target = 0;
    }

    // Hedef post video değilse en yakın oynatılabilir videoya kay.
    if (!agendaList[target].hasPlayableVideo) {
      final nextVideo =
          agendaList.indexWhere((p) => p.hasPlayableVideo, target);
      if (nextVideo != -1) {
        target = nextVideo;
      } else {
        final anyVideo = agendaList.indexWhere((p) => p.hasPlayableVideo);
        if (anyVideo != -1) target = anyVideo;
      }
    }

    if (target < 0 || target >= agendaList.length) return;
    lastCenteredIndex = target;
    if (centeredIndex.value != target) {
      centeredIndex.value = target;
    }

    final targetPost = agendaList[target];
    if (!targetPost.hasPlayableVideo) return;

    final manager = VideoStateManager.instance;
    manager.playOnlyThis(targetPost.docID);

    // Route/tab dönüşünde player yeniden register olabiliyor; bir kez daha tetikle.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (centeredIndex.value != target) return;
      manager.playOnlyThis(targetPost.docID);
    });
  }

  /// C-006: Sonraki 5 post'un görsellerini disk cache'e prefetch et.
  void _prefetchUpcomingImages() {
    final current = centeredIndex.value.clamp(0, agendaList.length - 1);
    final end = (current + 6).clamp(0, agendaList.length);
    for (int i = current + 1; i < end; i++) {
      final post = agendaList[i];
      // Post görseli
      if (post.img.isNotEmpty) {
        TurqImageCacheManager.instance.getSingleFile(post.img.first).ignore();
      }
      // Thumbnail (video postlar için)
      if (post.thumbnail.isNotEmpty) {
        TurqImageCacheManager.instance.getSingleFile(post.thumbnail).ignore();
      }
    }
  }

  /// Uygulama açıkken dışarıdan tetiklenen hafif cache ısınması.
  void ensureFeedCacheWarm() {
    _scheduleFeedPrefetch();
  }

  @override
  void onClose() {
    _visibilityDebounce?.cancel();
    _feedPrefetchDebounce?.cancel();
    unawaited(persistWarmLaunchCache());
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= agendaList.length) return;
    final prev = _visibleFractions[modelIndex];

    // Android'de hızlı scroll sırasında çok sık visibility callback gelir;
    // küçük dalgalanmaları ignore ederek rebuild/focus thrash'i azalt.
    if (GetPlatform.isAndroid &&
        prev != null &&
        (prev - visibleFraction).abs() < 0.08) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      _visibleUpdatedAt[modelIndex] = DateTime.now();
    }

    // Arşiv projedeki daha stabil akış:
    // %80+ görünürlükte oynat, %40 altına düşünce durdur.
    // Böylece üstte çok az görünen video oynatılmaz; merkezdeki video öncelik alır.
    const double playThreshold = 0.80;
    // Stop threshold'u Android'de biraz daha düşük tut:
    // merkez postu gereksiz yere -1 yapıp oynatma/pausa döngüsü oluşturmasın.
    final double stopThreshold = GetPlatform.isAndroid ? 0.25 : 0.40;

    if (visibleFraction >= playThreshold) {
      if (centeredIndex.value != modelIndex) {
        centeredIndex.value = modelIndex;
        lastCenteredIndex = modelIndex;
      }
      return;
    }

    if (visibleFraction < stopThreshold && centeredIndex.value == modelIndex) {
      centeredIndex.value = -1;
    }
  }

  void _bindFollowingListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // İlk yükleme: pull-based (SWR pattern)
    _fetchFollowingAndReshares(uid);
  }

  /// Pull-based following + reshares fetch (realtime listener yerine).
  /// Dışarıdan da çağrılabilir (ör. follow/unfollow sonrası).
  Future<void> _fetchFollowingAndReshares(String uid) async {
    try {
      final followSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('followings')
          .get();
      followingIDs.assignAll(followSnap.docs.map((d) => d.id).toSet());
    } catch (_) {}

    try {
      final reshareSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reshared_posts')
          .orderBy('timeStamp', descending: true)
          .limit(200)
          .get();
      final map = <String, int>{};
      for (final doc in reshareSnap.docs) {
        final data = doc.data();
        final postId = data['post_docID'] as String?;
        if (postId == null || postId.isEmpty) continue;
        final ts = (data['timeStamp'] ?? 0) as int;
        map[postId] = ts;
      }
      myReshares.value = map;
    } catch (_) {}
  }

  /// Follow/unfollow sonrası çağrılabilecek refresh metodu.
  Future<void> refreshFollowingData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _fetchFollowingAndReshares(uid);
  }

  // Fetch a few recent reshares for these posts from followers and public users
  Future<void> fetchResharesForPosts(List<PostsModel> posts,
      {int perPostLimit = 2}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final targetPosts = posts.take(_reshareScanPostLimit).toList();
      if (targetPosts.isEmpty) return;

      final existingKeys = publicReshareEvents
          .map((e) => '${e['postID']}::${e['userID']}')
          .toSet();
      final buffered = <Map<String, dynamic>>[];
      final maybeUnknownUsers = <String>{};

      for (final p in targetPosts) {
        try {
          final qs = await FirebaseFirestore.instance
              .collection('Posts')
              .doc(p.docID)
              .collection('reshares')
              .orderBy('timeStamp', descending: true)
              .limit(perPostLimit)
              .get();
          for (final d in qs.docs) {
            final rid = d.id;
            if (uid != null && rid == uid) {
              continue; // my own handled via myReshares
            }
            final key = '${p.docID}::$rid';
            if (existingKeys.contains(key)) continue;

            final data = d.data();
            final ts = (data['timeStamp'] ?? 0) as int;
            final originalUserID = data['originalUserID'] as String?;
            final originalPostID = data['originalPostID'] as String?;
            if (!followingIDs.contains(rid) &&
                !_userPrivacyCache.containsKey(rid)) {
              maybeUnknownUsers.add(rid);
            }

            // Twitter benzeri reshare event'i ekle - orijinal post bilgileriyle
            final reshareEvent = {
              'postID': p.docID,
              'userID': rid,
              'timeStamp': ts,
              'type': 'reshare'
            };

            // Orijinal post bilgilerini de ekle
            if (originalUserID != null && originalUserID.isNotEmpty) {
              reshareEvent['originalUserID'] = originalUserID;
              reshareEvent['originalPostID'] = originalPostID ?? p.docID;
            } else {
              reshareEvent['originalUserID'] = p.userID;
              reshareEvent['originalPostID'] = p.docID;
            }

            buffered.add(reshareEvent);
            existingKeys.add(key);
          }
        } catch (_) {}
      }

      await _warmPrivacyCacheForUsers(maybeUnknownUsers.toList());

      for (final event in buffered) {
        final rid = (event['userID'] ?? '').toString();
        if (rid.isEmpty) continue;
        if (followingIDs.contains(rid)) {
          publicReshareEvents.add(event);
          continue;
        }
        final isPrivate = _userPrivacyCache[rid] ?? false;
        if (!isPrivate) {
          publicReshareEvents.add(event);
        }
      }
    } catch (_) {}
  }

  // Güvenli ekleme: agendaList'e docID bazında tekilleştirerek ekle
  void _addUniqueToAgenda(List<PostsModel> items) {
    if (items.isEmpty) return;
    final existing = agendaList.map((e) => e.docID).toSet();
    final unique = <PostsModel>[];
    for (final p in items) {
      if (!existing.contains(p.docID)) {
        existing.add(p.docID);
        unique.add(p);
      }
    }
    if (unique.isNotEmpty) {
      agendaList.addAll(unique);
      _scheduleFeedPrefetch();
    }
  }

  Future<bool> _isUserPrivate(String userID) async {
    if (_userPrivacyCache.containsKey(userID)) {
      return _userPrivacyCache[userID]!;
    }
    try {
      final data = await _profileCache.getProfile(
        userID,
        preferCache: true,
        cacheOnly: !ContentPolicy.isConnected,
      );
      final gizli = (data?['isPrivate'] ?? false) == true;
      _userDeactivatedCache[userID] = _isUserMarkedDeactivated(data);
      _userPrivacyCache[userID] = gizli;
      return gizli;
    } catch (_) {
      _userPrivacyCache[userID] = false;
      _userDeactivatedCache[userID] = false;
      return false;
    }
  }

  bool _isUserMarkedDeactivated(Map<String, dynamic>? data) {
    if (data == null) return false;
    final deletedAccount = (data['isDeleted'] ?? false) == true;
    final status = (data['accountStatus'] ?? '').toString().toLowerCase();
    return deletedAccount ||
        status == 'pending_deletion' ||
        status == 'deleted';
  }

  Future<bool> _isUserDeactivated(String userID) async {
    if (_userDeactivatedCache.containsKey(userID)) {
      return _userDeactivatedCache[userID]!;
    }
    try {
      final data = await _profileCache.getProfile(
        userID,
        preferCache: true,
        cacheOnly: !ContentPolicy.isConnected,
      );
      final deactivated = _isUserMarkedDeactivated(data);
      _userDeactivatedCache[userID] = deactivated;
      _userPrivacyCache[userID] = (data?['isPrivate'] ?? false) == true;
      return deactivated;
    } catch (_) {
      _userDeactivatedCache[userID] = false;
      return false;
    }
  }

  Future<void> _warmPrivacyCacheForUsers(List<String> userIds) async {
    final unresolved = userIds
        .where((id) =>
            id.isNotEmpty &&
            (!_userPrivacyCache.containsKey(id) ||
                !_userDeactivatedCache.containsKey(id)))
        .toSet()
        .toList();
    if (unresolved.isEmpty) return;

    for (final chunk in _chunkList(unresolved, 10)) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        final found = <String>{};
        for (final d in snap.docs) {
          found.add(d.id);
          final data = d.data();
          _userPrivacyCache[d.id] = (data['isPrivate'] ?? false) == true;
          _userDeactivatedCache[d.id] = _isUserMarkedDeactivated(data);
        }
        for (final id in chunk) {
          if (found.contains(id)) continue;
          _userPrivacyCache[id] = false;
          _userDeactivatedCache[id] = false;
        }
      } catch (_) {}
    }
  }

  GlobalKey getAgendaKeyForDoc(String docID) {
    return _agendaKeys.putIfAbsent(
        docID, () => GlobalObjectKey("agenda_$docID"));
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;
    bool shouldShowNavBar;

    // Üst sınıra çok yakınken daima göster.
    if (currentOffset <= 0) {
      shouldShowNavBar = true;
    } else {
      // Aşağı kaydırınca gizle, yukarı kaydırınca göster.
      if (currentOffset > lastOffset) {
        shouldShowNavBar = false;
      } else if (currentOffset < lastOffset) {
        shouldShowNavBar = true;
      } else {
        shouldShowNavBar = navBarController.showBar.value;
      }
    }
    // Scroll boyunca gereksiz Rx publish'i engelle
    if (navBarController.showBar.value != shouldShowNavBar) {
      navBarController.showBar.value = shouldShowNavBar;
    }
    lastOffset = currentOffset;

    // Liste sonuna yaklaşınca yeni verileri çek
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      fetchAgendaBigData();
    }

    // FAB'ı sadece eşik geçişlerinde güncelle (her frame'de değil)
    final shouldShowFab = currentOffset <= 1000;
    if (showFAB.value != shouldShowFab) {
      showFAB.value = shouldShowFab;
    }
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController for $docID");
    }
  }

  void markHighlighted(List<String> docIDs, {Duration? keepFor}) {
    highlightDocIDs.addAll(docIDs);
    // Otomatik olarak belirli süre sonra temizle
    final d = keepFor ?? const Duration(seconds: 2);
    Future.delayed(d, () {
      highlightDocIDs.removeAll(docIDs);
    });
  }

  // Yeni yüklenen gönderileri en üste almak için güvenli yenileme
  Future<void> prependUploadedAndRefresh() async {
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      await refreshAgenda();
    } catch (e) {
      print('prependUploadedAndRefresh error: $e');
    }
  }

  Future<void> fetchAgendaBigData({bool initial = false}) async {
    if (initial) {
      lastDoc = null;
      hasMore.value = true;
      agendaList.clear();
      _shuffledPosts.clear(); // Shuffle cache'ini temizle
      _shuffledIndex = 0;
      // Eski yeniden paylaşım meta verilerini sıfırla
      publicReshareEvents.clear();
      feedReshareEntries.clear();

      // 🎯 INSTAGRAM STYLE: İlk açılışta centered index'i sıfırla
      centeredIndex.value = -1;

      // Hızlı ilk boya için: cache'ten doldurmayı dene (gizlilik güvenli)
      try {
        await _tryQuickFillFromCache();
      } catch (e) {
        // Sessizce devam et, sunucu isteğine geçilecek
        // print("quick cache fill error: $e");
      }

      // İlk yüklemede reshare eventlerini arka planda getir (feed'i bloklamasın)
      unawaited(_fetchAndMergeReshareEvents());
    }

    // Eğer shuffle edilmiş postlar varsa onlardan devam et
    if (_shuffledPosts.isNotEmpty && _shuffledIndex < _shuffledPosts.length) {
      if (!hasMore.value || isLoading.value) return;
      isLoading.value = true;

      try {
        final remainingCount = _shuffledPosts.length - _shuffledIndex;
        final takeCount =
            remainingCount > fetchLimit ? fetchLimit : remainingCount;

        final nextBatch =
            _shuffledPosts.sublist(_shuffledIndex, _shuffledIndex + takeCount);
        _addUniqueToAgenda(nextBatch);
        _shuffledIndex += takeCount;

        if (_shuffledIndex >= _shuffledPosts.length) {
          hasMore.value = false;
        }
      } finally {
        isLoading.value = false;
      }
      return;
    }

    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      Query query = FirebaseFirestore.instance
          .collection("Posts")
          .where("arsiv", isEqualTo: false)
          .where("flood", isEqualTo: false)
          .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
          .where('timeStamp', isLessThanOrEqualTo: nowMs)
          .orderBy("timeStamp", descending: true)
          .limit(fetchLimit);

      if (lastDoc != null) {
        query =
            (query as Query<Map<String, dynamic>>).startAfterDocument(lastDoc!);
      }

      final snap = await query.get();

      final items = snap.docs
          .map((doc) =>
              PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          // Son 24 saat penceresi
          .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
          .where((p) => p.deletedPost != true)
          .toList();

      // Yazarların gizlilik durumlarını çek ve gizli profilleri filtrele
      final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
      Map<String, bool> userPrivacy = {};
      Map<String, bool> userDeactivated = {};
      Map<String, Map<String, dynamic>> userMeta = {};
      if (uniqueUserIDs.isNotEmpty) {
        // whereIn 10 eleman sınırı — fetchLimit zaten 10
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: uniqueUserIDs)
            .get();
        for (final d in usersSnap.docs) {
          final data = d.data();
          final gizli = (data['isPrivate'] ?? false) == true;
          final deactivated = _isUserMarkedDeactivated(data);
          userPrivacy[d.id] = gizli;
          userDeactivated[d.id] = deactivated;
          _userPrivacyCache[d.id] = gizli;
          _userDeactivatedCache[d.id] = deactivated;
          userMeta[d.id] = data;
        }
      }

      final String? me = FirebaseAuth.instance.currentUser?.uid;
      final visibleItems = items.where((post) {
        if (hiddenPosts.contains(post.docID)) return false;
        if (post.deletedPost == true) return false;
        if (!_isRenderablePost(post)) return false;
        if (userDeactivated[post.userID] == true) return false;
        final isPrivate = userPrivacy[post.userID] ?? false;
        if (!isPrivate) return true;
        // Gizli ise: sadece kendi gönderisi veya takip ediliyorsa göster
        final isMine = me != null && post.userID == me;
        final follows = followingIDs.contains(post.userID);
        return isMine || follows;
      }).toList();

      lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

      if (visibleItems.isNotEmpty) {
        unawaited(_saveFeedPostsToPool(visibleItems, userMeta));
        // Yeni eklenecekler içinde "zamanlıydı ve yeni görünür oldu" olanları vurgula
        final existingIDs = agendaList.map((e) => e.docID).toSet();
        final toAdd = <PostsModel>[];
        final freshScheduled = <String>[];
        final tenMinAgo = nowMs - const Duration(minutes: 15).inMilliseconds;
        for (final p in visibleItems) {
          final isNew = !existingIDs.contains(p.docID);
          if (!isNew) continue;
          toAdd.add(p);
          final wasScheduled = p.timeStamp != 0;
          final justBecameVisible = wasScheduled && p.timeStamp >= tenMinAgo;
          if (justBecameVisible) {
            freshScheduled.add(p.docID);
          }
        }
        if (freshScheduled.isNotEmpty) {
          markHighlighted(freshScheduled,
              keepFor: const Duration(milliseconds: 900));
        }
        if (toAdd.isNotEmpty) {
          _addUniqueToAgenda(toAdd);
          // Fetch recent reshare events for these posts (followers or public users)
          // Fire and forget
          fetchResharesForPosts(toAdd, perPostLimit: 1);
        }
      }

      if (items.length < fetchLimit) {
        hasMore.value = false;
      }
    } catch (e) {
      print("fetchAgendaBigData error: $e");
    } finally {
      isLoading.value = false; // HER DURUMDA EN SON ÇALIŞIR

      // 🎯 INSTAGRAM STYLE: İlk açılışta ilk videoyu otomatik centered yap
      if (initial && agendaList.isNotEmpty) {
        // Bir frame bekle ki VisibilityDetector build olsun
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            centeredIndex.value = 0;
            lastCenteredIndex = 0;
          }
        });
      }
    }
  }

  Future<void> ensureInitialFeedLoaded() async {
    if (agendaList.isNotEmpty ||
        isLoading.value ||
        _ensureInitialLoadInFlight) {
      return;
    }

    final now = DateTime.now();
    if (_lastEnsureInitialLoadAt != null &&
        now.difference(_lastEnsureInitialLoadAt!) <
            const Duration(seconds: 2)) {
      return;
    }
    _lastEnsureInitialLoadAt = now;
    _ensureInitialLoadInFlight = true;
    try {
      await fetchAgendaBigData(initial: true);
    } finally {
      _ensureInitialLoadInFlight = false;
    }
  }

  // Cache-first: başlangıçta cache'te varsa hızlıca ilk 10 gönderiyi doldur
  Future<void> _tryQuickFillFromCache() async {
    await _tryQuickFillFromPool();
    if (agendaList.isNotEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    Query query = FirebaseFirestore.instance
        .collection("Posts")
        .where("arsiv", isEqualTo: false)
        .where("flood", isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy("timeStamp", descending: true)
        .limit(fetchLimit);

    final snap = await query.get(const GetOptions(source: Source.cache));
    if (snap.docs.isEmpty) return;

    final items = snap.docs
        .map((doc) =>
            PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
        .where((p) => p.deletedPost != true)
        .toList();
    if (items.isEmpty) return;

    // Kullanıcı gizliliklerini merkezi profile cache + Firestore cache'ten getir
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    Map<String, bool> userPrivacy = {};
    Map<String, bool> userDeactivated = {};
    final profiles = await _profileCache.getProfiles(
      uniqueUserIDs,
      preferCache: true,
      cacheOnly: true,
    );
    for (final uid in uniqueUserIDs) {
      final data = profiles[uid];
      if (data == null) continue;
      final gizli = (data['isPrivate'] ?? false) == true;
      final deactivated = _isUserMarkedDeactivated(data);
      userPrivacy[uid] = gizli;
      userDeactivated[uid] = deactivated;
      _userPrivacyCache[uid] = gizli;
      _userDeactivatedCache[uid] = deactivated;
    }

    final String? me = FirebaseAuth.instance.currentUser?.uid;
    final filtered = items.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (!_isRenderablePost(post)) return false;
      if (userDeactivated[post.userID] == true) return false;
      final isPrivate = userPrivacy[post.userID] ?? false;
      if (!isPrivate) return true;
      final isMine = me != null && post.userID == me;
      final follows = followingIDs.contains(post.userID);
      return isMine || follows;
    }).toList();

    if (filtered.isEmpty) return;
    // Duplicate'e düşmemek için mevcut ID'leri kontrol et
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd =
        filtered.where((p) => !existingIDs.contains(p.docID)).toList();
    if (toAdd.isNotEmpty) {
      _addUniqueToAgenda(toAdd);
      // Reshare'leri gecikmeli getir (açılışta bant genişliğini kritik sorgulara bırak)
      Future.delayed(const Duration(seconds: 2), () {
        fetchResharesForPosts(toAdd, perPostLimit: 1);
      });

      // 🎯 INSTAGRAM STYLE: Cache'den yüklendiğinde de ilk videoyu centered yap
      if (agendaList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            centeredIndex.value = 0;
            lastCenteredIndex = 0;
          }
        });
      }
    }
  }

  Future<void> _tryQuickFillFromPool() async {
    if (!Get.isRegistered<IndexPoolStore>()) return;
    final pool = Get.find<IndexPoolStore>();
    final fromPool = await pool.loadPosts(
      IndexPoolKind.feed,
      limit: ContentPolicy.feedInitialFromPool,
      allowStale: true,
    );
    if (fromPool.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final uniqueUserIDs = fromPool.map((e) => e.userID).toSet().toList();
    final profiles = await _profileCache.getProfiles(
      uniqueUserIDs,
      preferCache: true,
      cacheOnly: true,
    );
    final me = FirebaseAuth.instance.currentUser?.uid;

    // Pool'dan gelen postları gerçekten hızlıca göster.
    // Gizlilik için sadece cache-only profillere güveniriz; bilinmeyen kullanıcıyı
    // hızlı listede göstermeyip ağ fetch'ine bırakırız.
    final quickFiltered = fromPool.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (post.deletedPost == true) return false;
      if (!_isInAgendaWindow(post.timeStamp, nowMs)) return false;
      if (!_isRenderablePost(post)) return false;
      final profile = profiles[post.userID];
      if (profile == null) return false;
      final isPrivate = (profile['isPrivate'] ?? false) == true;
      final isDeactivated = _isUserMarkedDeactivated(profile);
      _userPrivacyCache[post.userID] = isPrivate;
      _userDeactivatedCache[post.userID] = isDeactivated;
      if (isDeactivated) return false;
      if (!isPrivate) return true;
      final isMine = me != null && post.userID == me;
      final follows = followingIDs.contains(post.userID);
      return isMine || follows;
    }).toList();

    if (quickFiltered.isEmpty) return;

    _addUniqueToAgenda(quickFiltered);

    // Arka planda: validasyon + gizlilik kontrolü + reshare
    unawaited(_postPoolFillCleanup(fromPool, quickFiltered));

    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          centeredIndex.value = 0;
          lastCenteredIndex = 0;
        }
      });
    }
  }

  /// Pool fill sonrası arka planda: validasyon, gizlilik prune, reshare fetch
  Future<void> _postPoolFillCleanup(
      List<PostsModel> originalPool, List<PostsModel> shown) async {
    try {
      // Validasyon: silinmiş/arşivlenmiş postları pool'dan temizle
      final valid = await _validatePoolPostsAndPrune(originalPool);
      final validIds = valid.map((p) => p.docID).toSet();

      // Toplu gizlilik kontrolü (whereIn ile, tek tek değil)
      final uniqueUserIDs = valid.map((e) => e.userID).toSet().toList();
      final Map<String, bool> userPrivacy = {};
      final Map<String, bool> userDeactivated = {};
      for (final chunk in _chunkList(uniqueUserIDs, 10)) {
        try {
          final usersSnap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final d in usersSnap.docs) {
            final data = d.data();
            final gizli = (data['isPrivate'] ?? false) == true;
            final deactivated = _isUserMarkedDeactivated(data);
            userPrivacy[d.id] = gizli;
            userDeactivated[d.id] = deactivated;
            _userPrivacyCache[d.id] = gizli;
            _userDeactivatedCache[d.id] = deactivated;
          }
        } catch (_) {}
      }

      final String? me = FirebaseAuth.instance.currentUser?.uid;

      // Gösterilen ama aslında geçersiz/gizli olan postları feed'den kaldır
      final toRemove = <String>[];
      for (final post in shown) {
        if (!validIds.contains(post.docID)) {
          toRemove.add(post.docID);
          continue;
        }
        if (userDeactivated[post.userID] == true) {
          toRemove.add(post.docID);
          continue;
        }
        final isPrivate = userPrivacy[post.userID] ?? false;
        if (isPrivate) {
          final isMine = me != null && post.userID == me;
          final follows = followingIDs.contains(post.userID);
          if (!isMine && !follows) {
            toRemove.add(post.docID);
          }
        }
      }

      if (toRemove.isNotEmpty) {
        agendaList.removeWhere((p) => toRemove.contains(p.docID));
      }

      // Reshare'leri gecikmeli getir (bant genişliği çakışmasını önle)
      Future.delayed(const Duration(seconds: 2), () {
        fetchResharesForPosts(agendaList.take(10).toList(), perPostLimit: 1);
      });
    } catch (_) {}
  }

  Future<List<PostsModel>> _validatePoolPostsAndPrune(
      List<PostsModel> posts) async {
    if (posts.isEmpty) return const <PostsModel>[];

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
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final d in snap.docs) {
        final data = d.data();
        final deleted = (data['deletedPost'] ?? false) == true;
        final archived = (data['arsiv'] ?? false) == true;
        final timeStamp =
            (data['timeStamp'] is num) ? (data['timeStamp'] as num).toInt() : 0;
        if (!deleted && !archived && _isInAgendaWindow(timeStamp, nowMs)) {
          validPostIds.add(d.id);
        }
      }
    }

    final validUserIds = <String>{};
    for (final chunk in _chunkList(userIds.toList(), 10)) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        final data = d.data();
        final deactivated = _isUserMarkedDeactivated(data);
        _userDeactivatedCache[d.id] = deactivated;
        _userPrivacyCache[d.id] = (data['isPrivate'] ?? false) == true;
        if (!deactivated) {
          validUserIds.add(d.id);
        }
      }
    }

    final valid = posts
        .where((p) =>
            validPostIds.contains(p.docID) && validUserIds.contains(p.userID))
        .toList();
    if (valid.length == posts.length) return valid;

    final invalidIds = posts
        .where((p) =>
            !validPostIds.contains(p.docID) || !validUserIds.contains(p.userID))
        .map((p) => p.docID)
        .toList();
    if (invalidIds.isNotEmpty && Get.isRegistered<IndexPoolStore>()) {
      await Get.find<IndexPoolStore>()
          .removePosts(IndexPoolKind.feed, invalidIds);
    }

    return valid;
  }

  Future<void> _saveFeedPostsToPool(
    List<PostsModel> posts,
    Map<String, Map<String, dynamic>> userMeta,
  ) async {
    if (posts.isEmpty) return;
    if (!Get.isRegistered<IndexPoolStore>()) return;
    await Get.find<IndexPoolStore>().savePosts(
      IndexPoolKind.feed,
      posts,
      userMeta: userMeta,
    );
  }

  Future<void> persistWarmLaunchCache() async {
    try {
      if (agendaList.isEmpty) return;
      if (!Get.isRegistered<IndexPoolStore>()) return;

      final posts = agendaList.take(40).toList(growable: false);
      if (posts.isEmpty) return;

      final userIds = <String>{
        for (final post in posts) post.userID,
        for (final post in posts)
          if (post.originalUserID.isNotEmpty) post.originalUserID,
      }.toList();

      final userMeta = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        final profileCache = Get.isRegistered<UserProfileCacheService>()
            ? Get.find<UserProfileCacheService>()
            : Get.put(UserProfileCacheService(), permanent: true);
        final cachedProfiles = await profileCache.getProfiles(
          userIds,
          preferCache: true,
          cacheOnly: true,
        );
        userMeta.addAll(cachedProfiles);
      }

      await _saveFeedPostsToPool(posts, userMeta);
    } catch (_) {}
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

  Future<void> refreshAgenda() async {
    try {
      // Refresh başlarken tüm oynatımları kesin durdur.
      pauseAll.value = true;
      centeredIndex.value = -1;
      lastCenteredIndex = null;
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}

      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      // Pull-to-refresh => "ilk açılış" gibi tam sıfırdan başlat.
      // Bu sayede shuffle yerine en güncel veriler yeniden çekilir.
      lastDoc = null;
      hasMore.value = true;
      agendaList.clear();
      _shuffledPosts.clear();
      _shuffledIndex = 0;
      _lastCacheTime = null;

      publicReshareEvents.clear();
      feedReshareEntries.clear();

      // Following/reshare verilerini yenile (SWR)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) unawaited(_fetchFollowingAndReshares(uid));

      // İlk açılış pipeline'ını kullan: hızlı cache + sunucudan güncel veri.
      await fetchAgendaBigData(initial: true);
      await _fetchAndMergeReshareEvents();
      pauseAll.value = false;
    } catch (e) {
      print("refreshAgenda error: $e");
      pauseAll.value = false;
    }
  }

  // Refresh sırasında karışık gönderi getir - HIZLI VERSİYON
  Future<void> fetchRandomizedAgendaData() async {
    try {
      // Cache kontrolü - eğer cache geçerliyse ve karışık postlar varsa hızlı yükle
      if (_isCacheValid() && _shuffledPosts.isNotEmpty) {
        print("Cache'den hızlı yükleme yapılıyor...");
        _shuffledPosts.shuffle(Random()); // Yeniden karıştır
        _shuffledIndex = 0;

        final initialItems = _shuffledPosts.take(fetchLimit).toList();
        _addUniqueToAgenda(initialItems);
        _shuffledIndex = fetchLimit;
        hasMore.value = _shuffledPosts.length > fetchLimit;

        // 🎯 INSTAGRAM STYLE: Cache'den yüklendiğinde ilk videoyu centered yap
        if (agendaList.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (agendaList.isNotEmpty && centeredIndex.value == -1) {
              centeredIndex.value = 0;
              lastCenteredIndex = 0;
            }
          });
        }
        return;
      }

      print("Yeni veri çekiliyor...");

      // İlk olarak küçük bir batch çek (hızlı görünüm için)
      await _fetchInitialShuffledBatch();

      // Arka planda daha fazla veri çek
      _fetchMoreShuffledDataInBackground();
    } catch (e) {
      print("fetchRandomizedAgendaData error: $e");
    }
  }

  // Cache geçerli mi kontrol et
  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    final now = DateTime.now();
    final diff = now.difference(_lastCacheTime!).inMinutes;
    return diff < _cacheValidMinutes;
  }

  // İlk küçük batch'i hızlıca getir
  Future<void> _fetchInitialShuffledBatch() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    Query query = FirebaseFirestore.instance
        .collection("Posts")
        .where("arsiv", isEqualTo: false)
        .where("flood", isEqualTo: false)
        .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy("timeStamp", descending: true)
        .limit(_initialShuffleSize); // 100 gönderi

    final snap = await query.get();
    // nowMs already computed above

    final items = snap.docs
        .map((doc) =>
            PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
        .where((p) => p.deletedPost != true)
        .toList();

    // Gizlilik kontrolü - sadece gerekli kullanıcılar için
    final visibleItemsRaw = await _filterPrivateItems(items);

    // DocID bazında tekilleştir
    final Map<String, PostsModel> uniqueMap = {
      for (final p in visibleItemsRaw) p.docID: p,
    };
    final visibleItems = uniqueMap.values.toList();

    // Karıştır ve göster
    visibleItems.shuffle(Random());
    _shuffledPosts = visibleItems;
    _shuffledIndex = 0;
    _lastCacheTime = DateTime.now();

    final initialItems = _shuffledPosts.take(fetchLimit).toList();
    _addUniqueToAgenda(initialItems);
    _shuffledIndex = fetchLimit;
    hasMore.value = _shuffledPosts.length > fetchLimit;

    // 🎯 INSTAGRAM STYLE: İlk batch yüklendiğinde ilk videoyu centered yap
    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          centeredIndex.value = 0;
          lastCenteredIndex = 0;
        }
      });
    }
  }

  // Arka planda daha fazla veri çek
  void _fetchMoreShuffledDataInBackground() async {
    try {
      // 2-3 saniye bekle ki kullanıcı hızlı görünümü görsün
      await Future.delayed(const Duration(seconds: 2));

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      Query query = FirebaseFirestore.instance
          .collection("Posts")
          .where("arsiv", isEqualTo: false)
          .where("flood", isEqualTo: false)
          .where('timeStamp', isGreaterThanOrEqualTo: cutoffMs)
          .where('timeStamp', isLessThanOrEqualTo: nowMs)
          .orderBy("timeStamp", descending: true)
          .limit(_backgroundShuffleFetchSize);

      final snap = await query.get();
      // nowMs already computed above

      final items = snap.docs
          .map((doc) =>
              PostsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
          .where((p) => p.deletedPost != true)
          .toList();

      final visibleItemsRaw = await _filterPrivateItems(items);
      // DocID bazında tekilleştir
      final Map<String, PostsModel> uniqueMap = {
        for (final p in visibleItemsRaw) p.docID: p,
      };
      final visibleItems = uniqueMap.values.toList();

      // Mevcut gösterilenleri koru, kalanları güncelle
      final currentVisible = agendaList.take(_shuffledIndex).toList();
      visibleItems.shuffle(Random());

      // Yeni listeyi hazırla (mevcut gösterilenler + yeni karışık liste)
      _shuffledPosts = [
        ...currentVisible,
        ...visibleItems.where(
            (item) => !currentVisible.any((shown) => shown.docID == item.docID))
      ];

      hasMore.value = _shuffledPosts.length > _shuffledIndex;
      print(
          "Arka plan yüklemesi tamamlandı: ${_shuffledPosts.length} gönderi hazır");
    } catch (e) {
      print("Background fetch error: $e");
    }
  }

  // Gizlilik filtreleme - optimize edilmiş
  Future<List<PostsModel>> _filterPrivateItems(List<PostsModel> items) async {
    final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
    Map<String, bool> userPrivacy = {};
    Map<String, bool> userDeactivated = {};

    if (uniqueUserIDs.isNotEmpty) {
      // Batch'leri 10'ar yerine 30'ar yap (daha az sorgu)
      final batches = <List<String>>[];
      for (int i = 0; i < uniqueUserIDs.length; i += 30) {
        final endIndex =
            (i + 30 > uniqueUserIDs.length) ? uniqueUserIDs.length : i + 30;
        final batch = uniqueUserIDs.sublist(i, endIndex);
        if (batch.length <= 10) {
          // 10 ve altındaysa tek sorguda çek
          batches.add(batch);
        } else {
          // 10'dan fazlaysa 10'ar böl
          for (int j = 0; j < batch.length; j += 10) {
            final subEndIndex = (j + 10 > batch.length) ? batch.length : j + 10;
            batches.add(batch.sublist(j, subEndIndex));
          }
        }
      }

      for (final batch in batches) {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final d in usersSnap.docs) {
          final data = d.data();
          final gizli = (data['isPrivate'] ?? false) == true;
          final deactivated = _isUserMarkedDeactivated(data);
          userPrivacy[d.id] = gizli;
          userDeactivated[d.id] = deactivated;
          _userPrivacyCache[d.id] = gizli;
          _userDeactivatedCache[d.id] = deactivated;
        }
      }
    }

    final String? me = FirebaseAuth.instance.currentUser?.uid;
    return items.where((post) {
      if (hiddenPosts.contains(post.docID)) return false;
      if (post.deletedPost == true) return false;
      if (!_isRenderablePost(post)) return false;
      if (userDeactivated[post.userID] == true) return false;
      final isPrivate = userPrivacy[post.userID] ?? false;
      if (!isPrivate) return true;
      final isMine = me != null && post.userID == me;
      final follows = followingIDs.contains(post.userID);
      return isMine || follows;
    }).toList();
  }

  // Yeni yüklenen gönderileri sadece listenin başına ekle (full refresh yapmadan)
  void addUploadedPostsAtTop(List<PostsModel> posts) {
    if (posts.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd = <PostsModel>[];
    for (final p in posts) {
      if (!existingIDs.contains(p.docID) &&
          !hiddenPosts.contains(p.docID) &&
          _isInAgendaWindow(p.timeStamp, nowMs) &&
          _isRenderablePost(p)) {
        toAdd.add(p);
      }
    }
    if (toAdd.isEmpty) return;
    agendaList.insertAll(0, toAdd);

    // Yeni eklenen postların originalUserID'lerini cache'e preload et
    _preloadOriginalUserNicknames(toAdd);
  }

  // Paylaşım yapan kullanıcıların nickname'lerini önceden cache'e yükle
  void _preloadOriginalUserNicknames(List<PostsModel> posts) {
    final userIDsToLoad = <String>{};

    for (final post in posts) {
      // Post sahibini cache'e ekle
      userIDsToLoad.add(post.userID);

      // Eğer paylaşım ise, orijinal kullanıcıyı da cache'e ekle
      // Eğer reshare ise, orijinal kullanıcıyı da cache'e ekle
      if (post.originalUserID.isNotEmpty) {
        userIDsToLoad.add(post.originalUserID);
      }
    }

    // Async olarak nickname'leri yükle (UI'yi bloklamadan)
    for (final userID in userIDsToLoad) {
      ReshareHelper.getUserNickname(userID).catchError((e) {
        // Hata durumunda sessizce geç, varsayılan değer döner
        return 'Bilinmeyen Kullanıcı';
      });
    }
  }

  // Reshare eventlerini getir ve ayrı listede tut (orijinal postlara dokunma)
  Future<void> _fetchAndMergeReshareEvents() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Takip edilen kullanıcıların reshare eventlerini getir
      final List<Map<String, dynamic>> allReshareEvents = [];

      // Kendi reshare eventleri (her zaman göster)
      final myReshareSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reshared_posts')
          .orderBy('timeStamp', descending: true)
          .limit(50)
          .get();

      for (final doc in myReshareSnap.docs) {
        final data = doc.data();
        final postId = data['post_docID'] as String?;
        final timestamp = (data['timeStamp'] ?? 0) as int;
        final originalUserID = data['originalUserID'] as String?;
        final originalPostID = data['originalPostID'] as String?;

        if (postId != null && postId.isNotEmpty) {
          allReshareEvents.add({
            'postID': postId,
            'userID': uid,
            'timeStamp': timestamp,
            'originalUserID': originalUserID ?? '',
            'originalPostID': originalPostID ?? '',
            'type': 'reshare'
          });
        }
      }

      // users/{otherUid}/reshared_posts owner-only olduğundan (rules),
      // sadece current user reshare verisi kullanılır.

      // Reshare eventlerdeki postları getir ve feed reshare entries'e ekle
      final Set<String> resharedPostIds =
          allReshareEvents.map((e) => e['postID'] as String).toSet();

      if (resharedPostIds.isNotEmpty) {
        final List<String> postIdsList = resharedPostIds.toList();

        // Firebase whereIn limit 10, bu yüzden batch'lere böl
        for (int i = 0; i < postIdsList.length; i += 10) {
          final batch = postIdsList.sublist(
              i, i + 10 > postIdsList.length ? postIdsList.length : i + 10);

          try {
            final postsSnap = await FirebaseFirestore.instance
                .collection('Posts')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

            for (final postDoc in postsSnap.docs) {
              final post = PostsModel.fromMap(postDoc.data(), postDoc.id);
              if (!await _canViewerSeePost(post)) continue;

              // Bu post ile ilgili tüm reshare eventleri
              final relatedReshares = allReshareEvents
                  .where((event) => event['postID'] == post.docID)
                  .toList();

              for (final reshareEvent in relatedReshares) {
                // Feed reshare entry'si oluştur
                final feedEntry = {
                  'type': 'reshare',
                  'post': post,
                  'reshareTimestamp': reshareEvent['timeStamp'],
                  'reshareUserID': reshareEvent['userID'],
                  'originalUserID': reshareEvent['originalUserID'],
                  'originalPostID': reshareEvent['originalPostID'],
                };

                // Duplicate kontrolü
                final entryId =
                    '${post.docID}_${reshareEvent['userID']}_${reshareEvent['timeStamp']}';
                final exists = feedReshareEntries.any((entry) {
                  final existingId =
                      '${(entry['post'] as PostsModel).docID}_${entry['reshareUserID']}_${entry['reshareTimestamp']}';
                  return existingId == entryId;
                });

                if (!exists) {
                  feedReshareEntries.add(feedEntry);
                }

                // Metadata'ya da ekle
                publicReshareEvents.add(reshareEvent);
              }
            }
          } catch (e) {
            print('Error fetching posts for batch $i: $e');
          }
        }
      }
    } catch (e) {
      print('_fetchAndMergeReshareEvents error: $e');
    }
  }

  // Sadece reshare entries'leri güncelle (scroll position'ı koruyarak)
  Future<void> updateReshareEntries() async {
    try {
      feedReshareEntries.clear();
      await _fetchAndMergeReshareEvents();
    } catch (e) {
      print('updateReshareEntries error: $e');
    }
  }

  // Yeni bir reshare entry'si ekle (en üste, en yeni timestamp ile)
  Future<void> addNewReshareEntry(String postId, String reshareUserID) async {
    try {
      // İlgili post'u bul
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        // Post bulunamadıysa Firebase'den çek
        final postDoc = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .get();

        if (!postDoc.exists) return;

        final fetchedPost = PostsModel.fromMap(postDoc.data()!, postDoc.id);
        if (!await _canViewerSeePost(fetchedPost)) return;

        // Yeni reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': fetchedPost,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': fetchedPost.originalUserID.isNotEmpty
              ? fetchedPost.originalUserID
              : fetchedPost.userID,
          'originalPostID': fetchedPost.originalPostID.isNotEmpty
              ? fetchedPost.originalPostID
              : fetchedPost.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
        // Mevcut post'tan reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': post.originalUserID.isNotEmpty
              ? post.originalUserID
              : post.userID,
          'originalPostID':
              post.originalPostID.isNotEmpty ? post.originalPostID : post.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      }
    } catch (e) {
      print('addNewReshareEntry error: $e');
    }
  }

  // Scroll pozisyonunu koruyarak reshare entry ekle
  Future<void> addNewReshareEntryWithoutScroll(
      String postId, String reshareUserID) async {
    try {
      // Mevcut scroll pozisyonunu kaydet
      final currentOffset =
          scrollController.hasClients ? scrollController.offset : 0.0;
      // İlgili post'u bul
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        // Post bulunamadıysa Firebase'den çek
        final postDoc = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .get();

        if (!postDoc.exists) return;

        final fetchedPost = PostsModel.fromMap(postDoc.data()!, postDoc.id);
        if (!await _canViewerSeePost(fetchedPost)) return;

        // Yeni reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': fetchedPost,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': fetchedPost.originalUserID.isNotEmpty
              ? fetchedPost.originalUserID
              : fetchedPost.userID,
          'originalPostID': fetchedPost.originalPostID.isNotEmpty
              ? fetchedPost.originalPostID
              : fetchedPost.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
        // Mevcut post'tan reshare entry'si oluştur
        final reshareEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': post.originalUserID.isNotEmpty
              ? post.originalUserID
              : post.userID,
          'originalPostID':
              post.originalPostID.isNotEmpty ? post.originalPostID : post.docID,
        };

        // En üste ekle
        feedReshareEntries.insert(0, reshareEntry);
      }

      // UI güncellensin diye bir frame bekle, sonra scroll pozisyonunu geri yükle
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scrollController.hasClients) {
          // Yeni item eklendi, bu nedenle eski pozisyona geri dön
          // Ama yeni item height'ı da hesaba kat
          await scrollController.animateTo(
            currentOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('addNewReshareEntryWithoutScroll error: $e');
    }
  }

  // Reshare entry'sini kaldır
  void removeReshareEntry(String postId, String reshareUserID) {
    try {
      feedReshareEntries.removeWhere((entry) {
        final entryPost = entry['post'] as PostsModel;
        final entryUserID = entry['reshareUserID'] as String;
        return entryPost.docID == postId && entryUserID == reshareUserID;
      });
    } catch (e) {
      print('removeReshareEntry error: $e');
    }
  }
}
