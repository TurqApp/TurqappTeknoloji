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

/// Kısa videoları Firestore'dan çekip saklayan ve
/// range bazlı (±7 etrafında) preload & prune desteği sunan controller
/// + AKILLI DİNAMİK KARIŞTIRMA SİSTEMİ
class ShortController extends GetxController {
  static ShortController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ShortController());
  }

  static ShortController? maybeFind() {
    final isRegistered = Get.isRegistered<ShortController>();
    if (!isRegistered) return null;
    return Get.find<ShortController>();
  }

  static const bool _verboseShortLogs = false;
  void _log(String message) {
    if (_verboseShortLogs) debugPrint(message);
  }

  final RxList<PostsModel> shorts = <PostsModel>[].obs;
  final GlobalVideoAdapterPool _videoPool = GlobalVideoAdapterPool.ensure();
  final ShortPlaybackCoordinator _playbackCoordinator =
      ShortPlaybackCoordinator.forCurrentPlatform();
  final Map<int, HLSVideoAdapter> cache = {};
  final Map<int, _CacheTier> _tiers = {};
  final lastIndex = 0.obs;
  Future<void>? _backgroundPreloadFuture;
  Future<void>? _initialLoadFuture;
  static const int _initialPreloadCount = 3;
  static const double _shortLandscapeAspectThreshold = 1.2;

  static final double _activeBufferSeconds =
      defaultTargetPlatform == TargetPlatform.android ? 5.0 : 4.8;
  static final double _neighborBufferSeconds =
      defaultTargetPlatform == TargetPlatform.android ? 3.6 : 3.6;
  static final double _prepBufferSeconds =
      defaultTargetPlatform == TargetPlatform.android ? 2.8 : 3.0;

  bool _isEligibleShortPost(PostsModel post) {
    if (!post.hasPlayableVideo) return false;
    final ar = post.aspectRatio.toDouble();
    if (ar > _shortLandscapeAspectThreshold) {
      return false;
    }
    return true;
  }

  // Dinamik yükleme durumları
  final int pageSize = 20;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isRefreshing = false.obs; // Yenileme durumu
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  // Basit yapı - davranış analizi kaldırıldı

  // Takip edilenler takibi
  final Set<String> _followingIDs = {};
  StreamSubscription? _followingSub;

  /// Kullanıcı özet cache'i — visibility ve rozet kuralını tekrar çözümlememek için tutulur.
  final _authorSummaryCache = LRUCache<String, UserSummary>(
    capacity: 500,
    ttl: const Duration(minutes: 10),
  );
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ShortRepository _shortRepository = ShortRepository.ensure();
  final ShortSnapshotRepository _shortSnapshotRepository =
      ShortSnapshotRepository.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  // Shuffle kontrolü - sadece UYGULAMA AÇILIŞINDA bir kez
  static bool _globalShuffleCompleted = false;

  @override
  void onInit() {
    super.onInit();
    _applyUserCacheQuota();
    _log('[Shorts] 🔄 ShortController.onInit() called');
    _bindFollowingListener();
    // İlk sayfayı manuel yüklemede çağırılacak (ShortView'dan)
  }

  Future<void> _applyUserCacheQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGb = (prefs.getInt('offline_cache_quota_gb') ?? 3).clamp(3, 6);
      final quotaGb = (savedGb + 1).clamp(4, 7);
      await StorageBudgetManager.maybeFind()?.applyPlanGb(quotaGb);
      await SegmentCacheManager.maybeFind()?.setUserLimitGB(quotaGb);
    } catch (e) {
      _log('Shorts cache quota apply error: $e');
    }
  }

  @override
  void onClose() {
    _log('[Shorts] ❌ ShortController.onClose() called');
    _playbackCoordinator.reset();
    clearCache();
    _followingSub?.cancel();
    super.onClose();
  }
}

enum _CacheTier { hot, warm }

class _ShortPageResult {
  final List<PostsModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const _ShortPageResult({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
  });
}
