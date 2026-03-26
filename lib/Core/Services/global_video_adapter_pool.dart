import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

part 'global_video_adapter_pool_facade_part.dart';
part 'global_video_adapter_pool_fields_part.dart';
part 'global_video_adapter_pool_runtime_part.dart';

const int _globalVideoAdapterPoolMaxWarmAdapters = 10;

class GlobalVideoAdapterPool extends GetxService {
  final _state = _GlobalVideoAdapterPoolState();

  @override
  void onClose() {
    unawaited(_GlobalVideoAdapterPoolRuntimeX(this).clear());
    super.onClose();
  }
}
