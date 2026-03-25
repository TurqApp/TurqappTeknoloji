import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

part 'global_video_adapter_pool_runtime_part.dart';

class GlobalVideoAdapterPool extends GetxService {
  static const int _maxWarmAdapters = 10;

  static GlobalVideoAdapterPool? maybeFind() {
    final isRegistered = Get.isRegistered<GlobalVideoAdapterPool>();
    if (!isRegistered) return null;
    return Get.find<GlobalVideoAdapterPool>();
  }

  static GlobalVideoAdapterPool ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
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
  }) =>
      _GlobalVideoAdapterPoolRuntimeX(this).acquire(
        cacheKey: cacheKey,
        url: url,
        autoPlay: autoPlay,
        loop: loop,
        coordinateAudioFocus: coordinateAudioFocus,
      );

  Future<void> release(
    HLSVideoAdapter adapter, {
    bool keepWarm = true,
  }) =>
      _GlobalVideoAdapterPoolRuntimeX(this).release(
        adapter,
        keepWarm: keepWarm,
      );

  Future<void> clear() => _GlobalVideoAdapterPoolRuntimeX(this).clear();

  HLSVideoAdapter? adapterForTesting(String cacheKey) =>
      _GlobalVideoAdapterPoolRuntimeX(this).adapterForTesting(cacheKey);

  Map<String, dynamic> debugSnapshot() =>
      _GlobalVideoAdapterPoolRuntimeX(this).debugSnapshot();

  @override
  void onClose() {
    unawaited(clear());
    super.onClose();
  }
}

Future<void> resetPlaybackForSurfaceRefresh() async {
  VideoStateManager.instance.pauseAllVideos(force: true);
  VideoStateManager.instance.clearAllStates();
  await GlobalVideoAdapterPool.ensure().clear();
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
