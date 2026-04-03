import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_segment_policy.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/playback_execution_service.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';

part 'video_state_manager_playback_part.dart';
part 'video_state_manager_fields_part.dart';
part 'video_state_manager_models_part.dart';
part 'video_state_manager_runtime_part.dart';

VideoStateManager resolveDefaultVideoStateManager() {
  return VideoStateManager.instance;
}

void claimExternalOnDemandFetchForDoc(String docId) {
  resolveDefaultVideoStateManager().claimExternalOnDemandFetch(docId);
}

void releaseExternalOnDemandFetchForDoc(String docId) {
  maybeFindVideoStateManager()?.releaseExternalOnDemandFetch(docId);
}
