import 'dart:math' as math;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import 'package:turqappv2/Core/Repositories/short_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/lru_cache.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/short_playback_coordinator.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import '../../Models/posts_model.dart';

part 'short_controller_loading_part.dart';
part 'short_controller_cache_part.dart';
part 'short_controller_fields_part.dart';
part 'short_controller_runtime_part.dart';
part 'short_controller_models_part.dart';

/// Kısa videoları Firestore'dan çekip saklayan ve
/// range bazlı (±7 etrafında) preload & prune desteği sunan controller
/// + AKILLI DİNAMİK KARIŞTIRMA SİSTEMİ
class ShortController extends GetxController {
  static ShortController ensure() => _ensureShortController();

  static ShortController? maybeFind() => _maybeFindShortController();

  void _log(String message) => _ShortControllerRuntimeX(this).log(message);
  final _state = _ShortControllerState();

  bool _isEligibleShortPost(PostsModel post) =>
      _ShortControllerRuntimeX(this).isEligibleShortPost(post);

  @override
  void onInit() {
    super.onInit();
    _ShortControllerRuntimeX(this).handleOnInit();
  }

  @override
  void onClose() {
    _ShortControllerRuntimeX(this).handleOnClose();
    super.onClose();
  }
}
