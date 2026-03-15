import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
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

part 'agenda_controller_feed_part.dart';
part 'agenda_controller_reshare_part.dart';

enum FeedViewMode { forYou, following, city }

class _AgendaSourcePage {
  const _AgendaSourcePage({
    required this.items,
    required this.lastDoc,
    required this.usesPrimaryFeed,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
}

class AgendaController extends GetxController {
  final scrollController = ScrollController();
  UserProfileCacheService get _profileCache =>
      Get.isRegistered<UserProfileCacheService>()
          ? Get.find<UserProfileCacheService>()
          : Get.put(UserProfileCacheService(), permanent: true);
  UserRepository get _userRepository => UserRepository.ensure();
  PostRepository get _postRepository => PostRepository.ensure();

  final RxList<PostsModel> agendaList = <PostsModel>[].obs;
  final RxList<Map<String, dynamic>> mergedFeedEntries =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFeedEntries =
      <Map<String, dynamic>>[].obs;
  final Map<String, GlobalKey> _agendaKeys = {};

  /// FAB gösterimi için kullanılır. Her frame'de reactive güncelleme yapmak yerine
  /// sadece eşik aşıldığında güncellenir (scroll jank'ı engeller).
  final RxBool showFAB = true.obs;
  final RxInt centeredIndex = 0.obs;
  int? lastCenteredIndex;
  var isMuted = false.obs;
  DocumentSnapshot? lastDoc;
  bool _usePrimaryFeedPaging = true;
  final RxBool hasMore = true.obs;
  final RxBool isLoading = false.obs;
  final int fetchLimit = 50;
  final pauseAll = false.obs;
  late NavBarController navBarController;
  final RxSet<String> highlightDocIDs = <String>{}.obs;
  Timer? _visibilityDebounce;
  Timer? _feedPrefetchDebounce;
  Worker? _mergedFeedWorker;
  Worker? _filteredFeedWorker;
  final Map<int, double> _visibleFractions = <int, double>{};
  final Map<int, DateTime> _visibleUpdatedAt = <int, DateTime>{};

  // Video içerik ekrana sadece HLS hazır olduğunda düşsün.
  bool _isRenderablePost(PostsModel post) {
    if (post.video.trim().isEmpty) return true; // text/photo post
    return post.hasPlayableVideo; // HLS ready + playbackUrl var
  }

  bool _isBlurredIzBirakVideo(PostsModel post, [int? nowMs]) {
    final scheduled = post.scheduledAt.toInt();
    if (scheduled <= 0 || post.video.trim().isEmpty) return false;
    final publishAt =
        scheduled > 0 ? scheduled : post.izBirakYayinTarihi.toInt();
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return publishAt > now;
  }

  bool _canAutoplayVideoPost(PostsModel post, [int? nowMs]) {
    return post.hasPlayableVideo && !_isBlurredIzBirakVideo(post, nowMs);
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

  bool _isEligibleAgendaPost(PostsModel post, int nowMs) {
    final ts = post.timeStamp.toInt();
    if (_agendaWindow != null && ts < _agendaCutoffMs(nowMs)) {
      return false;
    }
    if (ts <= nowMs) {
      return true;
    }
    return post.scheduledAt.toInt() > 0;
  }

  bool _isEligibleFeedReference(num ts, int nowMs) {
    final value = ts.toInt();
    if (_agendaWindow != null && value < _agendaCutoffMs(nowMs)) {
      return false;
    }
    return value > 0;
  }

  Future<List<PostsModel>> _fetchVisiblePublicIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final effectivePreferCache = cacheOnly ? preferCache : false;
    final publicIzBirakPosts =
        await _postRepository.fetchPublicScheduledIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      preferCache: effectivePreferCache,
      cacheOnly: cacheOnly,
    );
    if (publicIzBirakPosts.isEmpty) return const <PostsModel>[];

    final authorMeta = await _userRepository.getUsersRaw(
      publicIzBirakPosts.map((p) => p.userID).toSet().toList(),
      preferCache: effectivePreferCache,
      cacheOnly: cacheOnly,
    );
    return publicIzBirakPosts.where((post) {
      final meta = authorMeta[post.userID];
      final rozet = (meta?['rozet'] ?? '').toString().trim();
      final isApproved =
          (meta?['isApproved'] ?? meta?['hesapOnayi'] ?? false) == true;
      if (rozet.isEmpty && !isApproved) return false;
      return true;
    }).toList(growable: false);
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
    _bindMergedFeedEntries();
    _bindFilteredFeedEntries();
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
        if (_canAutoplayVideoPost(firstPost)) {
          videoManager.playOnlyThis(firstPost.docID);
        }
      }
      _scheduleFeedPrefetch();
    });
  }

  @override
  void onClose() {
    _mergedFeedWorker?.dispose();
    _filteredFeedWorker?.dispose();
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

  void _bindMergedFeedEntries() {
    _mergedFeedWorker?.dispose();
    _mergedFeedWorker = everAll(
      [agendaList, feedReshareEntries],
      (_) => _rebuildMergedFeedEntries(),
    );
    _rebuildMergedFeedEntries();
  }

  void _bindFilteredFeedEntries() {
    _filteredFeedWorker?.dispose();
    _filteredFeedWorker = everAll(
      [
        mergedFeedEntries,
        feedViewMode,
        followingIDs,
        CurrentUserService.instance.currentUserRx,
      ],
      (_) => _rebuildFilteredFeedEntries(),
    );
    _rebuildFilteredFeedEntries();
  }

  void _rebuildMergedFeedEntries() {
    if (agendaList.isEmpty && feedReshareEntries.isEmpty) {
      mergedFeedEntries.clear();
      return;
    }

    final agendaIndexByDoc = <String, int>{
      for (int i = 0; i < agendaList.length; i++) agendaList[i].docID: i,
    };

    final displayByDoc = <String, Map<String, dynamic>>{};

    for (int i = 0; i < agendaList.length; i++) {
      final post = agendaList[i];
      displayByDoc[post.docID] = {
        'type': 'normal',
        'model': post,
        'reshare': false,
        'reshareUserID': null,
        'timestamp': post.timeStamp,
        'agendaIndex': i,
      };
    }

    for (final reshareEntry in feedReshareEntries) {
      final post = reshareEntry['post'] as PostsModel;
      final idx = agendaIndexByDoc[post.docID] ?? -1;
      final modelRef = idx >= 0 ? agendaList[idx] : post;
      final reshareTimestamp = (reshareEntry['reshareTimestamp'] ?? 0) as int;
      final reshareUserID = reshareEntry['reshareUserID'] as String?;

      final existing = displayByDoc[post.docID];
      final existingTs = (existing?['timestamp'] ?? 0) as int;
      if (existing == null || reshareTimestamp >= existingTs) {
        displayByDoc[post.docID] = {
          'type': 'reshare',
          'model': modelRef,
          'reshare': true,
          'reshareUserID': reshareUserID,
          'timestamp': reshareTimestamp,
          'agendaIndex': idx,
        };
      }
    }

    final merged = displayByDoc.values.toList(growable: false)
      ..sort(
        (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );

    mergedFeedEntries.assignAll(merged);
  }

  void _rebuildFilteredFeedEntries() {
    if (mergedFeedEntries.isEmpty) {
      filteredFeedEntries.clear();
      return;
    }

    List<Map<String, dynamic>> filtered =
        mergedFeedEntries.toList(growable: false);

    if (isFollowingMode && followingIDs.isNotEmpty) {
      final followingSet = followingIDs;
      filtered = filtered.where((item) {
        final model = item['model'] as PostsModel;
        return followingSet.contains(model.userID);
      }).toList(growable: false);
    } else if (isCityMode) {
      final city = currentUserLocationCity.trim().toLowerCase();
      filtered = filtered.where((item) {
        final model = item['model'] as PostsModel;
        return model.locationCity.trim().toLowerCase() == city;
      }).toList(growable: false);
    }

    filteredFeedEntries.assignAll(filtered);
  }

  /// Pull-based following + reshares fetch (realtime listener yerine).
  /// Dışarıdan da çağrılabilir (ör. follow/unfollow sonrası).
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
      _usePrimaryFeedPaging = true;
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
      unawaited(_fetchAndMergeReshareEvents(eventLimit: 200));
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
      final loadLimit = initial ? 30 : fetchLimit;
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: loadLimit,
      );

      final items = page.items
          .where((p) => _isInAgendaWindow(p.timeStamp, nowMs))
          .where((p) => p.deletedPost != true)
          .toList();

      // Yazarların gizlilik durumlarını çek ve gizli profilleri filtrele
      final uniqueUserIDs = items.map((e) => e.userID).toSet().toList();
      Map<String, bool> userPrivacy = {};
      Map<String, bool> userDeactivated = {};
      Map<String, Map<String, dynamic>> userMeta = {};
      if (uniqueUserIDs.isNotEmpty) {
        final unresolved = _primeAgendaUserStateFromCaches(
          uniqueUserIDs,
          userPrivacy,
          userDeactivated,
          userMeta,
        );
        if (unresolved.isNotEmpty) {
          await _fillAgendaUserStateFromProfiles(
            unresolved,
            userPrivacy,
            userDeactivated,
            userMeta,
          );
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

      _usePrimaryFeedPaging = page.usesPrimaryFeed;
      lastDoc = page.lastDoc;

      if (visibleItems.isNotEmpty) {
        final missingMetaUserIDs = visibleItems
            .map((post) => post.userID)
            .where((uid) => !userMeta.containsKey(uid))
            .toSet()
            .toList();
        if (missingMetaUserIDs.isNotEmpty) {
          await _fillAgendaUserStateFromProfiles(
            missingMetaUserIDs,
            userPrivacy,
            userDeactivated,
            userMeta,
          );
        }
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

      if (page.lastDoc == null || items.length < loadLimit) {
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
    final page = await _loadAgendaSourcePage(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: fetchLimit,
      preferCache: true,
      cacheOnly: true,
    );
    if (page.items.isEmpty) return;

    final items = page.items
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
      unawaited(_revalidateQuickFilledAgenda(toAdd));
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
    final cutoffMs = _agendaCutoffMs(nowMs);
    final publicIzBirakPosts = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: ContentPolicy.feedInitialFromPool,
      preferCache: true,
      cacheOnly: true,
    );
    final sourcePosts = <PostsModel>[
      ...fromPool,
      ...publicIzBirakPosts,
    ];
    final uniqueUserIDs = sourcePosts.map((e) => e.userID).toSet().toList();
    final profiles = await _profileCache.getProfiles(
      uniqueUserIDs,
      preferCache: true,
      cacheOnly: true,
    );
    final me = FirebaseAuth.instance.currentUser?.uid;

    // Pool'dan gelen postları gerçekten hızlıca göster.
    // Gizlilik için sadece cache-only profillere güveniriz; bilinmeyen kullanıcıyı
    // hızlı listede göstermeyip ağ fetch'ine bırakırız.
    final quickFiltered = sourcePosts.where((post) {
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
    unawaited(_postPoolFillCleanup(sourcePosts, quickFiltered));

    if (agendaList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          centeredIndex.value = 0;
          lastCenteredIndex = 0;
        }
      });
    }
  }

  Future<void> _revalidateQuickFilledAgenda(List<PostsModel> shown) async {
    if (shown.isEmpty || !ContentPolicy.isConnected) return;
    try {
      final valid = await _validatePoolPostsAndPrune(shown);
      final validIds = valid.map((p) => p.docID).toSet();
      if (validIds.length == shown.length) return;

      final toRemove = shown
          .where((post) => !validIds.contains(post.docID))
          .map((post) => post.docID)
          .toSet();
      if (toRemove.isEmpty) return;

      agendaList.removeWhere((post) => toRemove.contains(post.docID));
    } catch (_) {}
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
      final userMeta = <String, Map<String, dynamic>>{};
      final unresolved = _primeAgendaUserStateFromCaches(
        uniqueUserIDs,
        userPrivacy,
        userDeactivated,
        userMeta,
      );
      if (unresolved.isNotEmpty) {
        await _fillAgendaUserStateFromProfiles(
          unresolved,
          userPrivacy,
          userDeactivated,
          userMeta,
          includeMeta: false,
        );
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
    final preferCache = !ContentPolicy.isConnected;
    final cacheOnly = !ContentPolicy.isConnected;
    for (final chunk in _chunkList(postIds.toList(), 10)) {
      final postsById = await _postRepository.fetchPostsByIds(
        chunk,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final entry in postsById.entries) {
        final post = entry.value;
        final deleted = post.deletedPost == true;
        final archived = post.arsiv == true;
        final timeStamp = post.timeStamp.toInt();
        if (!deleted && !archived && _isInAgendaWindow(timeStamp, nowMs)) {
          validPostIds.add(entry.key);
        }
      }
    }

    final validUserIds = <String>{};
    for (final chunk in _chunkList(userIds.toList(), 20)) {
      final users = await _userRepository.getUsersRaw(
        chunk,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final entry in users.entries) {
        final data = entry.value;
        final deactivated = _isUserMarkedDeactivated(data);
        _userDeactivatedCache[entry.key] = deactivated;
        _userPrivacyCache[entry.key] = (data['isPrivate'] ?? false) == true;
        if (!deactivated) {
          validUserIds.add(entry.key);
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

  Future<_AgendaSourcePage> _loadAgendaSourcePage({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (!_usePrimaryFeedPaging) {
      return _loadLegacyAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _loadLegacyAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    final page = await _postRepository.fetchUserFeedReferences(
      uid: uid,
      limit: limit,
      startAfter: lastDoc is DocumentSnapshot<Map<String, dynamic>>
          ? lastDoc as DocumentSnapshot<Map<String, dynamic>>
          : null,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );

    final refs = page.items
        .where(
          (item) =>
              item.timeStamp > 0 &&
              _isEligibleFeedReference(item.timeStamp, nowMs) &&
              (item.expiresAt <= 0 || item.expiresAt >= nowMs),
        )
        .toList(growable: false);

    final postIds = refs.map((item) => item.postId).toList(growable: false);
    final postsById = postIds.isEmpty
        ? const <String, PostsModel>{}
        : await _postRepository.fetchPostsByIds(
            postIds,
            preferCache: preferCache,
            cacheOnly: cacheOnly,
          );

    final merged = <String, PostsModel>{};
    for (final ref in refs) {
      final post = postsById[ref.postId];
      if (post == null) continue;
      merged[post.docID] = post;
    }

    final celebIds = await _postRepository.fetchCelebrityAuthorIds(
      <String>{uid, ...followingIDs}.toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    if (celebIds.isNotEmpty) {
      final celebPosts = await _postRepository.fetchRecentPostsForAuthors(
        celebIds,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        perAuthorLimit: max(2, (limit / max(1, celebIds.length)).ceil()),
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      for (final post in celebPosts) {
        merged.putIfAbsent(post.docID, () => post);
      }
    }

    final publicIzBirakPosts = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: max(20, limit),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    for (final post in publicIzBirakPosts) {
      merged.putIfAbsent(post.docID, () => post);
    }

    if (merged.isEmpty && page.lastDoc == null && lastDoc == null) {
      return _loadLegacyAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: limit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
    }

    final items = merged.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    return _AgendaSourcePage(
      items: items,
      lastDoc: page.lastDoc,
      usesPrimaryFeed: true,
    );
  }

  Future<_AgendaSourcePage> _loadLegacyAgendaSourcePage({
    required int nowMs,
    required int cutoffMs,
    required int limit,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final page = await _postRepository.fetchAgendaWindowPage(
      cutoffMs: cutoffMs,
      nowMs: nowMs,
      limit: limit,
      startAfter: lastDoc,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    return _AgendaSourcePage(
      items: page.items
          .where((p) => _isEligibleAgendaPost(p, nowMs))
          .where((p) => p.deletedPost != true)
          .toList(growable: false),
      lastDoc: page.lastDoc,
      usesPrimaryFeed: false,
    );
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
      await _fetchAndMergeReshareEvents(eventLimit: 500);
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
    final page = await _postRepository.fetchAgendaWindowPage(
      cutoffMs: cutoffMs,
      nowMs: nowMs,
      limit: _initialShuffleSize,
    );

    final publicIzBirakPosts = await _fetchVisiblePublicIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: _initialShuffleSize,
    );

    final items = <PostsModel>[
      ...page.items,
      ...publicIzBirakPosts,
    ]
        .where((p) => _isEligibleAgendaPost(p, nowMs))
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
      final page = await _postRepository.fetchAgendaWindowPage(
        cutoffMs: cutoffMs,
        nowMs: nowMs,
        limit: _backgroundShuffleFetchSize,
      );

      final publicIzBirakPosts = await _fetchVisiblePublicIzBirakPosts(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: _backgroundShuffleFetchSize,
      );

      final items = <PostsModel>[
        ...page.items,
        ...publicIzBirakPosts,
      ]
          .where((p) => _isEligibleAgendaPost(p, nowMs))
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
      final unresolved = _primeAgendaUserStateFromCaches(
        uniqueUserIDs,
        userPrivacy,
        userDeactivated,
        <String, Map<String, dynamic>>{},
      );
      if (unresolved.isNotEmpty) {
        await _fillAgendaUserStateFromProfiles(
          unresolved,
          userPrivacy,
          userDeactivated,
          <String, Map<String, dynamic>>{},
          includeMeta: false,
        );
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

  Future<void> addNewReshareEntryWithoutScroll(
    String postId,
    String reshareUserID,
  ) =>
      AgendaControllerResharePart(this).addNewReshareEntryWithoutScroll(
        postId,
        reshareUserID,
      );

  void removeReshareEntry(String postId, String reshareUserID) =>
      AgendaControllerResharePart(this).removeReshareEntry(
        postId,
        reshareUserID,
      );
}
