import 'dart:math' as math;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Services/PerformanceService.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Models/PostsModel.dart';

/// Kısa videoları Firestore'dan çekip saklayan ve
/// range bazlı (±7 etrafında) preload & prune desteği sunan controller
/// + AKILLI DİNAMİK KARIŞTIRMA SİSTEMİ
class ShortController extends GetxController {
  static const bool _verboseShortLogs = false;
  void _log(String message) {
    if (_verboseShortLogs) debugPrint(message);
  }

  final RxList<PostsModel> shorts = <PostsModel>[].obs;
  final Map<int, HLSVideoAdapter> cache = {};
  final Map<int, _CacheTier> _tiers = {};
  final lastIndex = 0.obs;
  Future<void>? _backgroundPreloadFuture;
  static const int _initialPreloadCount = 3;

  // Tier sınırları — Android'de decoder/surface baskısını azaltmak için daha dar pencere.
  static final int _hotAhead =
      defaultTargetPlatform == TargetPlatform.android ? 1 : 5;
  static final int _hotBehind =
      defaultTargetPlatform == TargetPlatform.android ? 0 : 2;
  static final int _warmBehind =
      defaultTargetPlatform == TargetPlatform.android ? 0 : 5;
  static final int _maxPlayers =
      defaultTargetPlatform == TargetPlatform.android ? 2 : 10;
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
  // Shuffle kontrolü - sadece UYGULAMA AÇILIŞINDA bir kez
  static bool _globalShuffleCompleted = false;

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
      final savedGb = prefs.getInt('offline_cache_quota_gb') ?? 3;
      final quotaGb = savedGb.clamp(2, 5);
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
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('TakipEdilenler')
          .get(); // ✅ get() instead of snapshots()

      _followingIDs
        ..clear()
        ..addAll(qs.docs.map((d) => d.id));
    } catch (e) {
      _log('following fetch error: $e');
    }
  }

  Future<_ShortPageResult> _fetchPage(
      {QueryDocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final base = FirebaseFirestore.instance.collection('Posts');

    Query<Map<String, dynamic>> query = base
        .where('arsiv', isEqualTo: false)
        .where('deletedPost', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: nowMs)
        .orderBy('timeStamp', descending: true)
        .limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get();
    } catch (e) {
      final isIndexError = e is FirebaseException
          ? e.code == 'failed-precondition'
          : e.toString().contains('requires an index');
      if (!isIndexError) rethrow;

      Query<Map<String, dynamic>> fallback =
          base.orderBy('timeStamp', descending: true).limit(pageSize);
      if (startAfter != null) {
        fallback = fallback.startAfterDocument(startAfter);
      }
      snap = await fallback.get();
    }

    if (snap.docs.isEmpty) {
      return _ShortPageResult(
          posts: const [], lastDoc: startAfter, hasMore: false);
    }

    final lastDoc = snap.docs.last;
    final allPosts =
        snap.docs.map((d) => PostsModel.fromMap(d.data(), d.id)).toList();

    final rawWithVideo =
        allPosts.where((p) => p.hasPlayableVideo).toList(growable: false);
    if (rawWithVideo.isEmpty) {
      return _ShortPageResult(
          posts: const [], lastDoc: lastDoc, hasMore: false);
    }

    final timeFiltered = rawWithVideo
        .where((p) => (p.timeStamp) <= nowMs)
        .toList(growable: false);
    final arsivFiltered =
        timeFiltered.where((p) => (p.arsiv == false)).toList(growable: false);
    final finalFiltered = arsivFiltered
        .where((p) => (p.deletedPost != true))
        .toList(growable: false);

    if (finalFiltered.isEmpty) {
      return _ShortPageResult(
          posts: const [], lastDoc: lastDoc, hasMore: false);
    }

    final authorIds = finalFiltered.map((e) => e.userID).toSet().toList();
    final Map<String, bool> userPrivacy = await _fetchUsersPrivacy(authorIds);
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

    if (filtered.isEmpty) {
      return _ShortPageResult(
          posts: const [], lastDoc: lastDoc, hasMore: false);
    }

    final hasMoreDocs = snap.docs.isNotEmpty;
    return _ShortPageResult(
        posts: filtered, lastDoc: lastDoc, hasMore: hasMoreDocs);
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
      await loadInitialShorts();

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

      final adapter = HLSVideoAdapter(
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
      print('[Shorts] Refresh blocked - already refreshing or loading');
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

      final newList = List<PostsModel>.from(result.posts);
      newList.shuffle();

      final newCache = <int, HLSVideoAdapter>{};
      final preloadCount = math.min(1, newList.length);
      for (int i = 0; i < preloadCount; i++) {
        await _preloadSingleVideoWithCache(i, newList[i],
            targetCache: newCache);
      }

      final oldAdapters = cache.values.toList(growable: false);

      shorts.assignAll(newList);
      cache
        ..clear()
        ..addAll(newCache);

      _lastDoc = result.lastDoc;
      hasMore.value = result.hasMore;
      lastIndex.value = 0;

      // Eski adapter'ları serbest bırak
      for (final adapter in oldAdapters) {
        try {
          adapter.dispose();
        } catch (_) {}
      }

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
    _log(
        '[Shorts] loadInitialShorts - BAŞLADI (global shuffle completed: $_globalShuffleCompleted)');
    _log(
        '[Shorts] Current shorts list IDs BEFORE: ${shorts.map((s) => s.docID).take(5).toList()}');

    // Sadece gerçekten boşsa sıfırla
    if (shorts.isEmpty) {
      await _tryQuickFillFromPool();
      if (shorts.isNotEmpty) {
        await preloadRange(0, range: 0);
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
      // Mevcut listeyi koruyoruz, sadece eksik cache'leri preload et
      await preloadRange(0, range: 0);
    }

    _log(
        '[Shorts] loadInitialShorts - TAMAMLANDI, shorts.length: ${shorts.length}');
    _log(
        '[Shorts] Current shorts list IDs AFTER: ${shorts.map((s) => s.docID).take(5).toList()}');
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
      // Eğer hiç yükleme yapılmadıysa ilk sayfayı başlat
      if (shorts.isEmpty && !isLoading.value) {
        await _loadNextPage();
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
    } catch (e) {
      print('[Shorts] warmStart error: $e');
    }
  }

  /// Posts query: en yeni -> eski, arsiv=false, deletedPost=false, zaman geldi
  Future<void> _loadNextPage() async {
    _log(
        '[Shorts] _loadNextPage başladı - isLoading: ${isLoading.value}, hasMore: ${hasMore.value}');
    if (isLoading.value || !hasMore.value) return;
    isLoading.value = true;
    try {
      final result = await PerformanceService.traceOperation(
        'shorts_page_load',
        () => _fetchPage(startAfter: _lastDoc),
      );

      if (result.posts.isEmpty) {
        hasMore.value = result.hasMore;
        if (!result.hasMore) {
          _log('[Shorts] Yeni sayfa bulunamadı, hasMore=false');
        }
        return;
      }

      _lastDoc = result.lastDoc;

      final incoming = result.posts;
      if (incoming.isNotEmpty) {
        if (shorts.isEmpty && !_globalShuffleCompleted) {
          final shuffled = List<PostsModel>.from(incoming);
          shuffled.shuffle();
          shorts.addAll(shuffled);
          unawaited(_saveShortsToPool(shuffled));
          _globalShuffleCompleted = true;
        } else {
          shorts.addAll(incoming);
          unawaited(_saveShortsToPool(incoming));
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

  /// Kümelenmiş whereIn ile kullanıcı gizliliklerini çek
  Future<Map<String, bool>> _fetchUsersPrivacy(List<String> uids) async {
    final Map<String, bool> res = {};
    const chunk = 10; // Firestore whereIn max 10
    for (int i = 0; i < uids.length; i += chunk) {
      final part = uids.sublist(i, (i + chunk).clamp(0, uids.length));
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: part)
          .get();
      for (final d in qs.docs) {
        final data = d.data();
        res[d.id] = (data['gizliHesap'] ?? false) == true;
      }
      // whereIn ile bulunamayan kullanıcılar default public varsayılır
      for (final id in part) {
        res.putIfAbsent(id, () => false);
      }
    }
    return res;
  }

  /// Üç katmanlı cache güncellemesi:
  /// HOT  (current-2 ... current+3) : Native player yüklü, ~2 segment buffered
  /// WARM (current-5 ... current-3) : Adapter hayatta, player stopped (network yok)
  /// COLD (geri kalan)              : Tamamen dispose
  Future<void> updateCacheTiers(int currentIndex) async {
    if (shorts.isEmpty) return;

    final hotStart = math.max(0, currentIndex - _hotBehind);
    final hotEnd = math.min(shorts.length - 1, currentIndex + _hotAhead);
    final warmStart = math.max(0, currentIndex - _warmBehind);

    // HOT indekslerini belirle
    final hotIndices = <int>{};
    for (int i = hotStart; i <= hotEnd; i++) {
      hotIndices.add(i);
    }

    // WARM indekslerini belirle (hot'un gerisinde)
    final warmIndices = <int>{};
    for (int i = warmStart; i < hotStart; i++) {
      warmIndices.add(i);
    }

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
        cache[i]!.pause();
        _tiers[i] = _CacheTier.warm;
      }
    }

    // 4. COLD: hot+warm dışındaki her şeyi dispose et
    final allCached = cache.keys.toList();
    for (final k in allCached) {
      if (!hotIndices.contains(k) && !warmIndices.contains(k)) {
        cache[k]?.dispose();
        cache.remove(k);
        _tiers.remove(k);
      }
    }

    // 5. Max player limiti
    _enforceMaxPlayers(currentIndex);

    // 6. Wi-Fi prefetch tetikle
    try {
      Get.find<PrefetchScheduler>().updateQueue(
        shorts.map((s) => s.docID).toList(),
        currentIndex,
      );
    } catch (_) {}
  }

  void _enforceMaxPlayers(int currentIndex) {
    final activeKeys = cache.keys.where((k) => !cache[k]!.isStopped).toList()
      ..sort((a, b) =>
          (a - currentIndex).abs().compareTo((b - currentIndex).abs()));

    if (activeKeys.length > _maxPlayers) {
      for (int i = _maxPlayers; i < activeKeys.length; i++) {
        final k = activeKeys[i];
        if (defaultTargetPlatform == TargetPlatform.android) {
          cache[k]?.dispose();
          cache.remove(k);
          _tiers.remove(k);
        } else {
          cache[k]?.pause();
          _tiers[k] = _CacheTier.warm;
        }
      }
    }
  }

  /// Backward compat: eski callsite'lar için thin wrapper
  Future<void> preloadRange(int index, {int range = 1}) async {
    await updateCacheTiers(index);
  }

  /// Backward compat: eski callsite'lar için thin wrapper
  void pruneOutsideRange(int index, {int range = 2}) {
    // updateCacheTiers zaten prune ediyor, burada ek iş yok
  }

  /// Tamamen temizler
  void clearCache() {
    for (var adapter in cache.values) {
      adapter.dispose();
    }
    cache.clear();
    _tiers.clear();
  }

  // PostModel güncelle
  Future<void> updateShort(String docID) async {
    final doc =
        await FirebaseFirestore.instance.collection('Posts').doc(docID).get();
    if (doc.exists) {
      final updatedPost = PostsModel.fromMap(doc.data()!, doc.id);
      final idx = shorts.indexWhere((e) => e.docID == docID);
      if (idx != -1) {
        shorts[idx] = updatedPost;
        shorts.refresh();
      }
    }
  }

  /// HLS adapter güncelle
  Future<void> refreshVideoController(int idx) async {
    final post = shorts[idx];
    if (cache[idx] != null) {
      cache[idx]!.dispose();
      cache.remove(idx);
    }
    if (post.playbackUrl.isNotEmpty) {
      cache[idx] = HLSVideoAdapter(
        url: post.playbackUrl,
        autoPlay: false,
        loop: true,
      );
    }
  }

  Future<void> _tryQuickFillFromPool() async {
    if (!Get.isRegistered<IndexPoolStore>()) return;
    final pool = Get.find<IndexPoolStore>();
    final fromPool = await pool.loadPosts(
      IndexPoolKind.shortFullscreen,
      limit: ContentPolicy.mobileWarmWindow,
    );
    if (fromPool.isEmpty) return;

    final filtered = fromPool
        .where((p) => p.hasPlayableVideo)
        .where((p) => p.deletedPost != true)
        .toList();
    if (filtered.isEmpty) return;

    final valid = await _validatePoolPostsAndPrune(filtered);
    if (valid.isEmpty) return;

    shorts.assignAll(valid);
    hasMore.value = true;
  }

  Future<void> _saveShortsToPool(List<PostsModel> posts) async {
    if (posts.isEmpty) return;
    if (!Get.isRegistered<IndexPoolStore>()) return;
    await Get.find<IndexPoolStore>().savePosts(
      IndexPoolKind.shortFullscreen,
      posts,
    );
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
        final isPlayable = (data['playbackUrl'] ?? '').toString().isNotEmpty &&
            (data['videoHLSMasterUrl'] ?? '').toString().isNotEmpty;
        final ts =
            (data['timeStamp'] is num) ? (data['timeStamp'] as num).toInt() : 0;
        if (!deleted && !archived && isPlayable && ts <= nowMs) {
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
        validUserIds.add(d.id);
      }
    }

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
            .removePosts(IndexPoolKind.shortFullscreen, invalidIds);
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
