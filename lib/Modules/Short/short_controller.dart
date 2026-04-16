import 'dart:math' as math;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import 'package:turqappv2/Core/Repositories/short_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/launch_motor_selection_service.dart';
import 'package:turqappv2/Core/Services/launch_motor_surface_contract.dart';
import 'package:turqappv2/Core/Services/lru_cache.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/network_policy.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/short_surface_mix_service.dart';
import 'package:turqappv2/Core/Services/short_playback_coordinator.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import '../../Models/posts_model.dart';
import '../PlaybackRuntime/playback_cache_runtime_service.dart';
import 'short_feed_application_service.dart';

part 'short_controller_loading_part.dart';
part 'short_controller_cache_part.dart';
part 'short_controller_fields_part.dart';
part 'short_controller_runtime_part.dart';
part 'short_controller_models_part.dart';

abstract class _ShortControllerBase extends GetxController {
  final _state = _ShortControllerState();

  @override
  void onInit() {
    super.onInit();
    _ShortControllerRuntimeX(this as ShortController).handleOnInit();
  }

  @override
  void onClose() {
    _ShortControllerRuntimeX(this as ShortController).handleOnClose();
    super.onClose();
  }
}

/// Kısa videoları Firestore'dan çekip saklayan ve
/// range bazlı (±7 etrafında) preload & prune desteği sunan controller
/// + AKILLI DİNAMİK KARIŞTIRMA SİSTEMİ
class ShortController extends _ShortControllerBase {
  static ShortController ensure() => ensureShortController();

  static ShortController? maybeFind() => maybeFindShortController();

  void _log(String message) => _ShortControllerRuntimeX(this).log(message);

  bool _isEligibleShortPost(PostsModel post) =>
      _ShortControllerRuntimeX(this).isEligibleShortPost(post);

  String playbackHandleKeyForDoc(String docId) => 'short:${docId.trim()}';
}

ShortController ensureShortController() => _ensureShortController();

ShortController? maybeFindShortController() => _maybeFindShortController();
