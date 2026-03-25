import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/feed_render_coordinator.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Core/Services/video_state_manager.dart';
import '../../Core/Services/audio_focus_coordinator.dart';
import '../../Core/Services/SegmentCache/prefetch_scheduler.dart';
import '../../Core/Services/IndexPool/index_pool_store.dart';
import '../../Core/Services/ContentPolicy/content_policy.dart';
import '../../Core/Services/agenda_shuffle_cache_service.dart';
import '../../Core/Services/user_profile_cache_service.dart';
import '../NavBar/nav_bar_controller.dart';
import 'AgendaContent/agenda_content_controller.dart';

part 'agenda_controller_feed_part.dart';
part 'agenda_controller_lifecycle_part.dart';
part 'agenda_controller_loading_part.dart';
part 'agenda_controller_loading_cache_part.dart';
part 'agenda_controller_loading_shuffle_part.dart';
part 'agenda_controller_models_part.dart';
part 'agenda_controller_playback_part.dart';
part 'agenda_controller_render_part.dart';
part 'agenda_controller_reshare_part.dart';
part 'agenda_controller_support_part.dart';

class AgendaController extends GetxController {
  static AgendaController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AgendaController(), permanent: permanent);
  }

  static AgendaController? maybeFind() {
    final isRegistered = Get.isRegistered<AgendaController>();
    if (!isRegistered) return null;
    return Get.find<AgendaController>();
  }

  final scrollController = ScrollController();

  final RxList<PostsModel> agendaList = <PostsModel>[].obs;
  final RxList<Map<String, dynamic>> mergedFeedEntries =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredFeedEntries =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> renderFeedEntries =
      <Map<String, dynamic>>[].obs;
  final Map<String, GlobalKey> _agendaKeys = {};

  final RxBool showFAB = true.obs;
  final RxInt centeredIndex = 0.obs;
  final RxBool playbackSuspended = false.obs;
  int? lastCenteredIndex;
  int _lastPlaybackRowUpdateIndex = -1;
  var isMuted = false.obs;
  DocumentSnapshot? lastDoc;
  bool _usePrimaryFeedPaging = true;
  final RxBool hasMore = true.obs;
  final RxBool isLoading = false.obs;
  final int fetchLimit = 50;
  final pauseAll = false.obs;
  late NavBarController navBarController;
  final RxSet<String> highlightDocIDs = <String>{}.obs;
  Timer? _visibilityDebounce;
  Timer? _feedPrefetchDebounce;
  Timer? _scrollIdleDebounce;
  Timer? _playbackReassertTimer;
  Timer? _reshareWarmupTimer;
  Timer? _resharePostsFetchTimer;
  Timer? _agendaRetryTimer;
  Timer? _deferredInitialNetworkBootstrapTimer;
  int _agendaRetryCount = 0;
  Worker? _mergedFeedWorker;
  Worker? _filteredFeedWorker;
  Worker? _renderFeedWorker;
  final Map<int, double> _visibleFractions = <int, double>{};
  final Map<int, DateTime> _visibleUpdatedAt = <int, DateTime>{};
  String? _lastPlaybackWindowSignature;
  String? _pendingCenteredDocId;
  int _prefetchedThumbnailPostCount = 0;

  final RxSet<String> followingIDs = <String>{}.obs;
  final Rx<FeedViewMode> feedViewMode = FeedViewMode.forYou.obs;
  final RxMap<String, int> myReshares = <String, int>{}.obs;
  final RxList<Map<String, dynamic>> publicReshareEvents =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> feedReshareEntries =
      <Map<String, dynamic>>[].obs;
  final Map<String, bool> _userPrivacyCache = {};
  final Map<String, bool> _userDeactivatedCache = {};

  List<String> hiddenPosts = [];
  double lastOffset = 0.0;
  AgendaShuffleCacheService get _shuffleCache =>
      AgendaShuffleCacheService.ensure();
  bool _ensureInitialLoadInFlight = false;
  Future<void>? _ensureInitialLoadFuture;
  DateTime? _lastEnsureInitialLoadAt;
  DateTime? _lastDeferredInitialNetworkBootstrapAt;
  DateTime? _lastPlaybackCommandAt;
  DateTime? _qaScrollStartedAt;
  double _qaScrollStartOffset = 0.0;
  int _qaScrollSequence = 0;
  String _qaActiveScrollToken = '';
  String _qaLatestScrollToken = '';
  String? _lastPlaybackCommandDocId;
  bool _feedModeFallbackQueued = false;
  int _feedModeFallbackEpoch = 0;
  static const Duration? _agendaWindow = null;
  static const int _reshareScanPostLimit = 12;

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onReady() {
    super.onReady();
    _handleLifecycleReady();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }

  Future<void> addNewReshareEntryWithoutScroll(
    String postId,
    String reshareUserID,
  ) =>
      _performAddNewReshareEntryWithoutScroll(postId, reshareUserID);

  void removeReshareEntry(String postId, String reshareUserID) =>
      _performRemoveReshareEntry(postId, reshareUserID);
}
