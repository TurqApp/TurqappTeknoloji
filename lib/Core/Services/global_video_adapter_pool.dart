import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

part 'global_video_adapter_pool_facade_part.dart';
part 'global_video_adapter_pool_fields_part.dart';
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

  final _state = _GlobalVideoAdapterPoolState();

  @override
  void onClose() {
    unawaited(_GlobalVideoAdapterPoolRuntimeX(this).clear());
    super.onClose();
  }
}

Future<void> resetPlaybackForSurfaceRefresh() async {
  VideoStateManager.instance.pauseAllVideos(force: true);
  VideoStateManager.instance.clearAllStates();
  await _GlobalVideoAdapterPoolRuntimeX(GlobalVideoAdapterPool.ensure())
      .clear();
}
