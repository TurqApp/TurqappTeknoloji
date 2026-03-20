import 'dart:math' as math;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import 'package:turqappv2/Core/Repositories/short_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/lru_cache.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/short_playback_coordinator.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import '../../Models/posts_model.dart';

/// Kısa videoları Firestore'dan çekip saklayan ve
/// range bazlı (±7 etrafında) preload & prune desteği sunan controller
/// + AKILLI DİNAMİK KARIŞTIRMA SİSTEMİ
class ShortController extends GetxController {
  static const bool _verboseShortLogs = false;
  void _log(String message) {
    if (_verboseShortLogs) debugPrint(message);
  }

  final RxList<PostsModel> shorts = <PostsModel>[].obs;
  final GlobalVideoAdapterPool _videoPool = GlobalVideoAdapterPool.ensure();
  final ShortPlaybackCoordinator _playbackCoordinator =
      ShortPlaybackCoordinator.forCurrentPlatform();
  final Map<int, HLSVideoAdapter> cache = {};
  final Map<int, _CacheTier> _tiers = {};
  final lastIndex = 0.obs;
  Future<void>? _backgroundPreloadFuture;
  Future<void>? _initialLoadFuture;
  static const int _initialPreloadCount = 3;

  static final double _activeBufferSeconds =
      defaultTargetPlatform == TargetPlatform.android ? 2.4 : 3.0;
  static final double _neighborBufferSeconds =
      defaultTargetPlatform == TargetPlatform.android ? 2.0 : 2.4;
  static final double _prepBufferSeconds =
      defaultTargetPlatform == TargetPlatform.android ? 1.8 : 2.1;

  // Dinamik yükleme durumları
  final int pageSize = 20;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isRefreshing = false.obs; // Yenileme durumu
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  // Basit yapı - davranış analizi kaldırıldı

  // Takip edilenler takibi
  final Set<String> _followingIDs = {};
  StreamSubscription? _followingSub;

  /// Kullanıcı gizlilik cache'i — her sayfa yüklemesinde aynı UID'leri tekrar sorgulamayı önler.
  /// Kapasite: 500 kullanıcı, TTL: 10 dakika (gizlilik ayarı sık değişmez).
  final _privacyCache = LRUCache<String, bool>(
    capacity: 500,
    ttl: const Duration(minutes: 10),
  );
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ShortRepository _shortRepository = ShortRepository.ensure();
  final ShortSnapshotRepository _shortSnapshotRepository =
      ShortSnapshotRepository.ensure();

  // Shuffle kontrolü - sadece UYGULAMA AÇILIŞINDA bir kez
  static bool _globalShuffleCompleted = false;

  Future<void> _downgradeAdapterForWarmTier(HLSVideoAdapter adapter) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await adapter.stopPlayback();
      return;
    }
    await adapter.pause();
  }

  @override
  void onInit() {
    super.onInit();
    _applyUserCacheQuota();
    _log('[Shorts] 🔄 ShortController.onInit() called');
    _bindFollowingListener();
    // İlk sayfayı manuel yüklemede çağırılacak (ShortView'dan)
  }

  Future<void> _applyUserCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGb = (prefs.getInt('offline_cache_quota_gb') ?? 3).clamp(3, 6);
      final quotaGb = (savedGb + 1).clamp(4, 7);
      if (Get.isRegistered<StorageBudgetManager>()) {
        await Get.find<StorageBudgetManager>().applyPlanGb(quotaGb);
      }
      if (Get.isRegistered<SegmentCacheManager>()) {
        await Get.find<SegmentCacheManager>().setUserLimitGB(quotaGb);
      }
    } catch (e) {
      _log('Shorts cache quota apply error: $e');
    }
  }

  @override
  void onClose() {
    _log('[Shorts] ❌ ShortController.onClose() called');
    _playbackCoordinator.reset();
    clearCache();
    _followingSub?.cancel();
    super.onClose();
  }

  /// Takip edilenler için realtime dinleyici
  /// ✅ OPTIMIZED: snapshots() → get() (real-time listener gereksiz)
  void _bindFollowingListener() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    _followingSub?.cancel();

    // One-time fetch instead of real-time listener
    _fetchFollowingList(myUid);
  }

  /// Fetch following list once
  Future<void> _fetchFollowingList(String myUid) async {
    try {
      final ids = await FollowRepository.ensure().getFollowingIds(
        myUid,
        preferCache: true,
      );
      _followingIDs
        ..clear()
        ..addAll(ids);
    } catch (e) {
      _log('following fetch error: $e');
    }
  }

  Future<_ShortPageResult> _fetchPage(
      {QueryDocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor = startAfter;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc = startAfter;
    bool hasMoreDocs = true;
    const int maxEmptyPageSkips = 3;

    for (int attempt = 0; attempt < maxEmptyPageSkips; attempt++) {
      final page = await _shortRepository.fetchReadyPage(
        startAfter: cursor,
        pageSize: pageSize,
        nowMs: nowMs,
      );

      lastDoc = page.lastDoc;
      hasMoreDocs = page.hasMore;

      if (page.posts.isEmpty) {
        return _ShortPageResult(
          posts: const [],
          lastDoc: cursor,
          hasMore: false,
        );
      }

      final rawWithVideo =
          page.posts.where((p) => p.hasPlayableVideo).toList(growable: false);
      final timeFiltered = rawWithVideo
          .where((p) => p.timeStamp <= nowMs)
          .toList(growable: false);
      final arsivFiltered =
          timeFiltered.where((p) => p.arsiv == false).toList(growable: false);
      final finalFiltered = arsivFiltered
          .where((p) => p.deletedPost != true)
          .toList(growable: false);

      if (finalFiltered.isNotEmpty) {
        final authorIds = finalFiltered.map((e) => e.userID).toSet().toList();
        final Map<String, bool> userPrivacy =
            await _fetchUsersPrivacy(authorIds);
        final myUid = FirebaseAuth.instance.currentUser?.uid;

        final filtered = <PostsModel>[];
        for (final p in finalFiltered) {
          final isPrivate = userPrivacy[p.userID] == true;
          final include = !isPrivate ||
              (myUid != null && p.userID == myUid) ||
              _followingIDs.contains(p.userID);
          if (include) {
            filtered.add(p);
          }
        }

        if (filtered.isNotEmpty) {
          return _ShortPageResult(
            posts: filtered,
            lastDoc: lastDoc,
            hasMore: hasMoreDocs,
          );
        }
      }

      if (!page.hasMore || page.lastDoc == null) {
        break;
      }
      cursor = page.lastDoc;
    }

    return _ShortPageResult(
      posts: const [],
      lastDoc: lastDoc,
      hasMore: hasMoreDocs,
    );
  }

  /// Arka plan preload - sadece ilk segment odaklı hafif hazırlık
  Future<void> backgroundPreload() async {
    if (_isFirstVideoReady()) {
      return;
    }

    // Birden fazla eş zamanlı preload isteğini tek Future'a bağla
    if (_backgroundPreloadFuture != null) {
      return _backgroundPreloadFuture;
    }

    _log(
        '[Shorts] 🚀 Background preload başlatılıyor (disk cache destekli)...');

    final future = _runBackgroundPreload();
    _backgroundPreloadFuture = future;

    try {
      await future;
    } finally {
      // Sadece bu Future işlemi tamamlandıysa null'a çek
      if (identical(_backgroundPreloadFuture, future)) {
        _backgroundPreloadFuture = null;
      }
    }
  }

  Future<void> _runInitialLoadOnce() {
    final inFlight = _initialLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _performInitialLoad();
    _initialLoadFuture = future;
    return future.whenComplete(() {
      if (identical(_initialLoadFuture, future)) {
        _initialLoadFuture = null;
      }
    });
  }

  Future<void> _performInitialLoad() async {
    _log(
        '[Shorts] loadInitialShorts - BAŞLADI (global shuffle completed: $_globalShuffleCompleted)');
    _log(
        '[Shorts] Current shorts list IDs BEFORE: ${shorts.map((s) => s.docID).take(5).toList()}');

    if (shorts.isEmpty) {
      final snapshot = await _shortSnapshotRepository.loadHome(
        userId: _currentUserId,
        limit: ContentPolicy.initialPoolLimit(ContentScreenKind.shorts),
      );
      final applied = _applySnapshotResource(snapshot);
      if (applied) {
        await preloadRange(0, range: 0);
        if (ContentPolicy.allowBackgroundRefresh(ContentScreenKind.shorts)) {
          unawaited(_loadNextPage());
        }
        return;
      }
      _log('[Shorts] Liste boş - sıfırlama yapılıyor');
      isLoading.value = false;
      hasMore.value = true;
      _lastDoc = null;
      clearCache();
      _log('[Shorts] loadInitialShorts - _loadNextPage çağrılıyor');
      await _loadNextPage();
    } else {
      _log('[Shorts] Liste zaten var (${shorts.length} video) - korunuyor');
      await preloadRange(0, range: 0);
    }

    _log(
        '[Shorts] loadInitialShorts - TAMAMLANDI, shorts.length: ${shorts.length}');
    _log(
        '[Shorts] Current shorts list IDs AFTER: ${shorts.map((s) => s.docID).take(5).toList()}');
  }

  Future<void> _runBackgroundPreload() async {
    if (shorts.isNotEmpty) {
      _log(
          '[Shorts] 🔄 Liste zaten mevcut (${shorts.length} video), ilk 5 preload');
      // İlk 3 videoyu preload et
      final initialCount = math.min(_initialPreloadCount, shorts.length);
      final futures = <Future>[];
      for (int i = 0; i < initialCount; i++) {
        if (!cache.containsKey(i)) {
          futures.add(_preloadSingleVideoWithCache(i, shorts[i]));
        }
      }
      await Future.wait(futures);
      // Tüm preloaded videolara düşük buffer ayarla
      for (int i = 0; i < initialCount; i++) {
        cache[i]?.setPreferredBufferDuration(_neighborBufferSeconds);
        _tiers[i] = _CacheTier.hot;
      }
      return;
    }

    // İlk yükleme
    try {
      _log('[Shorts] 📱 İlk defa yükleme yapılıyor...');
      await _runInitialLoadOnce();

      if (shorts.isNotEmpty) {
        final initialCount = math.min(_initialPreloadCount, shorts.length);
        _log('[Shorts] ⚡ İlk $initialCount video preload ediliyor...');
        final futures = <Future>[];
        for (int i = 0; i < initialCount; i++) {
          if (!cache.containsKey(i)) {
            futures.add(_preloadSingleVideoWithCache(i, shorts[i]));
          }
        }
        await Future.wait(futures);
        for (int i = 0; i < initialCount; i++) {
          cache[i]?.setPreferredBufferDuration(_neighborBufferSeconds);
          _tiers[i] = _CacheTier.hot;
        }
        _log(
            '[Shorts] ✅ Background preload tamamlandı - ilk $initialCount video hazır');
      }
    } catch (e) {
      _log('[Shorts] ❌ Background preload hatası: $e');
    }
  }

  /// Tek video için HLS adapter oluştur
  Future<HLSVideoAdapter?> _preloadSingleVideoWithCache(
      int index, PostsModel short,
      {Map<int, HLSVideoAdapter>? targetCache}) async {
    try {
      final videoUrl = short.playbackUrl;
      if (videoUrl.isEmpty) return null;

      final cacheTarget = targetCache ?? cache;
      if (cacheTarget.containsKey(index)) {
        return cacheTarget[index];
      }

      final adapter = _videoPool.acquire(
        cacheKey: short.docID,
        url: videoUrl,
        autoPlay: false,
        loop: true,
      );
      cacheTarget[index] = adapter;

      _log('[Shorts] ✅ Video $index HLS adapter hazır');
      return adapter;
    } catch (e) {
      _log('[Shorts] ❌ Video $index preload hatası: $e');
    }

    return null;
  }

  bool _isFirstVideoReady() {
    if (shorts.isEmpty) return false;
    return cache.containsKey(0);
  }

  /// Yenileme işlemi - basit ve etkili
  Future<void> refreshShorts() async {
    if (isRefreshing.value || isLoading.value) {
      return;
    }

    _log('[Shorts] 🔄 Refresh başlatıldı');
    isRefreshing.value = true;

    try {
      // Query state reset
      isLoading.value = false;
      hasMore.value = true;
      _lastDoc = null;

      final result = await _fetchPage();

      if (result.posts.isEmpty) {
        _log('[Shorts] ⚠️ Refresh sonucu boş - mevcut liste korunuyor');
        hasMore.value = result.hasMore;
        return;
      }

      final previousShorts = shorts.toList(growable: false);
      final newList = List<PostsModel>.from(result.posts);

      _replaceShorts(newList, remapCache: false);
      await _remapCacheForNewList(
        previous: previousShorts,
        next: newList,
      );
      final preloadCount = math.min(1, newList.length);
      for (int i = 0; i < preloadCount; i++) {
        if (!cache.containsKey(i)) {
          await _preloadSingleVideoWithCache(i, newList[i]);
        }
      }

      _lastDoc = result.lastDoc;
      hasMore.value = result.hasMore;
      lastIndex.value = 0;
      unawaited(_persistVisibleSnapshot());

      // Ek arka plan preload kapalı: sadece aktif video cache'te kalsın.
    } catch (e) {
      _log('[Shorts] ❌ Refresh hatası: $e');
      hasMore.value = true;
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Başlangıç yüklemesi (state reset + ilk sayfa)
  Future<void> loadInitialShorts() async {
    await _runInitialLoadOnce();
  }

  /// Sonsuz kaydırma için sonraki sayfa
  Future<void> loadMoreIfNeeded(int currentIndex) async {
    _log(
        '[Shorts] loadMoreIfNeeded called - currentIndex: $currentIndex, shorts.length: ${shorts.length}, isLoading: ${isLoading.value}, hasMore: ${hasMore.value}');
    if (isLoading.value || !hasMore.value) {
      _log(
          '[Shorts] loadMoreIfNeeded BLOCKED - isLoading: ${isLoading.value}, hasMore: ${hasMore.value}');
      return;
    }
    // Sona yaklaşınca getir
    if (currentIndex >= shorts.length - 3) {
      _log('[Shorts] loadMoreIfNeeded TRIGGERED - Loading next page...');
      await _loadNextPage();
    } else {
      _log(
          '[Shorts] loadMoreIfNeeded - Not yet time to load (need ${shorts.length - 3} but at $currentIndex)');
    }
  }

  /// Uygulama açılışında kısa videoları önceden getirip hazırlar
  /// Hedef: kullanıcı Short ekranına girdiğinde bekleme olmasın
  Future<void> warmStart({int targetCount = 20, int maxPages = 2}) async {
    try {
      if (shorts.isEmpty) {
        if (_backgroundPreloadFuture != null) {
          await _backgroundPreloadFuture;
        } else {
          await _runInitialLoadOnce();
        }
      }
      // İlk videoların adapter'larını hemen oluştur (ağ bağlantısı başlasın)
      if (shorts.isNotEmpty) {
        await updateCacheTiers(0);
      }
      // İkinci sayfa arka planda
      int loops = 0;
      while (shorts.length < targetCount && hasMore.value && loops < maxPages) {
        await _loadNextPage();
        loops++;
      }
    } catch (_) {}
  }

  /// Posts query: en yeni -> eski, arsiv=false, deletedPost=false, zaman geldi
  Future<void> _loadNextPage() async {
    _log(
        '[Shorts] _loadNextPage başladı - isLoading: ${isLoading.value}, hasMore: ${hasMore.value}');
    if (isLoading.value || !hasMore.value) return;
    isLoading.value = true;
    try {
      final result = await _fetchPage(startAfter: _lastDoc);

      if (result.posts.isEmpty) {
        hasMore.value = result.hasMore;
        if (!result.hasMore) {
          _log('[Shorts] Yeni sayfa bulunamadı, hasMore=false');
        }
        return;
      }

      _lastDoc = result.lastDoc;

      final existingIds = shorts.map((post) => post.docID).toSet();
      final incoming = result.posts
          .where((post) => !existingIds.contains(post.docID))
          .toList(growable: false);
      if (incoming.isNotEmpty) {
        if (shorts.isEmpty && !_globalShuffleCompleted) {
          final shuffled = List<PostsModel>.from(incoming);
          shuffled.shuffle();
          shorts.addAll(shuffled);
          unawaited(_persistVisibleSnapshot());
          _globalShuffleCompleted = true;
        } else {
          shorts.addAll(incoming);
          unawaited(_persistVisibleSnapshot());
        }
      }

      hasMore.value = result.hasMore;
    } catch (e) {
      _log('loadNextPage error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Eski shuffle sistemi tamamen kaldırıldı

  // Tüm shuffle fonksiyonları kaldırıldı

  // Tüm shuffle algoritmaları kaldırıldı

  // Eski shuffle sistemi tamamen kaldırıldı

  /// Kullanıcı gizliliklerini LRU cache üzerinden çek.
  /// Cache'te bulunanlar Firestore'a gitmez; sadece eksikler toplu sorgulanır.
  Future<Map<String, bool>> _fetchUsersPrivacy(List<String> uids) async {
    if (uids.isEmpty) return {};

    final result = <String, bool>{};

    // 1. Cache hit'leri topla
    final missing = <String>[];
    for (final uid in uids) {
      final cached = _privacyCache.get(uid);
      if (cached != null) {
        result[uid] = cached;
      } else {
        missing.add(uid);
      }
    }

    if (missing.isEmpty) return result;

    // 2. Sadece cache'te olmayan UID'leri Firestore'dan çek (whereIn max 10)
    const chunk = 10;
    for (int i = 0; i < missing.length; i += chunk) {
      final part = missing.sublist(i, (i + chunk).clamp(0, missing.length));
      try {
        final users = await _userSummaryResolver.resolveMany(
          part,
          preferCache: true,
        );

        for (final entry in users.entries) {
          final isPrivate = entry.value.isPrivate;
          result[entry.key] = isPrivate;
          _privacyCache.put(entry.key, isPrivate);
        }
      } catch (e) {
        _log('_fetchUsersPrivacy chunk error: $e');
      }

      // Firestore'da bulunmayan UID'ler → public varsay, cache'e ekle
      for (final uid in part) {
        result.putIfAbsent(uid, () => false);
        if (!_privacyCache.containsKey(uid)) {
          _privacyCache.put(uid, false);
        }
      }
    }

    return result;
  }

  /// Üç katmanlı cache güncellemesi:
  /// HOT  (current-2 ... current+3) : Native player yüklü, ~2 segment buffered
  /// WARM (current-5 ... current-3) : Adapter hayatta, player stopped (network yok)
  /// COLD (geri kalan)              : Tamamen dispose
  Future<void> updateCacheTiers(int currentIndex) async {
    if (shorts.isEmpty) return;
    final window = _playbackCoordinator.buildWindow(shorts, currentIndex);
    final hotIndices = window.hotIndices;
    final warmIndices = window.warmIndices;

    // 1. HOT: eksik adapter oluştur, stopped olanları reload et
    final futures = <Future>[];
    for (final i in hotIndices) {
      if (!cache.containsKey(i)) {
        futures.add(_preloadSingleVideoWithCache(i, shorts[i]));
      } else if (cache[i]!.isStopped) {
        futures.add(cache[i]!.reloadVideo());
      }
      _tiers[i] = _CacheTier.hot;
    }
    await Future.wait(futures);

    // 2. Buffer süreleri: current → geniş, ±1 → orta, diğer HOT → düşük
    for (final i in hotIndices) {
      final adapter = cache[i];
      if (adapter == null) continue;
      final distance = (i - currentIndex).abs();
      if (distance == 0) {
        adapter.setPreferredBufferDuration(_activeBufferSeconds);
      } else if (distance == 1) {
        adapter.setPreferredBufferDuration(_neighborBufferSeconds);
      } else {
        adapter.setPreferredBufferDuration(_prepBufferSeconds);
      }
    }

    // 3. WARM:
    // iOS/Android: yakın geri dönüşlerde siyah ekranı azaltmak için pause.
    // Uzak videolar COLD aşamasında dispose edildiğinden toplam yük yine kontrol altında.
    for (final i in warmIndices) {
      if (cache.containsKey(i) && _tiers[i] != _CacheTier.warm) {
        await _downgradeAdapterForWarmTier(cache[i]!);
        _tiers[i] = _CacheTier.warm;
      }
    }

    // 4. COLD: hot+warm dışındaki her şeyi dispose et
    final allCached = cache.keys.toList();
    for (final k in allCached) {
      if (!hotIndices.contains(k) && !warmIndices.contains(k)) {
        final adapter = cache[k];
        cache.remove(k);
        _tiers.remove(k);
        if (adapter != null) {
          unawaited(_videoPool.release(adapter));
        }
      }
    }

    // 5. Max player limiti
    _enforceMaxPlayers(currentIndex, window.maxAttachedPlayers);

    // 6. Wi-Fi prefetch tetikle
    try {
      Get.find<PrefetchScheduler>().updateQueue(
        shorts.map((s) => s.docID).toList(),
        currentIndex,
      );
    } catch (_) {}
  }

  void _enforceMaxPlayers(int currentIndex, int maxAttachedPlayers) {
    final activeKeys = cache.keys.where((k) => !cache[k]!.isStopped).toList()
      ..sort((a, b) =>
          (a - currentIndex).abs().compareTo((b - currentIndex).abs()));

    if (activeKeys.length > maxAttachedPlayers) {
      for (int i = maxAttachedPlayers; i < activeKeys.length; i++) {
        final k = activeKeys[i];
        final adapter = cache[k];
        cache.remove(k);
        _tiers.remove(k);
        if (adapter != null) {
          unawaited(_videoPool.release(adapter));
        }
      }
    }
  }

  /// Backward compat: eski callsite'lar için thin wrapper
  Future<void> preloadRange(int index, {int range = 1}) async {
    await updateCacheTiers(index);
  }

  /// Short ekranı ilk açıldığında warm-start cache çakışmasını azaltmak için
  /// yalnızca aktif index'i cache'te tut.
  Future<void> keepOnlyIndex(int index) async {
    final keys = cache.keys.toList(growable: false);
    for (final key in keys) {
      if (key == index) continue;
      final adapter = cache.remove(key);
      _tiers.remove(key);
      if (adapter != null) {
        try {
          await _videoPool.release(adapter);
        } catch (_) {}
      }
    }

    final current = cache[index];
    if (current != null && current.isStopped) {
      try {
        await current.reloadVideo();
      } catch (_) {}
    }
    if (cache.containsKey(index)) {
      _tiers[index] = _CacheTier.hot;
    }
  }

  /// Backward compat: eski callsite'lar için thin wrapper
  void pruneOutsideRange(int index, {int range = 2}) {
    // updateCacheTiers zaten prune ediyor, burada ek iş yok
  }

  /// Tamamen temizler
  void clearCache() {
    _playbackCoordinator.reset();
    for (final adapter in cache.values) {
      unawaited(_videoPool.release(adapter));
    }
    cache.clear();
    _tiers.clear();
  }

  // PostModel güncelle
  Future<void> updateShort(String docID) async {
    final updatedPost = await _shortRepository.fetchById(
      docID,
      preferCache: true,
    );
    if (updatedPost == null) return;
    final idx = shorts.indexWhere((e) => e.docID == docID);
    if (idx != -1) {
      shorts[idx] = updatedPost;
      shorts.refresh();
    }
  }

  /// HLS adapter güncelle
  Future<void> refreshVideoController(int idx) async {
    final post = shorts[idx];
    if (cache[idx] != null) {
      await _videoPool.release(cache[idx]!);
      cache.remove(idx);
    }
    if (post.playbackUrl.isNotEmpty) {
      cache[idx] = _videoPool.acquire(
        cacheKey: post.docID,
        url: post.playbackUrl,
        autoPlay: false,
        loop: true,
      );
    }
  }

  void markPlaybackReady(String docId) {
    _playbackCoordinator.markFirstFrame(docId);
  }

  bool _applySnapshotResource(CachedResource<List<PostsModel>> resource) {
    final data = resource.data;
    if (data == null || data.isEmpty) return false;
    _replaceShorts(data);
    hasMore.value = true;
    return true;
  }

  void _replaceShorts(
    List<PostsModel> newItems, {
    bool remapCache = true,
  }) {
    if (_hasSameRenderOrder(shorts, newItems)) {
      return;
    }
    final previous = shorts.toList(growable: false);
    shorts.assignAll(newItems);
    if (remapCache) {
      unawaited(_remapCacheForNewList(
        previous: previous,
        next: newItems,
      ));
    }
  }

  bool _hasSameRenderOrder(
    List<PostsModel> current,
    List<PostsModel> next,
  ) {
    if (identical(current, next)) return true;
    if (current.length != next.length) return false;
    for (int i = 0; i < current.length; i++) {
      if (current[i].docID != next[i].docID) {
        return false;
      }
    }
    return true;
  }

  Future<void> _persistVisibleSnapshot() async {
    final userId = _currentUserId;
    if (userId.isEmpty || shorts.isEmpty) return;
    await _shortSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: shorts.toList(growable: false),
      limit: ContentPolicy.initialPoolLimit(ContentScreenKind.shorts),
      source: CachedResourceSource.server,
    );
  }

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _remapCacheForNewList({
    required List<PostsModel> previous,
    required List<PostsModel> next,
  }) async {
    if (cache.isEmpty) return;

    final adaptersByDocId = <String, HLSVideoAdapter>{};
    final tiersByDocId = <String, _CacheTier>{};

    for (int i = 0; i < previous.length; i++) {
      final docId = previous[i].docID;
      if (docId.isEmpty) continue;
      final adapter = cache[i];
      if (adapter != null) {
        adaptersByDocId[docId] = adapter;
      }
      final tier = _tiers[i];
      if (tier != null) {
        tiersByDocId[docId] = tier;
      }
    }

    final remappedCache = <int, HLSVideoAdapter>{};
    final remappedTiers = <int, _CacheTier>{};
    final retainedDocIds = <String>{};

    for (int i = 0; i < next.length; i++) {
      final docId = next[i].docID;
      final adapter = adaptersByDocId[docId];
      if (adapter != null) {
        remappedCache[i] = adapter;
        retainedDocIds.add(docId);
      }
      final tier = tiersByDocId[docId];
      if (tier != null) {
        remappedTiers[i] = tier;
      }
    }

    final releaseTasks = <Future<void>>[];
    for (final entry in adaptersByDocId.entries) {
      if (retainedDocIds.contains(entry.key)) continue;
      releaseTasks.add(_videoPool.release(entry.value));
    }

    cache
      ..clear()
      ..addAll(remappedCache);
    _tiers
      ..clear()
      ..addAll(remappedTiers);

    if (releaseTasks.isNotEmpty) {
      try {
        await Future.wait(releaseTasks);
      } catch (_) {}
    }
  }
}

enum _CacheTier { hot, warm }

class _ShortPageResult {
  final List<PostsModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const _ShortPageResult({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
  });
}
