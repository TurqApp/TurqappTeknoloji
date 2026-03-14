import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

class GlobalVideoAdapterPool extends GetxService {
  static const int _maxWarmAdapters = 10;

  static GlobalVideoAdapterPool ensure() {
    if (Get.isRegistered<GlobalVideoAdapterPool>()) {
      return Get.find<GlobalVideoAdapterPool>();
    }
    return Get.put(GlobalVideoAdapterPool(), permanent: true);
  }

  final Map<String, _WarmAdapterEntry> _warmAdapters = {};
  final List<String> _warmOrder = <String>[];
  final Map<HLSVideoAdapter, String> _leasedKeys = <HLSVideoAdapter, String>{};
  final Map<String, int> _leaseCounts = <String, int>{};

  HLSVideoAdapter acquire({
    required String cacheKey,
    required String url,
    bool autoPlay = false,
    bool loop = true,
    bool coordinateAudioFocus = true,
  }) {
    final warmEntry = _warmAdapters.remove(cacheKey);
    _warmOrder.remove(cacheKey);

    HLSVideoAdapter adapter;
    if (warmEntry != null && _isReusable(warmEntry, url, coordinateAudioFocus)) {
      adapter = warmEntry.adapter;
      if (adapter.isDisposed) {
        adapter = _createAdapter(
          url: url,
          autoPlay: autoPlay,
          loop: loop,
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
        coordinateAudioFocus: coordinateAudioFocus,
      );
    }

    _leasedKeys[adapter] = cacheKey;
    _leaseCounts[cacheKey] = (_leaseCounts[cacheKey] ?? 0) + 1;
    _restoreSavedPosition(cacheKey, adapter);
    return adapter;
  }

  Future<void> release(
    HLSVideoAdapter adapter, {
    bool keepWarm = true,
  }) async {
    final cacheKey = _leasedKeys.remove(adapter);
    if (cacheKey == null) {
      if (!adapter.isDisposed) {
        if (keepWarm) {
          await adapter.pause();
        } else {
          adapter.dispose();
        }
      }
      return;
    }

    final remaining = (_leaseCounts[cacheKey] ?? 1) - 1;
    if (remaining > 0) {
      _leaseCounts[cacheKey] = remaining;
    } else {
      _leaseCounts.remove(cacheKey);
    }

    if (adapter.isDisposed) return;

    _saveState(cacheKey, adapter);

    if (!keepWarm || remaining > 0) {
      if (!keepWarm) {
        adapter.dispose();
      } else {
        await adapter.pause();
      }
      return;
    }

    await adapter.pause();

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
      url: adapter.url,
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

  bool _isReusable(
    _WarmAdapterEntry entry,
    String requestedUrl,
    bool coordinateAudioFocus,
  ) {
    return entry.url == requestedUrl &&
        entry.coordinateAudioFocus == coordinateAudioFocus &&
        !entry.adapter.isDisposed;
  }

  HLSVideoAdapter _createAdapter({
    required String url,
    required bool autoPlay,
    required bool loop,
    required bool coordinateAudioFocus,
  }) {
    return HLSVideoAdapter(
      url: url,
      autoPlay: autoPlay,
      loop: loop,
      coordinateAudioFocus: coordinateAudioFocus,
    );
  }

  void _restoreSavedPosition(String cacheKey, HLSVideoAdapter adapter) {
    final state = VideoStateManager.instance.getVideoState(cacheKey);
    if (state == null || state.position <= Duration.zero) return;
    unawaited(adapter.seekTo(state.position));
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
      adapter.dispose();
    }
  }

  @override
  void onClose() {
    unawaited(clear());
    super.onClose();
  }
}

class _WarmAdapterEntry {
  const _WarmAdapterEntry({
    required this.adapter,
    required this.url,
    required this.coordinateAudioFocus,
  });

  final HLSVideoAdapter adapter;
  final String url;
  final bool coordinateAudioFocus;
}
