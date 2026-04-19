part of 'global_video_adapter_pool.dart';

extension _GlobalVideoAdapterPoolRuntimeX on GlobalVideoAdapterPool {
  static const Duration _nonLoopingRestartTailThreshold = Duration(seconds: 5);

  int get _maxWarmAdapters {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _globalVideoAdapterPoolMaxWarmAdaptersAndroid;
    }
    return _globalVideoAdapterPoolMaxWarmAdapters;
  }

  Future<void> _parkAdapter(HLSVideoAdapter adapter) async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (Platform.isAndroid && adapter.preferWarmPoolPause) {
        debugPrint(
          '[PlaybackStopTrace] source=pool_park action=force_silence '
          'preferWarm=${adapter.preferWarmPoolPause}',
        );
        await adapter.forceSilence();
        return;
      }
      debugPrint(
        '[PlaybackStopTrace] source=pool_park action=stop_playback '
        'preferWarm=${adapter.preferWarmPoolPause}',
      );
      await adapter.silenceAndStopPlayback();
      return;
    }
    await adapter.pause();
  }

  HLSVideoAdapter acquire({
    required String cacheKey,
    required String url,
    bool autoPlay = false,
    bool loop = true,
    bool useLocalProxy = true,
    bool coordinateAudioFocus = true,
    bool preferWarmPoolPauseOnAndroid = false,
  }) {
    final sharedLeasedAdapter = _findReusableLeasedAdapter(
      cacheKey: cacheKey,
      requestedUrl: url,
      useLocalProxy: useLocalProxy,
      coordinateAudioFocus: coordinateAudioFocus,
    );
    if (sharedLeasedAdapter != null) {
      _leasedKeys[sharedLeasedAdapter] = cacheKey;
      _leaseCounts[cacheKey] = (_leaseCounts[cacheKey] ?? 0) + 1;
      if (defaultTargetPlatform == TargetPlatform.android &&
          preferWarmPoolPauseOnAndroid) {
        sharedLeasedAdapter.updateWarmPoolPausePreference(true);
      }
      unawaited(sharedLeasedAdapter.setLooping(loop));
      _restoreSavedPosition(cacheKey, sharedLeasedAdapter);
      return sharedLeasedAdapter;
    }

    final warmEntry = _warmAdapters.remove(cacheKey);
    _warmOrder.remove(cacheKey);

    HLSVideoAdapter adapter;
    if (warmEntry != null &&
        _isReusable(
          warmEntry,
          url,
          useLocalProxy,
          coordinateAudioFocus,
        )) {
      adapter = warmEntry.adapter;
      if (adapter.isDisposed) {
        adapter = _createAdapter(
          url: url,
          autoPlay: autoPlay,
          loop: loop,
          useLocalProxy: useLocalProxy,
          coordinateAudioFocus: coordinateAudioFocus,
        );
      } else {
        adapter.prepareForReuse();
        unawaited(adapter.setLooping(loop));
      }
    } else {
      if (warmEntry != null && !warmEntry.adapter.isDisposed) {
        warmEntry.adapter.dispose();
      }
      adapter = _createAdapter(
        url: url,
        autoPlay: autoPlay,
        loop: loop,
        useLocalProxy: useLocalProxy,
        coordinateAudioFocus: coordinateAudioFocus,
      );
    }

    _leasedKeys[adapter] = cacheKey;
    _leaseCounts[cacheKey] = (_leaseCounts[cacheKey] ?? 0) + 1;
    if (defaultTargetPlatform == TargetPlatform.android &&
        preferWarmPoolPauseOnAndroid) {
      adapter.updateWarmPoolPausePreference(true);
    }
    _restoreSavedPosition(cacheKey, adapter);
    return adapter;
  }

  HLSVideoAdapter? _findReusableLeasedAdapter({
    required String cacheKey,
    required String requestedUrl,
    required bool useLocalProxy,
    required bool coordinateAudioFocus,
  }) {
    for (final entry in _leasedKeys.entries) {
      if (entry.value != cacheKey) continue;
      final adapter = entry.key;
      if (adapter.isDisposed) continue;
      final leasedEntry = _WarmAdapterEntry(
        adapter: adapter,
        requestUrl: adapter.originalUrl,
        useLocalProxy: adapter.usesLocalProxy,
        coordinateAudioFocus: adapter.coordinateAudioFocus,
      );
      if (_isReusable(
        leasedEntry,
        requestedUrl,
        useLocalProxy,
        coordinateAudioFocus,
      )) {
        return adapter;
      }
    }
    return null;
  }

  Future<void> release(
    HLSVideoAdapter adapter, {
    bool keepWarm = true,
    bool clearSavedState = false,
  }) async {
    final cacheKey = _leasedKeys[adapter];
    if (cacheKey == null) {
      if (!adapter.isDisposed) {
        if (keepWarm) {
          await _parkAdapter(adapter);
        } else {
          adapter.dispose();
        }
      }
      return;
    }

    final remaining = (_leaseCounts[cacheKey] ?? 1) - 1;
    final activeAdapterCountForKey =
        _leasedKeys.values.where((key) => key == cacheKey).length;
    final adapterStillSharedBySameKey =
        remaining > 0 && activeAdapterCountForKey <= 1;
    debugPrint(
      '[PlaybackStopTrace] source=pool_release cacheKey=$cacheKey '
      'keepWarm=$keepWarm remaining=$remaining '
      'activeForKey=$activeAdapterCountForKey '
      'sharedSameAdapter=$adapterStillSharedBySameKey',
    );
    if (remaining > 0) {
      _leaseCounts[cacheKey] = remaining;
      if (adapterStillSharedBySameKey) {
        return;
      }
    } else {
      _leaseCounts.remove(cacheKey);
    }
    _leasedKeys.remove(adapter);

    if (adapter.isDisposed) return;

    if (clearSavedState || _shouldResetSavedState(adapter)) {
      VideoStateManager.instance.clearVideoState(cacheKey);
    } else {
      _saveState(cacheKey, adapter);
    }

    if (!keepWarm || remaining > 0) {
      if (!keepWarm) {
        adapter.dispose();
      } else {
        await _parkAdapter(adapter);
      }
      return;
    }

    await _parkAdapter(adapter);

    final existing = _warmAdapters[cacheKey];
    if (existing != null && !identical(existing.adapter, adapter)) {
      _warmAdapters.remove(cacheKey);
      _warmOrder.remove(cacheKey);
      if (!existing.adapter.isDisposed) {
        existing.adapter.dispose();
      }
    }

    _warmAdapters[cacheKey] = _WarmAdapterEntry(
      adapter: adapter,
      requestUrl: adapter.originalUrl,
      useLocalProxy: adapter.usesLocalProxy,
      coordinateAudioFocus: adapter.coordinateAudioFocus,
    );
    _warmOrder.remove(cacheKey);
    _warmOrder.add(cacheKey);
    await _trim();
  }

  Future<void> clear() async {
    final adapters = _warmAdapters.values.map((e) => e.adapter).toList();
    _warmAdapters.clear();
    _warmOrder.clear();
    _leasedKeys.clear();
    _leaseCounts.clear();
    for (final adapter in adapters) {
      if (!adapter.isDisposed) {
        adapter.dispose();
      }
    }
  }

  HLSVideoAdapter? adapterForTesting(String cacheKey) {
    for (final entry in _leasedKeys.entries) {
      if (entry.value == cacheKey) return entry.key;
    }
    final warmAdapter = _warmAdapters[cacheKey]?.adapter;
    if (warmAdapter != null) return warmAdapter;

    final normalizedCacheKey = _stripPlaybackNamespace(cacheKey);
    if (normalizedCacheKey.isEmpty) return null;

    for (final entry in _leasedKeys.entries) {
      if (_matchesTestingCacheKey(cacheKey, entry.value)) {
        return entry.key;
      }
    }

    for (final entry in _warmAdapters.entries) {
      if (_matchesTestingCacheKey(cacheKey, entry.key)) {
        return entry.value.adapter;
      }
    }
    return null;
  }

  Map<String, dynamic> debugSnapshot() {
    return <String, dynamic>{
      'warmCount': _warmAdapters.length,
      'maxWarmCount': _maxWarmAdapters,
      'leasedCount': _leasedKeys.length,
      'leaseKeyCount': _leaseCounts.length,
      'warmKeys': _warmOrder.toList(growable: false),
    };
  }

  bool _isReusable(
    _WarmAdapterEntry entry,
    String requestedUrl,
    bool useLocalProxy,
    bool coordinateAudioFocus,
  ) {
    return entry.requestUrl == requestedUrl &&
        entry.useLocalProxy == useLocalProxy &&
        entry.coordinateAudioFocus == coordinateAudioFocus &&
        !entry.adapter.isDisposed;
  }

  HLSVideoAdapter _createAdapter({
    required String url,
    required bool autoPlay,
    required bool loop,
    required bool useLocalProxy,
    required bool coordinateAudioFocus,
  }) {
    return HLSVideoAdapter(
      url: url,
      autoPlay: autoPlay,
      loop: loop,
      useLocalProxy: useLocalProxy,
      coordinateAudioFocus: coordinateAudioFocus,
    );
  }

  void _restoreSavedPosition(String cacheKey, HLSVideoAdapter adapter) {
    if ((Platform.isIOS || Platform.isAndroid) && cacheKey.startsWith('feed:')) {
      return;
    }
    final state = VideoStateManager.instance.getVideoState(cacheKey);
    if (state == null || state.position <= Duration.zero) return;
    unawaited(adapter.seekTo(state.position));
  }

  bool _shouldResetSavedState(HLSVideoAdapter adapter) {
    if (adapter.loop) return false;
    final value = adapter.value;
    if (value.isCompleted) return true;
    final duration = value.duration;
    final position = value.position;
    if (duration <= Duration.zero || position <= Duration.zero) return false;
    if (position >= duration) return true;
    final remaining = duration - position;
    if (remaining <= _nonLoopingRestartTailThreshold) return true;
    final watchedRatio =
        position.inMilliseconds / duration.inMilliseconds.clamp(1, 1 << 30);
    return watchedRatio >= 0.9;
  }

  bool _matchesTestingCacheKey(String requested, String candidate) {
    if (candidate == requested) return true;
    if (candidate.startsWith('${requested}_')) return true;
    return _stripPlaybackNamespace(candidate) ==
        _stripPlaybackNamespace(requested);
  }

  String _stripPlaybackNamespace(String value) {
    final colonIndex = value.indexOf(':');
    if (colonIndex <= 0 || colonIndex >= value.length - 1) {
      return value;
    }
    return value.substring(colonIndex + 1);
  }

  void _saveState(String cacheKey, HLSVideoAdapter adapter) {
    try {
      VideoStateManager.instance.saveVideoState(
        cacheKey,
        HLSAdapterPlaybackHandle(adapter),
      );
    } catch (_) {}
  }

  Future<void> _trim() async {
    while (_warmOrder.length > _maxWarmAdapters) {
      final oldestKey = _warmOrder.removeAt(0);
      final entry = _warmAdapters.remove(oldestKey);
      final adapter = entry?.adapter;
      if (adapter == null || adapter.isDisposed) continue;
      debugPrint(
        '[PlaybackStopTrace] source=pool_trim cacheKey=$oldestKey '
        'warmCount=${_warmOrder.length + 1} maxWarm=$_maxWarmAdapters',
      );
      adapter.dispose();
    }
  }
}
