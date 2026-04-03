import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Core/Services/feed_render_coordinator.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/device_session_service.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/audio_focus_coordinator.dart';
import '../../Core/Services/SegmentCache/cache_manager.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/IndexPool/index_pool_store.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/agenda_shuffle_cache_service.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../NavBar/nav_bar_controller.dart';
import 'AgendaContent/agenda_content_controller.dart';
import 'agenda_feed_application_service.dart';

part 'agenda_controller_feed_part.dart';
part 'agenda_controller_lifecycle_part.dart';
part 'agenda_controller_loading_part.dart';
part 'agenda_controller_loading_cache_part.dart';
part 'agenda_controller_loading_shuffle_part.dart';
part 'agenda_controller_constants_part.dart';
part 'agenda_controller_fields_part.dart';
part 'agenda_controller_models_part.dart';
part 'agenda_controller_playback_part.dart';
part 'agenda_controller_render_part.dart';
part 'agenda_controller_reshare_part.dart';
part 'agenda_controller_support_part.dart';

abstract class _AgendaControllerBase extends GetxController {
  final _state = _AgendaControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as AgendaController)._handleLifecycleInit();
  }

  @override
  void onReady() {
    super.onReady();
    (this as AgendaController)._handleLifecycleReady();
  }

  @override
  void onClose() {
    (this as AgendaController)._handleLifecycleClose();
    super.onClose();
  }
}

class AgendaController extends _AgendaControllerBase {
  RxList<PostsModel> get agendaList => _state.agendaList;
  RxInt get centeredIndex => _state.centeredIndex;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  RxBool get isMuted => _state.isMuted;
  RxBool get pauseAll => _state.pauseAll;
}

AgendaController? maybeFindAgendaController() {
  final isRegistered = Get.isRegistered<AgendaController>();
  if (!isRegistered) return null;
  return Get.find<AgendaController>();
}

AgendaController ensureAgendaController({bool permanent = false}) {
  final existing = maybeFindAgendaController();
  if (existing != null) return existing;
  return Get.put(AgendaController(), permanent: permanent);
}

extension AgendaControllerFacadePart on AgendaController {
  int get fetchLimit => ReadBudgetRegistry.feedBufferedFetchLimit;

  AgendaShuffleCacheService get _shuffleCache =>
      ensureAgendaShuffleCacheService();

  void promoteUploadedPosts(
    List<PostsModel> posts, {
    bool scrollToTop = false,
  }) {
    if (posts.isEmpty) return;
    addUploadedPostsAtTop(posts);
    if (scrollToTop && scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }
}
