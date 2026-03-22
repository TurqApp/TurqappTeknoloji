part of 'short_controller.dart';

extension ShortControllerCachePart on ShortController {
  Future<void> _downgradeAdapterForWarmTier(HLSVideoAdapter adapter) async {
    await adapter.pause();
  }

  Future<HLSVideoAdapter?> _preloadSingleVideoWithCache(
    int index,
    PostsModel short, {
    Map<int, HLSVideoAdapter>? targetCache,
  }) async {
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

  Future<void> updateCacheTiers(
    int currentIndex, {
    bool suppressWarmPause = false,
  }) async {
    if (shorts.isEmpty) return;
    final window = _playbackCoordinator.buildWindow(shorts, currentIndex);
    final hotIndices = window.hotIndices;
    final warmIndices = window.warmIndices;

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

    for (final i in hotIndices) {
      final adapter = cache[i];
      if (adapter == null) continue;
      final distance = (i - currentIndex).abs();
      if (distance == 0) {
        adapter
            .setPreferredBufferDuration(ShortController._activeBufferSeconds);
      } else if (distance == 1) {
        adapter.setPreferredBufferDuration(
          ShortController._neighborBufferSeconds,
        );
      } else {
        adapter.setPreferredBufferDuration(ShortController._prepBufferSeconds);
      }
    }

    for (final i in warmIndices) {
      if (cache.containsKey(i) && _tiers[i] != _CacheTier.warm) {
        if (!suppressWarmPause) {
          await _downgradeAdapterForWarmTier(cache[i]!);
        }
        _tiers[i] = _CacheTier.warm;
      }
    }

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

    _enforceMaxPlayers(currentIndex, window.maxAttachedPlayers);

    try {
      PrefetchScheduler.maybeFind()?.updateQueue(
        shorts.map((s) => s.docID).toList(),
        currentIndex,
      );
    } catch (_) {}
  }

  void _enforceMaxPlayers(int currentIndex, int maxAttachedPlayers) {
    final pinnedKeys = <int>{};
    if (defaultTargetPlatform == TargetPlatform.android && currentIndex <= 1) {
      if (cache.containsKey(0)) pinnedKeys.add(0);
      if (cache.containsKey(1)) pinnedKeys.add(1);
    }
    final activeKeys = cache.keys.where((k) => !cache[k]!.isStopped).toList()
      ..sort(
        (a, b) => (a - currentIndex).abs().compareTo((b - currentIndex).abs()),
      );

    _invariantGuard.assertCountWithinLimit(
      surface: 'short',
      invariantKey: 'active_player_overflow',
      observedCount: activeKeys.length,
      maxAllowed: maxAttachedPlayers,
      counterName: 'activePlayers',
      payload: <String, dynamic>{
        'currentIndex': currentIndex,
        'cacheSize': cache.length,
      },
    );

    if (activeKeys.length > maxAttachedPlayers) {
      final trimmableKeys = activeKeys
          .where((k) => !pinnedKeys.contains(k))
          .toList(growable: false);
      final allowedTrimCount = maxAttachedPlayers - pinnedKeys.length < 0
          ? 0
          : maxAttachedPlayers - pinnedKeys.length;
      for (int i = allowedTrimCount; i < trimmableKeys.length; i++) {
        final k = trimmableKeys[i];
        final adapter = cache[k];
        cache.remove(k);
        _tiers.remove(k);
        if (adapter != null) {
          unawaited(_videoPool.release(adapter));
        }
      }
    }
  }

  Future<void> preloadRange(int index, {int range = 1}) async {
    await updateCacheTiers(index);
  }

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

  void pruneOutsideRange(int index, {int range = 2}) {}

  void clearCache() {
    _playbackCoordinator.reset();
    for (final adapter in cache.values) {
      unawaited(_videoPool.release(adapter));
    }
    cache.clear();
    _tiers.clear();
  }

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
}
