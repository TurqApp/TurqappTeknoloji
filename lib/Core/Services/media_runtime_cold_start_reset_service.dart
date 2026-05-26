import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/SegmentCache/hls_data_usage_probe.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/playback_start_handoff_service.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/hls_player/hls_controller.dart';

Future<void> resetMediaRuntimeForColdStart({
  String source = 'app_launch',
}) async {
  final startedAt = DateTime.now();
  debugPrint('[MediaColdStartReset] status=start source=$source');

  PlaybackStartHandoffService.instance.resetForColdStart(source: source);

  try {
    ensureVideoStateManager().resetRuntimeForColdStart(source: source);
  } catch (error) {
    debugPrint('[MediaColdStartReset] video_state_failed error=$error');
  }

  try {
    maybeFindPrefetchScheduler()?.resetRuntimeForColdStart(source: source);
  } catch (error) {
    debugPrint('[MediaColdStartReset] prefetch_failed error=$error');
  }

  try {
    await maybeFindGlobalVideoAdapterPool()?.clear();
  } catch (error) {
    debugPrint('[MediaColdStartReset] adapter_pool_failed error=$error');
  }

  try {
    maybeFindHlsDataUsageProbe()?.resetSession(label: 'cold_start');
  } catch (error) {
    debugPrint('[MediaColdStartReset] usage_probe_failed error=$error');
  }

  try {
    AudioFocusCoordinator.maybeFind()?.pauseAllAudioPlayers();
  } catch (error) {
    debugPrint('[MediaColdStartReset] audio_focus_failed error=$error');
  }

  try {
    await HLSController.disposeAllNativePlayers();
  } catch (error) {
    debugPrint('[MediaColdStartReset] native_hls_failed error=$error');
  }

  final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
  debugPrint(
    '[MediaColdStartReset] status=done source=$source elapsedMs=$elapsedMs',
  );
}
